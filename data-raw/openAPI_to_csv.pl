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

my $data = get('https://search.patentsview.org/static/openapi.json');
open my $url_fh, '<', \$data or die $!;

$out_file = "fieldsdf.csv";
open(OUT, ">$out_file") || die ("couldn't write to $out_file");

# output headers
print OUT << "HEADERS";
"endpoint","field","data_type","group","common_name"
HEADERS

while($line = <$url_fh>)
{
   # figure out which endpoints are nested, ignoring the hateoas ones
   if($line =~ m|/api/v1/(.*)/"| && $line !~ /}/)
   {
      $endpoint = $1;
      
      # aarg, we need to make it plural
      if($endpoint =~ /s$/)
      {
         $endpoint .= "es";
      }
      else
      {
         $endpoint .= "s";
      }

      $endpoint = "wipo" if($endpoint eq "wipos");  # api returned entity is singular

      $unnested = $endpoint;
      $unnested = $' if($unnested =~ m|/|);
      $endpoints{$unnested} = $endpoint;
   }

   last if($line =~ /"components":/);
}

# another OpenAPI mistake - the returned entity is other_references but the endpoint is otherreference
$endpoints{'other_references'} = $endpoints{'otherreferences'} if(!exists $endpoints{'other_references'});

while($line = <$url_fh>)
{
   if($line =~ /"(\w+)SuccessResponse"/)
   {
      $entity = lc($1);
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
                           $common = $field;
                           $field = "$group.$field" if($group ne "");

                           # keep track of the types, if a new type shows up cast-pv-data will need code for it
                           $types{$type}++;

                           $output_entity = $endpoints{$entity};  # need to nest where needed

                           if(!exists $endpoints{$entity})
                           {
                              print "trouble with entity $entity\n";
                              $endpoints{$entity} = "trouble";
                              <STDIN>;
                           }

                           # temp test:
                           # use the endpoint when the group is not set (non nested attribute)
                           $ggroup = $group eq "" ? $output_entity : $group;

                           $output = << "DAT";
"$output_entity","$field","$type","$ggroup","$common"
DAT
                           $save{$output_entity}{$field} = $output;

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

close (DAT);
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


