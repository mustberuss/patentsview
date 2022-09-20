everything is a string?? no, there are fulltexts

# Affects on the R package of the Patentsview API changes announced in 2021
(This is [api-redesign.md](https://github.com/mustberuss/patentsview/blob/api-redesign/api-redesign.md) with navigation to the updated vignettes and reference pages.)


> &nbsp;&nbsp;&nbsp;"Let's not bicker and argue about who killed who".  
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp; From Monty Python and Holy Grail 
    
I wasn't sure what the githubby way to do this would be but this page chronicles the work done so far, the choices made along the way and what is still outstanding.  Whether some of this could or should be issues or a project, in either this repo or its parent's could be debated, or maybe we should find a better way to bicker! (properly discuss the right way to change the R package.) Or maybe slug it all out in an epic, one for the ages, pull request?

## Outstanding
The changes comprising an MVP have been masterfully merged onto ropensci by crew102. Here's what's left:
1. Update vignettes, all of them changed.  The original ropensci blog post has been updated and could be added
as a vignette.  There is a new one about converting an existing script and another new one about the api
changes.  They might be pushing the definition of vignette slightly.
2. possibly add qry_funs$in_range() and safe_date_ranges() to the r package, more about this in Question 1
3. There is supposed to be a code release and data update this month.  Hopefully the locations endpoint will be
add to the test server, along with the applications endpoint mentioned vaguely
[here](https://patentsview.org/forum/8/topic/572#comment-560)

## Questions:
1. Should the new stuff mentioned [here](https://mustberuss.github.io/patentsview/articles/converting-an-existing-script.html#additions-to-the-r-package-1) be added to the package?
2. Should we update the version number? Maybe to 1.0.0 since it's not backward compatible.
3. Should we use r-universe for the distribution until the original API version is retired? (It could then
be submitted to CRAN).  There is an unauthorized badge and installation instructions [here](https://mustberuss.github.io/patentsview/)  We'd really use <https://ropensci.r-universe.dev/ui#package:patentsview>
4. Should we post a tech note to ropensci when the new version of the package is ready?  
A potential posting is [here](https://mustberuss.github.io/patentsview/articles/ropensci_tech_note.html)  (the stuff about the
sticker could be dropped)
5. Should we add a CONTRIBUTING.md and an issue template? The [best practices page](https://devguide.ropensci.org/package-development-security-best-practices.html#secrets-in-packages-and-development
) recommends adding a CONTRIBUTING.md with API key instructions etc.  It also recommends
adding an issue template reminding people not to share their API key.  usethis::use_tidy_contributing() generates a base
[CONTRIBUTING.md](https://github.com/mustberuss/patentsview/tree/api-redesign/.github/CONTRIBUTING.md) (links to a CODE_OF_CONDUCT.md delete or link to ropensci's instead?)
6. Have you seen [this](https://content.govdelivery.com/accounts/USPTO/bulletins/32deb51)? patft and appft are going away at the end of September 2022.  The ropensci blog post vignette has two patft links that will need updating. Not even sure how the first one winds up on pn 11,451,709!

## Important Notes
1. The locations endpoint is not on the test server yet.
2. More endpoints are coming by the end of 2022, rumored to include one for application data.

## Required Further Reading: 
(Keep reading, they're not prerequisites to reading this page)
1. The [announcement](https://patentsview.org/data-in-action/whats-new-patentsview-july-2021) of the API changes.
2. The new and modified vignettes (use the nav above).
3. The new and modified [test cases](https://github.com/mustberuss/patentsview/tree/api-redesign/tests/testthat).

## Favorable API Changes
1. The API team has produced a [Swagger UI page](https://search.patentsview.org/swagger-ui/) for the new version of the API!  It has flaws but it's a start and is something I've been lobbying for since the launch of the API. If you aren't familiar with Swagger UI, it's like an online version of Postman, preloaded to use a particular API.  The underlying Swagger/OpenAPI object should comprehensively specify everything that the API is capable of doing, its verbs, inputs, outputs and errors. In other words, its the whole shebang if done properly.  The underlying object can even be imported into Postman or used as input to other opensource projects, as mentioned [below](#swagger-101-1).
2. In the new version of the API all fields are supposed to be quaryable. (Searching by cpc fields on the test server's patents endpoint is currently broken.) From the bottom of [this page](https://patentsview.org/apis/purpose), referring to the new [Swagger UI page](https://search.patentsview.org/swagger-ui/):
> Please refer to the 200 "Response" section for each endpoint for full list of fields available. All the available fields are "queryable." 
3. The API now returns most non strings as their appropriate type, integer or float.  It looks like now casting should only have to create R dates from the string dates that are received.  There are a couple of exceptions that I've opened as bugs, like assignees_at_grant.type from the patents endpoint, it's still a string when it should be an int

## General Upheaval
The villagers may revolt over some of these API changes... &nbsp;&nbsp; &nbsp; Or, the R package will become even more useful and relevant and there will be a parade.
1. The overall paged result set size limit is now 10,000, down from 100,000 (see the [converting-an-existing-script vignette](articles/converting-an-existing-script.html)).
2. The size/per_page maximum on a single request changes from 10,000 to 1,000.   Maximum check and message changed in validate-args.R, it could or should throw a warning when per_page is set above 1,000 and send to API as 1,000.  
3. A lot of fields seem to have gone away, like the governmental interests ones.  Some, but not all, are lists in the Discontinued Fields section of [this page](https://patentsview.org/data-in-action/whats-new-patentsview-july-2021).  The swagger definition (https://search.patentsview.org/static/openapi.json) does not contain  government interest fields, ipc fields, wipo fields, lawyer fields, foreign_priority fields, examiner fields, pct fields, raw inventor fields, coinventor fields, patent_firstnamed fields or patent_num_claims. Assuming all these fields are  going away, though more, unspecified, endpoints are supposed to be coming before the end of 2022.
4. The options matched_subentities_only and include_subentity_total_counts seem to have gone away, but they don't seem to throw errors when requested.  The R package should probably throw an error or warning when set, the behavior of an old script may be different than what the user expects.  From https://patentsview.org/api-v01-information-page  
    > Owing to de-normalized and split API design, sub-entity information is not available directly via each endpoint. As a consequence, "matched_subentity" option parameters are not valid. 
5. Some attributes have new names, like name_last in the nested inventor object returned from the patents endpoint. Now in the fields parameter it would be specified as “inventor.name_last” where formerly it was “inventor_last_name” when using the patents endpoint and name_last when hitting the assignees endpoint (where it comes back at the top level, not within an nested object).
6. There are type changes in some of the attributes, affecting which query methods are used, contains vs test_any etc.  organization (formerly the string assignee_organization) is now a full text field.  I need to confirm this, but it seems that most fields are now full text.  Exceptions seem to be in the patents endpoint.  
7. The uspc and nber fields do not currently come back from the patents endpoint.  Now there is no real point to call the uspc or nber endpoints.  This means there is no way to search for patents using the uspc or nber fields.  This is especially bad for plant, design and ressued patents.  The bulk cpc file only contains assignments for utility patents so plant, design and reissued patents cannot be searched by any classification system.  The ipc and wipo fields seem to have gone away in the new version of the API.
8. The cited_patent and citedby_patent fields no longer can come back from the patents endpoint, instead the new patent_citation endpoint needs to be called.  Similarily, the appcit_app fields come only from the new application_citation endpoint. 

## R Package Design Choices
1. **Changes made in search-pv.R**
   1. An API key is now required.  The [best practices page](https://cran.r-project.org/web/packages/httr/vignettes/api-packages.html) said to create an environmental variable for this. The environmental variable's name,  PATENTSVIEW_API_KEY, is the same one I used in my unadopted fork of the API's python wrapper https://github.com/mustberuss/PatentsView-APIWrapper/tree/api-change-2022
   2. The patentsview API team has made the 13 endpoints singular, patent instead of patents, but the returned data structures remain plural. The R package will continue to use the plural endpoint names as they match the returned data structure and going singular caused casting problems.  It also helps with backward compatibility.
   3. The API's paging attribute names changed from page and per_page to offset and size.  It seemed best to hide this from users.  The R package will still use page and per_page and convert when sending requests to the API. offset = (page-1) * per_page and size = per_page   
   4. Another API change makes the default return size 100, up from 25.  For backward compatibility it seemed like a good idea to leave the default of per_page at 25 in search-pv.R. 
   5. Throttling will be imposed. An http status of 429 "Too many requests" will be returned if more than 45 requests are received per minute.  The Retry-After header will specify the number of seconds to wait before sending the next request.  search-pv sleeps the required seconds (rather than always doing a Sys.sleep(3)) and then resends the same request to hide this change from the user.  It does throw a warning and prints a message which could be changed.
   6. An API change says that POST requests will need to send JSON data (instead of string representation of JSON). A Content-Type: application/json header was added.
   7. It seemed like a good idea to set per_page = 1000 when all_pages == TRUE, minimizing API calls if when the user left it at the default or other size.  I added a slighly wonky way to suppress this, so the paging test case can compare paged and non paged results of a small result set.
   8. The subdomain domain and pattern of the endpoints are changing.  
  existing  
    &emsp; https://api.patentsview.org/cpc_subsections/query?q=  
  new  
     &emsp; https://search.patentsview.org/api/v1/cpc_subsection/?q=  
    9. The ceiling calcuation changed and there are similar changes in process-resp.R as the data comes back in a different order than before.  Now the order is  
    ```error (boolean), count, total_hits, data```  
    while it used to be  
       ```data, count, total_<endpoint>_count```   
   Also note that total_hits comes back from all endpoints, previously there was an endpoint specific return, like total_patent_count
   10. The API now returns a few HATEOAS (Hypermedia as the Engine of Application State) links to retrieve more information, example "inventor": "https://search.patentsview.org/api/v1/inventor/252373/" (Clicking the link will result in a 403 Unauthorized - no API key is sent by a browser) Added [retrieve_linked_data()](reference/retrieve_linked_data.html) to retrieve this data for the user, they'd pass the full url.  One odd thing, in the q:/query and f:/fields paramters the HATEOAS field names end with an _id but it is returned without it, example: patents endpoint query: 

```{r}
library(patentsview)

query <- qry_funs$eq(assignees_at_grant.assignee_id = "35")
example <-search_pv(query=query, fields=c("assignees_at_grant.assignee_id"))

head(example$data$patents$assignees_at_grant, 1)
# [[1]]
#                                            assignee
# 1 https://search.patentsview.org/api/v1/assignee/35/

```
2. **General Choices**
   1. Now there are new, get-only convience endpoints that take a url parameter (what the HATEOAS links hit).  The R package ignores these and just uses the ones that do posts and gets using q,f,s and o parameters, as the original version of the API did.
   2. The online documentation is lagging.  The two new endpoints are documented on https://patentsview.org/data-in-action/whats-new-patentsview-july-2021 but they're missing the Query column (all fields queryable now).  Pages for the other endpoint haven't been changed yet. I created fake pages for data-raw/mbr_fieldsdf.R to consume.  They're on a site I control https://patentsview.historicip.com/api/. In the fake pages, "integer" fields get cast as_is while "int" fields (integers still sent as strings) get cast as.integer. _Update:_ The documentation has been updated but the fields are in an image.  Ex https://patentsview.org/apis/api-endpoints/patentsbeta
   3. As an alternative to scraping the fake pages just mentioned, I created data-raw/yml_extract.R to try to create the csv by parsing the API's Swagger definition.  _Update:_ data-raw/definition_extract.R parses the new json Swagger definition.
   4. Now only 3 of the 13 endpoints are searchable by patent number, which affected a few of the test cases.  I wound up adding R/test-helpers.R to generate a test query per endpoint.  Initially I had it as tests/testthat/helper-queries.R but I thought that caused the ubuntu-20.04 build failure.
   5. I set my API key as asecret in my repo so tests will run and the vignettes can be half rendered etc.  It's retrieved in R-CMD-check.yaml.
   6. I had to add dev = "png" to the knitr::opts_chunk$set in citation-networks.Rmd.orig to get it to render locally.
   7. See the new vignette [converting-an-existing-script.html#additions-to-the-r-package-1](articles/converting-an-existing-script.html#additions-to-the-r-package-1)  I wrote a function that uses the API to determine date ranges for a query returning more than 10,000 rows.  I think it should be added to the R package, but I wasn't sure if it's a good idea..
   8. Because of the singular endpoint name change, I added the following to utils.R to_plural() and to_singular() 

   9. I added an inclusive qry_funs$in_range() to try to make it easier for users to break up queries, due to the decrease in overall request size.
```{r}
   qry_funs$in_range("patent_date"=c("2000-01-07","2000-01-28"))
# {"_and":[{"_gte":{"patent_date":"2000-01-07"}},{"_lte":{"patent_date":"2000-01-28"}}]}>
```

## Try it out for yourself
Steps to try this out locally
1. Request an API key from the patentsview team https://patentsview.org/apis/keyrequest
2. Set the environmental variable PATENTSVIEW_API_KEY value to your key.     
 ex: set PATENTSVIEW_API_KEY=your_key_here (Windows)
3. Install the patentsview package from mustberuss' api-redesign branch ```devtools::install_github("mustberuss/patentsview@api-redesign")```

## Notes
1. https://patentsview.historicip.com/swagger/openapi.json (was https://patentsview.historicip.com/swagger/openapi_v2.yml) can be imported into Postman to give you a nicely loaded collection for the changed API.  You'll just need to set a global variable PVIEW_KEY and set the authorization's value to {{PVIEW_KEY}}.  The patentview team's Swagger definition has reported errors that make importing it problematic.
2. The swagger definition shows a X-Status-Reason-Code in addition to the existing X-Status-Reason. Not sure it matters to or would be useful for the r package.  It doesn't seem to add anything useful.
    ~~~~
    > print(httr::headers(resp)[['X-Status-Reason']])
    [1] "Invaild field: shoe_size"
    > print(httr::headers(resp)[['X-Status-Reason-Code']])
    [1] "ERR_Q"
    ~~~~

3. There  seems to be a change in case sensitivity compared to the original API. The original API would return results for q:{"patent_type":"Design"} while the ElasticSearch version does not.
4. It probably won't not matter to the R package but the slash in the url parameters of /api/v1/uspc_subclass/{uspc_subclass_id}/ and /api/v1/cpc_subgroup/{cpc_subgroup_id}/ need to be changed to colons, ex. 100:1 for 100/1 and A01B1:00 for A01B1/00 and respectively.  This can be seen in the return from the patent endpoint's cpc_current.cpc_subgroup, example  "https://search.patentsview.org/api/v1/cpc_subgroup/G01S7:4865/" (Clicking the link will result in a 403 Unauthorized - no API key is sent by a browser.) It's a HATEOAS style link that conatins a colon instead of a slash.
5. The API seems like it will become less useful.  A lot of use cases will break, like the ones lists on https://docs.ropensci.org/patentsview/articles/examples.html 
6. The API returns null as the value of some fields rather than not returning an attribute.  It might matter to cast-pv-data.R
```
      "assignees_at_grant": [
        {
          "name_first": null,
          "name_last": null,
          "organization": "INTERNATIONAL BUSINESS MACHINES CORPORATION",
        }
      ]
```

## TODOS
1. Some exampes may not be possible due to the API change, like searching inventors by location. (locations endpoint is not on the test server yet.)  There a bogus locations test in test-search-pv.R that should be reworked or removed.
2. (future feature?) Have a search-pv option to automatically retrieve these HATEOAS links if all_pages is FALSE?  Would be closer to the original version of the API if this data was added automatically. (Would need to check the data to see if this would be useful.)
3. (future feature?) Or in cast-pv-data offer an option to strip off the HATEOAS links?  Is this meaningful to the user: "cpc_subgroup": "https://search.patentsview.org/api/v1/cpc_subgroup/G01S7:4811/" (Clicking the link will result in a 403 Unauthorized - no API key is sent by a browser) or do they just want the value G01S7:4811 or even G01S7/4811?
4. Test that what comes back from the API calls matches the spreadsheet and/or their Swagger definition (should be ultimate source of truth). There's a "API Update Table" link to the fields spreadsheet at the very bottom of https://patentsview.org/apis/purpose  test-api-returns.R currently checks that all the groups come back, it could be extended to include all fields.
5. Check if the location specific error checking is still needed (throw_if_loc_error() in process-error.R). The locations endpoint won't return as many fields as before but it's not on the test server yet.  The locations tab in the spreadsheet just mentiomend don't look right.
6. It would be helpful if a test could be written to test the searchability of string/full text fields.  In other words, to we have the types right in the fake documentation?  Confirm that we can do a _text_any on all the fields we think are full text and _contains on all the ones we think are strings. _Update_: test-alpha-types.R does this if either of the Swagger parsers was run.  The API does not throw an error if the wrong set of operators is used, which would have made writing a test case easier.  On a lot of fields it doesn't seem to matter.  These both return results {"_text_phrase":{"patent_title":"world"}} {"_contains":{"patent_title":"world"}}  The only field that seems to matter is patent_abstract.
7. We probably should remove printing of the url to stderr in search-pv but it's been so darn useful durning development
8. (future feature?) Add a method that would iterate through the data ranges generated by safe_date_ranges (in the [converting-an-existing-script vignette](articles/converting-an-existing-script.html)) and return the concatenated results.  Or just wrap the whole thing, user passes in the query, we call safe_date_ranges and give them back the combined data set.
9. We probably don't need this in process-error.R though the location endpoint is not on the test server yet

        "Your request resulted in a 500 error, likely because you have ",
        "requested too many fields in your request (the locations endpoint ",
        "currently has restrictions on the number of fields/groups you can ",
        "request). Try slimming down your field list and trying again."
10. If possible, suppress api-redesign.md from producing docs/api-redesign.html
11. Clean up utils.R I hadn't noticed until writting test-utils.R that only to_singular is used by the package.  to_plural() isn't used, it's a hold over from a failed attempt at making the endpoints singular.
12. A tech note is probably in order to announce the new version of the package.  There's an unlinked [vignette](articles/ropensci_tech_note.html) as a potential starting point
13. The original [rOpenSci blog post](https://ropensci.org/blog/2017/09/19/patentsview/) is also reworked as a new, unlinked [vignette](articles/ropensci_blog_post.html)  It needs some work, the ggplot stopped working
14. README.Rmd's link should be changed if there is a new post or tech note.
15. Follow tidyverse style
16. Add an issue template saying that people shouldn't share their api key (as suggested on the 
[best practices](https://devguide.ropensci.org/package-development-security-best-practices.html#secrets-in-packages-and-development) page)
17. Add a CONTRIBUTING.md (also mentioned on that same best practices page) have info on setting up an API key in a forked repo etc.  Maybe include rendering vignettes locally.

## Questions
1. Should we bump the version number to 0.4.0 or 1.0.0?  The API key alone quarantees that the package won't be backward compatible.
2. Are there any other fields changing type?  (like assignee organization becoming a full text field, formerly it had been a string)
3. Are there more fields (like the government interests) that went away?
4. How to handle the release?  For a while both versions of the API are supposed to be around.  Have people install the updated R package from a branch on ropensci/patentsview?  When the original version of the API is retired do a CRAN build?  The r-universe would be a possibility see https://mustberuss.r-universe.dev/ui#package:patentsview
5. Possible idea: ask the patentsview people if they could create a separate category for the R package in their forum?  Guessing people may need help with their conversions!
6. Add the <a href="articles/converting-an-existing-script.html#additions-to-the-r-package-1">date range finder</a> to the package?  
7. Refactor the code and tests so the x.R and test-x.R pattern isn't broken?

## Swagger 101
Open my version of the Swagger object for the new version of the API in the [Swagger Editor](https://editor.swagger.io/?url=https://patentsview.historicip.com/swagger/openapi.json) then "Generate Client-r" or one of html ones. Pretty powerful huh? There are also numerous tools [here](https://openapi.tools/) that will do fun things with a Swagger object as input but nothing seems to be R based. I did find this that looks promising on [CRAN](https://cran.r-project.org/web/packages/rapiclient/rapiclient.pdf) or [github](https://github.com/bergant/rapiclient).  One gotcha, it expects the input file to be the older Swagger 2.0 format.  It works but throws a warning. It looks like what we really need is an R port of this python project https://github.com/cyprieng/swagger-parser!  Oops, that's reading Swagger 2 files.  All that to say that there isn't something to generate fieldsdf.csv from the Swagger definition, we may have to do some heavy lifting ourselves.

## Carried Over
Observations from the original version of the R package that are still true in this version.
1. Paging isn't quite right, it repeats the first request if all_pages = TRUE, slight improvement opportunity.
2. The search field has to be explicitly specified in the f: parameter when a sort field is specified.  The API does have default fields that could be sorted on, without specifying in the f: parameter.  A script could  make API calls to see what the default fields are.   Probably isn't worth the effort, and it's not necessarily an improvement! (it's just an observation)
3. The screenshot of the highcharter plot in the top-assignees vignette is incomplete.  The png only shows a little bit of IBM's yearly patents, not the full awesomeness of highcharter's plot.  The line graph in the roensci blog looks fine, how was that one done?
&nbsp;
&nbsp;
