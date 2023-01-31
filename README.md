# LUDVIG
Deliverables for the LUDVIG project - an analysis of the plays of Ludvig Holberg.

This is an RStudio project and you need to load the project by either using the "Open Project" menu in RStudio or double kllik on the `LUDGIV.Rproj` project file.



## Needed R packages

When the project is loaded, you can install all package dependencies by running the `setup.R` file either by opening the `setup.R` file in RStudio and selecting Run or in the R console executing

```
> source("setup.R")
```

That script installes these packages:

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
