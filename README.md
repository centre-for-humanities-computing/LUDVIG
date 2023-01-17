# LUDVIG
Deliverables for the LUDVIG project - an analysis of the plays of Ludvig Holberg

## Needed R packages

The following R packages must be installed by `install.packages(<package>)`.

```
DT
colorspace
dplyr
fs
ggplot2
ggraph
ggthemes
here
igraph
knitr
ndjson
purrr
readr
readxl
tidygraph
tidytext
tidyverse
tvthemes
viridis
xml2
xslt
```

The list is based on the output from this expression:

```
find . -name '*.Rmd' -exec egrep '^library\(' {} \;|sed 's/library(//;s/)//'| sort | uniq > used_packages
```