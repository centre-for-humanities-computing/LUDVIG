# This function cleans the Mascarade_mod.page file by transforming
# a single use of double quotes to single quotes
# The function takes one argument:
#   filename: the full path to the Mascarade_mod.page file
# The function changes the file in the process
clean_Mascarade <- function(filename) {
  file_content <- readLines(filename)
  transformed_content <- gsub( "\"nok en kop kaffe\"", "\'nok en kop kaffe\'", file_content)
  transformed_content <- gsub( "d\"Espagne", "d\'Espagne", transformed_content)
  writeLines(transformed_content, con=filename, sep="\n")
}

# This function takes on argument:
#   folder: the path to a folder containing one or more
#           TEI files with the .page extension
#
# The function creates JSONL versions of these files, and
# stores them in the same folder
# The function assumes the existence of two XSLT scripts present
# in the src folder of the project.
convert_TEI_to_JSONL <- function(folder) {
  # Load the XSL tranformations
  stripSeqXSL <- read_xml(here("src","stripSeq.xslt"))
  # TODO: add a column with all the titles
  tei2jsonlXSL <- read_xml(here("src","tei2jsonl.xslt"))
  
  # convert all .page files in the "test-data/tei" directory to JSONL files
  dir_walk(
    folder,
    function(filename) if (str_ends(filename,".page")) filename %>%
      read_xml() %>%
      xml_xslt(stripSeqXSL) %>%
      xml_xslt(tei2jsonlXSL) %>%
      write_file(fs::path(fs::path_ext_remove(filename), ext="jsonl")))
}

# This function reads all JSONL files in a folder into
# a tibble, adding an index numbering each scene within each play
#
# The ndjson::stream_in() function does not work on Microsoft Windows,
# as files are read using Latin-1, even though they are UTF-8.
# read_plays_jsonl <- function(folder) {
#   dir_ls(here(folder), glob = "*.jsonl") %>%
#     map_dfr(function(fn) ndjson::stream_in(fn) %>% tibble() %>% mutate(speaker = stringr::str_remove(speaker, " \\(")) %>% add_column(filename = basename(fn)))
# }
#
# Instead we use jsonlite::stream_in() that dosen't seem to have the same problem.
# This function has another challenge in that it fails to read quoted strings 
# within JSON strings. It's actually weird, that ndjson::stream_in didn't also 
# fail on this!
#
# To mitigate this error, ONE file must be corrected by hand in either the 
# Mascarade.page file before convert_TEI_to_JSONL or the Mascarade_mod.jsonl 
# after the conversion.
#
# The following sed command will do for both file types:
# sed "s/\"nok en kop kaffe\"/\'nok en kop kaffe\'/"
# 
# or use the following function defined in this file:

#R statements (as can be seen in deliverables/read-plays.Rmd)
# 
# ```{r}
# mascarade_file <- here(my_dir,"Mascarade_mod.page")
# file_content <- readLines(mascarade_file)
# transformed_content <- gsub( "\"", "\'", file_content)
# writeLines(transformed_content, con=mascarade_file, sep="\n")
# ```

read_plays_jsonl <- function(folder) {
  dir_ls(here(folder), glob = "*.jsonl") %>%
    map_dfr(
      function(fn) jsonlite::stream_in(file(fn), verbose = FALSE) %>% 
        tibble() %>%
        mutate(speaker = stringr::str_remove(speaker, " \\(")) %>%
        add_column(filename = basename(fn)))
}

read_play_jsonl <- function(file) {
  file %>% 
    map_dfr(
      function(fn) jsonlite::stream_in(file(fn), verbose = FALSE) %>% 
        tibble() %>%
        mutate(speaker = stringr::str_remove(speaker, " \\(")) %>% 
        add_column(filename = substr(file, 
                                     start = unlist(lapply(str_locate_all(file, '/'), max))+1, 
                                     stop = str_length(file)), .before = 0)
    )
}

# Below is the old implementation
# This function reads the JSONL file specified as input into
# a tibble, adding an index numbering each scene within each play
# and adds a filename coloumn
# read_play_jsonl <- function(file) {
#   file %>% 
#     map_dfr(
#       ~ndjson::stream_in(.) %>%
#         tibble() %>%
#         mutate(speaker = stringr::str_remove(speaker, " \\(")) %>% 
#         add_column(filename = substr(file, 
#                                      start = unlist(lapply(str_locate_all(file, '/'), max))+1, 
#                                      stop = str_length(file)), .before = 0)
#     )
# }

render_all_deliverables <- function() {
  setwd(here("deliverables"))
  purrr::map(list.files(pattern = "\\.Rmd$"), ~rmarkdown::render(.x))
  setwd(here())
}