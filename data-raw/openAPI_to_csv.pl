#!/usr/local/bin/perl

use LWP::Simple;

# Cheating a bit here, the OpenAPI specification changed a bit more than
# Mr dyplr and I could handle.  Here's a perl script to convert to a csv file
# to_rda.R will read the csv file and create the rda files

# super funky stuff going on in here:  there are fields in the OpenAPI spec that
# throw errors when used in the fields parameter.  Some are straight up fields,
# others seem to be hateoas related, where there are two overloaded-like
# attributes cpc_class (hateoas link) and cpc_class_id the former throws
# an error when included in the fields parameter.  Not positive if this is
# a bug or a feature, ie whether the code should remain or not.

# Now there are two rel_app_texts one is publication/rel_app_text/ and the other is
# patent/rel_app_text/ the messes up putting the last part of the paths
# in a hashmap

# latest weirdness: patents endpoint request inventors.inventor_id and
# assignees.assignee_id to receive inventors.inventor and assignees.assignee,
# their respective HATEOAS links

my $data = get('https://search.patentsview.org/static/openapi.json');
open my $url_fh, '<', \$data or die $!;

$out_file = "fieldsdf.csv";
open(OUT, ">$out_file") || die ("couldn't write to $out_file");

# output headers
print OUT << "HEADERS";
"endpoint","field","data_type","group","common_name"
HEADERS

# now a handful of endpoints besides just wipo return singular entities
# plus an oddity
%singular = ( 
   "brf_sum_texts" => "brf_sum_text",
   "claims" => "claim",
   "detail_desc_texts" => "detail_desc_text",
   "draw_desc_texts" => "draw_desc_text",
   "wipo" => "wipo",
   "patent/otherreference" => "other_references"  # endpoint is currently broken
);

while($line = <$url_fh>)
{
   # figure out which endpoints are nested, ignoring the hateoas ones
   if($line =~ m|/api/v1/(.*)/"| && $line !~ /}/)
   {
      $endpoint = $1;
      
      $unnested = $endpoint;
      $unnested = $' if($unnested =~ m|/|);

      # now there are two rel_app_texts endpoints, one under patents and one
      # under publications.  the publications one has an entity of 
      # rel_app_text_publications so we'll set that as unnested to avoid a collision
      if($endpoint eq "publication/rel_app_texts")
      {
         $returned_entity = "rel_app_text_publications"; 
         $unnested = $returned_entity; # avoids "trouble" below
      }

      # now a handful of endpoints besides just wipo return singular entities
      elsif(exists $singular{$endpoint})
      {
         $returned_entity = $singular{$endpoint};
         $unnested = $returned_entity;
      }
      elsif($unnested =~ /s$/)
      {
         $returned_entity = "${unnested}es";
      }
      else
      {
         $returned_entity = "${unnested}s";
      }

      print "$endpoint!$unnested!$returned_entity\n";

      $endpoints{$unnested} = $endpoint;

      # now we want to find the 200 response's entity reference
      # "$ref": "#/components/schemas/BrfSumTextSuccessResponse"
      while($line = <$url_fh>)
      {
         if($line =~ m|/(\w+)SuccessResponse"|)
         {
            $successResponse{$1} = $endpoint;
            last;
         }
      }
   }

   last if($line =~ /"components":/);
}

print "\n";

foreach $key (sort keys %endpoints)
{
   print "$key $endpoints{$key}\n";
}

print "successResponses:\n";
foreach $key (sort keys %successResponse)
{
   print "$key!$successResponse{$key}!\n";
}


# another OpenAPI mistake - the returned entity is other_references but the endpoint is otherreference
$endpoints{'other_references'} = $endpoints{'otherreferences'} if(!exists $endpoints{'other_references'});

while($line = <$url_fh>)
{
   if($line =~ /"((\w+)SuccessResponse)"/)
   {
      $entity = lc($1);
      $response = $2;

      next if($entity eq "api");  # don't want "APISuccessResponse"

      $line = <$url_fh>;

      $g_count = -1;

      # find first "properties" 
      while($line = <$url_fh>)
      {
         if($line =~ /"properties":/)
         {
            $line = <$url_fh>;
            if($line =~ /"(\w+)"/)
            {
               $entity = $1;
               $entity = "ipcs" if($entity eq "ipcr");  # mistake in OpenAPI spec

               $entities{$entity}++;

               $count = 0;
               $count++ if($line =~ /{/);
               $group = "";

               while($count != 0)
               {
                  $line = <$url_fh>;
                  $count++ if($line =~ /{/);
                  $count-- if($line =~ /}/);
                  $something = $1 if($line =~ /"(\w+)":/);

                  if($count == $g_count)
                  {
                     $group = "";
                     $g_count = -1;
                  }

                  if($line =~ /"type":\s*"array"/)
                  {
                     $group = $previous;
                  #  print "   group is $group\n";
                     $g_count = $count - 1;
                  }
                  else
                  {
                     if($line !~ /"example":|"items":|"properties":/) {
                        if($line =~ /"type":/)
                        {
                           $type = $1 if($line =~ /"type":\s*"(\w+)"/);
                           $type = "date" if($field =~ /_date$/);
                           $type = "integer" if($type eq "number");
                           $type = "number" if($field =~ /latitude|longitude/);  # strings in the openapi definition
                           $type = "int" if($field eq "assignee_type");  # string that needs to be cast as integers

                           # mistake in 4/3/24 on applicant_authority 
                           $type = "string" if($type eq "keyword");
                           $common = $field;
                           $field = "$group.$field" if($group ne "");

                           # keep track of the types, if a new type shows up cast-pv-data will need code for it
                           $types{$type}++;

                           # was $output_entity = $endpoints{$entity};  # need to nest where needed
                           $output_endpoint = $successResponse{$response};

                           if(!exists $successResponse{$response})
                           {
                              print "trouble with entity response $response!\n";
                              $endpoints{$entity} = "trouble";
                              <STDIN>;
                           }

                           # temp test:
                           # use the endpoint when the group is not set (non nested attribute)
                           # was $ggroup = $group eq "" ? $output_entity : $group;
                           $ggroup = $group eq "" ? $output_endpoint : $group;

                           # api weirdness, the entity for publication/rel_app_texts
                           # is publication/rel_app_text_applications
                           if($ggroup eq "publication/rel_app_texts") {
                              $ggroup = "publication/rel_app_text_publications";
                           }

                           # latest weirdness mentioned at the top
                           if("assignees.assignee" eq $field || 
                              "inventors.inventor" eq $field)
                           {
                              $field .= "_id";
                              $common .= "_id";
                           }

                           $output = << "DAT";
"$output_endpoint","$field","$type","$ggroup","$common"
DAT
                          # was $save{$output_entity}{$field} = $output;
                          $save{$output_endpoint}{$field} = $output;

                        }
                        else
                        {
                           $field = $something;
                        }

                     #  print "$count $line";
                     }
                  }
                  $previous = $something;
               }
               last;
            }
         }
      }
   }
}

# first remove the hateoas overloads
foreach my $endpoint ( keys %save ) {
    for my $attribute ( keys $save{$endpoint}->%* ) {
       if($attribute =~ /_id$/) {
          $hateoas = $`;  # before the match
          if(exists $save{$endpoint}{$hateoas}) {
             # print "deleting $hateoas from $endpoint\n";
             delete($save{$endpoint}{$hateoas});
          }
       }
    }
}

# iterate through $save again writing to the output file
# sort for reproducibility- we don't want a git diff if the output didn't change
foreach my $endpoint (sort keys %save ) {
    for my $attribute (sort keys $save{$endpoint}->%* ) {
           print OUT $save{$endpoint}{$attribute};
    }
}

close ($url_fh);
close (OUT);

# warn if there's a type we don't know about- would need to add 
# code to cast-pv-data.R
%known_types = ( "boolean" => 1, "date" => 1, "int" => 1, 
                 "integer" => 1, "number" => 1, "string" => 1);

print "types found:\n";
@warn = ();
$total = 0;

foreach $key (sort keys %types)
{
   print "($types{$key})\t$key\n";
   $total += $types{$key};
   push(@warn, "new data type $key found\n") if(!exists $known_types{$key});
}

print "\n$total\ttotal fields\n\n";

for $w (@warn)
{
   print $w;
}


