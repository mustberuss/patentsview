# Testing Guide

Tests use [vcr](https://docs.ropensci.org/vcr/) to record/replay HTTP responses (~8 sec vs minutes).

## Running Tests

```r
devtools::test()                    # All tests
testthat::test_file("tests/testthat/test-search-pv.R")  # One file
```

## Re-recording Cassettes

Delete the YAML file and re-run the test (requires `PATENTSVIEW_API_KEY`):

```r
unlink("tests/testthat/_vcr/my-test.yml")
devtools::test()
```

## Live API Tests

`test-api-bugs.R` hits the live API to detect when bugs are fixed. Skipped by default:

```r
Sys.setenv(PATENTSVIEW_LIVE_TESTS = "true")
testthat::test_file("tests/testthat/test-api-bugs.R")
```

## Adding Tests

Use `vcr::local_cassette()` with a unique name for any test that calls the API:

```r
test_that("my feature works", {
  vcr::local_cassette("my-feature")
  result <- search_pv(...)
  expect_equal(...)
})
```

API keys are automatically filtered from cassettes.
