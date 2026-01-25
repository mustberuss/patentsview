test_that("unnest works for patent endpoint", {
  skip_on_cran()

  vcr::local_cassette("unnest-patent")
  pv_out <- search_pv(
    query = '{"patent_id":"5116621"}',
    endpoint = "patent",
    fields = get_fields("patent")
  )
  unnested <- unnest_pv_data(pv_out$data)
  expect_s3_class(unnested, "pv_relay_db")
  expect_true("patents" %in% names(unnested))
  expect_true("patent_id" %in% names(unnested$patents))
})

test_that("unnest works for assignee endpoint", {
  skip_on_cran()

  vcr::local_cassette("unnest-assignee")
  pv_out <- search_pv(
    query = '{"_text_phrase":{"assignee_individual_name_last": "Clinton"}}',
    endpoint = "assignee",
    fields = get_fields("assignee")
  )
  unnested <- unnest_pv_data(pv_out$data)
  expect_s3_class(unnested, "pv_relay_db")
  expect_true("assignees" %in% names(unnested))
})

test_that("unnest works for inventor endpoint", {
  skip_on_cran()

  vcr::local_cassette("unnest-inventor")
  pv_out <- search_pv(
    query = '{"_text_phrase":{"inventor_name_last":"Clinton"}}',
    endpoint = "inventor",
    fields = get_fields("inventor")
  )
  unnested <- unnest_pv_data(pv_out$data)
  expect_s3_class(unnested, "pv_relay_db")
  expect_true("inventors" %in% names(unnested))
})

test_that("unnest handles empty results gracefully", {
  skip_on_cran()

  # Simulate empty API response (list, not data.frame)
  empty_list <- structure(
    list(patents = list()),
    class = c("list", "pv_data_result")
  )
  result <- unnest_pv_data(empty_list)
  expect_s3_class(result, "pv_relay_db")
  expect_length(result, 0)

 # Simulate empty data.frame response
  empty_df <- structure(
    list(patents = data.frame()),
    class = c("list", "pv_data_result")
  )
  result2 <- unnest_pv_data(empty_df)
  expect_s3_class(result2, "pv_relay_db")
  expect_length(result2, 0)
})

test_that("unnest separates nested entities", {
  skip_on_cran()

  vcr::local_cassette("unnest-nested")
  # Get patent with nested inventors and assignees
  pv_out <- search_pv(
    query = '{"patent_id":"5116621"}',
    fields = c("patent_id", "patent_title", "inventors", "assignees")
  )
  unnested <- unnest_pv_data(pv_out$data)

  expect_true("patents" %in% names(unnested))
  expect_true("inventors" %in% names(unnested))
  expect_true("assignees" %in% names(unnested))

  # Each subentity table should have the primary key for joining
  expect_true("patent_id" %in% names(unnested$inventors))
  expect_true("patent_id" %in% names(unnested$assignees))
})
