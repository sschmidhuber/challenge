#! /usr/bin/env Rscript

library(httr)
library(stringr)
library(jsonlite)
library(crayon)
library(readr)
library(subprocess)
library(uuid)

args <- commandArgs(trailingOnly = TRUE)
server <- NULL
tests <- c(executed = 0, failed = 0)

runTest <- function(url, query = "", res_pattern, log_msg = "", method = "GET", return_res = FALSE) {
  if (method == "GET") {
    res <- GET(url = url)
  } else if (method == "POST") {
    res <- POST(url = url, query = query, encode = "json")
  } else {
    stop(paste("method:", method, "not supported"))
  }
  
  if (str_length(log_msg) == 0) {
    cat(bold("\n-- Test", tests["executed"] + 1," --\n", sep = ""))
  } else {
    cat("\n", bold("-- ", log_msg, " (Test ", tests["executed"] + 1, ") --\n", sep = ""), sep = "")
  }
  
  tests["executed"] <<- tests["executed"] + 1
  if (str_detect(res, res_pattern)) {
    cat(green$bold("SUCCESS"), toJSON(suppressMessages(content(res)), auto_unbox = TRUE), "\n")
  } else {
    cat(red$bold("FAILED"), toJSON(content(res), auto_unbox = TRUE), "\n")
    cat("expected response pattern:", res_pattern, "\n")
    tests["failed"] <<- tests["failed"] + 1
  }
  
  if (return_res) suppressMessages(content(res))
}

system(command = "clear")
if (length(args) != 0) {
  if (str_detect(args, pattern = "start-server")) {
    cat("\nstart server...\n")
    server <- spawn_process(command = "R/app.R", arguments = c("--log-to-file"))
    Sys.sleep(1)
  }
}



## Tests ----------------------------------------------------------------------


runTest(log_msg = "try to sign in with unregistered user",
        method = "POST",
        url = "http://127.0.0.1:8000/signIn",
        query = list(password="password", name="alice"),
        res_pattern = '\\{\\"error\\":\\"unknown user\\"\\}')

alice <- runTest(log_msg = "sign up user alice:password",
                 method = "POST",
                 url = "http://127.0.0.1:8000/signUp",
                 query = list(name="alice", country="Germany", password="password"),
                 res_pattern = '\\{\\"player\\":\\".*\\",\\"name\\":\\"alice\\"\\}',
                 return_res = TRUE)[["player"]]

runTest(log_msg = "try to sign up with too short password",
        method = "POST",
        url = "http://127.0.0.1:8000/signUp",
        query = list(name="bob", country="Germany", password="pw"),
        res_pattern = '\\{\\"error\\":\\"name or password invalid\\"\\}')

runTest(log_msg = "try to sign up with username already in use",
        method = "POST",
        url = "http://127.0.0.1:8000/signUp",
        query = list(name="alice", country="Germany", password="12345"),
        res_pattern = '\\{\\"error\\":\\"name already assigned to another player\\"\\}')

runTest(log_msg = "try to sign up with username only differs by upper case letter",
        method = "POST",
        url = "http://127.0.0.1:8000/signUp",
        query = list(name="Alice", country="Germany", password="12345"),
        res_pattern = '\\{\\"error\\":\\"name already assigned to another player\\"\\}')

bob <- runTest(log_msg = "sign up Bob:12345, without country parameter",
               method = "POST",
               url = "http://127.0.0.1:8000/signUp",
               query = list(name="Bob", password="12345"),
               res_pattern = '\\{\\"player\\":\\".*\\",\\"name\\":\\"Bob\\"\\}',
               return_res = TRUE)[["player"]]

runTest(log_msg = "sign in user Bob:12345",
        method = "POST",
        url = "http://127.0.0.1:8000/signIn",
        query = list(name="Bob", password="12345"),
        res_pattern = paste0('\\{\\"player\\":\\"', bob, '\\",\\"name\\":\\"Bob\\"\\}'))

runTest(log_msg = "try to sign in with invalid password",
        method = "POST",
        url = "http://127.0.0.1:8000/signIn",
        query = list(name="alice", password="12345"),
        res_pattern = '\\{\\"error\\":\\"invalid password\\"\\}')

runTest(log_msg = "sign in user alice:password",
        method = "POST",
        url = "http://127.0.0.1:8000/signIn",
        query = list(name="alice", password="password"),
        res_pattern = paste0('\\{\\"player\\":\\"', alice, '\\",\\"name\\":\\"alice\\"\\}'))

runTest(log_msg = "try to start new game with invalid player ID",
        method = "GET",
        url = paste0("http://127.0.0.1:8000/newGame/", UUIDgenerate()),
        res_pattern = '\\{\\"error\\":\\"unknown user\\"\\}')

question_alice <- runTest(log_msg = "start new game for player alice",
                          method = "GET",
                          url = paste0("http://127.0.0.1:8000/newGame/", alice),
                          res_pattern = '\\{\\"question\\":\\".*\\"\\}',
                          return_res = TRUE)[["question"]]

question_alice <- runTest(log_msg = "answer question correctly",
                          method = "GET",
                          url = paste0("http://127.0.0.1:8000/answer/", alice, "/", eval(parse(text = str_remove(question_alice, "=")))),
                          res_pattern = '\\{\\"correct\\":true,\\"solution\\":\\".*\\",\\"question\\":\\".*\\"\\}',
                          return_res = TRUE)[["question"]]

question_bob <- runTest(log_msg = "start new game for player bob",
                        method = "GET",
                        url = paste0("http://127.0.0.1:8000/newGame/", bob),
                        res_pattern = '\\{\\"question\\":\\".*\\"\\}',
                        return_res = TRUE)[["question"]]

question_alice <- runTest(log_msg = "answer question incorrectly",
                          method = "GET",
                          url = paste0("http://127.0.0.1:8000/answer/", alice, "/", eval(parse(text = str_remove(question_alice, "="))) + 1),
                          res_pattern = '\\{\\"correct\\":false,\\"solution\\":\\".*\\",\\"question\\":\\".*\\"\\}',
                          return_res = TRUE)[["question"]]

question_bob <- runTest(log_msg = "answer question correctly",
                        method = "GET",
                        url = paste0("http://127.0.0.1:8000/answer/", bob, "/", eval(parse(text = str_remove(question_bob, "=")))),
                        res_pattern = '\\{\\"correct\\":true,\\"solution\\":\\".*\\",\\"question\\":\\".*\\"\\}',
                        return_res = TRUE)[["question"]]

question_bob <- runTest(log_msg = "answer question correctly",
                        method = "GET",
                        url = paste0("http://127.0.0.1:8000/answer/", bob, "/", eval(parse(text = str_remove(question_bob, "=")))),
                        res_pattern = '\\{\\"correct\\":true,\\"solution\\":\\".*\\",\\"question\\":\\".*\\"\\}',
                        return_res = TRUE)[["question"]]

runTest(log_msg = "try to answer with an invalid player ID",
        method = "GET",
        url = paste0("http://127.0.0.1:8000/answer/", UUIDgenerate(), "/", eval(parse(text = str_remove(question_alice, "="))) + 1),
        res_pattern = '\\{\\"error\\":\\"no game found\\"\\}')

runTest(log_msg = "try to finish the game",
        method = "GET",
        url = paste0("http://127.0.0.1:8000/finish/", alice),
        res_pattern = '\\{\\"finished\\":false\\}')

runTest(log_msg = "get empty highscore table",
        method = "GET",
        url = "http://127.0.0.1:8000/highscoreTable",
        res_pattern = '\\[\\]')

Sys.sleep(2)
runTest(log_msg = "try to finish the game, after waiting 2 seconds",
        method = "GET",
        url = paste0("http://127.0.0.1:8000/finish/", alice),
        res_pattern = '\\{\\"finished\\":true,\\"score\\":1\\}')

runTest(log_msg = "try to answer question after geme expired",
        method = "GET",
        url = paste0("http://127.0.0.1:8000/answer/", bob, "/", eval(parse(text = str_remove(question_bob, "=")))),
        res_pattern = '\\{\\"score\\":2\\}')

runTest(log_msg = "get highscore table",
        method = "GET",
        url = "http://127.0.0.1:8000/highscoreTable",
        res_pattern = paste0('\\[\\{\\"score\\":2,\\"player\\":\\"Bob\\",\\"date\\":\\"', Sys.Date(), '\\"\\},\\{\\"score\\":1,\\"player\\":\\"alice\\",\\"date\\":\\"', Sys.Date(), '\\"\\}\\]'))


# show logs and kill server
if (!is.null(server)) {
  test_log <- file(description = "server.log")
  cat(read_file(test_log))
  file.remove("server.log")
  cat("\nshutdown server...\n")
  if (process_terminate(server) == TRUE) cat("terminated\n")
}

cat("\nTests executed:\t", green$bold(tests["executed"]), "\nTests failed:\t", red$bold(tests["failed"]), "\n\n")
