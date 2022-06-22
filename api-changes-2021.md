# Affects of the 2021 Patentsview api changes on the R package

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
     
    Note that there are new, get-only convience endpoints that take url parameters.  The r package can ignore these and just use the ones that do posts and gets using q,f,s and o parameters.

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
1. assignee_organization is now a full text field, formerly it had been a string
2. The swagger definition (https://search.patentsview.org/static/openapi_v2.yml) does not contain  government interest fields or ipc fields. Assuming these fields are going away.

## Notes
1. The online documentation is lagging.  The two new endpoints are documented on https://patentsview.org/data-in-action/whats-new-patentsview-july-2021 but they're missing the Query column (see the next note).  Pages for the other endpoint haven't been changed. I created fake pages for data-raw/mbr_fieldsdf.R to consume.  They're listed on  https://patentsview.historicip.com/api/.  If I was better at R I would have parsed out the swagger definition https://search.patentsview.org/static/openapi_v2.yml  We would need to iterate over the paths (the endpoints).  The paths with url parameters wouldn't matter to the r package, it would continue to use the ones that take the q,f,s and o parameters.  The 200 responses' content could be parsed.  
2. All fields are queryable.  From https://patentsview.org/apis/purpose Field List
Please refer to the 200 "Response" section for each endpoint for full list of fields available. All the available fields are "queryable."
3. The Swagger definition (https://patentsview.historicip.com/swagger/openapi_v2.yml) can be imported into Postman to give you a nicely loaded collection for the changed api.  You'll just need to set a global variable PVIEW_KEY and set the authorization's value to {{PVIEW_KEY}}.  The [Swagger UI page](https://patentsview.historicip.com/swagger/new_swagger.htm) can also be used but there's [an api bug](https://github.com/PatentsView/PatentsView-API/issues/37) preventing the X-Status-Reason and X-Status-Reason-Code from being displayed.
4. The swagger definition shows a X-Status-Reason-Code in addition to the existing X-Status-Reason. Not sure it matters to or would be useful for the r package
    ~~~~
    > print(httr::headers(resp)[['X-Status-Reason']])
    [1] "Invaild field: shoe_size"
    > print(httr::headers(resp)[['X-Status-Reason-Code']])
    [1] "ERR_Q"
    ~~~~
5. in print.R it's still cpc_subsections even though the endpoint is now singular. Potential api bug. Groups and endpoints are now singular rather than being plural patent instead of patents etc. according to the spreadsheet they sent out. 
6. Not all of the cpc and uspc endpoints are working.  Some return a 400 with an X-Status-Reason: 
    > Text fields are not optimised for operations that require per-document field data like aggregations and sorting, so these operations are disabled by default. Please use a keyword field instead. Alternatively, set fielddata=true on [uspc_mainclass_id] in order to load field data by uninverting the inverted index. Note that this can use significant memory.


## TODOS
1. Vignettes and any automated testing will most likely have to change
2. Update comments
3. Paging isn't quite right, making a second request if all_pages = TRUE also seems to be sending offset:0, size:25 the first time and offset 0, size 25, per_page:10000, page:1
4. Test throttling
5. Check if we need to do anything about JSON on Posts (#6 at the top of the page)
6. Test that what comes back from the api calls matches the spreadsheet (singular/plural thing mentioned above)
7. Implement the warning mentioned above (second change to the options parameter)
8. Check if the location specific error checking is still needed (throw_if_loc_error() in process-error.R). The locations endpoint won't return as many fields as before. 
9. Add a warning message if the http status 403 Incorrect/Missing API Key is received. The api key must be in the environment at start up, so a 403 on a query should only be returned if it is invalid.
10. Maybe instead of having fake documentation, something like data-raw/mbr_fieldsdf.R should read the swagger definition to produce data-raw/fieldsdf.csv

## Questions
1. Does anything need to change in cast-pv-data.R?
2. Are existing sleeps in search-pv.R needed? (If the throttling works)
3. Are there any other fields changing type?  (like assignee_organization becoming a full text field, formerly it had been a string)
4. Are there more fields (like the government interests) that went away?
&nbsp;
&nbsp;
