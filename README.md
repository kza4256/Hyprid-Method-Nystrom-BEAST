# Hyprid-Method-Nystrom-BEAST
This MATLAB project demonstrates signal reconstruction using two types of landmarks: change-point (CP) and randomly selected points. The algorithm alternates between these landmark types to explore their individual and combined effects on reconstruction accuracy and execution time.
The main steps include:

    Loading neural signal data and predefined change points.
    Alternating between CP and random landmark selection.
    Reconstructing the signal using Kernel Ridge Regression (KRR) with the Nyström method.
    Visualizing results for CP-only, random-only, and combined reconstructions.
    Analyzing execution time versus relative reconstruction error.

Key Features:

    Dynamic landmark selection combining CP detection and random sampling.
    Comprehensive visual analysis through side-by-side comparison plots.
    Error vs. execution time analysis with a color-coded scatter plot.
