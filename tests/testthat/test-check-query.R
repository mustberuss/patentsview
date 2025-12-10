test_that("errors are thrown on invalid queries", {
  # These tests don't hit the API - they fail during validation
  expect_error(
    search_pv(qry_funs$eq("shoe_size" = 11.5)),
    "is not a valid field to query for your endpoint"
  )

  expect_error(
    search_pv(qry_funs$gt("patent_id" = "10000000")),
    "You cannot use the operator .* with the field"
  )

  expect_error(
    search_pv(qry_funs$eq("patent_date" = "10000000")),
    "Bad date: .*\\. Date must be in the format of yyyy-mm-dd"
  )

  expect_error(
    search_pv(qry_funs$gt("patent_id" = 10000000)),
    "must be of type character"
  )

  expect_error(
    search_pv(qry_funs$gt("patent_year" = 1980.5)),
    "must be an integer"
  )

  expect_error(
    search_pv(qry_funs$gt("patent_year" = "1980")),
    "must be an integer"
  )

  expect_error(
    search_pv(qry_funs$eq("application.rule_47_flag" = "TRUE")),
    "must be a boolean"
  )

  expect_error(
    search_pv(qry_funs$eq("rule_47_flag" = "TRUE"), endpoint = "publication"),
    "must be a boolean"
  )

  expect_error(
    search_pv(qry_funs$eq("patent_id" = "10000000"), exclude_withdrawn = "FALSE"),
    "must be NULL or a boolean"
  )

  expect_error(
    search_pv(list(patent_number = "10000000")),
    "is not a valid operator or not a valid field"
  )

  bogus_operator_query <- list("_ends_with" = list(patent_title = "dog"))
  expect_error(
    search_pv(bogus_operator_query),
    "is not a valid operator or not a valid field"
  )
})

test_that("valid nested field can be queried", {
  vcr::local_cassette("nested-field-query")
  results <- search_pv(qry_funs$eq("application.rule_47_flag" = TRUE))
  expect_gt(results$query_results$total_hits, 8000000)
})

test_that("_eq message is thrown for field:value pairs", {
  vcr::local_cassette("eq-message")
  expect_message(
    search_pv(list(patent_date = "2007-03-06")),
    "The _eq operator is a safer alternative"
  )
})

test_that("and operator works", {
  vcr::local_cassette("and-operator")
  query <- with_qfuns(
    and(
      text_phrase(inventors.inventor_name_first = "George"),
      text_phrase(inventors.inventor_name_last = "Washington")
    )
  )
  result <- search_pv(query)
  expect_gte(result$query_results$total_hits, 1)
})
