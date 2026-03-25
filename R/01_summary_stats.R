# Script:      01_summary_stats.R
# Description: Summary statistics and figures describing the intervention
#              review database (PRISMA flow, study design, geographic and
#              taxonomic coverage, intervention and outcome distributions)
# Author:      Lauric Thiault — CNRS / CRIOBE
# Created:     2023-08-02
# Updated:     2026-03-23


# SETUP -----------------------------------------------------------------------

library(tidyverse)    # data wrangling and ggplot2
library(metagear)     # PRISMA flow diagram
library(patchwork)    # combine multiple plots
library(webr)         # pie-donut charts
library(formattable)  # percent formatting in pie-donut charts

# LOAD DATA -------------------------------------------------------------------

df_clean <- read_csv("data/raw/reef-interventions_clean.csv")

## WoS export files (for PRISMA flow diagram) ----
# Place all WoS export .xls files in data/raw/WoS_export/
wos_files <- list.files("data/raw/WoS_export", full.names = TRUE)
wos_df <- map_dfr(wos_files, readxl::read_xls)


# PRISMA FLOW DIAGRAM ---------------------------------------------------------

start_wos        <- wos_df %>% distinct() %>% nrow()
start_add        <- df_clean %>% filter(citation_screening == "external sources") %>% nrow()
abstract_screened <- start_wos + start_add
fulltext_screened <- 1898
exclude_1        <- abstract_screened - fulltext_screened
included         <- n_distinct(df_clean$study_id)
exclude_2        <- fulltext_screened - included
n_interventions  <- n_distinct(df_clean$intervention_full_name)
n_datapoints     <- nrow(df_clean)

phases <- c(
  paste0("START_PHASE: studies identified through WoS searching (duplicates removed) n=", start_wos),
  paste0("START_PHASE: additional studies identified through other sources n=", start_add),
  paste0("studies with title and abstract screened n=", abstract_screened),
  paste0("EXCLUDE_PHASE: studies excluded n=", exclude_1),
  paste0("full-text articles assessed for eligibility n=", fulltext_screened),
  paste0("EXCLUDE_PHASE: full-text articles excluded, not fitting eligibility criteria n=", exclude_2),
  paste0("studies included in synthesis n=", included),
  paste0("case studies n=", n_interventions),
  paste0("records n=", n_datapoints)
)

plot_PRISMA(phases, design = "grey")


# PLOT THEME ------------------------------------------------------------------

theme_set(
  theme_minimal(base_family = "Libre Franklin") +
    theme(
      plot.title       = element_text(face = "bold"),
      panel.grid.minor = element_blank(),
      legend.position  = "bottom",
      legend.justification = "center"
    )
)


# EXCLUSION AND STUDY DESIGN BAR CHARTS ---------------------------------------

## Reasons for exclusion ----
exclude_why_bar <- df_clean %>%
  filter(fulltext_screening != "yes") %>%
  mutate(exclude_why = case_when(
    exclude_why == "outcomes not discernible"                                                                                  ~ "Unclear outcomes",
    exclude_why == "redundant study (same intervention, same data, etc.)"                                                      ~ "Not using primary data",
    exclude_why == "not an evaluation (review, opinion, framework, theoretical, etc.)"                                         ~ "Not an evaluation",
    exclude_why == "not listed intervention"                                                                                    ~ "Intervention out of scope",
    exclude_why == "confounding factors (multiple interventions, design issues, effect of intervention confounded with other factors, etc.)" ~ "Design issues",
    exclude_why == "not coral reef system"                                                                                     ~ "Not coral reef",
    exclude_why == "full text unavailable"                                                                                     ~ "Unclear outcomes",
    exclude_why == "not using primary data"                                                                                    ~ "Not using primary data",
    .default = NA
  )) %>%
  group_by(exclude_why) %>%
  summarise(count = n()) %>%
  drop_na() %>%
  mutate(freq = count / sum(count) * 100) %>%
  ggplot(aes(x = reorder(exclude_why, -count), y = count)) +
  geom_bar(fill = "#A49180", stat = "identity") +
  geom_text(aes(label = count), vjust = -0.3) +
  ggtitle("Reasons for exclusion") +
  ylab("Number of studies") +
  xlab(NULL)

## Study design ----
study_design_bar <- df_clean %>%
  mutate(study_design = case_when(
    study_design == "Qualitative"                              ~ "Qualitative",
    study_design == "'space-for-time substitution' (CI or distance)" ~ "CI & Distance",
    study_design == "longitudinal (BA or BACI)"                ~ "BA & BACI",
    study_design == "Perceptions"                              ~ "Perceptions & Census",
    study_design == "Expert knowledge"                         ~ "Expert knowledge",
    study_design == "Regression"                               ~ "As co-variable",
    study_design == "Other"                                    ~ "Other/Unsure",
    study_design == "Unsure"                                   ~ "Other/Unsure",
    .default = NA
  )) %>%
  group_by(study_design) %>%
  summarise(count = n()) %>%
  drop_na() %>%
  mutate(freq = count / sum(count) * 100) %>%
  ggplot(aes(x = reorder(study_design, -count), y = count)) +
  geom_bar(fill = "#4DBBAB", stat = "identity") +
  geom_text(aes(label = count), vjust = -0.3) +
  ggtitle("Study design") +
  ylab("Number of data points") +
  xlab(NULL)

wrap_plots(exclude_why_bar, study_design_bar, ncol = 1)


# MOSAIC PLOTS ----------------------------------------------------------------

## Region x intervention ----
# !! NOTE: "Development" and "Market" below should be updated to "SocioDev"
# and folded into "FishMan" to match the recoding in 00_download_and_clean.R !!

break_col_regions <- list(
  cols   = c("#e08d5f", "#ad466c", "#886aa8", "#447ABC", "#22A097", "#6FAA48"),
  breaks = c("SocioDev", "Bioengineering", "FishMan", "FishMan", "MarCon", "Watershed")
)
region_level <- c("Polynesia", "Eastern Tropical Pacific", "North Pacific Ocean", "Caribbean-Atlantic",
                  "Middle East and North Africa", "Western Indian Ocean", "Central Indian Ocean",
                  "Southeast Asia", "Australia", "Micronesia", "Melanesia")

chisq_df <- df_clean %>%
  drop_na(region) %>%
  group_by(region, intervention_dim) %>%
  summarise(value = sum(study_weight), .groups = "drop") %>%
  mutate_at(vars(value), as.integer) %>%
  uncount(value)

chisq.test(chisq_df$region, chisq_df$intervention_dim, simulate.p.value = TRUE)

chisq_df$intervention_dim <- factor(chisq_df$intervention_dim, levels = rev(break_col_regions$breaks))
chisq_df$region            <- factor(chisq_df$region, levels = region_level)

mosaic_regions <- chisq_df %>%
  ggplot() +
  geom_mosaic(alpha = 1, aes(x = product(region), fill = intervention_dim), offset = 0.003) +
  geom_mosaic_text(aes(x = product(region), fill = intervention_dim, label = after_stat(.wt))) +
  scale_fill_manual(breaks = break_col_regions$breaks, values = break_col_regions$cols) +
  guides(x = guide_axis(n.dodge = 2)) +
  theme(
    axis.title        = element_blank(),
    legend.position   = "right",
    axis.text.y       = element_blank(),
    legend.title      = element_blank(),
    panel.grid        = element_blank(),
    legend.box.margin = margin(0, 0, 0, 0)
  )

## Outcome x intervention ----
break_col_outcomes <- list(
  cols   = c("#1FAEB5", "#4ABEC3", "#75CFD2", "#A0DFE0", "#CBEFEE",
             "#59B53A", "#78C35E", "#97D282", "#B6E1A6", "#D5EFCA",
             "#E8C42A", "#EBCD4F", "#EED774", "#F1E098", "#F4E9BD"),
  breaks = c("Genes", "Species", "Community", "Functions", "Habitat",
             "Water Quality", "Climate", "Coastal \nProtection", "Materials", "Fishery",
             "Economic", "Social", "Health", "Governance", "Cultural")
)
intervention_level <- c("Bioengineering", "SocioDev", "FishMan", "MarCon", "Watershed")

chisq_outcomes <- df_clean %>%
  group_by(outcome_cat, intervention_dim) %>%
  summarise(value = sum(study_weight), .groups = "drop") %>%
  mutate_at(vars(value), as.integer) %>%
  replace_na(list(value = 0)) %>%
  uncount(value)

chisq_outcomes$intervention_dim <- factor(chisq_outcomes$intervention_dim, levels = intervention_level)
chisq_outcomes$outcome_cat      <- factor(chisq_outcomes$outcome_cat, levels = rev(break_col_outcomes$breaks))

mosaic_outcomes <- chisq_outcomes %>%
  ggplot() +
  geom_mosaic(alpha = 1, aes(x = product(intervention_dim), fill = outcome_cat), offset = 0.003) +
  geom_mosaic_text(aes(x = product(intervention_dim), fill = outcome_cat, label = after_stat(.wt))) +
  scale_fill_manual(breaks = break_col_outcomes$breaks, values = break_col_outcomes$cols) +
  theme(
    axis.text.x       = element_text(),
    axis.title        = element_blank(),
    legend.position   = "right",
    axis.text.y       = element_blank(),
    legend.title      = element_blank(),
    panel.grid        = element_blank(),
    legend.box.margin = margin(0, 0, 0, 0)
  )

wrap_plots(mosaic_regions, mosaic_outcomes, ncol = 1)


# PIE-DONUT CHARTS ------------------------------------------------------------

## Regions ----
lvl0 <- tibble(name = "Parent", value = 0, level = 0, fill = NA)

lvl1 <- df_clean %>%
  drop_na(country, region) %>%
  group_by(region) %>%
  summarise(value = sum(study_weight)) %>%
  mutate(freq = formattable::percent(value / sum(value))) %>%
  ungroup() %>%
  mutate(level = 1, fill = region, name = paste(region, freq, sep = "\n")) %>%
  select(name, value, level, fill)

lvl2 <- df_clean %>%
  drop_na(country, region) %>%
  group_by(country, region) %>%
  summarise(value = sum(study_weight)) %>%
  ungroup() %>%
  group_by(region) %>%
  mutate(cnt = sum(value)) %>%
  ungroup() %>%
  mutate(freq = formattable::percent(value / cnt),
         name = paste(country, freq, sep = "\n"),
         level = 2) %>%
  select(name, value, fill = region, level)

pie_regions <- bind_rows(lvl1, lvl2) %>%
  mutate(name = as.factor(name)) %>%
  arrange(fill, name) %>%
  bind_rows(lvl0) %>%
  bind_rows(tibble(name = "Parent", value = 0, level = -1, fill = NA)) %>%
  mutate(level = as.factor(level)) %>%
  ggplot(aes(x = level, y = value, fill = fill, alpha = level)) +
  geom_col(width = 1, color = "gray90", linewidth = 0.25, position = position_stack()) +
  geom_text(aes(label = name), size = 2.5, position = position_stack(vjust = 0.5)) +
  coord_flip() +
  scale_alpha_manual(values = c("0" = 0, "1" = 1, "2" = 0.7), guide = "none") +
  scale_x_discrete(breaks = NULL) +
  scale_y_continuous(breaks = NULL) +
  scale_fill_brewer(palette = "Set3", na.translate = FALSE) +
  labs(x = NULL, y = NULL) +
  theme_void() +
  theme(legend.position = "none")

## Outcomes ----
break_col_pie_outcomes <- list(
  cols   = c("#1FAEB5", "#75CFD2", "#75CFD2", "#75CFD2", "#75CFD2", "#75CFD2",
             "#59B53A", "#97D282", "#97D282", "#97D282", "#97D282", "#97D282",
             "#E8C42A", "#EED774", "#EED774", "#EED774", "#EED774", "#EED774"),
  breaks = c("Nature", "Genes", "Species", "Community", "Functions", "Habitat",
             "NCP", "Climate", "Coastal \nProtection", "Fishery", "Materials", "Water Quality",
             "People", "Social", "Health", "Governance", "Cultural", "Economic")
)

lvl1 <- df_clean %>%
  group_by(outcome_dim) %>%
  summarise(value = sum(study_weight)) %>%
  mutate(freq = formattable::percent(value / sum(value))) %>%
  ungroup() %>%
  mutate(level = 1, fill = outcome_dim, name = paste(outcome_dim, freq, sep = "\n")) %>%
  select(name, value, level, fill)

lvl2 <- df_clean %>%
  group_by(outcome_cat, outcome_dim) %>%
  summarise(value = sum(study_weight)) %>%
  ungroup() %>%
  group_by(outcome_dim) %>%
  mutate(cnt = sum(value)) %>%
  ungroup() %>%
  mutate(freq = formattable::percent(value / cnt),
         name = paste(outcome_cat, freq, sep = "\n"),
         level = 2) %>%
  select(name, value, fill = outcome_dim, level)

pie_outcomes <- bind_rows(lvl1, lvl2) %>%
  mutate(name = as.factor(name) %>% fct_reorder2(fill, value)) %>%
  arrange(fill, name) %>%
  bind_rows(lvl0) %>%
  bind_rows(tibble(name = "Parent", value = 0, level = -1, fill = NA)) %>%
  mutate(level = as.factor(level)) %>%
  ggplot(aes(x = level, y = value, fill = fill, alpha = level)) +
  geom_col(width = 1, color = "gray90", linewidth = 0.25, position = position_stack()) +
  geom_text(aes(label = name), size = 2.5, position = position_stack(vjust = 0.5)) +
  coord_polar(theta = "y") +
  scale_alpha_manual(values = c("0" = 0, "1" = 1, "2" = 0.7), guide = "none") +
  scale_x_discrete(breaks = NULL) +
  scale_y_continuous(breaks = NULL) +
  scale_fill_manual(breaks = break_col_pie_outcomes$breaks, values = break_col_pie_outcomes$cols) +
  labs(x = NULL, y = NULL) +
  theme_void() +
  theme(legend.position = "none")

## Interventions ----
break_col_interventions <- list(
  cols   = c("#F66356", "#F4B6B3",
             "#B54179", "#891863", "#B54179", "#F9DCEB",
             "#0A57A3", "#0A57A3", "#4784BE", "#84B1D9", "#C1DEF4",
             "#057572", "#057572", "#97D1C9",
             "#02563A", "#02563A", "#6FAA48", "#B2C69E"),
  breaks = c("SocioDev", "Livelihood Diversification",
             "Bioengineering", "Artificial Structures", "Biocontrol", "Transplantation and Restocking",
             "FishMan", "Access Rights", "Gear Management", "Species Restrictions", "Temporal Closures",
             "MarCon", "FPA", "PPA",
             "Watershed", "Land Use Management", "Water Systems Improvement", "Forest Conservation")
)
fill_factor <- c("SocioDev", "Bioengineering", "FishMan", "MarCon", "Watershed")

lvl1 <- df_clean %>%
  group_by(intervention_dim) %>%
  summarise(value = sum(study_weight)) %>%
  mutate(freq = formattable::percent(value / sum(value))) %>%
  ungroup() %>%
  mutate(level = 1, fill = intervention_dim, name = paste(intervention_dim, freq, sep = "\n")) %>%
  select(name, value, level, fill)

lvl2 <- df_clean %>%
  group_by(intervention_cat, intervention_dim) %>%
  summarise(value = sum(study_weight)) %>%
  ungroup() %>%
  group_by(intervention_dim) %>%
  mutate(cnt = sum(value)) %>%
  ungroup() %>%
  mutate(freq = formattable::percent(value / cnt),
         name = paste(intervention_cat, freq, sep = "\n"),
         level = 2) %>%
  select(name, value, fill = intervention_dim, level)

pie_interventions <- bind_rows(lvl1, lvl2) %>%
  mutate(name = as.factor(name) %>% fct_reorder2(fill, value),
         fill = factor(fill, levels = fill_factor)) %>%
  arrange(fill, name) %>%
  bind_rows(lvl0) %>%
  bind_rows(tibble(name = "Parent", value = 0, level = -1, fill = NA)) %>%
  mutate(level = as.factor(level)) %>%
  ggplot(aes(x = level, y = value, fill = fill, alpha = level)) +
  geom_col(width = 1, color = "gray90", linewidth = 0.25, position = position_stack()) +
  geom_text(aes(label = name), size = 3, position = position_stack(vjust = 0.5)) +
  coord_polar(theta = "y") +
  scale_alpha_manual(values = c("0" = 0, "1" = 1, "2" = 0.7), guide = "none") +
  scale_x_discrete(breaks = NULL) +
  scale_y_continuous(breaks = NULL) +
  scale_fill_manual(breaks = break_col_interventions$breaks, values = break_col_interventions$cols) +
  labs(x = NULL, y = NULL) +
  theme_void() +
  theme(legend.position = "none")

## Study method ----
classify_study_type <- function(study_design) {
  case_when(
    study_design == "Qualitative"          ~ "Qualitative",
    study_design == "CI/Distance"          ~ "Quantitative",
    study_design == "BACI/BA"              ~ "Quantitative",
    study_design == "Regression"           ~ "Quantitative",
    study_design == "Other"                ~ "Mixed",
    study_design == "Expert knowledge"     ~ "Mixed",
    study_design == "Perceptions/Survey"   ~ "Mixed"
  )
}

lvl1 <- df_clean %>%
  mutate(study_type = classify_study_type(study_design)) %>%
  group_by(study_type) %>%
  summarise(value = sum(study_weight)) %>%
  mutate(freq = formattable::percent(value / sum(value))) %>%
  ungroup() %>%
  mutate(level = 1, fill = study_type, name = paste(study_type, freq, sep = "\n")) %>%
  select(name, value, level, fill)

lvl2 <- df_clean %>%
  mutate(study_type = classify_study_type(study_design)) %>%
  group_by(study_design, study_type) %>%
  summarise(value = sum(study_weight)) %>%
  ungroup() %>%
  group_by(study_type) %>%
  mutate(cnt = sum(value)) %>%
  ungroup() %>%
  mutate(freq = formattable::percent(value / cnt),
         name = paste(study_design, freq, sep = "\n"),
         level = 2) %>%
  select(name, value, fill = study_type, level)

pie_method <- bind_rows(lvl1, lvl2) %>%
  mutate(name = as.factor(name)) %>%
  arrange(fill, name) %>%
  bind_rows(lvl0) %>%
  bind_rows(tibble(name = "Parent", value = 0, level = -1, fill = NA)) %>%
  mutate(level = as.factor(level)) %>%
  ggplot(aes(x = level, y = value, fill = fill, alpha = level)) +
  geom_col(width = 1, color = "white", linewidth = 0.25, position = position_stack()) +
  geom_text(aes(label = name), size = 2.5, position = position_stack(vjust = 0.5)) +
  coord_polar(theta = "y", start = -pi) +
  scale_alpha_manual(values = c("0" = 0, "1" = 1, "2" = 0.7), guide = "none") +
  scale_x_discrete(breaks = NULL) +
  scale_y_continuous(breaks = NULL) +
  scale_fill_brewer(palette = "Set1", na.translate = FALSE) +
  labs(x = NULL, y = NULL) +
  theme_void() +
  theme(legend.position = "none")


# COUNTRY BAR CHARTS ----------------------------------------------------------

# !! TO-DO: add count by intervention_dim rather than plain bars !!

records <- df_clean %>%
  group_by(country) %>%
  summarise(count = n()) %>%
  mutate(freq = count / sum(count) * 100) %>%
  ggplot(aes(x = reorder(country, count), y = count)) +
  coord_flip() +
  geom_bar(fill = "#908791", stat = "identity") +
  ggtitle("Records per country") +
  ylab("Number of records") +
  xlab(NULL)

study_sites <- df_clean %>%
  group_by(country) %>%
  summarise(count = n_distinct(intervention_full_name)) %>%
  mutate(freq = count / sum(count) * 100) %>%
  ggplot(aes(x = reorder(country, count), y = count)) +
  coord_flip() +
  geom_bar(fill = "#9F7DAF", stat = "identity") +
  ggtitle("Study sites per country") +
  ylab("Number of study sites") +
  xlab(NULL)

interventions_plot <- df_clean %>%
  group_by(country) %>%
  summarise(count = n_distinct(intervention_simple_name)) %>%
  mutate(freq = count / sum(count) * 100) %>%
  ggplot(aes(x = reorder(country, count), y = count)) +
  coord_flip() +
  geom_bar(fill = "#415A91", stat = "identity") +
  ggtitle("Interventions per country") +
  ylab("Number of interventions") +
  xlab(NULL)

wrap_plots(records, study_sites, interventions_plot, ncol = 3)


# EXPORT FIGURES --------------------------------------------------------------

Fig1b_pieDonuts <- wrap_plots(pie_outcomes, pie_interventions, pie_method, ncol = 1)
ggsave("outputs/figures/Fig1b_pieDonuts.pdf", Fig1b_pieDonuts,
       width = 40, height = 30, units = "cm", device = "pdf")

pie_regions