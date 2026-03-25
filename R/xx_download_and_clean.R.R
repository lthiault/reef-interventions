# Script:      00_download_and_clean.R
# Description: Download the master intervention database from Google Sheets,
#              clean and process it, and export the analysis-ready dataset to
#              data/raw/reef-interventions_clean.csv.
#              !! PRIVATE — do not push to GitHub (listed in .gitignore) !!
# Author:      Lauric Thiault — CNRS / CRIOBE
# Created:     2023-11-09
# Updated:     2026-03-23

# SETUP -----------------------------------------------------------------------

library(tidyverse)      # data wrangling
library(googlesheets4)  # read Google Sheets
library(sf)             # spatial vectors
library(terra)          # rasters and spatial analysis
library(RANN)           # nearest-neighbour search (used in extract_andrello)

# Custom extraction functions
source("R/functions/extract_andrello.R") # anthropogenic threats (Andrello et al. 2022)
source("R/functions/extract_dhw.R")      # degree heating weeks (NOAA)
source("R/functions/extract_raster.R")   # generic raster extraction at point coordinates
source("R/functions/extract_gini.R")     # Gini coefficient


# PARAMETERS ------------------------------------------------------------------

min_casestudy_threshold <- 5  # minimum number of case studies per intervention


# AUTHENTICATE ----------------------------------------------------------------

# First run: opens a browser for Google authentication.
# Credentials are cached locally; subsequent runs authenticate silently.
gs4_auth(scopes = "https://www.googleapis.com/auth/spreadsheets.readonly")
2

# DOWNLOAD --------------------------------------------------------------------

SHEET_URL <- "https://docs.google.com/spreadsheets/d/1not2hK5TJtorXI4oySZ--QUhCnTi6GUY8w3mpkwdrTU"


df <- read_sheet(SHEET_URL) %>%
  mutate(
    study_year        = vapply(study_year,        function(x) if (is.null(x)) NA_real_ else as.numeric(x[[1]]), numeric(1)),
    data_year         = vapply(data_year,          function(x) if (is.null(x)) NA_real_ else as.numeric(x[[1]]), numeric(1)),
    intervention_year = vapply(intervention_year,  function(x) if (is.null(x)) NA_real_ else as.numeric(x[[1]]), numeric(1))
  )

message("✓ Downloaded ", nrow(df), " rows from Google Sheets (", Sys.Date(), ")")


# LOAD PREDICTOR DATASETS -----------------------------------------------------

## Anthropogenic threats — Andrello et al. (2022) Conservation Letters ----
allreefs <- st_read("data/raw/predictors/Andrello et al. 2022/data/allreefs_WGS84.shp")

## Downscaled HDI — MOSAIKS (mosaiks.org) ----
hdi_1 <- rast("data/raw/predictors/mosaiks.org/hdi_raster_predictions.tiff")
names(hdi_1) <- "hdi_1"

## Human dependency on marine ecosystems — Selig et al. (2018) ----
mardep <- read_delim("data/raw/predictors/Selig et al. 2018/human dependence on marine ecosystems.csv", delim = ";") %>%
  mutate(
    `Nutritional dependence` = suppressWarnings(as.numeric(`Nutritional dependence`)),
    `Economic dependence`    = suppressWarnings(as.numeric(`Economic dependence`))
  )

## UNDP indicators ----
gii <- read_delim("data/raw/predictors/UNDP/HDR21-22_Statistical_Annex_GII_Table.csv", delim = ";") %>%
  mutate(gii_2021_value = as.numeric(gsub(",", ".", gii_2021_value)))

hdi_2 <- read_delim("data/raw/predictors/UNDP/HDR21-22_Statistical_Annex_HDI_Table_2.csv", delim = ";")

## World Bank indicators ----
gini <- read_delim("data/raw/predictors/World Bank/API_SI.POV/Data-Table 1.csv", delim = ";")

wgi <- read_delim("data/raw/predictors/World Bank/P_Data_Extract_From_Worldwide_Governance_Indicators/clean_df_2.csv", delim = ";") %>%
  mutate(y2021 = suppressWarnings(as.numeric(y2021))) %>%
  drop_na() %>%
  group_by(country) %>%
  summarise(wgi_mean = mean(y2021))


# CLEAN DATA ------------------------------------------------------------------

df_clean <- df %>%
  
  ## Filter rows ----
filter(
  fulltext_screening == "yes",          # passed both screening phases
  study_design != "Model/simulations",  # exclude modelling studies
  outcome_category != "unsure",         # exclude unclear outcomes
  outcome_impact != "unsure"            # exclude unclear outcomes
) %>%
  
  ## Add row index and format citation ----
rowid_to_column("row_id") %>%
  mutate(
    article_title = str_to_sentence(article_title),
    source_title  = str_to_title(source_title),
    study_year_2  = paste0("(", study_year, ")"),
    citation      = paste(authors, article_title, study_year_2, source_title, sep = " ")
  ) %>%
  
  ## Parse GPS coordinates ----
mutate(
  gps = replace_na(gps, "NA,NA"),
  gps = gsub(" ", "", gps)
) %>%
  separate(gps, into = c("lat", "lon"), sep = ",", convert = TRUE) %>%
  mutate(
    lat       = suppressWarnings(as.numeric(lat)),
    lon       = suppressWarnings(as.numeric(lon)),
    data_year = if_else(is.na(data_year), study_year - 1, data_year)
  ) %>%
  
  ## Extract contextual predictors at study locations ----
extract_gini(data = .) %>%
  extract_dhw(data = ., buffer = 5000, DHW_threshold = 4) %>%  # 4 = mild, 7 = moderate, 10 = high
  extract_andrello(data = ., allreefs = allreefs, max.radius = 5000) %>%
  extract_raster(data = ., r.raster = hdi_1, buffer = 50000) %>%
  left_join(mardep, join_by(country == Country)) %>%
  left_join(hdi_2,  join_by(country == Country)) %>%
  left_join(gii,    join_by(country == Country)) %>%
  left_join(wgi,    join_by(country == country)) %>%
  
  ## Derive composite variables ----
mutate(
  age = data_year - intervention_year,   # intervention age (years)
  hdi = coalesce(hdi_1, HDI_2021_value)  # use national HDI when downscaled unavailable
) %>%
  
  ## Rename columns to short, consistent names ----
rename(
  ggi              = gii_2021_value,
  wgi              = wgi_mean,
  gini             = gini_index,
  mardep_nutri     = `Nutritional dependence`,
  mardep_eco       = `Economic dependence`,
  region           = Region,
  market_gravity   = grav_NC,
  sediments        = sediment,
  nutrients        = nutrient,
  connectivity     = scorecn,
  coastal_pop      = pop_count,
  tourism          = reef_value,
  ports            = num_ports,
  cyclone_freq     = scorecy,
  last_heat_stress = th_stress
) %>%
  
  ## Select relevant columns ----
select(
  # identifiers
  row_id, study_id, polygon, coder, citation_screening, exclude_why,
  # study metadata
  citation, fulltext_screening, study_year,
  # intervention and outcomes
  intervention_full_name, intervention_simple_name, sub_intervention_name,
  unit, outcome_category, outcome_indicator_full, outcome_impact, outcome_comment,
  # institutional / management predictors
  budget, staff, monitoring, enforcement, clear_rules, gazetted,
  management, compliance, funding, conflict_resol, stake_agency,
  decision_making, fishery_type,
  # intervention design
  age, size, size_unit, depth_cat, material_cat,
  livdiv_process, livdiv_pathway, gear_managed,
  # biophysical predictors
  last_heat_stress, heat_stress_freq, connectivity, cyclone_freq, sediments, nutrients,
  # anthropogenic stressors
  market_gravity, coastal_pop, ports, tourism,
  # socio-economic predictors
  mardep_nutri, mardep_eco, ggi, hdi, wgi, gini,
  # covariates and spatial info
  study_design, country, region, location, lat, lon, data_year, cost_USD,
  paired_intervention_1, paired_intervention_2
) %>%
  
  ## Recode categorical variables ----
mutate(
  outcome_category = case_when(
    outcome_category == "Nature - Functions and Processes" ~ "Nature - Functions",
    outcome_category == "NCP - Coastal Protection"        ~ "NCP - Coastal \nProtection",
    .default = outcome_category
  ),
  intervention_simple_name = case_when(
    # merge former "Market" strategy into Fisheries Management
    str_starts(intervention_simple_name, "Market - ") ~
      str_replace(intervention_simple_name, "^Market - ", "FishMan - "),
    # rename "Development" strategy to "SocioDev"
    str_starts(intervention_simple_name, "Development - ") ~
      str_replace(intervention_simple_name, "^Development - ", "SocioDev - "),
    .default = intervention_simple_name
  ),
  study_design = case_when(
    study_design == "Intervention as co-variable" ~ "Regression",
    .default = study_design
  )
) %>%
  
  ## Split composite labels into dimension / category columns ----
separate_wider_delim(outcome_category,         delim = " - ", names = c("outcome_dim",      "outcome_cat"),      cols_remove = FALSE) %>%
  separate_wider_delim(intervention_simple_name, delim = " - ", names = c("intervention_dim", "intervention_cat"), cols_remove = FALSE) %>%
  rename(outcome_catdim = outcome_category) %>%
  
  ## Derive row-wise composite predictors and fill missing regions ----
rowwise() %>%
  mutate(
    mardep  = mean(c_across(c(mardep_nutri, mardep_eco)), na.rm = TRUE),  # combined marine dependency
    sednutr = mean(c(sediments, nutrients), na.rm = TRUE),                 # combined local stressors
    region  = case_when(
      is.na(region) & country == "United States"   ~ "Caribbean-Atlantic",
      is.na(region) & country == "Australia"       ~ "Australia",
      is.na(region) & country == "Philippines"     ~ "Southeast Asia",
      is.na(region) & country == "Belize"          ~ "Caribbean-Atlantic",
      is.na(region) & country == "Tonga"           ~ "Polynesia",
      is.na(region) & country == "Thailand"        ~ "Southeast Asia",
      is.na(region) & country == "Solomon Islands" ~ "Melanesia",
      .default = region
    )
  ) %>%
  ungroup() %>%
  
  ## Apply inclusion filters ----
filter(livdiv_process %in% c("Exogenous", NA)) %>%
  group_by(intervention_simple_name) %>%
  mutate(n_case_studies = n_distinct(intervention_full_name)) %>%
  filter(n_case_studies >= min_casestudy_threshold) %>%
  ungroup() %>%
  
  ## Add inverse-frequency weight to reduce over-represented interventions ----
add_count(intervention_full_name, intervention_simple_name, outcome_cat,
          name = "record_weight") %>%
  mutate(record_weight = 1 / record_weight) %>%
  
  as.data.frame()


# EXPORT ----------------------------------------------------------------------

write_csv(df_clean, "data/raw/reef-interventions_clean.csv")

message("✓ Clean dataset saved to data/raw/reef-interventions_clean.csv")
message("  Rows: ", nrow(df_clean), " | Columns: ", ncol(df_clean))
