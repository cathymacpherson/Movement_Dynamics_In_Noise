import numpy as np

# Custom DFA function
def dfa(data, min_window_size=8):
    """
    Standard (univariate) Detrended Fluctuation Analysis (DFA).

    - Mean subtraction and integration of the input signal.
    - Linear detrending within non-overlapping windows at multiple scales.
    - Calculates root-mean-square fluctuation at each scale.
    - Estimates scaling exponent (alpha) from log-log regression.

    Args:
        data (np.ndarray): 1D time series array (length N).
        min_window_size (int): Minimum scale (window size) to start from.

    Returns:
        tuple:
            alpha (float): Estimated scaling exponent.
            scales (np.ndarray): Array of scales (window sizes).
            flucts (np.ndarray): RMS fluctuation at each scale.
            fit_line (np.ndarray): Fitted log-log line for plotting.
    """
    N = len(data)
    data = np.cumsum(data - np.mean(data))    #integrate data
    flucts = []
    scales = np.logspace(np.log10(min_window_size), np.log10(N//4), num=16, dtype=int)
    scales = np.unique(scales)  # Remove duplicate scales
    for scale in scales:
        rms_vals = []
        for i in range(0, N, scale):
            if i + scale < N:
                segment = data[i:i+scale]
                trend = np.polyfit(np.arange(scale), segment, 1)
                fit = np.polyval(trend, np.arange(scale))
                rms = np.sqrt(np.mean((segment - fit) ** 2))
                rms_vals.append(rms)
        flucts.append(np.mean(rms_vals))
    flucts = np.array(flucts)
    scales = np.array(scales)
    coeffs = np.polyfit(np.log(scales), np.log(flucts), 1)
    alpha = coeffs[0]
    fit_line = np.polyval(coeffs, np.log(scales))
    return alpha, scales, flucts, fit_line

# Function to perform DFA
def perform_dfa_for_plotting(data, min_window_size=8):
    """
    Applies DFA to each column in a DataFrame for plotting purposes.

    - Normalizes each time series (z-scoring).
    - Computes DFA alpha and fluctuation curves per signal.
    - Useful for visualizing log-log scaling of fluctuation magnitude.

    Args:
        data (pd.DataFrame): Each column is a 1D time series.
        min_window_size (int): Minimum window size to use in DFA.

    Returns:
        dict: For each column, returns:
              {'alpha', 'scales', 'flucts', 'fit_line'}
    """
    dfa_results = {}
    for column in data.columns:
        data.loc[:, column] = (data[column] - data[column].mean()) / data[column].std()
        alpha, scales, flucts, fit_line = dfa(data[column], min_window_size)
        dfa_results[column] = {'alpha': alpha, 'scales': scales, 'flucts': flucts, 'fit_line': fit_line}
    return dfa_results

def perform_dfa(data, min_window_size=8):
    """
    Applies DFA to each column in a DataFrame and returns only the alpha values.

    - Normalizes each time series (z-scoring).
    - Computes DFA alpha (scaling exponent) for each signal.

    Args:
        data (pd.DataFrame): Each column is a 1D time series.
        min_window_size (int): Minimum window size to use in DFA.

    Returns:
        dict: Mapping from column name to alpha value.
    """
    dfa_results = {}
    for column in data.columns:
        data.loc[:, column] = (data[column] - data[column].mean()) / data[column].std()
        alpha, scales, flucts, fit_line = dfa(data[column], min_window_size)
        dfa_results[column] = alpha  # Only store alpha for simplicity
    return dfa_results



