# These tests verify known API bugs/quirks.
# They hit the live API intentionally - we want to know when bugs are fixed.
# Tests skip by default; enable with: Sys.setenv(PATENTSVIEW_LIVE_TESTS = "true")
#
# When a test fails, the bug may be fixed - verify and remove the workaround.

skip_if_not_live <- function() {
  skip_on_cran()
  skip_if_offline()
  skip_if(
    Sys.getenv("PATENTSVIEW_LIVE_TESTS") != "true",
    "Set PATENTSVIEW_LIVE_TESTS=true to run live API tests"
  )
  skip_if(Sys.getenv("PATENTSVIEW_API_KEY") == "", "No API key")
}

# --- HATEOAS :80 bug (FIXED as of Dec 2025 API release) ---
# HATEOAS links previously included :80 in https URLs causing SSL errors.
# Workaround: retrieve_linked_data() strips :80 (search-pv.R:416)
# Bug was fixed in Dec 2025 API release - workaround kept for safety.

test_that("HATEOAS links no longer contain :80 bug", {
  skip_if_not_live()

  res <- search_pv(
    '{"patent_id":"10000000"}',
    fields = c("assignees")
  )

  url <- res$data$patents$assignees[[1]]$assignee
  # Bug was fixed in Dec 2025 API release - verify it stays fixed
  expect_no_match(url, ":80")
})

# --- Extra fields returned bug ---
# API returns more fields than requested, can break paging with rbind.
# Workaround: repair_resp() strips unrequested fields (process-resp.R:54)

test_that("API returns extra fields not requested", {
  skip_if_not_live()

  # Bypass repair_resp() by using retrieve_linked_data()
  url <- paste0(
    "https://search.patentsview.org/api/v1/patent/",
    "?q=%7B%22patent_id%22%3A%225116621%22%7D",
    "&f=%5B%22patent_id%22%5D&s=&o=%7B%22size%22%3A1000%7D"
  )
  res <- retrieve_linked_data(url)
  returned <- names(res$data[[1]])

  # Should only get patent_id, but API returns more
  extra <- setdiff(returned, "patent_id")
  # Test fails when bug is fixed - then remove repair_resp() workaround
  expect_true(
    length(extra) > 0,
    label = "Bug may be fixed - check repair_resp() workaround"
  )
})

# --- Unadvertised fields bug ---
# Some endpoints return fields not in openapi.json spec.

test_that("patent/foreign_citation returns unadvertised 'patent' field", {
  skip_if_not_live()

  res <- search_pv(
    '{"patent_id": "10000001"}',
    endpoint = "patent/foreign_citation",
    fields = get_fields("patent/foreign_citation")
  )

  # Bypass repair_resp()
  url <- httr2::last_request()$url
  raw <- retrieve_linked_data(url)
  returned <- names(raw$data[[1]])
  advertised <- get_fields("patent/foreign_citation")

  extra <- setdiff(returned, advertised)
  expect_true("patent" %in% extra)
})

# --- Case sensitivity bug (PVS-1147) ---
# String equality is case-sensitive, unlike the old API.

test_that("string equals is case sensitive (PVS-1147)", {
  skip_if_not_live()

  # Exact case works
  res <- search_pv(
    qry_funs$eq(assignee_organization = "Johnson & Johnson International"),
    endpoint = "assignee"
  )
  expect_equal(res$query_results$total_hits, 1)

  # Lowercase returns nothing
  res <- search_pv(
    qry_funs$eq(assignee_organization = "johnson & johnson international"),
    endpoint = "assignee"
  )
  expect_equal(res$query_results$total_hits, 0)
})

# --- Withdrawn patents (PVS-1342) ---
# Withdrawn patents excluded by default (this is correct behavior now).

test_that("withdrawn patents excluded by default (PVS-1342)", {
  skip_if_not_live()

  withdrawn <- c("9978309", "9978406", "9978509")
  query <- qry_funs$eq(patent_id = withdrawn)

  res <- search_pv(query, method = "POST")
  expect_equal(res$query_results$total_hits, 0)
})

# --- publication rule_47_flag bug (PVS-1884) ---

test_that("publication rule_47_flag query inverted (PVS-1884)", {
  skip_if_not_live()

  # FALSE should return results but returns 0
  res <- search_pv(
    qry_funs$eq(rule_47_flag = FALSE),
    endpoint = "publication"
  )
  expect_equal(res$query_results$total_hits, 0)
})

# --- IPC endpoint field bug ---
# The ipc endpoint returns HTTP 500 when requesting only the primary key (ipc_id).
# Works fine when requesting all fields.

test_that("ipc endpoint fails with default fields (only ipc_id)", {
  skip_if_not_live()

  # When no fields specified, search_pv() adds only the primary key ipc_id
  # This triggers a 500 error from the API
  expect_error(
    search_pv('{"ipc_id": "1"}', endpoint = "ipc"),
    regexp = "500|Internal Server Error"
  )
})

test_that("ipc endpoint works with all fields", {
  skip_if_not_live()

  # When requesting all fields, the endpoint works correctly
  res <- search_pv(
    '{"ipc_id": "1"}',
    endpoint = "ipc",
    fields = get_fields("ipc")
  )
  expect_gte(res$query_results$total_hits, 1)
})

# --- Paging structure mismatch bug ---
# Some queries return different fields on different pages, breaking rbind.
# Workaround: stop() with clear error message in search-pv.R

test_that("paging returns inconsistent fields (structure mismatch)", {
  skip_if_not_live()

  # This query is known to return different fields across pages
  query <- with_qfuns(
    and(
      gte(patent_earliest_application_date = "2001-01-01"),
      eq(cpc_current.cpc_subclass_id = "B62K"),
      eq(assignees.assignee_country = "US")
    )
  )

  # Request all fields - some pages return uspc_at_issue, others don't
  fields <- get_fields("patent")

  # Test fails when bug is fixed - then the stop() workaround can be removed

  expect_error(
    search_pv(query, fields = fields, all_pages = TRUE),
    regexp = "API returned paged data with different structure"
  )
})

# --- Test query validation ---
# Verify that all TEST_QUERIES in helpers.R return at least 1 result.
# This catches cases where API data changes cause queries to return 0 hits.

test_that("all TEST_QUERIES return at least 1 result", {
  skip_if_not_live()

  for (ep in names(TEST_QUERIES)) {
    if (ep %in% GENERALLY_BAD_EPS) next

    # Use get_fields() to request all fields - some endpoints (like ipc)
    # fail with default fields but work with all fields
    res <- search_pv(TEST_QUERIES[[ep]], endpoint = ep, fields = get_fields(ep))
    expect_gte(
      res$query_results$total_hits, 1,
      label = sprintf("Endpoint '%s' should return >= 1 hit", ep)
    )
  }
})
