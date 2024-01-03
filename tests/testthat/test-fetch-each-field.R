
# Temporary test case - fail when all fields can be retrieved!

# maybe try retrieving all fields and see if all the expected fields are returned??
# "patents assignees.assignee_id not returned"  probably the _id thing, assignees.assignee probably returned

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

  # make it noticeable that all is not right with the API
  skip("Skip for API bugs") # TODO: remove when the API is fixed
})
