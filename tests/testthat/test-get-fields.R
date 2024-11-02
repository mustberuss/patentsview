test_that("get_fields works as expected", {
  skip_on_cran()

  expect_error(
    get_fields("bogus endpoint"),
    "endpoint must be",
    fixed = TRUE
  )

  expect_error(
    get_fields("patent", groups = "bogus"),
    "groups for the patent endpoint",
    fixed = TRUE
  )
})
