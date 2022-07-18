context("hateoas")

test_that("We won't expose the user's patentsview API key to random websites", {
  skip_on_cran()
  skip_on_ci()
 
  # We will try to call the api that tells us who is currently in space 
  in_space_now_url <- 'http://api.open-notify.org/astros.json'

  expect_error(
     retrieve_linked_data(in_space_now_url)
  )
})


test_that("We can call all the legitimate HATEOAS endpoints", {
  skip_on_cran()
  skip_on_ci()

  # call the new, Get only endpoints that don't accept s:, o:, f:, parameters
  # the links are returned fully qualified, like below, from some of the endpoints
  # these queries retrieve 1 specific row
  single_item_queries <- c(
     'https://search.patentsview.org/api/v1/assignee/10/',
     'https://search.patentsview.org/api/v1/cpc_group/A01B/',
     'https://search.patentsview.org/api/v1/cpc_subgroup/G01S7:4811/',
     'https://search.patentsview.org/api/v1/cpc_subsection/A01/',
     'https://search.patentsview.org/api/v1/inventor/10/',
     'https://search.patentsview.org/api/v1/nber_category/1/',
     'https://search.patentsview.org/api/v1/nber_subcategory/11/',
     'https://search.patentsview.org/api/v1/patent/10757852/',
     'https://search.patentsview.org/api/v1/uspc_mainclass/30/',
     'https://search.patentsview.org/api/v1/uspc_subclass/30:100/'
   )

   # these queries can return more than a single row
   multi_item_queries <- c(
     'https://search.patentsview.org/api/v1/application_citation/10966293/',
     'https://search.patentsview.org/api/v1/patent_citation/10966293/'
   )

  x = lapply(single_item_queries, function(q) {
    Sys.sleep(2)
    print(q)
    j <- retrieve_linked_data(q)
 
    # here all the total hits should be 1
     expect_equal(j$query_results$total_hits, 1)
  })

  x = lapply(multi_item_queries, function(q) {
    Sys.sleep(2)
    print(q)
    j <- retrieve_linked_data(q)
 
    # here all the total hits should be 1 or more rows
     expect_true(j$query_results$total_hits >= 1)
  })
})





