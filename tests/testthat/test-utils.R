context("utils")

test_that("we can convert endpoints to their singular form and back", {
  eps <- get_endpoints()
  z <- vapply(eps, function(x) {
    to_plural(to_singular(x))
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  # we now need to unnest the endpoints for the comparison to work
  unnested_eps <- vapply(eps, function(x) {
    sub("patent/", "", x)
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  expect_equal(unnested_eps, z)
})
