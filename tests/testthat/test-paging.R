context("paging")

test_that("Data matches between a paged and non paged response", {
  skip_on_cran()
  skip_on_ci()

  # check that paging works properly.  we'll make a single request that will return a 
  # limited amount of data. we'll then make multiple requests to retrieve the same data
  # in theory the result sets should match
  
  # currently there are 43 inventors whose last name is Quack
  # this test case would break if there are ever more than 1000 Quacks
  #query <- '{"_text_phrase":{"inventors_at_grant.name_last":"Quack"}}'
  query <- qry_funs$text_phrase("inventors_at_grant.name_last" = "Quack")

  sort <- c("patent_number" = "asc")
  fields <- c("patent_number", "patent_title", "patent_date","inventors_at_grant.name_last","inventors_at_grant.name_first" )

  res <- search_pv(
     query = query,
     fields = fields,
     sort = sort,
     per_page = 1000
   )

  dl <- unnest_pv_data(res$data, "patent_number")

  # we are assuming we can get all the Quacks in a single request
  # we'll assert this so we'll know if this is ever not the case
  # (the length would be at most 1000, the total_hits could eventually go higher, if a 
  # lot of Quacks get patents)
  expect_equal(res$query_results$total_hits, length(res$data$patents$patent_number))

  # now we'll request half the data with paging turned on 
  # rats- search-pv cant default this?  or change to a warning there and check here?

  half = ceiling(res$query_results$total_hits / 2)

   res2 <- search_pv(
     query = query,
     fields = fields,
     sort = sort,
     per_page = half,
     all_pages = TRUE,
     FORCE_PAGING = TRUE
   )

   dl2 <- unnest_pv_data(res2$data, "patent_number")
   expect_equal(dl, dl2)

})
