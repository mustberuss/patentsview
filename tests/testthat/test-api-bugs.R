# These tests verify known API bugs/quirks.
# They hit the live API intentionally - we want to know when bugs are fixed.
# Run with: Sys.setenv(PATENTSVIEW_LIVE_TESTS = "true")

skip_if_not_live <- function() {
  skip_on_cran()
  skip_if_offline()
  skip_if(
    Sys.getenv("PATENTSVIEW_LIVE_TESTS") != "true" &&
      Sys.getenv("NOT_CRAN") != "true",
    "Set PATENTSVIEW_LIVE_TESTS=true to run live API tests"
  )
  skip_if(Sys.getenv("PATENTSVIEW_API_KEY") == "", "No API key")
}

test_that("case sensitivity on string equals (PVS-1147)", {
  skip_if_not_live()

  # Exact case works
  res <- search_pv(
    qry_funs$eq(assignee_organization = "Johnson & Johnson International"),
    endpoint = "assignee"
  )
  expect_equal(res$query_results$total_hits, 1)

  # Lowercase fails - this is the bug
  res <- search_pv(
    qry_funs$eq(assignee_organization = "johnson & johnson international"),
    endpoint = "assignee"
  )
  expect_equal(res$query_results$total_hits, 0)
})

test_that("withdrawn patents excluded by default (PVS-1342)", {
  skip_if_not_live()

  # These patents were withdrawn but used to appear in results
  withdrawn <- c("9978309", "9978406", "9978509")
  query <- qry_funs$eq(patent_id = withdrawn)

  # With default exclude_withdrawn (TRUE), should get 0 hits
  res <- search_pv(query, method = "POST")
  expect_equal(res$query_results$total_hits, 0)
})

test_that("HATEOAS links contain :80 bug", {
  skip_if_not_live()

  res <- search_pv(
    '{"patent_id":"10000000"}',
    fields = c("inventors", "assignees")
  )

  url <- res$data$patents$assignees[[1]]$assignee
  # Test will fail when bug is fixed - then we can remove the workaround
  expect_match(url, ":80")
})

test_that("publication rule_47_flag always FALSE (PVS-1884)", {
  skip_if_not_live()

  # This should return results but doesn't due to bug
  res <- search_pv(
    qry_funs$eq(rule_47_flag = FALSE),
    endpoint = "publication"
  )
  # Bug: returns 0 even though there should be matches
  expect_equal(res$query_results$total_hits, 0)
})
