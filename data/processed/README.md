# data/raw

This folder contains raw data snapshots used in the reef interventions analysis. Files here are never modified by hand — they are either exported from the master database or downloaded from external sources.

> **Note:** This folder is listed in `.gitignore` and is not tracked by Git. To reproduce the analysis, generate `reef-interventions.csv` locally by running `R/00_download_data.R`.

---

## Files

### `reef-interventions.csv`

A snapshot of the master intervention review database, exported from the Google Sheets master spreadsheet via `R/00_download_data.R`. Each row represents one outcome, from one study, at one site.

#### Column structure

Columns follow a prefix convention:

| Prefix | Category | Description |
|--------|----------|-------------|
| `M_` | Metadata | Bibliographic information: authors, title, year, DOI, journal |
| `I_` | Intervention | Strategy, type, duration, and design of the management intervention |
| `O_` | Outcome | Indicator, category, and direction of impact on nature / people / NCP |
| `P_` | Predictor | Contextual variables: biophysical, governance, socio-economic, anthropogenic stressors |

#### Key fields

| Column | Description |
|--------|-------------|
| `study_id` | Unique identifier for each study |
| `citation` | Formatted bibliographic reference |
| `intervention_full_name` | Full intervention name as recorded in the database |
| `intervention_simple_name` | Simplified intervention label (dimension - category) |
| `outcome_category` | Outcome dimension and category (e.g. Nature - Biodiversity) |
| `outcome_impact` | Direction of impact: positive, negative, neutral, mixed |
| `lat` / `lon` | GPS coordinates of the study site |
| `country` / `region` | Study location |
| `study_year` | Year of publication |
| `data_year` | Year the outcome data were collected |

---

## Data access

This dataset is **open access**. If you use it, please cite the associated publications:

> Thiault L. et al. (in prep). *Coral reef management interventions* — CNRS / CRIOBE.

For questions, contact: lauric.thiault@gmail.com