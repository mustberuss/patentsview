library(rvest)
library(reshape2)
library(dplyr)
library(devtools)

#' nber_category
#' nber_subcategory
#' cpc_group
#' cpc_subgroup

print("starting");

endpoints <- c(
  "application_citations" = "application_citations",
  "assignees" = "assignees",
  "cpc_groups" = "cpc_groups",
  "cpc_subgroups" = "cpc_subgroups",
  "cpc_subsections" = "cpc_subsections",
  "nber_categories" = "nber_categories",
  "nber_subcategories" = "nber_subcategories",
  "uspc_mainclasses" = "uspc_mainclasses",
  "uspc_subclasses" = "uspc_subclasses",
  "inventors" = "inventors",
  "locations" = "locations",
  "patent_citations" = "patent_citations",
  "patents" = "patents"
)

all_tabs <- sapply(endpoints, function(x) {
  print(x)
  url <- paste0("https://patentsview.historicip.com/api/_", x)
  print(url)
  html <- read_html(url)
  html_table(html)[[2]]
}, simplify = FALSE, USE.NAMES = TRUE)

# we want to allow dots for nested objects
clean_field <- function(x) {
  gsub("[^[:alnum:]_.]", "", tolower(as.character(x)))
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
