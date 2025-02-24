library(tidyverse)
library(devtools)
library(rapiclient)

load_all()

api <- get_api(url = "https://search.patentsview.org/static/openapi.json")

endpoint_paths <- names(api$paths)

# get rid of url parameter paths
endpoint_paths <- endpoint_paths[!grepl("\\{", endpoint_paths)]

# now we need to keep the parent portion of the nested patent/ and publication/ endpoints
endpoints <- sub("/api/v1/((patent/|publication/)?\\w+)/$", "\\1", endpoint_paths)

entities <-
  sapply(endpoint_paths, function(y) {
    success_response <- api$paths[y][1][[y]]$get$responses$`200`$content$`application/json`$schema$`$ref`
    gsub(".*/(\\w+SuccessResponse)", "\\1", success_response)
  })

lookup <- endpoints
names(lookup) <- entities

data_type_intuit <- function(field_definition) {
  type <- field_definition$type
  format <- if ("format" %in% names(field_definition)) field_definition$format else ""
  example <- if ("example" %in% names(field_definition)) field_definition$example else ""
  as_is_types <- c("integer", "boolean", "array")

  if (type %in% as_is_types) {
    type
  } else if (type == "number") {
    "integer"
  } else if (format == "date") {
    "date"
  } else if (type == "string" && example == "double") {
    "number"
  } else {
    type
  }
}

extract_relevant_schema_info <- function(schema_elements) {
  lapply(schema_elements, function(schema_element) {
    middle <- lapply(
      names(api$components$schemas[[schema_element]]$properties[[1]]$items$properties),
      function(x, y) {
        data_type <- data_type_intuit(y[[x]])

        if (data_type == "array") {
          group <- x

          inner <- lapply(
            names(y[[x]]$items$properties),
            function(a, b) {
              # only nested one deep- wouldn't be an array here
              data.frame(
                endpoint = lookup[[schema_element]],
                field = paste0(group, ".", a),
                data_type = data_type_intuit(b[[a]]),
                group = group
              )
            },
            y[[x]]$items$properties
          )

          do.call(rbind, inner)
        } else {
          data.frame(
            endpoint = lookup[[schema_element]],
            field = x,
            data_type = data_type,
            group = names(api$components$schemas[[schema_element]]$properties)
          )
        }
      }, api$components$schemas[[schema_element]]$properties[[1]]$items$properties
    )

    do.call(rbind, middle)
  }) %>%
    do.call(rbind, .) %>%
    arrange(endpoint, group, field)
}

fieldsdf <- extract_relevant_schema_info(entities)
row.names(fieldsdf) <- NULL

# API weirdness:
# We need to append "_id" to fields below to allow them to be queried.

add_id_to <- c("assignees.assignee", "inventors.inventor")

fieldsdf <- fieldsdf %>%
  mutate(
    field = if_else(field %in% add_id_to, paste0(field, "_id"), field)
  )

write.csv(fieldsdf, "data-raw/fieldsdf.csv", row.names = FALSE)

use_data(fieldsdf, internal = FALSE, overwrite = TRUE)
use_data(fieldsdf, internal = TRUE, overwrite = TRUE)
