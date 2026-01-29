The Matlab-file processing_impact_echo_for_GitHub.m reads in the measurement data, performs calculations such as Fast-Foruier-Transformation, freqeuncy picking, calculation of enery content, etc. Finally, the processed data a visualised in several plots. 

Spectral Analysis of Vibration Measurements on B70 Concrete Sleepers

This repository contains a MATLAB script for the processing and spectral analysis of time-domain vibration measurements acquired during laboratory experiments on B70 concrete railway sleepers. The script evaluates multiple sleepers, excitation types, and measurement positions along the sleeper length.

The main objective is to identify dominant frequency components and energy distributions in defined frequency bands for different excitation mechanisms.

📌 Overview

The MATLAB script performs the following tasks:

Reads TDMS measurement files from laboratory experiments

Processes multiple concrete sleepers and excitation types

Computes averaged power spectral densities (PSD) using the Welch method

Extracts dominant frequencies within a defined frequency range

Analyzes frequency-band-related energy shares along the sleeper

The results can be used for structural assessment, comparative studies, or damage detection of concrete sleepers.

🧪 Experimental Setup
Investigated Sleepers

The following sleepers were measured in the laboratory:

sleeper_number = [2, 3, 7, 8, 9, 10];

Measurement Positions

Measurements are taken along the sleeper in 5 cm increments

Total evaluated length: 250 cm

x_position_in_cm = 5:5:250;

Excitation Types

Up to three different excitation mechanisms were applied:

Air-coupled actuation

Manual impact hammer excitation

Electro-mechanical impactor

Not every excitation type was applied to every sleeper. The availability is defined in the excitation_matrix.

📁 Data Structure

The measurement data must follow the directory structure below:

sleeper_XX_complete/
│
├── air_coupled/
│   └── *.tdms
├── manual_impact_hammer/
│   └── *.tdms
└── electromechanical_impactor/
    └── *.tdms


File naming convention:

File names must contain the sleeper number and the measurement position in cm

These values are automatically extracted from the file name

⚙️ Signal Processing
Sampling Rate
sample_rate = 250000; % samples per second

Processing Workflow

Read TDMS files for each sleeper and excitation type

Extract five repeated measurements per measurement position

Compute power spectral densities using pwelch

Window length: 1/10 of the sampling rate

Overlap: 50 %

Average the spectra over the five repetitions

Store all spectra in a multi-dimensional matrix for further analysis

📊 Frequency Analysis
Dominant Frequencies

Frequency range of interest: 5 kHz – 25 kHz

Determination of the frequency with the maximum spectral amplitude per position

Frequencies below 5 kHz are set to NaN (measurement region below the rail)

Spectral Energy Evaluation

Spectral energy is evaluated in the following bands:

5–10 kHz (low-frequency band)

10–20 kHz (high-frequency band)

Energy values are normalized with respect to the total energy in the range 5–20 kHz.

📦 Key Output Variables
Variable	Description
spectrum_all	Averaged PSDs for all sleepers and excitation types
maximum_frequencies	Dominant frequencies per measurement position
total_power	Total spectral energy (5–20 kHz)
power_share_normalised_low_frequency_band	Normalized energy share (5–10 kHz)
power_share_normalised_high_frequency_band	Normalized energy share (10–20 kHz)

📈 Additional Data Extraction

For selected sleepers, individual time signals are stored in order to:

Compare different excitation mechanisms directly

Enable detailed post-processing and visualization

🛠 Requirements

MATLAB (recommended: R2021b or newer)

Signal Processing Toolbox

TDMS file support (tdmsread)

👤 Author / Context

This script was developed in the context of laboratory investigations on concrete railway sleepers and is intended for systematic spectral analysis of high-frequency vibration measurements.
