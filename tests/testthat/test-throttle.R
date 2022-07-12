context("throttling")

test_that("Throttled requests are automatically retried", {
  skip_on_cran()
  skip_on_ci()

# Should this be its own test or part of test-search-pv? Probably complicated enough
# to be its own tests.

# See if we can get throttled!  We'll ask for 50 patent numbers and then call back 
# for the citations of each - the new version of the api won't return citations
# from the patent endpoint.  This would be a semi legitimate use case though we'd probably 
# call back for all the patents or groups of patents, rather than individually.

# Currently there is a warning in the R package when throttling occurs so 
# we can expect_warning() here.  Wondering if the warning is a good idea.  Possibly add
# an optional parameter to search_pv?  Then the warning could be suppressed
# by default and enabled on the calls here.

   res <- search_pv(
     '{"_gte":{"patent_date":"2007-01-04"}}',
     per_page = 50
   )

   dl <- unnest_pv_data(res$data, "patent_number")

   # Fire off the individual requests as fast as we can - the api should throttle us if we make 
   # more than 45 requests per minute.  The throttling reply contains a header
   # of how many seconds to wait before retrying the request.  We're testing that search_pv
   # handles this for us.

   # We'll combine the output of the 50 calls
   built_singly <- data.frame()

  expect_warning(
      for(i in 1:length(dl$patents$patent_number))
      {
         query =  qry_funs$eq(patent_number = dl$patents$patent_number[i])

         res2 <- search_pv(
            query = query,
            endpoint = "patent_citations",
            fields = c("patent_number","cited_patent_number"),
            sort = c("cited_patent_number" = "asc"),
            per_page = 1000  # new maximum
         )

         built_singly <- rbind(built_singly, res2$data$patent_citations);
      }
   )

   # Now we want to make a single call to get the same data and
   # assert that the bulk results match the list of individual calls -
   # to prove that the throttled call eventually went through properly

   query_all = qry_funs$eq(patent_number = dl$patents$patent_number)

   result_all <- search_pv(
       query = query_all,
       fields = c("patent_number","cited_patent_number"),
       endpoint = "patent_citations",
       sort = c("patent_number" = "asc", "cited_patent_number" = "asc"),
       per_page = 1000,  # new maximum
       all_pages = TRUE  # would there be more than one page of results?
       )

   all <- unnest_pv_data(result_all$data, "patent_number")

   expect_identical(all$patent_citations, built_singly)

})


