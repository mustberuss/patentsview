# Vector of queries (one for each endpoint) that are used during testing. We
# need this b/c in the new version of the api, only three of the endpoints are
# searchable by patent number (i.e., we can't use a generic patent number
# search query).  further, now patent_number has been patent_id

TEST_QUERIES <- c(
  "patent/us_application_citation" = '{"patent_id": "10966293"}',
  "assignee" = '{"_text_phrase":{"assignee_individual_name_last": "Clinton"}}',
  "cpc_subclass" = '{"cpc_subclass_id": "A01B"}',
  "cpc_group" = '{"cpc_group_id": "A01B1/00"}',
  "cpc_class" = '{"cpc_class_id": "A01"}',
  "inventor" = '{"_text_phrase":{"inventor_name_last":"Clinton"}}',
  "patent" = '{"patent_id":"5116621"}',
  "patent/us_patent_citation" = '{"patent_id":"5116621"}',
  "uspc_mainclass" = '{"uspc_mainclass_id":"30"}',
  "uspc_subclass" = '{"uspc_subclass_id": "100/1"}',
  "patent/attorney" = '{"attorney_id":"005dd718f3b829bab9e7e7714b3804a5"}',
  "patent/foreign_citation" = '{"patent_id": "10000001"}',
  "patent/rel_app_text" =  '{"patent_id": "10000007"}',
  "ipc" = '{"ipc_id": "1"}',
  "location" = '{"location_name":"Chicago"}',
  "wipo" = '{"wipo_id": "1"}',
  "publication" = '{"document_number": 20010000002}',
  "publication/rel_app_text" = '{"document_number": 20010000001}',
  "brf_sum_text" = '{"patent_id": "11530080"}',
  "claim" = '{"patent_id": "11530080"}',
  "detail_desc_text" = '{"patent_id": "11530080"}',
  "draw_desc_text" = '{"patent_id": "11530080"}'
   
)
