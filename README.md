# Fractal Dynamics and Complexity Matching in Noisy Interactions

## Overview
This repository contains the analysis pipeline for two studies that examine the impact of background noise on the structure of postural dynamics and complexity matching, in naturalistic social interactions.

Pairs of participants engaged in conversation under various levels of background noise. Movement data was collected via on-body sensors (Study 1) or pose estimation (Study 2). Root-mean-square (RMS) and alpha (via Detrended Fluctuation Analysis) were calculated for each movement time series. These values were also cross-correlated within pairs, to determine linear covariance (RMS) and complexity matching (alpha).

## Set Up Instructions
For new users, please refer to the set-up instructions [here](Setup/SETUP.md) for details on cloning this repository and setting up a virtual environment.

**Important**: This repository uses both Python and R in Jupyter Notebooks. In order to integrate R and Jupyter, please refer to the instructions located [here](Setup/SETUP_R.md).

## Processing Pipeline

### Accessing the Raw Data
The data for both studies can be downloaded from the [Open Science Framework](https://osf.io/3a59k/overview?view_only=0d3bb8b3c2cb4dc58717154d288c7d03).

Once downloaded, the data should be placed in the project root directory with the following structure:

```
Movement_Dynamics_In_Noise/
├── final datasets/ # OIRs and movement data for mixed effects models 
│   ├── study1/              # Final study 1 data
│   ├── study2/              # Final study 2 data
├── raw data/ # The original raw time series data
│   ├── study1/              # Raw study 1 movement data (.csv files)
│   ├── study2/              # Raw study 2 movement data (.csv files)
│   └── study2_conditions.csv   # Conditions mapping for Study 2
├── stimuli/    # Audio stimuli and background noise envelope information
│   ├── study1/              # Study 1 stimuli (.wav and .csv files)
│   ├── study2/              # Study 2 stimuli (.wav and .csv files)
├── results/    # All preliminary datasets constructed using the analysis pipeline are placed here
└── [other project files]
```

### Study 1

#### Movement Data Processing
1. **[dfaAnalysisStudy1.ipynb](dfaAnalysisStudy1.ipynb)**: Pre-processes the data and calculates:
   - Alpha (DFA - Detrended Fluctuation Analysis)
   - RMS (Root Mean Square)
   - Complexity matching
   - RMS cross-correlation
   - Outputs saved to [`results/study1/`](results/study1/)

2. **[mergeDatasets.ipynb](mergeDatasets.ipynb)**: Merges movement data with OIRs (Other-initiated repair sequences) data

3. **[R_MEMs.ipynb](R_MEMs.ipynb)**: Implements functionality from `lmerTest` and `ggplot2` to:
   - Run Mixed-Effects Models (MEMs)
   - Create visualizations for both studies
   - Generate figures for manuscript

#### Stimuli Processing
- **[dfaAudio.ipynb](dfaAudio.ipynb)**: Analyzes background noise audio files
  - Processes audio from [`stimuli/study1/`](stimuli/study1/)

### Study 2

#### Movement Data Processing
1. **[dfaAnalysisStudy2.ipynb](dfaAnalysisStudy2.ipynb)**: Pre-processes the data and calculates:
   - Alpha (DFA - Detrended Fluctuation Analysis)
   - RMS (Root Mean Square)
   - Complexity matching
   - RMS cross-correlation
   - Outputs saved to [`results/study2/`](results/study2/)

2. **[mergeDatasets.ipynb](mergeDatasets.ipynb)**: Merges movement data with OIRs data

3. **[R_MEMs_Combined.ipynb](R_MEMs_Combined.ipynb)**: Implements functionality from `lmerTest` and `ggplot2` to:
   - Run Mixed-Effects Models (MEMs)
   - Create visualizations for both studies
   - Generate figures for manuscript

#### Stimuli Processing
- **[dfaAudio.ipynb](dfaAudio.ipynb)**: Analyzes background noise audio files
  - Processes audio from [`stimuli/study2/`](stimuli/study2/)

### Supplementary Materials
- **[R_MEMs_Supplementary.ipynb](R_MEMs_Supplementary.ipynb)**: This provides the statistical analyses and visualisations for information found in the supplementary materials of the paper listed below (Macpherson et al., submitted).

### Output Folders
- **[`results/study1/`](results/study1/)**: Saves DFA, RMS, OIRS data, and correlation analyses for Study 1
- **[`results/study2/`](results/study2/)**: Saves DFA, RMS, OIRS data, and correlation analyses for Study 2
- **[`figures/manuscript/`](figures/manuscript/)**: Figures for the main manuscript
- **[`figures/supplementary/`](figures/supplementary/)**: Supplementary figures

## Associated Publications
Macpherson, M. C., Miles, K., Weisser, A., Luthy, B., Buchholz, J. M., Carlile, S., & Richardson, M. J. (submitted). Background noise shapes fractal dynamics and complexity matching during social interaction.