library(rvest)
library(reshape2)
library(dplyr)
library(devtools)

endpoints <- c(
  "assignee" = "assignees",
  "application_citation" = "application_citations",
  "cpc_group" = "cpc_groups",
  "cpc_subgroup" = "cpc_groups",
  "cpc_subsections" = "cpc_subsections",
  "inventor" = "inventors",
  "location" = "locations",
  "nber_category" = "nber_categories",
  "nber_subcategy" = "nber_subcategories",
  "patent" = "patents",
  "patent_citation" = "patent_citations",
  "uspc_mainclass" = "uspc_mainclasses",
  "uspc_subclass" = "uspc_subclasses"
)

all_tabs <- sapply(endpoints, function(x) {
  print(x)
  url <- paste0("https://www.patentsview.org/apis/api-endpoints/", x)
  html <- read_html(url)
  html_table(html)[[2]]
}, simplify = FALSE, USE.NAMES = TRUE)

clean_field <- function(x) {
  gsub("[^[:alnum:]_]", "", tolower(as.character(x)))
}

convert_to_ascii <- function(x) {
  iconv(x, to = "ASCII", sub = "")
}

fieldsdf <-
  melt(all_tabs) %>%
  rename(
    field = `API Field Name`, data_type = Type, can_query = Query,
    endpoint = L1, group = Group, common_name = `Common Name`,
    description = Description
  ) %>%
  select(endpoint, field, data_type, can_query, group, common_name, description) %>%
  mutate_all(convert_to_ascii) %>%
  mutate_at(vars(1:5), funs(clean_field))

write.csv(fieldsdf, "data-raw/fieldsdf.csv", row.names = FALSE)
use_data(fieldsdf, internal = FALSE, overwrite = TRUE)
use_data(fieldsdf, internal = TRUE, overwrite = TRUE)
