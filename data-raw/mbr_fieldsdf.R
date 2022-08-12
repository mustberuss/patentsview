library(rvest)
library(reshape2)
library(dplyr)
library(devtools)
library(stringr)

# The patentsview team has only provided documentation for the new endpoints,
# see Patent Citation Endpoint and Application Citation Endpoint undere New API Fields
# on https://patentsview.org/data-in-action/whats-new-patentsview-july-2021
# They also refer users to the new Swagger UI page, instructing them to look at the 200
# response sections https://search.patentsview.org/swagger-ui/

# We could parse the swagger yml definition but I don't think we can tell string
# fields from full text fields. Now there are only a handful of string fields so
# maybe hard code them?

# For now we'll retrieve fake documentation pages from a site I control.
# In the new version of the api, all fields are supposed to be quaryable.
# In the fake docs the quaryable columns are all Ys.

print("starting")

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

# We want to allow dots for nested objects- it seems that's how we request nested
# object's fields in the f: parameter.  inventor_at_grant.name_last now instead of
# inventor_last_name.  Top level parameters are requested by name, no dot

clean_field <- function(x) {
  gsub("[^[:alnum:]_.]", "", tolower(as.character(x)))
}

convert_to_ascii <- function(x) {
  iconv(x, to = "ASCII", sub = "")
}

# We mutate in a new column 'plain_name', we want the field without the optional
# nested object name and dot for casting.  Or we could remove the parent.field from the
# fake docs and build a column here.  Qualified name would be parent.field when group
# doesn't match the endpoint, otherwise it's just field.  ex. on /patent endpoint
# patent_num_foreign_documents_cited is in patents group so no patents dot (group=endpoint)
# but assignee_id has a group of assignees_at_grant so it would be
# assignees_at_grant.assignee_id (as it currently is in the fake doc)

# Or we could leave the dots in the fake docs and remove them when casting?
fieldsdf <-
  melt(all_tabs) %>%
  rename(
    field = `API Field Name`, data_type = Type, can_query = Query,
    endpoint = L1, group = Group, common_name = `Common Name`,
    description = Description
  ) %>%
  mutate(plain_name = str_extract(field, "(\\w+)$")) %>% # after optional dot
  select(endpoint, field, data_type, can_query, group, common_name, description, plain_name) %>%
  mutate_all(convert_to_ascii) %>%
  mutate_at(vars(1:5), funs(clean_field))

write.csv(fieldsdf, "data-raw/fieldsdf.csv", row.names = FALSE)
use_data(fieldsdf, internal = FALSE, overwrite = TRUE)
use_data(fieldsdf, internal = TRUE, overwrite = TRUE)
