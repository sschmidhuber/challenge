#! /usr/bin/env Rscript

# app.R

# This script starts the MathChallenge server


source("R/packages.R")
app <- plumb("R/service.R")
app$run(port = 8000)
