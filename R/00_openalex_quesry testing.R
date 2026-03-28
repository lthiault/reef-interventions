# Script:      01_openalex_query.R
# Description: Systematic literature search for coral reef management
#              intervention studies using the OpenAlex API (via openalexR).
#              Searches are structured around two fixed blocks (ecosystem /
#              geography, study design) and one variable block (intervention
#              type). Results are deduplicated and exported to data/raw/.
#              Set retrieve = TRUE to download records.
#              Set retrieve = FALSE for count-only test runs.
# Author:      Lauric Thiault — CNRS / CRIOBE
# Created:     2026-03-26


## Setup -----------------------------------------------------------------------

library(openalexR)
library(tidyverse)
library(dotenv)


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
# Full query structure per intervention type:
#   (block1_eco OR block1_geo) AND (block2) AND (block3_*)
#
# block1_eco: coral reef ecosystem descriptors and named reef systems —
#             specific enough to stand alone without anchoring
# block1_geo: country and territory names paired with marine anchor terms
#             via proximity (~500) — confirms marine/coastal framing in the
#             same abstract, excluding pure agricultural or development
#             literature from reef countries
# block2:     study design and outcome framing — confirms the paper reports
#             an empirical assessment rather than a descriptive study
# block3_*:   intervention-specific terms — one variant per intervention type
#
# Stemming rules (confirmed via 03_test_stemming.R):
#   - Regular plurals: stemming handles — one form only
#   - Irregular plurals (fishery/fisheries, sanctuary/sanctuaries):
#     stemming handles inside quoted phrases — one form only
#   - Spelling variants (British/American: licence/license,
#     stabilisation/stabilization): stemming does NOT fix — list both explicitly
# Proximity search (~N) catches hyphenated/unhyphenated variants (N = 1) and
# word insertions without listing explicit variants (n >= 2)


## Block 1a — Ecosystem type (fixed across all searches) ----
# Core coral reef descriptors and named reef systems
# Specific enough to stand alone — no geographic anchoring needed
# Stemming handles: reef/reefs, assemblage/assemblages, community/communities

block1_eco <- paste(
  
  # Core coral reef ecosystem and associated communities descriptors
  '"coral reef" OR "coral ecosystem" OR "coral system"',
  'OR "reef fish" OR "reef community" OR "reef habitat"',
  'OR "fringing reef" OR "barrier reef" OR "outer reef" OR atoll',
  'OR "reef flat" OR "reef slope"',
  'OR "tropical coastal"~2',
  'OR "reef associated"~2 OR "reef dependent"~2',
  
  # Named reef systems and seas
  'OR "Great Barrier Reef" OR "Coral Triangle" OR "Mesoamerican Reef"',
  'OR "Coral Sea" OR "Red Sea" OR "South China Sea"',
  'OR "Persian Gulf" OR "Gulf of Aqaba" OR "Gulf of Mannar"',
  'OR "Indo-Pacific" OR Caribbean',
  
  # Iconic reef sites frequently cited in the literature
  'OR "Raja Ampat" OR "Tubbataha" OR "Wakatobi" OR "Moorea"',
  'OR "Florida Keys" OR "Florida Reef"~2 OR "Abrolhos" OR "Aldabra" OR "Chagos"',
  'OR "Ningaloo" OR "Lord Howe"',
  
  sep = " "
)



## Block 1b — Geography (fixed across all searches) ----
# Country and territory names anchored to marine context via proximity ~500
# "country anchor"~500 requires both to appear within 500 words — equivalent
# to co-occurrence within the same abstract
# Anchor terms and country lists defined separately for easy tuning
# Stemming handles morphological variants of anchor terms

# Anchor terms — edit here to test broader or narrower marine scoping
#geo_anchors <- c("marine")
geo_anchors <- c("reef", "marine", "coral")

# Countries and territories with coral reef ecosystems — organised by region
SEA             <- c("Indonesia", "Philippines", "Malaysia", "Vietnam",
                     "Thailand", "Cambodia", "Myanmar", "Brunei",
                     "Timor-Leste", "Singapore")

melanesia       <- c("Papua New Guinea", "Solomon Islands", "Vanuatu",
                     "Fiji", "New Caledonia")

micronesia      <- c("Palau", "Federated States of Micronesia",
                     "Marshall Islands", "Kiribati", "Nauru",
                     "Guam", "Northern Mariana Islands")

polynesia       <- c("French Polynesia", "Tonga", "Samoa", "American Samoa",
                     "Tuvalu", "Niue", "Cook Islands", "Wallis and Futuna",
                     "Hawaii", "Tokelau")

australia_swp   <- c("Australia", "Pacific Islands")

east_africa     <- c("Kenya", "Tanzania", "Mozambique", "Madagascar",
                     "Comoros", "Mayotte", "Reunion", "Mauritius",
                     "Seychelles")

south_asia      <- c("Maldives", "Sri Lanka", "India")

middle_east     <- c("Saudi Arabia", "Yemen", "Oman", "United Arab Emirates",
                     "Bahrain", "Qatar", "Kuwait", "Djibouti", "Eritrea",
                     "Jordan", "Egypt", "Israel")

western_io      <- c("Chagos", "Aldabra", "Cocos Islands", "Christmas Island")

greater_antilles <- c("Cuba", "Jamaica", "Haiti", "Dominican Republic",
                      "Puerto Rico")

lesser_antilles <- c("Barbados", "Trinidad and Tobago", "Grenada",
                     "Saint Vincent", "Saint Lucia", "Martinique",
                     "Guadeloupe", "Dominica", "Antigua and Barbuda",
                     "Saint Kitts", "Montserrat", "Anguilla",
                     "Aruba", "Bonaire", "Curacao",
                     "Sint Maarten", "Saint Martin", "Saba")

caribbean_other <- c("Bahamas", "Turks and Caicos", "Cayman Islands",
                     "Bermuda", "British Virgin Islands", "US Virgin Islands")

central_america <- c("Belize", "Mexico", "Honduras", "Nicaragua",
                     "Costa Rica", "Panama")

south_america   <- c("Colombia", "Venezuela", "Brazil")

east_atlantic   <- c("Cape Verde", "Sao Tome and Principe",
                     "Ascension Island", "Saint Helena")

# Combine all regions
# geo_countries <- c(SEA, melanesia, micronesia, polynesia, australia_swp,
#                    east_africa, south_asia, middle_east, western_io,
#                    greater_antilles, lesser_antilles, caribbean_other,
#                    central_america, south_america, east_atlantic)

geo_countries <- c(south_america)


# Generate all country-anchor proximity pairs programmatically
block1_geo <- expand.grid(country = geo_countries,
                          anchor  = geo_anchors,
                          stringsAsFactors = FALSE) %>%
  mutate(term = paste0('"', country, " ", anchor, '"~500')) %>%
  pull(term) %>%
  paste(collapse = " OR ")


## Block 2 — Study design / Outcome framing (fixed across all searches) ----
# Confirms the paper reports an empirical assessment of an intervention's
# effect rather than a purely descriptive or methodological study
# Covers both quantitative (experimental, monitoring) and qualitative
# (ethnographic, perception-based) study designs
# Stemming handles: assess/assessment, evaluat/evaluation, perceiv/perception
# ~1 catches hyphenated variants: "before-after", "control-impact",
#   "semi-structured interview"

block2 <- paste(
  'effect OR impact OR outcome OR benefit OR effectiveness',
  'OR assessment OR evaluation OR monitoring',
  'OR "before after"~1 OR "control impact"~1 OR BACI',
  'OR perception OR attitude OR "local knowledge"',
  'OR "semi-structured interview"~1 OR "focus group"',
  'OR participatory OR ethnograph OR survey',
  'OR "household survey" OR "key informant" OR "expert knowledge"',
  sep = " "
)


## Block 3 — Interventions (varies by intervention type) ----
# One variant per intervention type (n=5)
# Search approach: exact phrases for intervention names and management instruments
# Proximity (~N) replaces hyphenated/unhyphenated pairs and recovers NEAR/n logic
# Stemming handles ALL plurals including irregular forms — one form listed only
# Spelling variants (British/American) listed explicitly —
#   stemming does not resolve different character strings

# Area-based conservation
block3_area_based <- paste(
  
  # Locally and community managed areas
  # ~2 catches word insertions and hyphenated/unhyphenated variants
  # Stemming handles: area/areas, manage/managed/management
  '"locally managed marine area"~2 OR LMMA',
  'OR "community based marine area"~2',
  
  # Traditional and cultural closures
  # Stemming handles: closure/closures, fishery/fisheries
  'OR taboo OR tabu OR tapu OR rahui',
  'OR "fishery closure"~2 OR "fishing closure"~2',
  
  # No-take and exclusion zones
  # ~1 catches "no-take zone", "no-go zone" (hyphenated variants)
  'OR "no take zone"~1 OR "no go zone"~1 OR "exclusion zone"',
  'OR "no take area"~1 OR "no take reserve"~1 OR "no take reef"~1',
  
  # Protection level descriptors
  # Stemming handles: area/areas, reserve/reserves
  'OR "fully protected area" OR "partially protected area"',
  'OR "strictly protected area" OR "integral reserve"~2',
  
  # OECMs
  # ~1 catches "area-based" vs "area based" hyphenation variant
  'OR OECM OR "other effective area based conservation measure"~1',
  
  # Marine protected areas — core terms
  # ~2 catches "marine and coastal protected area" etc.
  # Stemming handles: reserve/reserves, park/parks, sanctuary/sanctuaries
  'OR "marine protected area"~2 OR "marine reserve"',
  'OR "ocean reserve" OR "marine park"~2',
  'OR "marine sanctuary" OR "marine conservation area" OR "marine restricted area"',
  'OR "fish sanctuary" OR "reef reserve"',
  
  sep = " "
)


# Fisheries management
block3_fisheries <- paste(
  
  # Temporal closures
  # Stemming handles: closure/closures, fishery/fisheries, periodic/periodically
  # ~1 catches "time-area closure"
  # ~2 catches "periodically harvested closures", etc. (via stemming)
  '"fishery management"',
  'OR "periodic closure"~2 OR "periodically closure"~2',
  'OR "temporary closure"~2 OR "seasonal closure"~2 OR "rotational closure"~2',
  'OR "dynamic closure"~2 OR "time area closure"~2 OR "fishing ban"',

  # Access rights and effort control
  # Stemming handles: restrict/restriction, limit/limits, fishery/fisheries
  # Spelling variants: license/licence listed explicitly
  # ~1 catches "territorial-use right", "rights-based management"
  # Stemming handles TURF/TURFS and fishery/fisheries inside proximity
  'OR "effort limit" OR "effort restriction" OR "input control"',
  'OR "fishing license" OR "fishing licence"',
  'OR "territorial use right"~1 OR TURF',
  'OR "customary marine tenure" OR "customary management"',
  'OR "rights based management"~1',
  
  # Co-management — fisheries specific
  # ~2 catches "fishery co-management", "fisheries co-management" and
  # "community-based fishery" "community based fisheries" (via stemming)
  'OR "fishery co management"~2',
  'OR "community based fishery"~2',
  
  # Gear-based management
  # Stemming handles: restrict/restriction, manage/management
  # ~1 catches "by-catch reduction", "by-catch management"
  # ~4 catches "gear restriction", "restrictions on fishing gear" (via stemming)
  'OR "gear restriction"~4 OR "gear management"~4 OR "gear ban"~4 OR "gear control"',
  'OR "gear closure" OR "selective gear"',
  'OR "bycatch reduction"~1 OR "bycatch management"~1',
  'OR "blast fishing" OR "cyanide fishing"',
  
  # Catch restrictions
  # Stemming handles: quota/quotas, limit/limits
  # ~2 catches "limits on catches", "control of harvest"
  'OR "catch limit"~2 OR "catch quota" OR "total allowable catch"',
  'OR "catch share" OR "harvest control"~2',
  
  # Species and size restrictions
  # Stemming handles: restrict/restriction, ban/bans
  # ~3 catches "species moratorium", "moratorium on certain species"
  'OR "species ban" OR "species moratorium"~3 OR "species restriction"~3',
  'OR "parrotfish ban"~3 OR "herbivore protection"~2',
  'OR "size limit"~3 OR "minimum size"~3 OR "mesh size"',
  
  # Capacity reduction
  # Stemming handles: decommission/decommissioning
  # Spelling variants: license/licence listed explicitly
  'OR "capacity reduction" OR "vessel decommissioning"',
  'OR "license buyback"~1 OR "licence buyback"',
  'OR "fishing buyout"~1',
  
  sep = " "
)


# Watershed management
block3_watershed <- paste(
  
  # Agriculture and land-based runoff
  # Stemming handles: conserve/conservation, manage/management, restore/restoration
  '"sustainable agriculture" OR "best management practice"',
  'OR "erosion control" OR "soil erosion" OR "soil conservation"',
  'OR "livestock management" OR "catchment management"',
  'OR agroforestry OR "riparian buffer" OR "vegetated buffer"',
  
  # Reforestation and forest conservation
  # Stemming handles: reforest/reforestation, conserve/conservation
  # ~2 catches "watershed-level management", "watershed-based restoration"
  'OR reforestation OR afforestation',
  'OR "forest restoration" OR "forest conservation" OR "forest management"',
  'OR "logging ban"~2 OR "selective logging"',
  'OR "watershed management"~2 OR "watershed restoration"~2',
  'OR "terrestrial protected area" OR "terrestrial reserve"',
  
  # Passive mangrove interventions — active restoration goes to Bioengineering
  # ~1 catches "mangrove-conservation", "mangrove-protection" (hyphenated variants)
  'OR "mangrove conservation"~1 OR "mangrove protection"~1 OR "mangrove management"~1',
  
  # Water systems and sanitation
  # Stemming handles: treat/treatment, manage/management
  'OR "sewage treatment" OR "wastewater treatment"',
  'OR "water quality management" OR "nutrient management"',
  
  # Ridge-to-reef and integrated approaches
  # ~1 catches "ridge-to-reef", "land-use management", "land-use planning",
  #   "land-sea management"
  'OR "ridge to reef"~1',
  'OR "land use management"~1 OR "land use planning"~1',
  'OR "land sea management"~1 OR "integrated coastal management"',
  
  sep = " "
)


# Bioengineering
block3_bioengineering <- paste(
  
  # Transplantation and restocking
  # Stemming handles: transplant/transplantation, restore/restoration,
  #   restock/restocking, outplant/outplanting, propagate/propagation
  # ~1 catches "micro-fragmentation"
  # ~2 catches "coral reef restoration"
  '"coral restoration"~2 OR "coral transplant" OR "coral outplant"',
  'OR "coral gardening" OR "coral nursery" OR "coral farming"',
  'OR "coral fragment" OR "micro fragmentation"~1',
  'OR "larval seeding" OR "larval enhancement"',
  'OR "fish restocking" OR "stock enhancement"',
  
  # Active restoration — passive mangrove conservation goes to Watershed
  'OR "mangrove restoration" OR "mangrove planting"',
  'OR "mangrove transplantation" OR "mangrove rehabilitation"',
  'OR "giant clam restoration" OR "seagrass restoration"',
  
  # Biocontrol — COTS
  # ~1 catches "crown-of-thorns" vs "crown of thorns" (hyphenation variant)
  'OR "crown of thorns control"~1 OR "COTS control"',
  'OR "crown of thorns culling"~1 OR "COTS culling"',
  'OR "crown of thorns removal"~1 OR "COTS removal"',
  
  # Biocontrol — other species
  # Stemming handles: cull/culling, remove/removal, control/controlling
  # ~2 catches "invasive alien species control" etc.
  'OR "lionfish culling" OR "lionfish removal" OR "lionfish control"',
  'OR "invasive species control"~2 OR "invasive species removal"~2',
  'OR "macroalgae removal"~2 OR "algae removal"~2',
  'OR "rat eradication"~4 OR "pest control"',

  # Coral treatment
  # Stemming handles: treat/treatment, antibiotic/antibiotics
  'OR "coral treatment"~2 OR "coral probiotic" OR "coral antibiotic"',
  'OR "coral disease management"~1',
  'OR "coral shading"~4',
  
  # Assisted evolution
  # Stemming handles: evolve/evolution, adapt/adaptation
  # Spelling variants: acclimatization/acclimatisation listed explicitly
  'OR "assisted evolution" OR "assisted gene flow"',
  'OR "selective breeding" OR "transgenic coral"',
  'OR "symbiont shuffling"',
  'OR "coral acclimatization" OR "coral acclimatisation"',
  
  # Artificial structures
  # Stemming handles: reef/reefs, structure/structures, habitat/habitats
  # ~2 catches "artificial coral reef", "artificial rocky structure" etc.
  # ~1 catches "eco-designed structure"
  # Spelling variants: stabilization/stabilisation listed explicitly
  'OR "artificial reef"~2 OR "artificial structure"~2',
  'OR "reef ball" OR biorock OR "eco designed structure"~1',
  'OR "substrate stabilization"~1 OR "substrate stabilisation"~1',
  'OR "rubble stabilization"~1 OR "rubble stabilisation"~1',
  'OR "artificial habitat"~2 OR "artificial substrate"~2',
  
  sep = " "
)


# Socioeconomic development
block3_socioeconomic <- paste(
  
  # Livelihood diversification
  # Stemming handles: diversify/diversification, transition/transitioning
  # ~4 catches "alternative sources of livelihood"
  # Spelling variants: program/programme listed explicitly
  '"livelihood diversification"~2 OR "livelihood diverse"~2',
  '"livelihood transition"~2',
  'OR "alternative livelihood"~4 OR "livelihood portfolio"~2',
  'OR "livelihood program"~2 OR "livelihood programme"~2',
  'OR "income diversification"~2 OR "income diverse"~2',
  
  # Tourism
  # Stemming handles: tour/tourism/tourist
  # ~1 catches "eco-tourism", "community-based tourism"
  'OR ecotourism OR "eco tourism"~1',
  'OR "dive tourism" OR "marine tourism"',
  'OR "community based tourism"~1 OR "sustainable tourism"',
  
  # Aquaculture
  # Stemming handles: farm/farming, culture/aquaculture
  # ~1 catches "seaweed-farming" etc.
  # ~5 catches "small-scale coastal aquaculture" etc.
  'OR aquaculture',
  'OR "seaweed farming"~1 OR "seaweed farm"~1',
  'OR "shellfish farming"~1 OR "shellfish farming"~1',
  'OR "sea cucumber farming"~1 OR "giant clam farming"~1',
  
  # Social protection
  # Stemming handles: protect/protection, assist/assistance
  # Spelling variants: program/programme listed explicitly
  'OR "social protection"',
  'OR "social safety net"',
  'OR "cash transfer"',
  'OR "social welfare" OR "welfare program" OR "welfare programme"',
  'OR "food assistance" OR "subsidy program" OR "subsidy programme"',
  
  # Microfinance and savings
  # Stemming handles: finance/microfinance, credit/microcredit
  'OR microfinance OR microcredit OR microloan',
  'OR "community savings" OR "revolving fund" OR "financial inclusion"',
  
  # Family planning and health
  # Stemming handles: plan/planning, health
  'OR "family planning" OR "reproductive health" OR "maternal health"',
  
  sep = " "
)


## Search function -------------------------------------------------------------

# Runs two sub-queries per intervention type:
#   query_eco: ecosystem descriptors and named reef systems (block1_eco)
#   query_geo: country names anchored to reef context (block1_geo)
# Results are combined and deduplicated within each intervention type.
# Count-only mode always runs; retrieval only runs if retrieve = TRUE
# and count is within max_records.

run_search <- function(block3, intervention_label) {
  
  query_eco <- paste0("(", block1_eco, ") AND (", block2, ") AND (", block3, ")")
  query_geo <- paste0("(", block1_geo, ") AND (", block2, ") AND (", block3, ")")
  
  cat("Checking:", intervention_label, "\n")
  
  fetch_count <- function(q) {
    tryCatch(
      oa_fetch(
        entity                    = "works",
        title_and_abstract.search = q,
        type                      = "article",
        is_retracted              = FALSE,
        count_only                = TRUE,
        verbose                   = FALSE
      ),
      error = function(e) { message("  ERROR: ", e$message); NULL }
    )
  }
  
  res_eco <- fetch_count(query_eco)
  res_geo <- fetch_count(query_geo)
  
  n_eco <- if (!is.null(res_eco)) res_eco$count else NA_integer_
  n_geo <- if (!is.null(res_geo)) res_geo$count else NA_integer_
  
  cat("  Ecosystem / named terms:", n_eco, "\n")
  cat("  Geo + reef anchor:      ", n_geo, "\n")
  
  # Sum is a conservative upper bound on unique records —
  # deduplication at retrieval stage handles overlap between sub-queries
  n_total <- sum(c(n_eco, n_geo), na.rm = TRUE)
  cat("  Combined (pre-dedup):   ", n_total, "\n")
  
  status <- case_when(
    n_total <= max_records ~ "OK",
    n_total <= 15000       ~ "HIGH — consider trimming Block 3",
    TRUE                   ~ "TOO LARGE — must trim before retrieval"
  )
  cat(" ", status, "\n\n")
  
  count_row <- tibble(
    intervention_type = intervention_label,
    n_eco             = n_eco,
    n_geo             = n_geo,
    n_total_prededup  = n_total,
    search_date       = Sys.Date(),
    status            = status
  )
  
  records <- NULL
  if (retrieve) {
    
    fetch_records <- function(q, label) {
      tryCatch(
        oa_fetch(
          entity                    = "works",
          title_and_abstract.search = q,
          type                      = "article",
          is_retracted              = FALSE,
          count_only                = FALSE,
          verbose                   = TRUE,
          timeout                   = 600
        ),
        error = function(e) {
          message("  ERROR retrieving ", label, ": ", e$message)
          NULL
        }
      )
    }
    
    raw_eco <- if (!is.na(n_eco) && n_eco <= max_records) {
      cat("  Retrieving ecosystem / named terms...\n")
      fetch_records(query_eco, "eco")
    } else {
      cat("  Skipping eco query — count", n_eco, "exceeds max_records.\n")
      NULL
    }
    
    raw_geo <- if (!is.na(n_geo) && n_geo <= max_records) {
      cat("  Retrieving geo + reef anchor...\n")
      fetch_records(query_geo, "geo")
    } else {
      cat("  Skipping geo query — count", n_geo, "exceeds max_records.\n")
      NULL
    }
    
    raw <- bind_rows(raw_eco, raw_geo)
    
    if (nrow(raw) > 0) {
      records <- raw %>%
        distinct(id, .keep_all = TRUE) %>%
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
      cat("  Done:", nrow(records), "records after within-intervention dedup.\n")
    }
  }
  
  list(count = count_row, records = records)
}


## Run searches ----------------------------------------------------------------

searches <- list(
  list(block3 = block3_area_based,     label = "Area-based conservation"),
  list(block3 = block3_fisheries,      label = "Fisheries management"),
  list(block3 = block3_watershed,      label = "Watershed management"),
  list(block3 = block3_bioengineering, label = "Bioengineering"),
  list(block3 = block3_socioeconomic,  label = "Socioeconomic development")
)

results <- map(searches, function(s) {
  run_search(block3 = s$block3, intervention_label = s$label)
})


## Counts summary --------------------------------------------------------------

counts <- map_dfr(results, "count")

cat("\n")
print(counts)
cat("\nTarget: <", max_records, "records per intervention type\n")
cat("Interventions within target:",
    sum(counts$n_total_prededup <= max_records, na.rm = TRUE), "/", nrow(counts), "\n")
cat("Total records across all searches (before deduplication):",
    sum(counts$n_total_prededup, na.rm = TRUE), "\n")


## Save counts summary ---------------------------------------------------------

# Saved to docs/ for reporting and version tracking
# Filename includes date so multiple runs are preserved and comparable
write_csv(counts, paste0("docs/search_counts_", Sys.Date(), ".csv"))
message("✓ Count summary saved to docs/search_counts_", Sys.Date(), ".csv")


## Save records if retrieved ---------------------------------------------------

if (retrieve) {
  
  all_records <- map_dfr(results, "records")
  
  if (nrow(all_records) > 0) {
    
    # Deduplicate across intervention types
    # Papers appearing in multiple searches get intervention labels concatenated
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