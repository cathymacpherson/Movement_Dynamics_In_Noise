import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

def order_xy_pairs(columns):
    """
    Order columns so left/right pairs are grouped consistently.
    Uses skeleton-like pairing logic instead of pure alphabetical.

    Parameters
    ----------  
    columns : list
        List of column names (e.g., ['LTemple_x_offset', 'LTemple_y_offset', ...])
    """
    
    ordered = []
    used = set()

    # Extract all base labels (without x/y)
    base_labels = sorted({c.rsplit("_", 2)[0] for c in columns if c.endswith(("_x_offset", "_y_offset"))})

    for base in base_labels:
        if base in used:
            continue

        if base.startswith("L") or base.startswith("R"):
            root = base[1:]  # strip L/R
            for side in ["L", "R"]:
                candidate = f"{side}{root}"
                x_col = f"{candidate}_x_offset"
                y_col = f"{candidate}_y_offset"
                if x_col in columns and y_col in columns:
                    ordered.extend([x_col, y_col])
                    used.add(candidate)
        else:
            # Midline keypoint
            x_col = f"{base}_x_offset"
            y_col = f"{base}_y_offset"
            if x_col in columns and y_col in columns:
                ordered.extend([x_col, y_col])
            used.add(base)

    return ordered

def build_symmetric_face_template(X_raw, expected_cols, mode="none"):
    """
    Build a global facial template with optional symmetrization.
    
    Parameters
    ----------
    X_raw : pd.DataFrame
        Concatenated raw keypoint data across participants/sessions.
    expected_cols : list
        List of facial column names (x/y offsets).
    mode : str
        Symmetrization mode:
        - "nose": center the nose horizontally
        - "full": symmetrize all left/right facial pairs
        - "none": return raw mean template
    
    Returns
    -------
    np.ndarray
        Template as (n_points, 2) array.
    """
    # Average position of each keypoint
    template = np.array([
        [X_raw[col_x].mean(), X_raw[col_y].mean()]
        for col_x, col_y in zip(expected_cols[::2], expected_cols[1::2])
    ])

    if mode == "none":
        return template

    mid_x = (template[:, 0].max() + template[:, 0].min()) / 2

    if mode == "nose":
        try:
            nose_idx = next(i for i, n in enumerate(expected_cols[::2]) if "Nose" in n)
        except StopIteration:
            raise ValueError("No Nose keypoint found in expected_cols for nose symmetrization")
        x_shift = mid_x - template[nose_idx, 0]
        template[:, 0] += x_shift
        return template

    if mode == "full":
        for i, name in enumerate(expected_cols[::2]):
            if "L" in name:
                mirror_name = name.replace("L", "R")
            elif "R" in name:
                mirror_name = name.replace("R", "L")
            else:
                continue

            try:
                j = next(idx for idx, n in enumerate(expected_cols[::2]) if mirror_name in n)
            except StopIteration:
                continue

            xi, yi = template[i]
            xj, yj = template[j]
            xi_ref = mid_x - (xi - mid_x)
            xj_ref = mid_x - (xj - mid_x)
            avg_x, avg_y = (xi_ref + xj) / 2, (yi + yj) / 2
            template[i] = [avg_x, avg_y]
            template[j] = [avg_x, avg_y]
        return template

    raise ValueError(f"Unknown symmetrization mode: {mode}")

def plot_alignment_diagnostics_face(global_template, raw_windows, expected_cols,
                                    align_keypoints, n_samples=2,
                                    procrustes=True, allow_rotation=True,
                                    reference="Nose"):
    """
    Overlay the global face template with several raw, post-reference, and aligned trial means.
    Panels:
    1. Before alignment
    2. After reference subtraction (pre-Procrustes)
    3. After full alignment (Procrustes)
    Parameters
    ----------
    global_template : np.ndarray
        Global template pose (n_points x 2).
    raw_windows : list of tuples
        Each tuple is (window_df, metadata) for a trial/window.
    expected_cols : list
        List of facial column names (x/y offsets).
    align_keypoints : function
        Function to align keypoints for one trial/window.
    n_samples : int, default 2
        Number of random samples to plot.
    procrustes : bool, default True
        Whether to apply Procrustes alignment.
    allow_rotation : bool, default True
        Allow rotation in Procrustes alignment.
    reference : str, default "Nose"
        Keypoint used for centering.
    """

    n_points = len(expected_cols) // 2
    sample_indices = np.linspace(0, len(raw_windows)-1,
                                 min(n_samples, len(raw_windows))).astype(int)

    fig, axes = plt.subplots(1, 3, figsize=(18, 6), constrained_layout=True)
    titles = ["Before Alignment", "Post-Reference (pre-Procrustes)", "After Alignment"]

    for ax, title in zip(axes, titles):
        ax.set_aspect("equal")
        ax.set_title(title)
        ax.axhline(0, color="lightgrey", linewidth=0.8)
        ax.axvline(0, color="lightgrey", linewidth=0.8)
        ax.grid(True, linestyle="--", alpha=0.4)

    colors = plt.cm.tab10.colors

    # --- Build lookup once: {"Nose": 0, "LTemple": 1, ...}
    kp_names = [c.replace("_x_offset", "").replace("_y_offset", "")
                  .replace("_x", "").replace("_y", "")
                for c in expected_cols[::2]]
    kp_to_idx = {name: i for i, name in enumerate(kp_names)}

    if reference not in kp_to_idx:
        raise ValueError(f"Reference '{reference}' not found in expected_cols")

    ref_idx = kp_to_idx[reference]

    # For global axis limits
    all_coords = []

    for i, idx in enumerate(sample_indices):
        window_df, _ = raw_windows[idx]
        color = colors[i % len(colors)]

        coords = window_df[expected_cols].values.reshape(-1, n_points, 2)
        mean_coords = coords.mean(axis=0)

        # --- Step 1: raw
        axes[0].scatter(mean_coords[:, 0], mean_coords[:, 1],
                        c=[color], label=f"sample {i}", s=20)
        all_coords.append(mean_coords)

        # --- Step 2: reference subtraction only
        ref_coords = mean_coords - mean_coords[ref_idx]
        axes[1].scatter(ref_coords[:, 0], ref_coords[:, 1],
                        c=[color], s=20)
        all_coords.append(ref_coords)

        # --- Step 3: full alignment
        aligned, *_ = align_keypoints(window_df, expected_cols,
                            reference=reference,
                            template=global_template,
                            use_procrustes=procrustes,
                            allow_rotation=allow_rotation)

        aligned_coords = aligned.mean(axis=0).reshape(n_points, 2)
        axes[2].scatter(aligned_coords[:, 0], aligned_coords[:, 1],
                        c=[color], s=20)
        all_coords.append(aligned_coords)

    # Overlay global template
    for ax in axes:
        ax.scatter(global_template[:, 0], global_template[:, 1],
                   c="black", marker="x", s=40, label="Template")

    # --- Set common axis limits ---
    all_coords = np.vstack(all_coords + [global_template])
    x_min, x_max = all_coords[:, 0].min(), all_coords[:, 0].max()
    y_min, y_max = all_coords[:, 1].min(), all_coords[:, 1].max()

    # Add margin for clarity
    margin_x = 0.05 * (x_max - x_min)
    margin_y = 0.05 * (y_max - y_min)

    for ax in axes:
        ax.set_xlim(x_min - margin_x, x_max + margin_x)
        ax.set_ylim(y_min - margin_y, y_max + margin_y)

    axes[0].legend()
    plt.show()

def compute_procrustes_transform(template, trial_mean, allow_rotation=True):
    """
    Compute Procrustes transform, optionally without rotation.
    Parameters
    ----------
    template : np.ndarray
        Global template pose (n_points x 2). 
        trial_mean : np.ndarray
        Mean pose of the trial (n_points x 2).
    allow_rotation : bool, default True
        Allow rotation in Procrustes alignment.
     -----------
   """

    template_c = template - template.mean(axis=0)
    trial_c = trial_mean - trial_mean.mean(axis=0)

    norm_template = np.linalg.norm(template_c)
    norm_trial = np.linalg.norm(trial_c)
    template_c /= norm_template
    trial_c /= norm_trial

    if allow_rotation:
        U, _, Vt = np.linalg.svd(trial_c.T @ template_c)
        R = U @ Vt
    else:
        R = np.eye(2)  # identity matrix, no rotation

    scale = norm_template / norm_trial
    t = template.mean(axis=0) - scale * trial_mean.mean(axis=0) @ R
    return R, scale, t

def align_face_keypoints(df, keypoint_names, reference="Nose",
                         template=None, use_procrustes=False,
                         allow_rotation=True):
    """
    Align facial keypoints for a trial (or stack of frames).
    
    Parameters
    ----------
    df : pd.DataFrame
        Data for one trial/window.
    keypoint_names : list
        List of facial keypoint columns (x/y offsets).
    reference : str, default "Nose"
        Keypoint used for centering (must exist in df).
    template : np.ndarray, optional
        Global template pose (n_points x 2).
    use_procrustes : bool, default False
        Apply Procrustes (rotation/scale/translation) if True.
    allow_rotation : bool, default True
        Allow rotation in Procrustes alignment.
    
    Returns
    -------
    np.ndarray
        Aligned data as (n_frames, n_points*2).
    tuple
        Shape of the template (n_points, 2).
    """
    n_points = len(keypoint_names) // 2
    coords_all = df.values.reshape(len(df), n_points, 2)

    if np.isnan(coords_all).any() or np.isinf(coords_all).any():
        raise ValueError("[SKIP] NaN/Inf detected during alignment.")

    # --- Step 1: reference subtraction (Nose or other facial anchor) ---
    if f"{reference}_x_offset" not in df.columns or f"{reference}_y_offset" not in df.columns:
        raise ValueError(f"Reference keypoint {reference} not found in dataframe.")

    ref_x = df[f"{reference}_x_offset"].mean()
    ref_y = df[f"{reference}_y_offset"].mean()

    coords_all[:, :, 0] -= ref_x
    coords_all[:, :, 1] -= ref_y

    if not use_procrustes:
        return coords_all.reshape(len(df), n_points*2), (n_points, 2)

    if template is None:
        raise ValueError("Template required when use_procrustes=True")

    # --- Step 2: Procrustes using mean pose of this stack ---
    trial_mean = coords_all.mean(axis=0)  # (n_points, 2)
    R, scale, t = compute_procrustes_transform(template, trial_mean, allow_rotation)
    aligned_frames = np.array([scale * c @ R + t for c in coords_all])

    return aligned_frames.reshape(len(df), n_points*2), (n_points, 2)

def rebuild_aligned_dataframe(aligned_X, expected_cols):
    """
    Rebuild a DataFrame from aligned_X ensuring consistent keypoint ordering.
    aligned_X: np.ndarray of shape (n_frames, n_points*2)
    expected_cols: list of keypoint columns [kp1_x, kp1_y, kp2_x, kp2_y, ...]
    """
    n_points = len(expected_cols) // 2
    poses = aligned_X.reshape(-1, n_points, 2)

    data = {}
    for idx, base_label in enumerate(expected_cols[::2]):
        data[base_label] = poses[:, idx, 0]   # x
        data[expected_cols[2*idx+1]] = poses[:, idx, 1]  # y
    return pd.DataFrame(data)[expected_cols]
