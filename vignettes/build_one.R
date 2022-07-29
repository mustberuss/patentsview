# I found it handly to half render a single file during development.
# I'd edit a Rmd.orig, half render it with this script's half_render_one()
# and then do a pkgdown::build_articles() to see what the html looked like. 
# Much faster than half rendering everything with build.R and 
# doing a pkgdown::build_site()
# rscript -e "source('vignettes/build_one.R'); half_render_one()"

half_render_one <- function() {
  # I want the figures directory that's created when knitr renders the docs to
  # be within the vignettes dir, hence the directory change below
  cur_dir <- getwd()
  on.exit(setwd(cur_dir))
  setwd("vignettes")

  #source_files <- list.files(pattern = "\\.Rmd\\.orig$")
  #source_files <- c("converting-an-existing-script.Rmd.orig")
  #source_files <- c("test.Rmd.orig")
  #source_files <- c("top-assignees.Rmd.orig")
  #source_files <- c("ropensci_blog.Rmd.orig")
  #source_files <- c("getting-started.Rmd.orig")
  source_files <- c("api-changes.Rmd.orig")

  for (file in source_files) {
    print(paste("Knitting", file))
    knitr::knit(file, gsub("\\.orig$", "", file))
  }
}


