import numpy as np
import pandas as pd
from scipy.stats import pearsonr

def compute_rms(signal):
    """Root mean square of a 1D signal (after centering)."""
    return np.sqrt(np.mean(signal ** 2))

def safe_corr(x, y):
    """Return Pearson r, handling NaNs and constant signals."""
    if len(x) < 2 or x.std() == 0 or y.std() == 0:
        return float("nan")
    r, _ = pearsonr(x, y)
    return r

def fisher_z(r):
    """Apply Fisher Z transform safely."""
    if pd.isna(r) or r >= 1 or r <= -1:
        return float("nan")
    return np.arctanh(r)

_XY_SUFFIX_CANDIDATES = [("_x_offset", "_y_offset"), ("_x", "_y")]

def _xy_cols_for(base, columns):
    """Return (x_col, y_col) for a base using any accepted suffix pair, else (None, None)."""
    for xs, ys in _XY_SUFFIX_CANDIDATES:
        xcol, ycol = f"{base}{xs}", f"{base}{ys}"
        if xcol in columns and ycol in columns:
            return xcol, ycol
    return None, None

def head_center_series_temples(aligned_df):
    """
    Compute head centre series (cx, cy) from the left/right temple midpoint.
    Returns: cx, cy, (Lname, Rname)
    """
    cols = aligned_df.columns
    left_base, right_base = "leftTemple", "rightTemple"

    ax, ay = _xy_cols_for(left_base, cols)
    bx, by = _xy_cols_for(right_base, cols)
    if not (ax and ay and bx and by):
        templeish = [c for c in cols if "Temple" in c or "temple" in c]
        raise ValueError(
            "Could not resolve temple x/y columns. "
            f"Tried suffixes {_XY_SUFFIX_CANDIDATES} for {left_base}/{right_base}. "
            f"Found temple-like columns: {templeish}"
        )

    cx = 0.5 * (aligned_df[ax].to_numpy() + aligned_df[bx].to_numpy())
    cy = 0.5 * (aligned_df[ay].to_numpy() + aligned_df[by].to_numpy())
    return cx, cy

def compute_velocity(cx, cy, fps):
    """
    Central-difference velocity in aligned 2D space (no resampling).
    Returns vx, vy, speed (per second in aligned units).
    """
    n = len(cx)
    if n < 3:
        vx = np.gradient(cx) * fps
        vy = np.gradient(cy) * fps
    else:
        vx = np.empty(n); vy = np.empty(n)
        vx[1:-1] = (cx[2:] - cx[:-2]) * (fps / 2.0)
        vy[1:-1] = (cy[2:] - cy[:-2]) * (fps / 2.0)
        vx[0] = (cx[1] - cx[0]) * fps
        vy[0] = (cy[1] - cy[0]) * fps
        vx[-1] = (cx[-1] - cx[-2]) * fps
        vy[-1] = (cy[-1] - cy[-2]) * fps
    speed = np.sqrt(vx*vx + vy*vy)
    return vx, vy, speed

def calculate_distances(coords):
    """Calculate Euclidean distances between consecutive coordinates."""
    diffs = np.diff(coords, axis=0) # Differences between consecutive points
    distances = np.sqrt(np.sum(diffs**2, axis=1)) # Euclidean distances
    return np.concatenate(([np.nan], distances))  # Add NaN for the first row