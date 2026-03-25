# Systematic Literature Search — OpenAlex via openalexR
# Blocks 1 and 3 fixed; Block 2 varies by intervention type
#
# REPRODUCIBILITY NOTE
# This script reads a private API key from a local `.env` file
# which is excluded from version control via `.gitignore`.
# To run this script:
#   1. Create a free OpenAlex account at https://openalex.org
#   2. Copy `.env.example` to `.env` in the project root
#   3. In new '.env' replace the placeholder with your own API key and save.
# Never paste your API key directly into this script.


# Setup -----------------------------------------------------------------------
library(openalexR)
library(dplyr)
library(dotenv)   # reads key=value pairs from .env into environment variables

# Load API key from .env (file is listed in .gitignore and never committed)
dotenv::load_dot_env(".env")
options(openalexR.apikey = Sys.getenv("OPENALEX_API_KEY"))

# Safety check — stops execution if key is missing
if (nchar(Sys.getenv("OPENALEX_API_KEY")) == 0) {
  stop("OPENALEX_API_KEY not found. See .env.example for setup instructions.")
}

# Set API key for openalexR
options(openalexR.apikey = OPENALEX_API_KEY)

# Block 1 — Geography / Ecosystem (fixed) -------------------------------------

block1 <- paste(
  '"coral reef" OR "coral reefs" OR "coral ecosystem" OR "coral system"',
  'OR "tropical coastal community" OR "tropical coastal communities"',
  'OR "tropical coastal people"',
  'OR marine OR coastal',
  'OR "Great Barrier Reef" OR "Coral Triangle" OR "Mesoamerican Reef"',
  'OR "Coral Sea" OR "Red Sea" OR "South China Sea"',
  'OR "Persian Gulf" OR "Arabian Gulf" OR "Gulf of Aqaba" OR "Gulf of Mannar"',
  'OR "Maldives" OR "Palau" OR "Kiribati" OR "Tuvalu"',
  'OR "Marshall Islands" OR "Solomon Islands" OR "Vanuatu"',
  'OR "French Polynesia" OR "New Caledonia"',
  'OR "Seychelles" OR "Comoros" OR "Mayotte"',
  'OR "Raja Ampat" OR "Tubbataha" OR "Wakatobi" OR "Moorea"',
  'OR "Florida Keys" OR "Abrolhos" OR "Aldabra" OR "Chagos"',
  sep = " "
)


# Block 3 — Outcomes (fixed) --------------------------------------------------

block3 <- paste(
  'effect OR outcome OR impact OR assessment OR evaluation OR benefit OR effectiveness',
  'OR "coral cover" OR "fish biomass" OR biomass OR abundance OR density OR recruitment',
  'OR survival OR recovery OR resilience',
  'OR "species richness" OR "species diversity" OR "community composition"',
  'OR "trophic level" OR "trophic structure"',
  'OR "functional diversity" OR "functional richness"',
  'OR herbivory OR "grazing rate" OR spillover OR connectivity',
  'OR bleaching OR "genetic diversity" OR CPUE',
  'OR "water quality" OR turbidity OR sedimentation OR nutrient OR nutrients',
  'OR eutrophication OR nitrogen OR phosphorus',
  'OR "coastal protection" OR "wave attenuation" OR "storm protection"',
  'OR "coastal erosion" OR "carbon stock" OR "carbon storage"',
  'OR livelihood OR income OR employment OR poverty',
  'OR "food security" OR nutrition OR wellbeing OR "well-being" OR "life satisfaction"',
  'OR governance OR compliance OR stewardship OR legitimacy',
  'OR "resource control" OR equity OR empowerment OR conflict',
  'OR "decision-making" OR perception OR attitude',
  'OR "traditional knowledge" OR "cultural practices" OR "social cohesion"',
  sep = " "
)


# Block 2 variants — Interventions --------------------------------------------

block2_marine <- paste(
  '"locally managed marine area" OR "locally managed marine areas"',
  'OR "community based marine area" OR "community based marine areas"',
  'OR "LMMA"',
  'OR "fishery closure" OR "fisheries closure" OR "fisher closure"',
  'OR "fishing closure"',
  'OR taboo OR tabu OR rahui',
  'OR "no-take" OR "no take"',
  'OR "no-go zone" OR "no go zone"',
  'OR "fully protected area" OR "fully protected areas"',
  'OR "partially protected area" OR "partially protected areas"',
  'OR "integral reserve" OR "integral reserves"',
  'OR "OECM" OR "other effective area-based conservation measure"',
  'OR "other effective area based conservation measure"',
  'OR "marine protected area" OR "marine protected areas"',
  'OR "marine reserve" OR "marine reserves"',
  'OR "marine park" OR "marine parks"',
  'OR "ocean reserve" OR "ocean park"',
  'OR "marine sanctuary" OR "marine sanctuaries"',
  'OR "marine conservation area" OR "marine conserved territory"',
  'OR "marine restricted area"',
  'OR "community based marine" OR "community-based marine"',
  'OR "managed marine area"',
  sep = " "
)

block2_fisheries <- paste(
  '"effort limit" OR "effort limits" OR "effort restriction" OR "effort control"',
  'OR "input control" OR "fishing restriction" OR "fishing restrictions"',
  'OR "territorial use right" OR "territorial use rights"',
  'OR "area-based right" OR "area based right"',
  'OR "fishing right" OR "fishing rights"',
  'OR "access right" OR "access rights"',
  'OR "fishing license" OR "fishing licence"',
  'OR "gear restriction" OR "gear restrictions" OR "gear management"',
  'OR "gear ban" OR "gear prohibition"',
  'OR "species restriction" OR "species ban" OR "species moratorium"',
  'OR "size limit" OR "size limits" OR "minimum size"',
  'OR "catch limit" OR "catch quota" OR "total allowable catch"',
  'OR "temporal closure" OR "seasonal closure" OR "periodic closure"',
  'OR "periodically harvested closure"',
  'OR "co-management" OR "comanagement" OR "co management"',
  'OR "community based fishery" OR "community-based fishery"',
  'OR "community based fisheries" OR "community-based fisheries"',
  sep = " "
)

block2_watershed <- paste(
  '("agriculture" OR "livestock" OR "logging" OR "catchment")',
  'AND ("sustainable" OR "conservation" OR "restoration" OR "agroecology"',
  'OR "runoff" OR "run-off" OR "erosion")',
  'OR "reforestation" OR "vegetated buffer" OR "riparian buffer"',
  'OR ("sewage" OR "wastewater" OR "waste water" OR "cesspool" OR "drainage")',
  'AND ("treatment" OR "management" OR "improvement")',
  'OR "septic tank"',
  'OR "ridge-to-reef" OR "ridge to reef"',
  'OR "land use planning" OR "land use management" OR "land-sea management"',
  'OR ("watershed" OR "forest") AND ("restoration" OR "management"',
  'OR "conservation" OR "protection")',
  'OR "logging ban"',
  'OR "terrestrial protected area"',
  sep = " "
)


# Search function -------------------------------------------------------------
# Runs count check first, retrieves if count <= max_records
# Tags each result with intervention_type

run_search <- function(block2, intervention_label, max_records = 30000) {
  
  full_query <- paste0("(", block1, ") AND (", block2, ") AND (", block3, ")")
  
  cat("\nIntervention:", intervention_label, "\n")
  
  count_result <- oa_fetch(
    entity                    = "works",
    title_and_abstract.search = full_query,
    type                      = "article",
    is_retracted              = FALSE,
    count_only                = TRUE,
    verbose                   = FALSE
  )
  
  n <- count_result$count
  cat("Records found:", n, "\n")
  
  if (n > max_records) {
    cat("WARNING: count exceeds max_records (", max_records, ").",
        "Skipping — consider splitting Block 2 into sub-queries.\n")
    return(NULL)
  }
  
  cat("Retrieving...\n")
  
  results <- oa_fetch(
    entity                    = "works",
    title_and_abstract.search = full_query,
    type                      = "article",
    is_retracted              = FALSE,
    count_only                = FALSE,
    verbose                   = TRUE
  )
  
  results_clean <- results %>%
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
  
  cat("Done:", nrow(results_clean), "records retrieved.\n")
  return(results_clean)
}


# Run all searches ------------------------------------------------------------

searches <- list(
  list(block2 = block2_marine,    label = "Marine Conservation"),
  list(block2 = block2_fisheries, label = "Fisheries Management"),
  list(block2 = block2_watershed, label = "Watershed Management")
)

all_results <- lapply(searches, function(s) {
  run_search(
    block2             = s$block2,
    intervention_label = s$label,
    max_records        = 5000
  )
}) %>%
  bind_rows()


# Deduplicate -----------------------------------------------------------------
# Same paper may appear in multiple searches — intervention tags are concatenated

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
cat("Records appearing in multiple searches:",
    sum(grepl("\\|", all_results_dedup$intervention_type)), "\n")


# Export ----------------------------------------------------------------------

saveRDS(all_results_dedup, "data/processed/openalex_results.rds")
write.csv(all_results_dedup, "data/processed/openalex_results.csv", row.names = FALSE)