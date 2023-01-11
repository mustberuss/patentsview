# Vector of queries (one for each endpoint) that are used during testing. We
# need this b/c in the new version of the api, only three of the endpoints are
# searchable by patent number (i.e., we can't use a generic patent number
# search query).

# the ones with ids may break if they aren't persistent

TEST_QUERIES <- c(
  "patent/us_application_citations" = '{"patent_id": "10966293"}',
  "assignees" = '{"_text_phrase":{"assignee_individual_name_last": "Clinton"}}',
  "cpc_subclasses" = '{"cpc_subclass_id": "A01B"}',
  "cpc_groups" = '{"cpc_group_id": "A01B1/00"}',
  "cpc_classes" = '{"cpc_class_id": "A01"}',
  "inventors" = '{"_text_phrase":{"inventor_name_last":"Clinton"}}',
  "nber_categories" = '{"nber_category_id": "1"}',
  "nber_subcategories" = '{"nber_subcategory_id": "11"}',
  "patents" = '{"patent_id":"5116621"}',
  "patent/us_patent_citations" = '{"patent_id":"5116621"}',
  "uspc_mainclasses" = '{"uspc_mainclass_id":"30"}',
  "uspc_subclasses" = '{"uspc_subclass_id": "100/1"}',
  "locations" = '{"location_name":"Chicago"}',
  # wipo: matching our endpoint pseudonym with the returned entity
  "wipo" = '{"wipo_id": "1"}',
  "ipcs" = '{"ipc_id":"1"}',
  "patent/attorneys" = '{"attorney_id":"005dd718f3b829bab9e7e7714b3804a5"}',
  "patent/foreign_citations" = '{"patent_id": "10000001"}',
  "patent/rel_app_texts" = '{"patent_id": "10000007"}'

)




