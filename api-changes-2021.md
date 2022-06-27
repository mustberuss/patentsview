# Affects on the R package of the Patentsview api changes announced in 2021

As announced [here](https://patentsview.org/data-in-action/whats-new-patentsview-july-2021) in 2021, the patentsview api will be changing sometime in 2022. This will impact the r package in the following ways.

1. An api key will be required and will affect all users. Following the best practice of using an environmental variable to hold the value (https://cran.r-project.org/web/packages/httr/vignettes/api-packages.html), PATENTSVIEW_API_KEY must exist in the environment.  Changes in search-pv.R 
2. Endpoint Changes
     1. Two totally new endpoints
        *  /api/v1/patent_citation/
        * /api/v1/application_citation/
    2. Original endpoints cpc, nbr and cpc become these endpoints:
        * /cpc_group
        * /cpc_subgroup
        * /cpc_subsection
        * /nber_category
        * /nber_subcategory
        * /uspc_mainclass
        * /uspc_subclass
Note that cpc_subsection looks like the existing cpc endpoint and uspc_mainclass looks like the existing uspc endpoint but they will behave quite differently.
   3. Existing endpoints currently on the test server
         *  /patents
         *  /assignees
         *  /inventors
   4. Existing endpoints not currently on the test server
         *  /locations
     
    Note that there are new, get-only convience endpoints that take a url parameter.  The r package can ignore these and just use the ones that do posts and gets using q,f,s and o parameters.

3. Throttling will be imposed. An http status of 429 "Too many requests" will be returned if more than 45 requests are received per minute.  The Retry-After header will specify the number of seconds to wait before sending the next request.
Changes in search-pv.R sleep Retry-After seconds then retries the query to hide this change from package users. 
4. The subdomain domain and pattern of the endpoints are changing. Corresponding changes made in search-pv.R
  existing
 &emsp; https://api.patentsview.org/cpc_subsections/query?q=
  new
  &emsp; https://search.patentsview.org/api/v1/cpc_subsection/?q=

5. Options change (o parameter)
    1. size and offset rather than page and per_page
      can be hidden from users in search_pv.R

        ```
        offset = (page-1) * per_page,
        size = per_page
        ```
    2. size/per_page maximum changes from 10,000 to 1,000 could affect users       maximum check and message changed in validate-args.R could throw a warning when per_page is set above 1,000 send to api as 1,000
    3. matched_subentities_only and include_subentity_total_counts seem to have gone away. https://patentsview.org/api-v01-information-page mentions 
     Owing to de-normalized and split API design, sub-entity information is not available directly via each endpoint. As a consequence, "matched_subentity" option parameters are not valid. 
    4. The api's default result set size changed from 25 to 100 when no side/per_page is specified.  In search-pv.R it's defaulted to 25 when not specified, so no impact to current package users.
6. POST requests will need to send JSON data (instead of string representation of JSON). Added a Content-Type: application/json header in search-pv.R, otherwise the api returned Unsupported Media Type (HTTP 415).

7. The data comes back in a different order than before.  Not positive that this is correct.
    ~~~~
    in process-resp.R it's
       list(prsd_resp[[4]]),
       names = names(prsd_resp[4]),
    ~~~~
    it used to be
    ~~~~
       list(prsd_resp[[1]]),
       names = names(prsd_resp[1]),
    ~~~~
    now the order is
       error, count, total_hits, data
    while it used to be
       data, count, total_patent_count
    
    change in search-pv.R
      req_pages

## Observations
1. The endpoints are singular now, instead of being plural.  Ex /patents is now /patent
2. organization (formerly assignee_organization) is now a full text field, formerly it had been a string
3. The swagger definition (https://search.patentsview.org/static/openapi_v2.yml) does not contain  government interest fields, ipc fields, wipo fields, lawyer fields, foreign_priority fields, examiner fields, pct fields, raw inventor fields, coinventor fields, patent_firstnamed fields or patent_num_claims. Assuming these fields are all going away.
4. There  seems to be a change in case sensitivity compared to the original api. The original api would return results for q:{"patent_type":"Design"} while the ElasticSearch version does not.
5. Nested fields can be specified in the f: parameter (ex [ "patent_number", "assignees_at_grant.organization","assignees_at_grant.assignee"]) but the api throws a 500 error when they are used in the q: parameter (ex: q:{"cpc_current.cpc_subgroup_title": "Hand tools"}).  It also seems to matter on the endpoints that use url parameters.
6. It probably won't not matter to the r package but the slash in the url parameters of /api/v1/uspc_subclass/{uspc_subclass_id}/ and /api/v1/cpc_subgroup/{cpc_subgroup_id}/ need to be changed to colons, ex. 100:1 for 100/1 and A01B1:00 for A01B1/00 and respectively.  This can be seen in the return from the patent endpoint's cpc_current.cpc_subgroup, example  "https://search.patentsview.org/api/v1/cpc_subgroup/G01S7:4865/" It's a HATEOAS style link that conatins a colon instead of a slash.
7. The api seems like it will become less useful.  A lot of use cases will break, like the ones lists on https://docs.ropensci.org/patentsview/articles/examples.html 
8. There used to be endpoint specific _counts ex total_assignee_count.  Now all the endpoints return total_hits

## Notes
1. The online documentation is lagging.  The two new endpoints are documented on https://patentsview.org/data-in-action/whats-new-patentsview-july-2021 but they're missing the Query column (see the next note).  Pages for the other endpoint haven't been changed. I created fake pages for data-raw/mbr_fieldsdf.R to consume.  They're listed on  https://patentsview.historicip.com/api/.  If I was better at R I would have parsed out the swagger definition https://search.patentsview.org/static/openapi_v2.yml  We would need to iterate over the paths (the endpoints).  The paths with url parameters wouldn't matter to the r package, it would continue to use the ones that take the q,f,s and o parameters.  The 200 responses' content could be parsed, though I'm not sure strings can be differentiate from full text fields.
2. All fields are queryable.  From https://patentsview.org/apis/purpose Field List
Please refer to the 200 "Response" section for each endpoint for full list of fields available. All the available fields are "queryable." It's referring to the 200 Responses shown on the swagger page https://search.patentsview.org/swagger-ui/
3. The Swagger definition (https://patentsview.historicip.com/swagger/openapi_v2.yml) can be imported into Postman to give you a nicely loaded collection for the changed api.  You'll just need to set a global variable PVIEW_KEY and set the authorization's value to {{PVIEW_KEY}}.  
4. The swagger definition shows a X-Status-Reason-Code in addition to the existing X-Status-Reason. Not sure it matters to or would be useful for the r package
    ~~~~
    > print(httr::headers(resp)[['X-Status-Reason']])
    [1] "Invaild field: shoe_size"
    > print(httr::headers(resp)[['X-Status-Reason-Code']])
    [1] "ERR_Q"
    ~~~~

## TODOS
1. Vignettes and any automated testing will most likely have to change.  Looks like we'd need to set up a secret to hold an api key https://docs.github.com/en/rest/actions/secrets
2. Update comments
3. Paging isn't quite right, making a second request if all_pages = TRUE also seems to be sending offset:0, size:25 the first time and offset 0, size 25, per_page:10000, page:1
4. Test throttling
5. Check if we need to do anything about JSON on Posts (#6 at the top of the page)
6. Test that what comes back from the api calls matches the spreadsheet (singular/plural thing mentioned above)
7. Implement the warning mentioned above (second change to the options parameter)
8. Check if the location specific error checking is still needed (throw_if_loc_error() in process-error.R). The locations endpoint won't return as many fields as before. 
9. Add a warning message if the http status 403 Incorrect/Missing API Key is received. The api key must be in the environment at start up, so a 403 on a query should only be returned if it is invalid.
10. Maybe instead of having fake documentation, something like data-raw/mbr_fieldsdf.R should read the swagger definition to produce data-raw/fieldsdf.csv
11. mbr_fieldsdf.R probably needs to output group.field where the group doesn't match the endpoint's name.  Ex. for the patent endpoint, the group of patents doesn't need the group to be specified but the other fields would need to be preceded by their group and a dot.  Or change the fields in the fake documentation (to add the group.field where necessary)?
12. we probably don't need this in process-error.R

        "Your request resulted in a 500 error, likely because you have ",
        "requested too many fields in your request (the locations endpoint ",
        "currently has restrictions on the number of fields/groups you can ",
        "request). Try slimming down your field list and trying again."
13. problems with cast-pv-data.R  We need the dots when requesting data, ex. assignees_at_grant.state at patent endpoint, but then we don't want the dots when casting.  Probably need to remove the dots from the fake web pages and rescrape.  get_fields would need to add the groups and dot when the fields are nested. It's the one test that fails.


## Try it yourself
Steps to try this out locally
1. Request an api key from the patentsview team https://patentsview.org/apis/keyrequest
2. Set the environmental variable PATENTSVIEW_API_KEY value to your key.     
 ex: set PATENTSVIEW_API_KEY=your_key_here
3. Install the patentsview package from mustberuss' api-change-2021 branch devtools::install_github("mustberuss/patentsview@api-change-2021")

The environmental variable's name is the same one I used in the api's python wrapper https://github.com/mustberuss/PatentsView-APIWrapper/tree/api-change-2022
## Questions
1. Does anything need to change in cast-pv-data.R?
2. Are existing sleeps in search-pv.R needed? (If the throttling works)
3. Are there any other fields changing type?  (like assignee organization becoming a full text field, formerly it had been a string)
4. Are there more fields (like the government interests) that went away?
&nbsp;
&nbsp;