
# Tests from the other files in this directory that are masking API errors
# This file was submitted to the API team as PVS-1125

eps <- (get_endpoints())

add_base_url <- function(x) {
  paste0("https://search.patentsview.org/api/v1/", x)
}

test_that("there is trouble paging", {
  skip_on_cran()
  skip_on_ci()

  # reprex inspired by https://patentsview.org/forum/7/topic/812
  # Not all requested groups are coming back as we page, causing
  # Error in rbind(deparse.level, ...) :
  # numbers of columns of arguments do not match
  # This query fails if any of these groups are specified
  # "applicants", "cpc_at_issue", "gov_interest_contract_award_numbers",
  # "uspc_at_issue")

  query <- with_qfuns(
    and(
      gte(application.filing_date = "2000-01-01"),
      eq(cpc_current.cpc_subclass_id = "A01D")
    )
  )

  sort <- c("patent_id" = "asc")
  fields <- c(
    "patent_id", "applicants", "cpc_at_issue",
    "gov_interest_contract_award_numbers", "uspc_at_issue"
  )

  result1 <- search_pv(query,
    method = "GET", all_pages = FALSE,
    fields = fields, sort = sort, size = 1000
  )

  result2 <- search_pv(query,
    method = "GET", all_pages = FALSE,
    fields = fields, sort = sort, size = 1000, after = "06901731"
  )

  # result1$data$patents$applicants is sparse, mostly NULL
  # there isn't a result2$data$patents$applicants
  names1 <- names(result1$data$patents)
  names2 <- names(result2$data$patents)

  expect_failure(
    expect_setequal(names1, names2)
  )
})

test_that("there is case sensitivity on string equals", {
  skip_on_cran()
  skip_on_ci()

  # reported to the API team PVS-1147
  # not sure if this is a bug or feature - original API was case insensitive
  # using both forms of equals, impied and explicit

  assignee <- "Johnson & Johnson International"
  query1 <- sprintf('{"assignee_organization": \"%s\"}', assignee)
  a <- search_pv(query1, endpoint = "assignee")
  query2 <- qry_funs$eq(assignee_organization = assignee)
  b <- search_pv(query2, endpoint = "assignee")
  expect_equal(a$query_results$total_hits, 1)
  expect_equal(b$query_results$total_hits, 1)

  assignee <- tolower(assignee)
  query1 <- sprintf('{"assignee_organization": \"%s\"}', assignee)
  c <- search_pv(query1, endpoint = "assignee")
  query2 <- qry_funs$eq(assignee_organization = assignee)
  d <- search_pv(query2, endpoint = "assignee")
  expect_equal(c$query_results$total_hits, 0)
  expect_equal(d$query_results$total_hits, 0)
})

test_that("string vs text operators behave differently", {
  skip_on_cran()

  # # reported to the API team PVS-1147
  query <- qry_funs$begins(assignee_organization = "johnson")
  a <- search_pv(query, endpoint = "assignee")

  query <- qry_funs$text_any(assignee_organization = "johnson")
  b <- search_pv(query, endpoint = "assignee")

  expect_failure(
    expect_equal(a$query_results$total_hits, b$query_results$total_hits)
  )
})

test_that("API returns all requested groups", {
  skip_on_cran()
  skip_on_ci()

  # can we traverse the return building a list of fields?
  # sort both requested fields and returned ones to see if they are equal

  # TODO: remove the trickery to get this test to pass, once the API is fixed
  bad_eps <- c(
    "cpc_subclasses",
    "location" # Error: Invalid field: location_latitude
    , "uspc_subclasse" # Error: Internal Server Error
    , "uspc_mainclass" # Error: Internal Server Error
    , "wipo" # Error: Internal Server Error
    , "claim" # Error: Invalid field: claim_dependent
    , "draw_desc_text" # Error: Invalid field: description_sequence
    , "cpc_subclass" # 404?  check the test query
    , "uspc_subclass" # 404
    , "pg_claim" # Invalid field: claim_dependent
    , "assignee" # Invalid field: assignee_years.num_patents
    , "inventor" # Invalid field: inventor_years.num_patents
  )

  mismatched_returns <- c(
    "patent",
    "publication"
  )

  good_eps <- eps[!eps %in% c(mismatched_returns, bad_eps)]

  z <- lapply(good_eps, function(endpoint) {
    print(endpoint)
    res <- search_pv(
      query = TEST_QUERIES[[endpoint]],
      endpoint = endpoint,
      fields = get_fields(endpoint)
    )

    dl <- unnest_pv_data(res$data, pk = get_ok_pk(endpoint))

    actual_groups <- names(dl)

    expected_groups <- unique(fieldsdf[fieldsdf$endpoint == endpoint, "group"])

    # we now need to unnest the endpoints for the comparison to work
    #expect ed_groups <- gsub("^(patent|publication)/", "", expected_groups)

    expect_setequal(actual_groups, expected_groups)
    show_failure(expect_setequal(actual_groups, expected_groups))
  })

  # this will fail when the api is fixed
  z <- lapply(bad_eps, function(x) {
    print(x)
    expect_error(
      j <- search_pv(query = TEST_QUERIES[[x]], endpoint = x, fields = get_fields(x))
    )
  })

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
    expected_groups <- gsub("^(patent|publication)/", "", expected_groups)

    # the expected group for unnested attributes would be "" in actuality the come back
    # in an entity matching the plural form of the unnested endpoint
    expected_groups <- replace(expected_groups, expected_groups == "", to_plural(x))

    expect_failure(
      expect_setequal(actual_groups, expected_groups)
    )
  })

  # make it noticeable that all is not right with the API
  skip("Skip for API bugs") # TODO: remove when the API is fixed
})

eps <- (get_endpoints())

# request size 0?

test_that("each field in fieldsdf can be retrieved", {
  skip_on_cran()

  # PVS-1125
  # Iterate through fieldsdf, requesting one field at a time to see if the field
  # really can be retrieved.  What fields work and don't work is constantly changing
  # as the new version of the api is being developed

  endpoints <- get_endpoints()
  endpoints <- c("uspc_subclass", "location")

  troubled <- sapply(endpoints, function(endpoint) {
    fields <- fieldsdf[fieldsdf$endpoint == endpoint, c("field")]

    # here we want to remove nested fields like assignees.assignee_id
    # probably should check these once the non nested ones stop throwing errors
    fields <- fields[!fields %in% fields[grepl("\\.", fields)]]

    # should also test that there are unique values, some fields come back all NULLS

    result <- lapply(fields, function(field) {
      tryCatch(
        expr = {
          # try adding the primary key to fields to see if that stops the 500s- helped some but not all
          # pk <- get_ok_pk(endpoint)
          pv_out <- search_pv(query = TEST_QUERIES[[endpoint]], endpoint = endpoint, fields = c(field))

          error_reason <- NULL

          # see if the field actually came back - a fair amount don't come back
          # make sure pv_out$query_results$total_hits >= 1 first
          if (pv_out$query_results$total_hits == 0) {
            print(paste(endpoint, "zero hits"))
            error_reason <- "zero hits"
          } else {
            found <- FALSE
            if (!field %in% colnames(pv_out$data[[1]])) {
              # check for the _id thing, ex requested assignee_id but got assignee back

              if (grepl("_id", field)) {
                idless <- sub("_id", "", field)

                found <- idless %in% colnames(pv_out$data[[1]])
                if (found) {
                  print(paste("id dance on", endpoint, field))
                }
              }
              if (!found) {
                print(paste("not returned", endpoint, field))
                error_reson <- "not returned"
              }
            }
          }
          if (is.null(error_reson)) NA else paste(error_reson, endpoint, field)
        },
        error = function(e) {
          paste("error", endpoint, field)
        }
      )
    })
    result[!is.na(result)]
  })

  troubled_fields <- do.call(c, unlist(troubled, recursive = FALSE))

  names(troubled_fields) <- NULL
  print(troubled_fields)
  expect_gt(length(troubled_fields), 0) # would fail when the API doesn't throw errors etc.
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
  # we'll know the api is fixed when this test fails
  dev_null <- lapply(broken_single_item_queries, function(q) {
    expect_error(
      j <- retrieve_linked_data(add_base_url(q))
    )
  })
})

test_that("individual fields are still broken", {
  skip_on_cran()

  # Sample fields that cause 500 errors when requested by themselves.
  # Some don't throw errors when included in get_fields() but they do if
  # they are the only field requested.  Other individual fields at these
  # same endpoints throw errors.  Check fields again when these fail.
  sample_bad_fields <- c(
    "assignee_organization" = "assignees",
    "inventor_lastknown_longitude" = "inventors",
    "inventor_gender_code" = "inventors",
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

test_that("we can't sort by all fields", {
  skip_on_cran()

  # seems to behave differently for POSTs than GETs ?
  # PVS-1377

  endpoint_bad_fields <- lapply(eps, function(endpoint) {
    unnested_fields <- get_fields(endpoint, groups = to_plural(endpoint))

    result <- lapply(unnested_fields, function(field) {
      tryCatch(
        {
          sort <- c("asc")
          names(sort) <- field
          j <- search_pv(
            query = TEST_QUERIES[[endpoint]],
            endpoint = endpoint, sort = sort, method = "GET"
          )
          NA
        },
        error = function(e) {
          paste(endpoint, field)
        }
      )
    })
    result[!is.na(result)]
  })

  bad_sort_fields <- do.call(c, unlist(endpoint_bad_fields, recursive = FALSE))

  print(bad_sort_fields)

  expect_gt(length(bad_sort_fields), 0)
})


test_that("withdrawn patents are still present in the database", {
  skip_on_cran()

  # PVS-1342 Underlying data issues
  # There are 8,000 patents that were in the bulk xml files patentsiew is based on.
  # The patents were subsequently withdrawn but not removed from the database
  withdrawn <- c(
    "9978309", "9978406", "9978509", "9978615", "9978659",
    "9978697", "9978830", "9978838", "9978886", "9978906", "9978916",
    "9979255", "9979355", "9979482", "9979700", "9979841", "9979847",
    "9980139", "9980711", "9980782", "9981222", "9981277", "9981423",
    "9981472", "9981603", "9981760", "9981914", "9982126", "9982172",
    "9982670", "9982860", "9982871", "9983588", "9983756", "9984058",
    "9984899", "9984952", "9985340", "9985480", "9985987", "9986046"
  )

  query <- qry_funs$eq("patent_id" = c(withdrawn))
  results <- search_pv(query, method = "POST")
  expect_equal(results$query_results$total_hits, length(withdrawn))
})

test_that("missing patents are still missing", {
  skip_on_cran()

  # PVS-1342 Underlying data issues
  # There are around 300 patents that aren't in the bulk xml files patentsiew is based on.
  missing <- c(
    "4097517", "4424514", "4480077", "4487876", "4704648", "4704721",
    "4705017", "4705031", "4705032", "4705036", "4705037", "4705097", "4705107",
    "4705125", "4705142", "4705169", "4705170", "4705230", "4705274", "4705328",
    "4705412", "4705416", "4705437", "4705455", "4705462", "5493812", "5509710",
    "5697964", "5922850", "6087542", "6347059", "6680878", "6988922", "7151114",
    "7200832", "7464613", "7488564", "7606803", "8309694", "8455078"
  )
  query <- qry_funs$eq("patent_id" = missing)
  results <- search_pv(query, method = "POST")

  # This would fail if these patents are added to the patentsview database
  expect_equal(results$query_results$total_hits, 0)
})

test_that("we can't explicitly request assignee_ or inventor_years.num_patents", {
  skip_on_cran()

  bad_eps <- c(
    "assignee", # Invalid field: assignee_years.num_patents. assignee_years is not a nested field
    "inventor" # Invalid field: inventor_years.num_patents.
  )

  # PVS-1437 Errors are thrown when requesting assignee_years or inventor_years
  # (it works if the group name is used but fails on fully qualified nested fields)
  tmp <- lapply(bad_eps, function(endpoint) {
    expect_error(
      pv_out <- search_pv(
        query = TEST_QUERIES[[endpoint]],
        endpoint = endpoint,
        fields = fieldsdf[fieldsdf$endpoint == endpoint, "field"]
      ),
      "Invalid field: (assignee|inventor)_years.num_patents"
    )
  })
})

test_that("uspcs aren't right", {
  skip_on_cran()

  # PVS-1615

    endpoint <- "patent"
    res <- search_pv(
      query = TEST_QUERIES[[endpoint]],
      endpoint = endpoint,
      fields = get_fields(endpoint, groups="uspc_at_issue")
    )

  # id fields are correct, non id fields should be HATEOAS links
  uspcs <- res$data$patents$uspc_at_issue

  # these should fail when the API is fixed
  expect_equal(uspcs$uspc_mainclass, uspcs$uspc_mainclass_id)
  expect_equal(uspcs$uspc_subclass, uspcs$uspc_subclass_id)
  
})


