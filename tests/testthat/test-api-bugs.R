
# Tests from the other files in this directory that are masking API errors
# This file will be submitted to the API team

eps <- (get_endpoints())

# from test-api-returns.R
test_that("API returns all requested groups", {
  skip_on_cran()
  skip_on_ci()

  # endpoints where an error is thrown if we request all the fields listed 
  # in the OpenAPI object

  bad_eps <- c("cpc_subclasses"
    , "locations"        # Error: Invalid field: location_latitude
    , "uspc_subclasses"  # Error: Internal Server Error
    , "uspc_mainclasses" # Error: Internal Server Error
    , "wipo"             # Error: Internal Server Error
    , "claims"           # Error: Invalid field: claim_dependent
    , "draw_desc_texts"  # Error: Invalid field: description_sequence
   )

  # this will fail when the api is fixed
  z <- lapply(bad_eps, function(x) {
    print(x)
    expect_error(
       j <- search_pv(query = TEST_QUERIES[[x]], endpoint = x, fields = get_fields(x))
    )
  })

  # endpoints where we request all fields but not all the expected groups 
  # are returned
  mismatched_returns <- c(
     "patents",
     "publications"
  ) 

  # this will fail when the API is fixed
  z <- lapply(mismatched_returns, function(x) {
    print(x)
    res <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )

    dl <- unnest_pv_data(res$data)

    actual_groups <- names(dl)
    expected_groups <- unique(fieldsdf[fieldsdf$endpoint == x, "group"])

    # we now need to unnest the endpoints for the comparison to work
    expected_groups <- sub("patent/","",expected_groups)
    expected_groups <- sub("publication/","",expected_groups)

    # better way to do this?  want to expect_set_not_equal
    expect_false(isTRUE(all.equal(length(actual_groups), length(expected_groups))))

  })

# test-fetch-each-field.R
test_that("each field in fieldsdf can be retrieved", {
  # Iterate through fieldsdf, requesting one field at a time to see if the field
  # really can be retrieved.  What fields work and don't work is constantly changing
  # as the new version of the api is being developed

  # maybe have the return be the fields that failed?  "endpoint"    "field"
  count <- 0

  dev_null <- sapply(get_endpoints(), function(endpoint) {
    fields <- fieldsdf[fieldsdf$endpoint == endpoint, c("field")]

    # here we want to remove nested fields like assignees.assignee_id
    fields <- fields[!fields %in% fields[grepl("\\.", fields)]]

    # should also test that there are unique values, some fields come back all NULLS

    lapply(fields, function(field) {
      tryCatch(
        expr = {
          # try adding the primary key to fields to see if that stops the 500s- helped some but not all
          # pk <- get_ok_pk(endpoint)
          pv_out <- search_pv(query = TEST_QUERIES[[endpoint]], endpoint = endpoint, fields = c(field))

          # see if the field actually came back - a fair amount don't come back
          # make sure pv_out$query_results$total_hits >= 1 first
          if(pv_out$query_results$total_hits == 0) 
             print(paste(endpoint,"zero hits"))
          else
          {
             found <- FALSE
             if(! field %in% colnames(pv_out$data[[1]])) {
                # check for the _id thing, ex requested assignee_id but got assignee back

                if(grepl("_id", field)) {
                   idless <- sub("_id","",field)

                   found <- idless  %in% colnames(pv_out$data[[1]])
                   if(found)
                      print(paste("id dance on ", endpoint, field))
                }
                if(!found)
                   print(paste(endpoint, field,"not returned"))
             }
          }
          NA
        },
        error = function(e) {
          print(paste("error",endpoint, field))
          print(e)
          count <<- count + 1
          c(endpoint, field)
        }
      )
    })
  })

  expect_true(count > 0)  # would fail when the API doesn't throw errors
})

# from test-search-pv.R
test_that("We can call all the legitimate HATEOAS endpoints", {
  skip_on_cran()

  # these currently throw Error: Internal Server Error
  broken_single_item_queries <- c(
    "cpc_subclass/A01B/",
   "uspc_mainclass/30/",
   "uspc_subclass/30:100/",
    "wipo/1/"
  )


  # TODO: remove when this is fixed
  # we'll know the api is fixed when this fails
  dev_null <- lapply(broken_single_item_queries, function(q) {
    expect_error(
       j <- retrieve_linked_data(add_base_url(q))
    )
  })

  # We'll make a call to get an inventor and assignee HATEOAS link
  # in case their ids are not persistent
  # new weirdness: we request inventor_id and assignee_id but the
  # fields come back without the _id
  res <- search_pv('{"patent_id":"10000000"}',
    fields = c("inventors.inventor_id", "assignees.assignee_id")
  )

  assignee <- retrieve_linked_data(res$data$patents$assignees[[1]]$assignee)
  expect_true(assignee$query_results$total_hits == 1)

  inventor <- retrieve_linked_data(res$data$patents$inventors[[1]]$inventor)
  expect_true(inventor$query_results$total_hits == 1)

})

# from test-search-pv.R
test_that("individual fields are still broken", {
  skip_on_cran()

  # Sample fields that cause 500 errors when requested by themselves.
  # Some don't throw errors when included in get_fields() but they do if
  # they are the only field requested.  Other individual fields at these
  # same endpoints throw errors.  Check fields again when these fail.
  sample_bad_fields <- c(
    "assignee_organization" = "assignees", 
    "inventor_lastknown_longitude" = "inventors",
    "inventor_gender_code"  = "inventors",
    "location_name" = "locations", 
    "attorney_name_last" = "patent/attorneys",
    "citation_country" = "patent/foreign_citations",
    "ipc_id" = "ipcs"
  )

  dev_null <- lapply(names(sample_bad_fields), function(x) {
    endpoint <- sample_bad_fields[[x]]
    expect_error(
      out <- search_pv(query = TEST_QUERIES[[endpoint]], endpoint = endpoint, fields = c(x))
    )
  })
})

})
