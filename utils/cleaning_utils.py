import numpy as np
import pandas as pd
from scipy.stats import linregress
from scipy.signal import butter, filtfilt, sosfiltfilt

def load_data(file_path):
    """
    Load data from a CSV file into a pandas DataFrame.

    Parameters
    file_path : str
        Path to the CSV file.

    Returns
    pd.DataFrame or None
        Loaded DataFrame, or None if file not found.
    """
    try:
        return pd.read_csv(file_path)
    except FileNotFoundError:
        print(f"File not found: {file_path}")
        return None

def normalize_by_resolution(df, width=720, height=720):
    """
    Normalize keypoint coordinates in a DataFrame by resolution.
    - Raw coordinates (0 → width/height) are scaled to [0, 1].
    - Offset coordinates (-width/2 → +width/2, etc.) are scaled to [-1, 1].

    Parameters
    df : pd.DataFrame
        DataFrame containing keypoint coordinates.
    width : int
        Width of the video frame (default: 720).
    height : int
        Height of the video frame (default: 720).

    Returns
    pd.DataFrame
        Normalized DataFrame with coordinates scaled to [0, 1] or [-1, 1].
    """
    df = df.copy()

    # === Raw coordinates (0 → width/height) → scale to [0,1]
    raw_x_cols = [col for col in df.columns if col.endswith("_x") and "_offset" not in col]
    raw_y_cols = [col for col in df.columns if col.endswith("_y") and "_offset" not in col]
    df[raw_x_cols] = df[raw_x_cols] / width
    df[raw_y_cols] = df[raw_y_cols] / height

    # === Offset coordinates (-width/2 → +width/2, etc.) → scale to [-1,1]
    offset_x_cols = [col for col in df.columns if col.endswith("_x_offset")]
    offset_y_cols = [col for col in df.columns if col.endswith("_y_offset")]
    df[offset_x_cols] = df[offset_x_cols] / (width / 2)
    df[offset_y_cols] = df[offset_y_cols] / (height / 2)

    return df

def mask_low_confidence(df, threshold=0.3):
    """
    Replace keypoint coordinates with NaN if confidence < threshold.
    Works with columns ending in '_confidence'.

    Parameters
    df : pd.DataFrame
        DataFrame containing keypoint coordinates and confidence scores.
    threshold : float
        Confidence threshold below which coordinates are masked (default: 0.3).

    Returns
    pd.DataFrame
        DataFrame with low-confidence coordinates replaced by NaN.
    """
    df = df.copy()
    conf_cols = [c for c in df.columns if c.endswith("_confidence")]
    
    for conf_col in conf_cols:
        base = conf_col.rsplit("_", 1)[0]  # remove "_confidence"
        
        x_col = f"{base}_x_offset"
        y_col = f"{base}_y_offset"
        
        if x_col in df.columns and y_col in df.columns:
            mask = df[conf_col] < threshold
            df.loc[mask, x_col] = np.nan
            df.loc[mask, y_col] = np.nan
            
            # Optional: mask raw x/y too if present
            raw_x, raw_y = f"{base}_x", f"{base}_y"
            if raw_x in df.columns and raw_y in df.columns:
                df.loc[mask, raw_x] = np.nan
                df.loc[mask, raw_y] = np.nan
    
    return df

def filter_data_safe_preserve_nans(
    df: pd.DataFrame,
    fs: float = 60.0,
    cutoff: float = 10.0,
    order: int = 4,
    audit: bool = True,
) -> pd.DataFrame:
    """
    Low‑pass each numeric column with zero‑phase Butterworth (sosfiltfilt),
    filling gaps only internally for stability, then RESTORING original NaNs.
    - If the series is too short or filtering fails, returns the original column (NaNs intact).

    Parameters:
    - df (pd.DataFrame): Input DataFrame with data to be filtered.
    - fs (float): Sampling rate of the data (default: 60.0).
    - cutoff (float): Cutoff frequency for the low-pass filter (default: 10.0).
    - order (int): Order of the Butterworth filter (default: 4).
    - audit (bool): If True, prints summary of unfiltered columns (default: True).

    Returns:
    - pd.DataFrame: DataFrame with filtered numeric columns.
    """
    out = df.copy()
    num_cols = [c for c in out.columns if pd.api.types.is_numeric_dtype(out[c])]
    if not num_cols:
        return out

    # Butterworth design
    wn = cutoff / (fs / 2.0)
    wn = min(max(wn, 1e-6), 0.999999)  # clamp to (0,1)
    sos = butter(order, wn, btype='low', output='sos')

    all_nan_before, too_short, pad_failed = [], [], []

    for c in num_cols:
        x = out[c].to_numpy(dtype=float, copy=True)
        finite = np.isfinite(x)

        if not finite.any():
            all_nan_before.append(c)
            continue

        # Internal fill for filter stability (linear across gaps + hold edges)
        idx = np.arange(x.size)
        x_filled = x.copy()
        if not finite.all():
            x_filled[~finite] = np.interp(idx[~finite], idx[finite], x[finite])
            first, last = np.where(finite)[0][[0, -1]]
            x_filled[:first] = x_filled[first]
            x_filled[last+1:] = x_filled[last]

        # Heuristic minimum length for filtfilt
        min_len = max(25, 4 * order + 5)
        if x_filled.size < min_len:
            too_short.append(c)
            # Keep original (but ensure original NaNs remain)
            out[c] = x
            continue

        # Filter; if it fails (padding issues), keep original
        try:
            y = sosfiltfilt(sos, x_filled, padtype='odd')
        except Exception:
            pad_failed.append(c)
            out[c] = x
            continue

        # Restore genuine missing samples
        y[~finite] = np.nan
        out[c] = y

    if audit:
        if all_nan_before:
            print(f"[filter_data_safe_preserve_nans] All‑NaN (unchanged): {len(all_nan_before)} cols (e.g., {all_nan_before[:5]})")
        if too_short:
            print(f"[filter_data_safe_preserve_nans] Unfiltered (too short): {len(too_short)} cols (e.g., {too_short[:5]})")
        if pad_failed:
            print(f"[filter_data_safe_preserve_nans] Unfiltered (pad failure): {len(pad_failed)} cols (e.g., {pad_failed[:5]})")

    return out

def interpolate_nans(data, max_gap=60): 
    """
    Linearly interpolate NaN values in a DataFrame or Series, 
    but only for gaps <= max_gap. Longer gaps remain NaN.

    Parameters:
    - data (pd.DataFrame or pd.Series): The data with potential NaN values.
    - max_gap (int): Maximum number of consecutive NaNs to fill.

    Returns:
    - pd.DataFrame or pd.Series: Data with NaN values linearly interpolated 
      where gaps <= max_gap.
    """
    if isinstance(data, pd.DataFrame):
        return data.interpolate(
            method='linear', 
            axis=0, 
            limit=max_gap, 
            limit_direction='both'
        )
    elif isinstance(data, pd.Series):
        return data.interpolate(
            method='linear', 
            limit=max_gap, 
            limit_direction='both'
        )
    else:
        raise TypeError("Input must be a pandas DataFrame or Series.")

def butter_lowpass(cutoff, fs, order=4):
    """
    Design a Butterworth lowpass filter.

    Parameters:
    cutoff (float): The cutoff frequency of the filter.
    fs (float): The sampling rate of the signal.
    order (int): The order of the filter.

    Returns:
    tuple: Filter coefficients (b, a).
    """
    nyq = 0.5 * fs  # Nyquist frequency
    normal_cutoff = cutoff / nyq  # Normalized cutoff frequency
    b, a = butter(order, normal_cutoff, btype='low', analog=False)  # Butterworth filter design
    return b, a

def apply_filter(data, cutoff=10, fs=60, order=4):
    """
    Apply a lowpass Butterworth filter to the data.

    Parameters:
    data (array-like): The input data to be filtered.
    cutoff (float): The cutoff frequency of the filter.
    fs (float): The sampling rate of the signal.
    order (int): The order of the filter.

    Returns:
    array-like: The filtered data.
    """
    b, a = butter_lowpass(cutoff, fs, order)  # Get filter coefficients
    y = filtfilt(b, a, data)  # Apply the filter to the data
    return y

def filter_data(df, cutoff=10.0, fs=60.0, order=4):
    """
    Apply a lowpass filter to each numeric column in a DataFrame, ignoring columns with all NaN values.

    Parameters:
    df (pd.DataFrame): The input DataFrame with data to be filtered.

    Returns:
    pd.DataFrame: The filtered DataFrame.
    """
    df = df.copy()  # Make a copy to avoid modifying the original DataFrame
    
    for column in df.columns:
        # Skip columns with all NaN values
        if df[column].isna().all():
            print(f"Skipping column with all NaN values: {column}")
            continue
        
        try:
            # Replace NaNs with 0 for filtering, but preserve original NaNs
            column_data = df[column].fillna(0)
            filtered_data = apply_filter(column_data, cutoff=cutoff, fs=fs, order=order)
            # Restore original NaNs after filtering
            df[column] = np.where(df[column].isna(), np.nan, filtered_data)
        except Exception as e:
            print(f"Error applying filter to column {column}: {e}")
    
    return df

def get_window_indices(data_length, window_size, overlap):
    """
    Generate start and end indices for sliding windows over data.
    
    Parameters:
    data_length : int
        Length of the data series.
    window_size : int
        Size of each window.
    overlap : float
        Fractional overlap between windows (0 to <1).

    Returns:
    list of tuples
        List of (start, end) index tuples for each window.
    """
    step = int(window_size * (1 - overlap))
    return [(start, start + window_size) for start in range(0, data_length - window_size + 1, step)]
    
def linear_detrend(df, columns=None):
    """
    Removes linear trends from numeric columns by subtracting the best-fit line.
    If columns is None, applies to all numeric columns.

    Parameters:
    df : pd.DataFrame
        Input DataFrame.
    columns : list of str, optional
        List of column names to detrend. If None, all numeric columns are detrended.

    Returns:
    pd.DataFrame
        Detrended DataFrame.
    """

    df_detrended = df.copy()
    if columns is None:
        columns = df_detrended.select_dtypes(include=[np.number]).columns

    for col in columns:
        x = np.arange(len(df_detrended[col]))
        slope, intercept, _, _, _ = linregress(x, df_detrended[col])
        df_detrended[col] = df_detrended[col] - (slope * x + intercept)

    return df_detrended

def normalize_data(data, norm):
    if norm == 1:
        return (data - np.min(data)) / (np.max(data) - np.min(data))  # Unit interval
    elif norm == 2:
        return (data - np.mean(data)) / np.std(data)  # Z-score
    elif norm == 3:
        return data - np.mean(data)  # Center around mean
    else:
        return data  # No normalization
    
