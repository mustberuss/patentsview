# we could half render a single file  

half_render_one <- function() {
  # I want the figures directory that's created when knitr renders the docs to
  # be within the vignettes dir, hence the directory change below
  cur_dir <- getwd()
  on.exit(setwd(cur_dir))
  setwd("vignettes")

  #source_files <- list.files(pattern = "\\.Rmd\\.orig$")
  #source_files <- c("converting-an-existing-script.Rmd.orig")
  #source_files <- c("test.Rmd.orig")
  source_files <- c("top-assignees.Rmd.orig")

  for (file in source_files) {
    print(paste("Knitting", file))
    knitr::knit(file, gsub("\\.orig$", "", file))
  }
}


