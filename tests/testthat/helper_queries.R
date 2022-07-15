# In the new version of the api, only three of the endpoints are searchable 
# by patent number.  get_test_query() provides a sample query for each 
# endpoint, except for locations, which isn't on the test server yet

query_for_endpoint <- c(
      "application_citations" = '{"patent_number": "10966293"}',  # still searchable by pn
      "assignees" = '{"_text_phrase":{"name_last": "Clinton"}}',
      "cpc_groups" = '{"cpc_group_id": "A01B"}',
      "cpc_subgroups" = '{"cpc_subgroup_id": "A01B1/00"}',
      "cpc_subsections" = '{"cpc_subsection_id": "A01"}',
      "inventors" = '{"_text_phrase":{"name_last":"Clinton"}}',
      "locations" = NA,
      "nber_categories" = '{"nber_category_id": "1"}',
      "nber_subcategories" = '{"nber_subcategory_id": "11"}',
      "patents" = '{"patent_number":"5116621"}',           # still searchable by pn
      "patent_citations" = '{"patent_number":"5116621"}',  # still searchable by pn
      "uspc_mainclasses" = '{"uspc_mainclass_id":"30"}',
      "uspc_subclasses" = '{"uspc_subclass_id": "100/1"}')

# Here so more than one test can use the queries

get_test_query <- function (endpoint) {

   ifelse(endpoint %in% names(query_for_endpoint), query_for_endpoint[[endpoint]], NA)

}

