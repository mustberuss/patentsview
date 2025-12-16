EPS <- get_endpoints()

GENERALLY_BAD_EPS <- c(
  # Empty - all endpoints work when requesting all fields via get_fields()
)

# Queries (one for each endpoint) that are used during testing. We
# need this b/c in the new version of the api, only ten of the endpoints are
# searchable by patent number (i.e., we can't use a generic patent number
# search query).
TEST_QUERIES <- c(
  "assignee" = '{"_text_phrase":{"assignee_individual_name_last": "Clinton"}}',
  "cpc_class" = '{"cpc_class_id": "A01"}',
  "cpc_group" = '{"cpc_group_id": "A01B1/00"}',
  "cpc_subclass" = '{"cpc_subclass_id": "A01B"}',
  "g_brf_sum_text" = '{"patent_id": "PP36776"}',
  "g_claim" = '{"patent_id": "PP36776"}',
  "g_detail_desc_text" = '{"patent_id": "PP36776"}',
  "g_draw_desc_text" = '{"patent_id": "PP36776"}',
  "inventor" = '{"_text_phrase":{"inventor_name_last":"Clinton"}}',
  "ipc" = '{"ipc_id": "1"}',
  "location" = '{"location_name":"Chicago"}',
  "patent" = '{"patent_id":"5116621"}',
  "patent/attorney" = '{"attorney_id":"005dd718f3b829bab9e7e7714b3804a5"}',
  "patent/foreign_citation" = '{"patent_id": "10000001"}',
  "patent/other_reference" = '{"patent_id": "3930306"}',
  "patent/rel_app_text" = '{"patent_id": "10000007"}',
  "patent/us_application_citation" = '{"patent_id": "10966293"}',
  "patent/us_patent_citation" = '{"patent_id":"5116621"}',
  "pg_brf_sum_text" = '{"document_number": 20250212711}',
  "pg_claim" = '{"document_number": 20250212711}',
  "pg_detail_desc_text" = '{"document_number": 20250107476}',
  "pg_draw_desc_text" = '{"document_number": 20250107476}',
  "publication" = '{"document_number": 20010000002}',
  "publication/rel_app_text" = '{"document_number": 20010000001}',
  "uspc_mainclass" = '{"uspc_mainclass_id":"30"}',
  "uspc_subclass" = '{"uspc_subclass_id": "100/1"}',
  "wipo" = '{"wipo_id": "1"}'
)
