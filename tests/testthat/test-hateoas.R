context("hateoas")

test_that("We won't expose the user's patentsview API key to random websites", {
  skip_on_cran()
  skip_on_ci()

  # We will try to call the api that tells us who is currently in space
  in_space_now_url <- "http://api.open-notify.org/astros.json"

  expect_error(
    retrieve_linked_data(in_space_now_url)
  )
})


test_that("We can call all the legitimate HATEOAS endpoints", {
  skip_on_cran()
  skip_on_ci()

  # Call the new, Get only endpoints that don't accept q: s:, o:, f:, parameters
  # The links are returned fully qualified, like below, from some of the endpoints
  # These queries retrieve one specific row
  single_item_queries <- c(
    "https://search.patentsview.org/api/v1/assignee/00000ce5-b13f-4a23-a8fb-c14409ad7b68/",
    "https://search.patentsview.org/api/v1/cpc_subclass/A01B/",
    "https://search.patentsview.org/api/v1/cpc_class/A01/",
    "https://search.patentsview.org/api/v1/inventor/0000n6xqianutadbzbgzwled7/",
    "https://search.patentsview.org/api/v1/nber_category/1/",
    "https://search.patentsview.org/api/v1/nber_subcategory/11/",
    "https://search.patentsview.org/api/v1/patent/10757852/",
    "https://search.patentsview.org/api/v1/uspc_mainclass/30/",
    "https://search.patentsview.org/api/v1/location/00235947-16c8-11ed-9b5f-1234bde3cd05/",

    # return entity is a wipo, singular not plural - hateoas link throws a 400
    # "https://search.patentsview.org/api/v1/wipo/1/",

    # urls now nested under /patent
    "https://search.patentsview.org/api/v1/patent/attorney/005dd718f3b829bab9e7e7714b3804a5/"

  )

  # These queries can return more than a single row
  # now returned entities come back with a leading us_ but the api is throwing 404s

  multi_item_queries <- c(
    "https://search.patentsview.org/api/v1/patent/us_application_citation/10966293/",
    "https://search.patentsview.org/api/v1/patent/us_patent_citation/10966293/",

    # next two mistakenly return multiple records
    "https://search.patentsview.org/api/v1/uspc_subclass/30:100/",
    "https://search.patentsview.org/api/v1/cpc_group/G01S7:4811/"
  )

  x <- lapply(single_item_queries, function(q) {
    Sys.sleep(2)
    print(q)
    j <- retrieve_linked_data(q)

    print(j$query_results$total_hits)
    # here all the total hits should be 1
    expect_equal(j$query_results$total_hits, 1)
  })

  x <- lapply(multi_item_queries, function(q) {
    Sys.sleep(2)
    print(q)
    j <- retrieve_linked_data(q)

    print(j$query_results$total_hits)

    # here all the total hits should be 1 or more rows
   expect_true(j$query_results$total_hits >= 1)
  })
})

