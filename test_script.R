#! /usr/bin/env Rscript

library(httr)
library(stringr)
library(jsonlite)
library(crayon)
library(readr)

args <- commandArgs(trailingOnly = TRUE)
server <- FALSE # true if the server was started
tests <- c(executed = 0, failed = 0)

runTest <- function(url, query, resPattern, logMessage = "", method = "GET", returnRes = FALSE) {
  if (method == "GET") {
    res <- GET(url = url)
  } else if (method == "POST") {
    res <- POST(url = url, query = query, encode = "json")
  } else {
    stop(paste("method:", method, "not supported"))
  }
  
  if (str_length(logMessage) == 0) {
    cat(bold("\nTest", tests["executed"] + 1,"\n", sep = ""))
  } else {
    cat("\n", bold(logMessage, " (Test ", tests["executed"] + 1, ")\n", sep = ""), sep = "")
  }
  
  tests["executed"] <<- tests["executed"] + 1
  if (str_detect(res, resPattern)) {
    cat(green$bold("SUCCESS"), toJSON(content(res), auto_unbox = TRUE), "\n")
  } else {
    cat(red$bold("FAILED"), toJSON(content(res), auto_unbox = TRUE), "\n")
    cat("expected response pattern:", resPattern, "\n")
    tests["failed"] <<- tests["failed"] + 1
  }
  
  if (returnRes) content(res)
}

system(command = "clear")
if (length(args) != 0) {
  if (str_detect(args, pattern = "start-server")) {
    cat("\nstart server...\n")
    system(command = "r/app.R &>test.log &")
    server <- TRUE
    Sys.sleep(1)
  }
}

## tests

runTest(logMessage = "try to sign in with unregistered user",
       method = "POST",
       url = "http://127.0.0.1:8000/signIn",
       query = list(password="password", name="alice"),
       resPattern = '\\{\\"error\\":\\"unknown user\\"\\}')

alice <- runTest(logMessage = "sign up user alice:password",
        method = "POST",
        url = "http://127.0.0.1:8000/signUp",
        query = list(name="alice", country="Germany", password="password"),
        resPattern = '\\{\\"player\\":\\".*\\"\\}',
        returnRes = TRUE)["player"]

runTest(logMessage = "try to sign up with invalid too short password",
        method = "POST",
        url = "http://127.0.0.1:8000/signUp",
        query = list(name="bob", country="Germany", password="pw"),
        resPattern = '\\{\\"error\\":\\"name or password invalid\\"\\}')

runTest(logMessage = "try to sign up with username already in use",
        method = "POST",
        url = "http://127.0.0.1:8000/signUp",
        query = list(name="alice", country="Germany", password="12345"),
        resPattern = '\\{\\"error\\":\\"name already assigned to another player\\"\\}')

runTest(logMessage = "try to sign up with username only differs by upper case letter",
        method = "POST",
        url = "http://127.0.0.1:8000/signUp",
        query = list(name="Alice", country="Germany", password="12345"),
        resPattern = '\\{\\"error\\":\\"name already assigned to another player\\"\\}')

bob <- runTest(logMessage = "try to sign up without parameter country",
        method = "POST",
        url = "http://127.0.0.1:8000/signUp",
        query = list(name="Bob", password="12345"),
        resPattern = '\\{\\"player\\":\\".*\\"\\}',
        returnRes = TRUE)

runTest(logMessage = "sign up user Bob:12345",
        method = "POST",
        url = "http://127.0.0.1:8000/signIn",
        query = list(name="Bob", password="12345"),
        resPattern = paste0('\\{\\"player\\":\\"', bob, '\\"\\}'))

runTest(logMessage = "try to sign in with invalid password",
        method = "POST",
        url = "http://127.0.0.1:8000/signIn",
        query = list(name="alice", password="12345"),
        resPattern = '\\{\\"error\\":\\"invalid password\\"\\}')

runTest(logMessage = "sign up user alice:password",
        method = "POST",
        url = "http://127.0.0.1:8000/signIn",
        query = list(name="alice", password="password"),
        resPattern = paste0('\\{\\"player\\":\\"', alice, '\\"\\}'))

question <- runTest(logMessage = "start new game for player alice",
        method = "GET",
        url = paste0("http://127.0.0.1:8000/newGame/", alice),
        resPattern = paste0('\\{\\"question\\":\\".*\\"\\}'),
        returnRes = TRUE)["question"]


cat("\nTests executed:\t", green$bold(tests["executed"]), "\nTests failed:\t", red$bold(tests["failed"]), "\n\n")

# show logs and kill server
if (server) {
  testLog <- file(description = "test.log")
  cat(read_file(testLog))
  file.remove("test.log")
  cat("\nshutdown server...\n")
  system(command = "pkill R")
}