# During developent I found it handy to half render only some Rmd.orig's 
# I'd edit Rmd.orig's, half render them with this script's half_render_some()
# and then do a pkgdown::build_articles() to see what the html looked like locally. 
# Much faster than half rendering everything with build.R and 
# doing a pkgdown::build_site()
# rscript -e "source('vignettes/build_some.R'); half_render_some()"

half_render_some <- function() {
  # I want the figures directory that's created when knitr renders the docs to
  # be within the vignettes dir, hence the directory change below
  cur_dir <- getwd()
  on.exit(setwd(cur_dir))
  setwd("vignettes")

  args<-commandArgs(TRUE)

  for (source_file in args) {
     destination_file = gsub("\\.orig$", "", source_file)
     print(paste("Knitting", source_file))
     knitr::knit(source_file, destination_file)
   }
}


