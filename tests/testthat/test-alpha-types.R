context("test_alpha_types")

library(dplyr)

# in the patentsview API the set of operators that can be used on an alpha field
# vary depending on whether the field is a string or full text.  Here we will
# test that we have pulled them from the Swagger definition properly.

# There is a hard coded list of string fields in yml_extract.R
# This test assumes that it was run - it puts the examples in the description
# column of fieldsdf.
# TODO: should add a column for this field in the spreadsheet.  We could then
# skip these tests if the fake page scrapper was run (mbr_fieldsdf.R)

# Here we'll look at the patent_number of the patents endpoint.  If it's not
# a utility patent we'll skip these tests (mbr_fieldsdf.R was run)
description <- fieldsdf %>%
  filter(endpoint == "patents" & field == "patent_number") %>%
  select(description)

# figure out whether mbr_fieldsdf.R or yml_extract.R was run
# we'll skip these tests if mbr_fieldsdf.R was run

can_run <- grepl("^[0-9]+$", description)

test_that("all string fields have an example", {
  skip_on_cran()
  skip_on_ci()

  skip_if(!can_run, "We don't have sample values")

  need_examples <-
    fieldsdf %>%
    filter(data_type == "string" & description == "") %>%
    select(endpoint, field, data_type, description) %>%
    arrange(endpoint, field)

  expect_true(count(need_examples) == 0)
})

test_that("all full text fields have an example", {
  skip_on_cran()
  skip_on_ci()

  skip_if(!can_run, "We don't have sample values")

  need_examples <-
    fieldsdf %>%
    filter(data_type == "full text" & description == "") %>%
    select(endpoint, field, data_type, description) %>%
    arrange(endpoint, field)

  expect_true(count(need_examples) == 0)
})


test_that("string fields behave properly", {
  skip_on_cran()
  skip_on_ci()

  skip_if(!can_run, "We don't have sample values")

  # get the sample queries for string fields

  string_fields <- fieldsdf %>%
    filter(data_type == "string" & description != "") %>%
    select(endpoint, field, data_type, description) %>%
    arrange(endpoint, field)

  # fire off the sample queries
  returned_counts <- apply(string_fields, 1, function(x) {
    query <- paste0('{"', x["field"], '":"', x["description"], '"}')
    response <- search_pv(query = query, endpoint = x["endpoint"])
    if (response$query_results$total_hits == 0) {
      print(paste0(x["endpoint"], ".", x["field"]))
    }

    response$query_results$total_hits
  })

  # assert that the return counts are non zero
  expect_true(all(returned_counts > 0))
})

test_that("full text fields behave properly", {
  skip_on_cran()
  skip_on_ci()

  skip_if(!can_run, "We don't have sample values")

  # get the sample queries for full text fields

  # TODO: remove this when the api is fixed!
  # temporarily want to exclude the cpc_current fields from the patents endpoint

  # More API weirdness, patent_uspc_current_mainclass_average_patent_processing_days
  # is a string field and is always null.  We'll filter it until the API is fixed

  fulltext_fields <- fieldsdf %>%
    filter(data_type == "full text" & description != "") %>% # keep
    filter(!(endpoint == "patents" & group == "cpc_current")) %>% # remove
    filter(!(endpoint == "patents" & # remove
      field == "patent_uspc_current_mainclass_average_patent_processing_days")) %>%
    select(endpoint, field, data_type, description) %>%
    arrange(endpoint, field)

  # fire off the sample queries
  returned_counts <- apply(fulltext_fields, 1, function(x) {
    query <- paste0('{"_text_phrase":{"', x["field"], '":"', x["description"], '"}}')

    response <- search_pv(query = query, endpoint = x["endpoint"])
    if (response$query_results$total_hits == 0) {
      print(paste0(x["endpoint"], ".", x["field"]))
      print(query)
    }
    response$query_results$total_hits
  })

  # assert that the return counts are non zero
  expect_true(all(returned_counts > 0))
})
