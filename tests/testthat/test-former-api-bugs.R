# Verify that former API bugs remain fixed

# --- HATEOAS :80 bug (FIXED as of Dec 2025 API release) ---
# HATEOAS links previously included :80 in https URLs causing SSL errors.
# Workaround: retrieve_linked_data() strips :80 (search-pv.R:416)
# Bug was fixed in Dec 2025 API release - workaround kept for safety.

test_that("HATEOAS links no longer contain :80 bug", {
  skip_on_cran()

  vcr::local_cassette("hateoas-link-check")
  res <- search_pv(
    '{"patent_id":"10000000"}',
    fields = c("assignees")
  )

  url <- res$data$patents$assignees[[1]]$assignee
  # Bug was fixed in Dec 2025 API release - verify it stays fixed
  expect_no_match(url, ":80")
})

# --- Withdrawn patents (PVS-1342) ---
# Withdrawn patents excluded by default (this is correct behavior now).

test_that("withdrawn patents excluded by default (PVS-1342)", {
  skip_on_cran()

  vcr::local_cassette("withdrawn-patent-behavior")
  withdrawn <- c("9978309", "9978406", "9978509")
  query <- qry_funs$eq(patent_id = withdrawn)

  res <- search_pv(query, method = "POST")
  expect_equal(res$query_results$total_hits, 0)
})

# --- Test query validation ---
# Verify that all TEST_QUERIES in helpers.R return at least 1 result.
# This catches cases where API data changes cause queries to return 0 hits.

test_that("all TEST_QUERIES return at least 1 result", {
  skip_on_cran()

  vcr::local_cassette("test-queries-return-results")
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
