
library(rapiclient)
library(stringr)

# Here we generate generated_fieldsdf by reading the API's Swagger UI object!
# The API team's one has errors so we'll use my corrected one for now.

# We don't be able to make API calls using rapiclient with the replacement, but we 
# can use its method to read the API's swagger file.  It'll throw  a warning, but it's ok:  
# "Missing Swagger Specification version".  (It's expecting a Swagger 2 object
# but the patentsview API team more correctly created a OpenAPI/Swagger 3 object)

# Maybe use a different library?  We're abusing rapiclient, only using it 
# to read the Swagger UI object. It would be nice if there was a package that
# resolved the reference links for us.  I couldn't find another R package to use though.

# OpenAPI/Swagger 3 highlights

# 1. The API specification can be yml or json (about all that we use rapiclient for)

# 2. Dates have a type of string with a format of date

# ..$ first_seen_date  :List of 3
# .. ..$ type   : chr "string"
# .. ..$ format : chr "date"
# .. ..$ example: chr "1988-12-06"

# 3. Floats are specified as number

# $ lastknown_latitude :List of 2
#  ..$ type   : chr "number"
#  ..$ example: num 40.7
# $ lastknown_longitude:List of 2
#  ..$ type   : chr "number"
#  ..$ example: num -73.9

# 4. Strings and integers are as expected.  Caveat with this API, I don't think we can tell
# the difference between a string and a full text field (which matters to which operators are used).
# We might need to assume full text (more are full text now) and have a hardcoded list of exclusions

# $ nber_subcategory_title          :List of 3
#  ..$ type     : chr "string"
#  ..$ maxLength: int 1024
#  ..$ example  : chr "Agriculture,Food,Textiles"
# $ nber_subcategory_num_patents    :List of 2
#  ..$ type   : chr "integer"
#  ..$ example: int 21160

# 5. Fields can nested objects or arrays of objects.  Returned from the patents endpoint:

# $ assignees_at_grant                                          :List of 2
#  ..$ type : chr "array"
#  ..$ items:List of 1
#  .. ..$ $ref: chr "#/components/schemas/AssigneeNested"
# $ inventors_at_grant                                          :List of 2
#  ..$ type : chr "array"
#  ..$ items:List of 1
#  .. ..$ $ref: chr "#/components/schemas/InventorNested"
# $ cpc_current                                                 :List of 2
#  ..$ type : chr "array"
#  ..$ items:List of 1
#  .. ..$ $ref: chr "#/components/schemas/CPCSubGroupNested"

# use rapiclient's method to read the API's definition
pview_api <- get_api(url = "https://patentsview.historicip.com/swagger/openapi_v2.yml")

# Not that we'll actually make API calls, but adding these headers would allow us to do that
# (it would work if we use the API team's swagger object, see
# https://github.com/bergant/rapiclient/issues/17#issuecomment-1193196626)

pview_ops <- get_operations(pview_api,  handle_response = content_or_stop, 
   .headers = c("X-Api-Key" = Sys.getenv("PATENTSVIEW_API_KEY"), 
                "User-Agent" = "https://github.com/bergant/rapiclient"))

client <- list(operations = pview_ops, schemas = get_schemas(pview_api),
   paths = pview_api$paths)

endpoints <- names(client$paths)
#  [1] "/api/v1/patent/"                  we want this one, it uses q: s: f: o:
#  [2] "/api/v1/patent/{patent_number}/"  not this one, it uses url parameters (get only)

# We want to exclude paths with just a url parameter, like [2]. 
# They're get only with no f: q: s: or o: parameters
endpoints <- endpoints[!grepl("\\{", endpoints)]

# ultimately, we want these columns in the csv
# "endpoint","field","data_type","can_query","group","common_name","description","plain_name"

# Maybe use examples in the Swagger definition for the csv description fielld?
# "field" would be group.field in a nested object (where group != endpoint)
# plain_name is always the field without a group name

# Would want to iterate over endpoints looking for the returned structure's reference
# We'd need this to find the nested array that gets returned 
# client$paths["/api/v1/assignee/"]$`/api/v1/assignee/`$post$responses$`200`$content$`application/json`$schema$`$ref`
# [1] "#/components/schemas/AssigneeSuccessResponse"

responses <- 
lapply(endpoints, function(y, obj) {
   obj[y][1][[y]]$get$responses$`200`$content$`application/json`$schema$`$ref`
}, obj=client$paths)

entities <- str_extract(responses, "(\\w+)(SuccessResponse)")  
entities <- sub("SuccessResponse","", entities)

# Slight cheat here, instead of resolving the actual entities, we're 
# assuming we can remove "SuccessResponse" to get to the nested object.
# It currently works but could break if the API team doesn't always follow this rule.

# ex resolve NBERSubCategorySuccessResponse or just assume NBERSubCategory?
# NBERSubCategorySuccessResponse is the error_boolean, count in this request, 
# total_hits and array of NBERSubCategory (what we actually want)

# We'll need a lookup for the endpoint names from the entities in a bit, 
# tolower works on some, like Patents to patents but not all  
# Ex: endpoint for entity USApplicationCitation is  application_citations

enames <- str_extract(endpoints, "(\\w+)/$")  
enames <- sub("/","", enames)

# last piece of monkey buisness, we need the enames to be plural
enames <- sapply(enames, function(ename) {
      if(endsWith(ename,'y'))
         plural <- sub('y$', 'ies', ename )
      else if(endsWith(ename ,'s'))
         plural <- paste0(ename,"es")
      else
         plural <- paste0(ename,"s")
},USE.NAMES = FALSE)

# enames and entities are in the same order
lookup = enames;
names(lookup) <- entities;

csv_data <- 
   lapply(entities, function(entity) {

   outer <-
      lapply(names(pview_api$components$schemas[[entity]]$properties), function(x, obj) {

         plural_endpoint <- lookup[[entity]]
         group <- plural_endpoint 

         # see if this is a nested object - fortunately the patentsview API only nests
         # one level
         if(!is.null(obj[[x]]$items$`$ref`)) {

             # $assignee_years$items
             # $assignee_years$items$`$ref`
             # [1] "#/components/schemas/YearlyPatents"

             group <- x  # attribute name becomes the group name and the nested fields would be x.z
             # example "#/components/schemas/YearlyPatents"
             nested <-  str_extract( obj[[x]]$items$`$ref`, "(\\w+)$")

             # we want to lapply here ...
             # where x would become the group in the lapply and the fields would be nested
             # as x.nestd_fields

             inner = lapply(names(pview_api$components$schemas[[nested]]$properties), function(z, subgroup, obj) {
                # do the type thingie
                type = ifelse(obj[[z]]$type == "number", "float", obj[[z]]$type)

                # look for type string and format "date" or at least the date part!
               if(!is.null(obj[[z]]$format) && obj[[z]]$format == "date")
                  type = "date";

               data.frame(endpoint=plural_endpoint, 
                  field=paste0(subgroup,'.',z), data_type=type, 
                  can_query='Y', group=subgroup, common_name="common_name",
                  description="description", plain_name=z)

             }, subgroup=x, obj=pview_api$components$schemas[[nested]]$properties)
             do.call(rbind, inner)
         }
         else
         {
            # want "number" written as "float"
            # write example as the description?
            type = ifelse(obj[[x]]$type == "number", "float", obj[[x]]$type)

            # look for type string and format "date" or at least the date part!
            if(!is.null(obj[[x]]$format) && obj[[x]]$format == "date")
               type = "date";

            # csv headers:
            # "endpoint","field","data_type","can_query","group","common_name","description","plain_name"

            data.frame(endpoint=plural_endpoint, field=x, data_type=type, 
               can_query='Y', group=group, common_name="common_name",
               description="description", plain_name=x)

          }

      }, obj=pview_api$components$schemas[[entity]]$properties)
      do.call(rbind, outer)
})

csv_data <- do.call(rbind, csv_data)

write.csv(csv_data, "data-raw/generated_fieldsdf.csv", row.names = FALSE)

