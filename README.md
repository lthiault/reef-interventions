# reef-interventions
Systematic literature review of the social-ecological outcomes of coral reef interventions


> Code and data repository accompanying two peer-reviewed publications.

**Author:** Lauric Thiault — CNRS / CRIOBE  
**Status:** Active data collection  
**Archive:** *(Zenodo DOI will be added upon publication)*

---

## Overview

This repository contains all analysis scripts, processed data, and documentation for a systematic review of coral reef management interventions. The review builds a global database of interventions and assesses their effects on nature, people, and Nature's Contributions to People (NCP), as well as the role of contextual factors in shaping those outcomes.

The original PDF documents reviewed are not included due to copyright restrictions. See `docs/references.md` for full citations and DOIs.

---

## Repository Structure
```
reef-interventions/
│
├── data/
│   ├── raw/           # Original datasets — do not modify
│   │   └── README.md  # Source and retrieval info for each file
│   └── processed/     # Cleaned data produced by R scripts
│
├── R/                 # Analysis scripts, numbered in execution order
├── outputs/
│   ├── figures/       # All plots and maps
│   └── tables/        # Result tables
│
└── docs/
    └── references.md  # Full citations and DOIs of reviewed papers
```

---

## How to Reproduce the Analysis

### Requirements

- R (version X.X.X)  
- RStudio (recommended)  
- R packages managed via `renv` — see `renv.lock` for exact versions

### Steps

1. Clone this repository
```bash
   git clone https://github.com/lauricthiault/reef-interventions.git
```
2. Open `reef-interventions.Rproj` in RStudio
3. Restore the package environment
```r
   renv::restore()
```
4. Run scripts in order from the `R/` folder:
   - `01_load_clean.R`
   - `02_analyse.R`
   - `03_visualise.R`

---

## Data

The master database is maintained as a spreadsheet and exported to CSV for analysis. Raw CSV files in `data/raw/` are snapshots taken at the time of analysis. See `data/raw/README.md` for details on each file, its source, and the date it was exported.

---

## Publications

*To be added upon acceptance.*

---

## License

Code: [MIT License](LICENSE)  
Data: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

---

## Contact

Lauric Thiault — [CRIOBE](https://www.criobe.pf)  
For questions about the data or methods, please open a GitHub Issue.
A few things to fill in later when you have them: the R version number, your actual GitHub username in the clone URL, the script names once they're finalised, and the publication references. Everything else can stay as-is until you're ready to publish and freeze the repo.few corrections : contact is lauric.thiault@gmail.com + remove licence11:24Here's the updated README:
markdown# Outcomes of Coral Reef Management Interventions

> Code and data repository accompanying two peer-reviewed publications.

**Author:** Lauric Thiault — CNRS / CRIOBE  
**Status:** Active data collection  
**Archive:** *(Zenodo DOI will be added upon publication)*

---

## Overview

This repository contains all analysis scripts, processed data, and documentation for a systematic review of coral reef management interventions. The review builds a global database of interventions and assesses their effects on nature, people, and Nature's Contributions to People (NCP), as well as the role of contextual factors in shaping those outcomes.

The original PDF documents reviewed are not included due to copyright restrictions. See `docs/references.md` for full citations and DOIs.

---

## Repository Structure
```
reef-interventions/
│
├── data/
│   ├── raw/           # Original datasets — do not modify
│   │   └── README.md  # Source and retrieval info for each file
│   └── processed/     # Cleaned data produced by R scripts
│
├── R/                 # Analysis scripts, numbered in execution order
├── outputs/
│   ├── figures/       # All plots and maps
│   └── tables/        # Result tables
│
└── docs/
    └── references.md  # Full citations and DOIs of reviewed papers
```

---

## How to Reproduce the Analysis

### Requirements

- R (version X.X.X)  
- RStudio (recommended)  
- R packages managed via `renv` — see `renv.lock` for exact versions

### Steps

1. Clone this repository
```bash
   git clone https://github.com/lauricthiault/reef-interventions.git
```
2. Open `reef-interventions.Rproj` in RStudio
3. Restore the package environment
```r
   renv::restore()
```
4. Run scripts in order from the `R/` folder:
   - `01_load_clean.R`
   - `02_analyse.R`
   - `03_visualise.R`

---

## Data

The master database is maintained as a spreadsheet and exported to CSV for analysis. Raw CSV files in `data/raw/` are snapshots taken at the time of analysis. See `data/raw/README.md` for details on each file, its source, and the date it was exported.

---

## Publications

*To be added upon acceptance.*

---

## Contact

Lauric Thiault — lauric.thiault@gmail.com  
For questions about the data or methods, please open a GitHub Issue.