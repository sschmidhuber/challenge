#! /usr/bin/env Rscript

# app.R

# This script starts the MathChallenge server

setwd("/home/stefan/R/MathChallenge/")
source("r/packages.R")
app <- plumb("r/mathChallenge.R")
app$run()
