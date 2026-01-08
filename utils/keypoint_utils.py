import pandas as pd

def extract_keypoints(file_path_or_data, sets=["hand", "face", "body"]):
    """
    Extract raw keypoints (x, y, confidence) from the dataset based on predefined sets.

    Parameters:
    - file_path_or_data (str or pd.DataFrame): Path to the CSV file or a DataFrame.
    - sets (list): List of sets to include in the output.
                   Options: "hand", "face", "body", "center_face", "arm", "temple", "nose".

    Returns:
    - pd.DataFrame: DataFrame containing the selected keypoint columns (x, y, confidence).
    """

    # Load data
    if isinstance(file_path_or_data, str):
        data = pd.read_csv(file_path_or_data)
    elif isinstance(file_path_or_data, pd.DataFrame):
        data = file_path_or_data
    else:
        raise ValueError("Input must be a file path or a pandas DataFrame.")

    PREDEFINED_SETS = {
        'face': ["Eye", "Pupil", "Chin", "Jaw", "Cheek", "Nostril", "Lip", "Temple", "Nose"], 
        'center_face': ["Eye", "Pupil", "Chin", "Nostril", "Lip", "Nose"],
        'template': ["chin", "OuterEyeBrow", 
                     "Nose",
                     "leftEdgeEyeLeft", "rightEdgeEyeRight", 
                     "leftEdgeLip", "rightEdgeLip"],
        'temple': ["leftTemple", "rightTemple"],   # strict match
        'nose': ["Nose"]        # strict match
    }

    labels = []
    for s in sets:
        labels.extend(PREDEFINED_SETS.get(s, [s]))

    xyconf_cols = []
    for col in data.columns:
        if not (col.endswith("_x_offset") or col.endswith("_y_offset") or col.endswith("_confidence")):
            continue
        for lbl in labels:
            if lbl in ["Nose", "Temple"]:   # strict match
                if col.startswith(lbl + "_"):
                    xyconf_cols.append(col)
                    break
            else:   # substring match
                if lbl in col:
                    xyconf_cols.append(col)
                    break

    return data[xyconf_cols].copy()
