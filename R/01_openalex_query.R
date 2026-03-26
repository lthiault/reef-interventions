# Script:      01_openalex_query.R
# Description: Systematic literature search for coral reef management
#              intervention studies using the OpenAlex API (via openalexR).
#              Searches are structured around two fixed blocks (geography,
#              outcomes) and one variable block (intervention type).
#              Results are deduplicated and exported to data/raw/.
# Author:      Lauric Thiault — CNRS / CRIOBE
# Created:     2023-11-09
# Updated:     2026-03-23


## Setup -----------------------------------------------------------------------

library(openalexR)  # OpenAlex API client
library(tidyverse)  # data wrangling
library(dotenv)     # load API key from .env file


## API key ---------------------------------------------------------------------

# REPOSITORY OWNER: key is loaded from a local .env file (not committed to GitHub)
# COLLABORATORS: paste your own key in the string below
#   Get a free key at https://openalex.org/settings/api

collaborator_key <- ""

if (nchar(collaborator_key) > 0) {
  options(openalexR.apikey = collaborator_key)
} else {
  dotenv::load_dot_env(".env")
  options(openalexR.apikey = Sys.getenv("OPENALEX_API_KEY"))
}

if (nchar(getOption("openalexR.apikey")) == 0) {
  stop("No API key found. Either paste your key into 'collaborator_key' above,
       or create a .env file with OPENALEX_API_KEY=your_key (repo owner only).")
}


## Search blocks ---------------------------------------------------------------

## Block 1 — Geography / Ecosystem (fixed across all searches) ----
# Covers coral reef ecosystems, tropical coastal systems, and key reef regions
# Search approach: exact phrases for ecosystem types and named geographic locations
# Broad terms (marine, coastal) included to maximise recall — scoping done by Blocks 2 and 3
# Stemming ON for unquoted terms

block1 <- paste(
  
  # Coral reef and tropical coastal ecosystem types
  '"coral reef" OR "coral ecosystem" OR "coral system"',
  'OR "tropical coastal community" OR "tropical coastal people"',
  'OR marine OR coastal',
  
  # Named reef systems and seas
  'OR "Great Barrier Reef" OR "Coral Triangle" OR "Mesoamerican Reef"',
  'OR "Coral Sea" OR "Red Sea" OR "South China Sea"',
  'OR "Persian Gulf" OR "Gulf of Aqaba" OR "Gulf of Mannar"',
  
  # Small island states with significant reef systems
  'OR "Maldives" OR "Palau" OR "Kiribati" OR "Tuvalu"',
  'OR "Marshall Islands" OR "Solomon Islands" OR "Vanuatu"',
  'OR "French Polynesia" OR "New Caledonia" OR "Seychelles"',
  
  # Iconic reef sites frequently cited in the literature
  'OR "Raja Ampat" OR "Tubbataha" OR "Wakatobi" OR "Moorea"',
  'OR "Florida Keys" OR "Abrolhos" OR "Aldabra" OR "Chagos"',
  
  sep = " "
)


## Block 2 — Interventions (varies by intervention type) ----
# One variant per intervention type (n=5)
# Search approach: most distinctive terms per intervention — redundant variants removed
# Singular/plural and hyphenation variants consolidated where stemming is sufficient
# Stemming ON for unquoted terms

# Area-based conservation
block2_area_based <- paste(
  
  # Locally and community managed areas
  '"locally managed marine area" OR "locally-managed marine area" OR LMMA',
  'OR "community-based marine area" OR "community based marine area"',
  
  # Traditional and cultural closures
  'OR taboo OR tabu OR rahui',
  'OR "fishery closure" OR "fishing closure"',
  
  # No-take and exclusion zones
  'OR "no-take" OR "no take" OR "no-go zone" OR "exclusion zone"',
  
  # Protection level descriptors
  'OR "fully protected area" OR "partially protected area"',
  'OR "strictly protected area" OR "integral reserve"',
  
  # OECMs
  'OR OECM OR "other effective area-based conservation measure"',
  
  # Marine protected areas — core terms
  # Stemming handles: reserve/reserves, park/parks, sanctuary/sanctuaries
  'OR "marine protected area" OR "marine reserve"',
  'OR "marine park" OR "marine sanctuary"',
  'OR "marine conservation area" OR "marine restricted area"',
  'OR "no-take zone" OR "no-take reserve"',
  'OR "fish sanctuary" OR "reef reserve"',
  
  sep = " "
)


# Fisheries management
block2_fisheries <- paste(
  
  # Temporal closures
  # Stemming handles: periodic/periodically, seasonal, rotational, temporary
  '"periodic closure" OR "periodically harvested closure"',
  'OR "temporary closure" OR "seasonal closure" OR "rotational closure"',
  'OR "dynamic closure" OR "time-area closure" OR "fishing ban"',
  
  # Access rights and effort control
  # Stemming handles: territorial/territory, license/licensing
  'OR "effort limit" OR "effort restriction" OR "input control"',
  'OR "fishing license" OR "fishing licence"',
  'OR "territorial use right" OR TURF OR "customary marine tenure"',
  'OR "rights-based fishery" OR "rights-based management"',
  'OR "co-management" OR "community based fishery"',
  
  # Gear-based management
  # Stemming handles: restrict/restriction, manage/management
  'OR "gear restriction" OR "gear management" OR "gear ban"',
  'OR "bycatch reduction" OR "by-catch reduction"',
  'OR "selective gear" OR "destructive fishing"',
  'OR "blast fishing" OR "cyanide fishing"',
  
  # Catch restrictions
  # Stemming handles: quota/quotas
  'OR "catch limit" OR "catch quota" OR "total allowable catch"',
  'OR "catch share" OR "harvest control"',
  
  # Species and size restrictions
  'OR "species ban" OR "species moratorium" OR "species restriction"',
  'OR "parrotfish ban" OR "herbivore protection"',
  'OR "size limit" OR "minimum size" OR "mesh size"',
  
  # Capacity reduction
  # Stemming handles: decommission/decommissioning
  'OR "capacity reduction" OR "vessel decommissioning"',
  'OR "license buyback" OR "fishing buyout"',
  
  sep = " "
)


# Watershed management
block2_watershed <- paste(
  
  # Agriculture and land-based runoff
  # Stemming handles: agriculture/agricultural, manage/management
  '"sustainable agriculture" OR "best management practice"',
  'OR "agricultural runoff" OR "non-point source pollution"',
  'OR "erosion control" OR "soil erosion" OR "soil conservation"',
  'OR "livestock management" OR "catchment management"',
  'OR agroforestry OR "riparian buffer" OR "vegetated buffer"',
  
  # Reforestation and forest conservation
  # Stemming handles: reforest/reforestation, conserve/conservation
  'OR reforestation OR afforestation',
  'OR "forest restoration" OR "forest conservation" OR "forest management"',
  'OR "logging ban" OR "selective logging"',
  'OR "watershed management" OR "watershed restoration"',
  'OR "terrestrial protected area" OR "terrestrial reserve"',
  'OR "payment for ecosystem services" OR REDD',
  'OR "mangrove restoration" OR "mangrove conservation"',
  
  # Water systems and sanitation
  # Stemming handles: treat/treatment, manage/management
  'OR "sewage treatment" OR "wastewater treatment"',
  'OR "water treatment" OR "sanitation system"',
  'OR "septic tank" OR "cesspool" OR "constructed wetland"',
  'OR "water quality management" OR "nutrient management"',
  
  # Integrated approaches
  'OR "ridge-to-reef" OR "ridge to reef"',
  'OR "land use management" OR "land use planning"',
  'OR "land-sea management" OR "integrated coastal management"',
  
  sep = " "
)


# Bioengineering
block2_bioengineering <- paste(
  
  # Transplantation and restocking
  # Stemming handles: transplant/transplantation, restore/restoration,
  #                   restock/restocking, outplant/outplanting
  '"coral restoration" OR "coral transplantation" OR "coral outplanting"',
  'OR "coral gardening" OR "coral nursery" OR "coral farming"',
  'OR "coral fragment" OR "micro-fragmentation"',
  'OR "larval seeding" OR "larval enhancement" OR "coral propagation"',
  'OR "fish restocking" OR "stock enhancement"',
  'OR "giant clam restoration" OR "seagrass restoration"',
  'OR "mangrove planting" OR "mangrove transplantation"',
  
  # Biocontrol
  # Stemming handles: control/controlling, remove/removal, cull/culling
  'OR "crown-of-thorns" OR COTS OR "COTS control"',
  'OR "lionfish culling" OR "lionfish removal"',
  'OR "invasive species control" OR "invasive species removal"',
  'OR "macroalgae removal" OR "algae removal"',
  'OR "rat eradication" OR "pest control"',
  'OR biocontrol OR "biological control"',
  
  # Coral treatment
  # Stemming handles: treat/treatment, antibiotic/antibiotics
  'OR "coral treatment" OR "coral probiotic" OR "coral antibiotic"',
  'OR "coral disease treatment" OR "coral disease management"',
  'OR "coral shading" OR "symbiodinium" OR "coral microbiome"',
  
  # Assisted evolution
  # Stemming handles: evolve/evolution, adapt/adaptation, tolerate/tolerance
  'OR "assisted evolution" OR "assisted gene flow"',
  'OR "selective breeding" OR "thermal tolerance"',
  'OR "gene editing" OR CRISPR OR "transgenic coral"',
  'OR "symbiont shuffling" OR "coral acclimatization"',
  
  # Artificial structures
  # Stemming handles: stabilize/stabilization
  'OR "artificial reef" OR "artificial structure"',
  'OR "reef ball" OR biorock OR "eco-designed structure"',
  'OR "substrate stabilization" OR "rubble stabilization"',
  'OR "artificial habitat" OR "artificial substrate"',
  
  sep = " "
)


# Socioeconomic development
block2_socioeconomic <- paste(
  
  # Livelihood diversification
  # Stemming handles: diversify/diversification, alternate/alternative
  '"livelihood diversification" OR "income diversification"',
  'OR "alternative livelihood" OR "livelihood portfolio"',
  'OR "livelihood program" OR "livelihood intervention"',
  
  # Tourism as livelihood
  # Stemming handles: tour/tourism/tourist
  'OR ecotourism OR "dive tourism" OR "marine tourism"',
  'OR "community-based tourism" OR "sustainable tourism"',
  'OR "blue economy"',
  
  # Aquaculture and mariculture
  # Stemming handles: farm/farming, culture/aquaculture
  'OR aquaculture OR mariculture',
  'OR "seaweed farming" OR "shellfish farming"',
  'OR "sea cucumber farming" OR "giant clam farming"',
  'OR "coastal aquaculture" OR "community aquaculture"',
  
  # Social protection
  # Stemming handles: assist/assistance, protect/protection
  'OR "social protection" OR "social safety net"',
  'OR "cash transfer" OR "conditional cash transfer"',
  'OR "social welfare" OR "welfare program" OR "direct payment"',
  'OR "food assistance" OR "subsidy program"',
  
  # Credit, microfinance and savings
  # Stemming handles: finance/financial
  'OR microfinance OR microcredit OR microloan',
  'OR "community savings" OR "revolving fund" OR "financial inclusion"',
  
  # Family planning, health and gender
  # Stemming handles: plan/planning
  'OR "family planning" OR "reproductive health" OR "maternal health"',
  'OR "health intervention" OR "community health"',
  'OR "women empowerment" OR "gender equity" OR "women in fisheries"',
  
  sep = " "
)


## Block 3 — Study design / Outcome framing (fixed across all searches) ----
# Confirms the paper reports an assessment of an intervention's effect
# rather than a descriptive or methodological study
# Includes both quantitative (experimental, monitoring) and qualitative
# (ethnographic, perception-based) study designs
# Stemming ON for unquoted terms

block3 <- paste(
  
  # Explicit evaluation framing
  'effect OR impact OR outcome OR benefit OR effectiveness',
  'OR assessment OR evaluation OR monitoring',
  
  # Quantitative — before-after and experimental framing
  'OR "before-after" OR "before after"',
  'OR "control-impact" OR BACI',
  'OR "compared to" OR "relative to control"',
  
  # Qualitative and social science framing
  'OR perception OR attitude OR "local knowledge"',
  'OR "semi-structured interview" OR "focus group"',
  'OR "participatory" OR ethnograph',
  'OR "household survey" OR "key informant"',
  'OR "stakeholder" OR "community-based"',
  
  sep = " "
)


## Search function — split query version ---------------------------------------

# For intervention types with large Block 2, the query string can exceed
# OpenAlex URL limits. This version splits Block 2 into sub-blocks,
# runs each separately, then combines and deduplicates before returning.

run_search <- function(block2_list, intervention_label, max_records = 30000) {
  
  # Accept either a single string or a named list of sub-blocks
  if (is.character(block2_list)) {
    block2_list <- list(main = block2_list)
  }
  
  cat("\nIntervention type:", intervention_label, "\n")
  
  all_sub_results <- map_dfr(names(block2_list), function(sub_name) {
    
    full_query <- paste0("(", block1, ") AND (", block2_list[[sub_name]], ") AND (", block3, ")")
    
    cat("  Sub-query:", sub_name, "— checking count...\n")
    
    count_result <- oa_fetch(
      entity                    = "works",
      title_and_abstract.search = full_query,
      type                      = "article",
      is_retracted              = FALSE,
      count_only                = TRUE,
      verbose                   = FALSE
    )
    
    n <- count_result$count
    cat("  Records found:", n, "\n")
    
    if (n > max_records) {
      cat("  WARNING: count exceeds max_records (", max_records, "). Skipping sub-query.\n")
      return(NULL)
    }
    
    cat("  Retrieving...\n")
    
    results <- oa_fetch(
      entity                    = "works",
      title_and_abstract.search = full_query,
      type                      = "article",
      is_retracted              = FALSE,
      count_only                = FALSE,
      verbose                   = TRUE,
      timeout                   = 600
    )
    
    results %>%
      mutate(
        intervention_type = intervention_label,
        author = sapply(authorships, function(a) {
          if (is.null(a) || nrow(a) == 0) return(NA_character_)
          paste(a$display_name, collapse = "; ")
        })
      ) %>%
      select(
        intervention_type,
        title            = display_name,
        author,
        doi,
        publication_year,
        journal          = source_display_name,
        abstract,
        oa_url,
        id
      )
  })
  
  # Deduplicate within intervention type before returning
  all_sub_results %>%
    group_by(id) %>%
    slice(1) %>%
    ungroup()
}


## Run searches ----------------------------------------------------------------

searches <- list(
  list(block2 = block2_area_based,     label = "Area-based conservation"),
  list(block2 = block2_fisheries,      label = "Fisheries management"),
  list(block2 = block2_watershed,      label = "Watershed management"),
  list(block2 = block2_bioengineering, label = "Bioengineering"),
  list(block2 = block2_socioeconomic,  label = "Socioeconomic development")
)

all_results <- map_dfr(searches, function(s) {
  run_search(
    block2             = s$block2,
    intervention_label = s$label,
    max_records        = 30000
  )
})


## Deduplicate -----------------------------------------------------------------

# A paper may appear across multiple intervention types — labels are concatenated

all_results_dedup <- all_results %>%
  group_by(id) %>%
  summarise(
    intervention_type = paste(unique(intervention_type), collapse = " | "),
    title            = first(title),
    author           = first(author),
    doi              = first(doi),
    publication_year = first(publication_year),
    journal          = first(journal),
    abstract         = first(abstract),
    oa_url           = first(na.omit(oa_url)),
    .groups          = "drop"
  )

cat("\nTotal unique records after deduplication:", nrow(all_results_dedup), "\n")
cat("Records appearing in multiple intervention types:",
    sum(grepl("\\|", all_results_dedup$intervention_type)), "\n")


## Export ----------------------------------------------------------------------

write_csv(all_results_dedup, "data/raw/openalex_results.csv")

message("✓ Results saved to data/raw/openalex_results.csv")
message("  Unique records: ", nrow(all_results_dedup))