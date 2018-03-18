#! /usr/bin/env Rscript

# app.R

# This script starts the MathChallenge server


source("r/packages.R")
app <- plumb("r/mathChallenge.R")
app$run(port = 8000)
