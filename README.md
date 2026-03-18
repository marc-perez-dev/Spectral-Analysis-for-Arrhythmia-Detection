# Spectral Analysis for Arrhythmia Detection

This project implements a signal processing pipeline in MATLAB to characterize cardiac signals, focusing on the spectral signature of ventricular and supraventricular arrhythmias. By analyzing the frequency domain, the system extracts critical features such as peak frequencies and harmonic distribution to provide a deep understanding of complex cardiac rhythms.

The methodology is validated using two primary data sources: a controlled set of clinical ECG recordings representing Sinus Rhythm (RS), Ventricular Tachycardia (VT), and Supraventricular Tachycardia (SVT), alongside the MIT-BIH Malignant Ventricular Ectopy Database (VFDB). This dual-dataset approach ensures that the spectral features are robust across both curated clinical signals and the non-stationary complexities of real-world physiological data.

The analytical pipeline follows a precise three-stage execution sequence. The process initiates with `signal_spectral_characterization.m`, which performs a fundamental analysis of individual signals using FFT and harmonic detection. Subsequently, `feature_extraction_reference_model.m` processes the baseline dataset to extract morphological spectral features and generate a reference model through Z-score normalization. The workflow concludes with `arrhythmia_detection_mit_vfdb.m`, where the pre-trained model is deployed to classify segments from the MIT-VFDB database using a hybrid framework of template matching and K-means clustering.

The system is designed for high portability and technical rigor, utilizing Welch's method for Power Spectral Density (PSD) estimation and a modular architecture that separates core algorithmic logic in the source directory from low-level data ingestion utilities.
