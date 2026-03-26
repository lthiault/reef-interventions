# Script:      01_openalex_query.R
# Description: Systematic literature search for coral reef management
#              intervention studies using the OpenAlex API (via openalexR).
#              Searches are structured around three fixed blocks (geography, 
#              ecosystem, outcomes) and one variable block (intervention type).
#              Results are deduplicated and exported to data/raw/.
#              Set retrieve = TRUE to download records.
#              Set retrieve = FALSE for count-only test runs.
# Author:      Lauric Thiault — CNRS / CRIOBE
# Created:     2026-03-26


## Setup -----------------------------------------------------------------------

library(openalexR)
library(tidyverse)


## API key ---------------------------------------------------------------------

# REPOSITORY OWNER: key is loaded from a local .env file (not committed to GitHub)
# USERS: paste your own key in the string below
#   Get a free key at https://openalex.org/settings/api

user_key <- ""

if (nchar(user_key) > 0) {
  options(openalexR.apikey = user_key)
} else {
  dotenv::load_dot_env(".env")
  options(openalexR.apikey = Sys.getenv("OPENALEX_API_KEY"))
}

if (nchar(getOption("openalexR.apikey")) == 0) {
  stop("No API key found. Either paste your key into 'user_key' above,
       or create a .env file with OPENALEX_API_KEY=your_key (repo owner only).")
}


## Run options -----------------------------------------------------------------

# Set retrieve = TRUE to download records in addition to counting them
# Records are saved to data/raw/
# retrieve = FALSE runs counts only — faster, useful for tuning search terms

retrieve    <- TRUE
max_records <- 8000


## Search blocks ---------------------------------------------------------------
# Search approach: proximity search (~N) used to catch hyphenated/unhyphenated
# variants and word insertions without listing explicit variants
# Stemming ON but spelling variants (British/American) still listed explicitly


## Block 1 — Ecosystem type (fixed across all searches) ----
# Targets coral reef and associated tropical coastal ecosystems

block1 <- paste(
  
  # Core coral reef descriptors
  '"coral reef" OR "coral ecosystem" OR "coral system"',
  'OR "coral assemblage" OR "coral community"',
  'OR "reef fish" OR "reef community" OR "reef habitat"',
  'OR "fringing reef" OR "barrier reef" OR atoll',
  'OR "reef flat" OR "reef slope" OR lagoon',
  # FLAG: atoll and lagoon are broad — scoped by Blocks 2 and 3
  
  # Tropical coastal communities dependent on reefs
  'OR "tropical coastal community"~2 OR "tropical coastal people"~2',
  'OR "tropical coastal population"~2',
  
  sep = " "
)


## Block 2 — Geography (fixed across all searches) ----
# Covers named reef systems, seas, countries, and iconic reef sites

block2 <- paste(
  
  # Named reef systems and seas
  '"Great Barrier Reef" OR "Coral Triangle" OR "Mesoamerican Reef"',
  'OR "Coral Sea" OR "Red Sea" OR "South China Sea"',
  'OR "Persian Gulf" OR "Gulf of Aqaba" OR "Gulf of Mannar"',
  'OR "Indo-Pacific" OR Caribbean',
  
  # Small island states and territories with significant reef systems
  'OR "Maldives" OR "Palau" OR "Kiribati" OR "Tuvalu"',
  'OR "Marshall Islands" OR "Solomon Islands" OR "Vanuatu"',
  'OR "French Polynesia" OR "New Caledonia" OR "Seychelles"',
  'OR "Comoros" OR "Mayotte" OR "Fiji"',
  'OR "Papua New Guinea" OR "Timor-Leste" OR "Indonesia"',
  'OR "Philippines" OR "Malaysia" OR "Vietnam"',
  'OR "Kenya" OR "Tanzania" OR "Mozambique" OR "Madagascar"',
  
  # Iconic reef sites frequently cited in the literature
  'OR "Raja Ampat" OR "Tubbataha" OR "Wakatobi" OR "Moorea"',
  'OR "Florida Keys" OR "Abrolhos" OR "Aldabra" OR "Chagos"',
  'OR "Ningaloo" OR "Lord Howe" OR "Cocos Island"',
  'OR "Belize" OR "Bonaire" OR "Curacao"',
  
  sep = " "
)


## Block 3 — Study design / Outcome framing (fixed across all searches) ----
# Confirms the paper reports an assessment of an intervention's effect
# rather than a descriptive or methodological study
# Includes both quantitative (experimental, monitoring) and qualitative
# (ethnographic, perception-based) study designs

block3 <- paste(
  'effect OR impact OR outcome OR benefit OR effectiveness',
  'OR assessment OR evaluation OR monitoring',
  'OR "before after"~1 OR "control impact"~1 OR BACI',
  'OR perception OR attitude OR "local knowledge"',
  'OR "semi-structured interview"~1 OR "focus group"',
  'OR "participatory" OR ethnograph OR survey',
  'OR "household survey" OR "key informant" OR "expert knowledge"',
  sep = " "
)


## Block 4 — Interventions (varies by intervention type) ----
# One variant per intervention type (n=5)

# Area-based conservation
block4_area_based <- paste(
  
  # Locally and community managed areas
  '"locally managed marine area"~2 OR LMMA',
  'OR "community based marine area"~2',
  
  # Traditional and cultural closures
  'OR taboo OR tabu OR tapu OR rahui',
  'OR "fishery closure"~1 OR "fishing closure"',
  
  # No-take and exclusion zones
  'OR "no take zone"~1 OR "no go zone"~1 OR "exclusion zone"',
  'OR "no take area"~1 OR "no take reserve"~1 OR "no take reef"~1',
  
  # Protection level descriptors
  'OR "fully protected area" OR "partially protected area"',
  'OR "strictly protected area" OR "integral reserve"',
  
  # OECMs
  'OR OECM OR "other effective area based conservation measure"~2',
  
  # Marine protected areas — core terms
  'OR "marine protected area"~2 OR "marine reserve"',
  'OR "ocean reserve" OR "marine park"',
  'OR "marine sanctuary"',
  'OR "marine conservation area" OR "marine restricted area"',
  'OR "fish sanctuary" OR "reef reserve"',
  
  sep = " "
)


# Fisheries management
block4_fisheries <- paste(
  
  # Temporal closures
  '"fisheries management"',
  'OR "periodic closure" OR "periodically harvested closure"',
  'OR "temporary closure" OR "seasonal closure" OR "rotational closure"',
  'OR "dynamic closure" OR "time area closure"~1 OR "fishing ban"',
  
  # Access rights and effort control
  'OR "effort limit" OR "effort restriction" OR "input control"',
  'OR "fishing license" OR "fishing licence"',
  'OR "territorial use right"~1 OR TURF',
  'OR "customary marine tenure" OR "customary management"',
  'OR "rights based management"~1',
  
  # Co-management — fisheries specific
  'OR "fishery co management"~2',
  'OR "community based fishery"~1',
  
  # Gear-based management
  'OR "gear restriction" OR "gear management" OR "gear ban" OR "gear control"',
  'OR "gear closure" OR "selective gear"',
  'OR "bycatch reduction"~1 OR "bycatch management"~1',
  'OR "blast fishing" OR "cyanide fishing"',
  
  # Catch restrictions
  'OR "catch limit" OR "catch quota" OR "total allowable catch"',
  'OR "catch share" OR "harvest control"',
  
  # Species and size restrictions
  'OR "species ban" OR "species moratorium" OR "species restriction"',
  'OR "parrotfish ban" OR "herbivore protection"',
  'OR "size limit" OR "minimum size" OR "mesh size"',
  
  # Capacity reduction
  'OR "capacity reduction" OR "vessel decommissioning"',
  'OR "license buyback"~1 OR "licence buyback"',
  'OR "fishing buyout"~1',
  
  sep = " "
)


# Watershed management
block4_watershed <- paste(
  
  # Agriculture and land-based runoff
  '"sustainable agriculture" OR "best management practice"',
  'OR "erosion control" OR "soil erosion" OR "soil conservation"',
  'OR "livestock management" OR "catchment management"',
  'OR agroforestry OR "riparian buffer" OR "vegetated buffer"',
  
  # Reforestation and forest conservation
  'OR reforestation OR afforestation',
  'OR "forest restoration" OR "forest conservation" OR "forest management"',
  'OR "logging ban"~2 OR "selective logging"',
  'OR "watershed management"~2 OR "watershed restoration"~2',
  'OR "terrestrial protected area" OR "terrestrial reserve"',
  
  # Passive mangrove interventions (active restoration → Bioengineering)
  'OR "mangrove conservation"~1 OR "mangrove protection"~1 OR "mangrove management"~1',
  
  # Water systems and sanitation
  'OR "sewage treatment" OR "wastewater treatment"',
  'OR "water quality management" OR "nutrient management"',
  
  # Ridge-to-reef and integrated approaches
  'OR "ridge to reef"~1',
  'OR "land use management"~1 OR "land use planning"~1',
  'OR "land sea management"~1 OR "integrated coastal management"',
  
  sep = " "
)


# Bioengineering
block4_bioengineering <- paste(
  
  # Transplantation and restocking
  '"coral restoration" OR "coral transplantation" OR "coral outplanting"',
  'OR "coral gardening" OR "coral nursery" OR "coral farming"',
  'OR "coral fragment" OR "micro fragmentation"~1',
  'OR "larval seeding" OR "larval enhancement" OR "coral propagation"',
  'OR "fish restocking" OR "stock enhancement"',
  'OR "giant clam restoration" OR "seagrass restoration"',
  
  # Active mangrove restoration (passive conservation → Watershed)
  'OR "mangrove restoration" OR "mangrove planting" OR "mangrove transplantation"',
  
  # Biocontrol — COTS
  'OR "crown of thorns control"~1 OR "COTS control"',
  'OR "crown of thorns culling"~1 OR "COTS culling"',
  'OR "crown of thorns removal"~1 OR "COTS removal"',
  
  # Biocontrol — other species
  'OR "lionfish culling" OR "lionfish removal" OR "lionfish control"',
  'OR "invasive species control"~2 OR "invasive species removal"~2',
  'OR "macroalgae removal"~1 OR "algae removal"~1',
  'OR "rat eradication"~1 OR "pest control"',
  'OR biocontrol OR "biological control"',
  
  # Coral treatment
  'OR "coral treatment" OR "coral probiotic" OR "coral antibiotic"',
  'OR "coral disease treatment"~1 OR "coral disease management"~1',
  'OR "coral shading"~5',
  
  # Assisted evolution
  'OR "assisted evolution" OR "assisted gene flow"',
  'OR "selective breeding" OR "transgenic coral"',
  'OR "symbiont shuffling"',
  'OR "coral acclimatization" OR "coral acclimatisation"',
  
  # Artificial structures
  'OR "artificial reef"~2 OR "artificial structure"~2',
  'OR "reef ball" OR biorock OR "eco designed structure"~1',
  'OR "substrate stabilization"~1 OR "substrate stabilisation"~1',
  'OR "rubble stabilization"~1 OR "rubble stabilisation"~1',
  'OR "artificial habitat"~2 OR "artificial substrate"~2',
  
  sep = " "
)


# Socioeconomic development
block4_socioeconomic <- paste(
  
  # Livelihood diversification
  '"livelihood diversification"~2 OR "income diversification"~2',
  'OR "alternative livelihood"~2 OR "livelihood portfolio"~2',
  'OR "livelihood program"~2 OR "livelihood programme"~2',
  
  # Tourism
  'OR "ecotourism" OR "eco tourism"~1',
  'OR "dive tourism" OR "marine tourism"',
  'OR "community based tourism"~1 OR "sustainable tourism"',
  
  # Aquaculture
  'OR "seaweed farming"~1 OR "shellfish farming"~1',
  'OR "sea cucumber farming"~1 OR "giant clam farming"~1',
  'OR "coastal aquaculture"~5 OR "community aquaculture"~5',
  
  # Social protection
  'OR "social protection" OR "social safety net"',
  'OR "cash transfer"',
  'OR "social welfare" OR "welfare program" OR "welfare programme"',
  'OR "food assistance" OR "subsidy program" OR "subsidy programme"',
  
  # Microfinance and savings
  'OR microfinance OR microcredit OR microloan',
  'OR "community savings" OR "revolving fund" OR "financial inclusion"',
  
  # Family planning and health
  'OR "family planning" OR "reproductive health" OR "maternal health"',
  
  sep = " "
)


## Search function -------------------------------------------------------------

# Runs a count check first, then optionally retrieves records if retrieve = TRUE
# and count <= max_records. Tags each result with the intervention type label.

run_search <- function(block4, intervention_label) {
  
  full_query <- paste0(
    "(", block1, ") AND (",
    block2, ") AND (",
    block3, ") AND (",
    block4, ")"
  )
  
  cat("Checking:", intervention_label, "... ")
  
  count_result <- tryCatch(
    oa_fetch(
      entity                    = "works",
      title_and_abstract.search = full_query,
      type                      = "article",
      is_retracted              = FALSE,
      count_only                = TRUE,
      verbose                   = FALSE
    ),
    error = function(e) {
      message("ERROR: ", e$message)
      return(NULL)
    }
  )
  
  if (is.null(count_result)) {
    cat("ERROR\n")
    return(list(
      count = tibble(intervention_type = intervention_label,
                     n_records         = NA_integer_,
                     search_date       = Sys.Date(),
                     status            = "ERROR"),
      records = NULL
    ))
  }
  
  n <- count_result$count
  status <- case_when(
    n <= max_records ~ "OK",
    n <= 15000       ~ "HIGH — consider trimming Block 4",
    TRUE             ~ "TOO LARGE — must trim before retrieval"
  )
  
  cat(n, "—", status, "\n")
  
  count_row <- tibble(
    intervention_type = intervention_label,
    n_records         = n,
    search_date       = Sys.Date(),
    status            = status
  )
  
  # Retrieval — only if retrieve = TRUE and count is within limit
  records <- NULL
  if (retrieve) {
    if (n > max_records) {
      cat("  Skipping retrieval — count exceeds max_records (", max_records, ").\n")
    } else {
      cat("  Retrieving", n, "records...\n")
      raw <- oa_fetch(
        entity                    = "works",
        title_and_abstract.search = full_query,
        type                      = "article",
        is_retracted              = FALSE,
        count_only                = FALSE,
        verbose                   = TRUE,
        timeout                   = 600
      )
      records <- raw %>%
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
      cat("  Done:", nrow(records), "records retrieved.\n")
    }
  }
  
  list(count = count_row, records = records)
}


## Run searches ----------------------------------------------------------------

searches <- list(
  list(block4 = block4_area_based,     label = "Area-based conservation"),
  list(block4 = block4_fisheries,      label = "Fisheries management"),
  list(block4 = block4_watershed,      label = "Watershed management"),
  list(block4 = block4_bioengineering, label = "Bioengineering"),
  list(block4 = block4_socioeconomic,  label = "Socioeconomic development")
)

results <- map(searches, function(s) {
  run_search(block4 = s$block4, intervention_label = s$label)
})


## Counts summary --------------------------------------------------------------

counts <- map_dfr(results, "count")

cat("\n")
print(counts)
cat("\nTarget: <", max_records, "records per intervention type\n")
cat("Interventions within target:",
    sum(counts$n_records <= max_records, na.rm = TRUE), "/", nrow(counts), "\n")
cat("Total records across all searches (before deduplication):",
    sum(counts$n_records, na.rm = TRUE), "\n")


## Save counts summary ---------------------------------------------------------

# Saved to docs/ for reporting and version tracking
write_csv(counts, paste0("docs/search_counts_", Sys.Date(), ".csv"))
message("✓ Count summary saved to docs/search_counts_", Sys.Date(), ".csv")


## Save records if retrieved ---------------------------------------------------

if (retrieve) {
  
  all_records <- map_dfr(results, "records")
  
  if (nrow(all_records) > 0) {
    
    # Deduplicate — papers appearing in multiple searches get labels concatenated
    all_records_dedup <- all_records %>%
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
    
    cat("\nTotal unique records after deduplication:", nrow(all_records_dedup), "\n")
    cat("Records appearing in multiple intervention types:",
        sum(grepl("\\|", all_records_dedup$intervention_type)), "\n")
    
    write_csv(all_records_dedup, "data/raw/openalex_results.csv")
    message("✓ Records saved to data/raw/openalex_results.csv")
    message("  Unique records: ", nrow(all_records_dedup))
    
  } else {
    message("No records retrieved — all searches exceeded max_records or errored.")
  }
}