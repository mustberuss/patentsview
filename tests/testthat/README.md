# Testing Guide

Tests use [vcr](https://docs.ropensci.org/vcr/) to record/replay HTTP responses (~8 sec vs minutes).

## Running Tests

```r
devtools::test()                    # All tests
devtools::test(filter="search-pv")  # runs just test-search-pv.R 
```

## Re-recording Cassettes

Delete one or more of the YAML files and re-run the test (requires `PATENTSVIEW_API_KEY`):

```r
unlink("tests/testthat/_vcr/my-test.yml")
devtools::test()
```

## Running test without recordings

The vcr package checks for an environmental variable `VCR_TURN_OFF`. If  true it turns off all vcr usage so that all requests are live.  It would be a good idea to do this after an API release.  

```r
Sys.setenv(VCR_TURN_OFF = "true")
devtools::test()
```

## API Bug Testing

When running live, `test-api-bugs.R` hits the API to detect when bugs are fixed. When a test fails, the bug may be fixed - verify and remove the workaround.

```r
unlink("tests/testthat/_vcr/bug*.yml")
devtools::test(filter="api-bugs")
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
