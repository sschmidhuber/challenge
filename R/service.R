# mathChallenge.R


# This script provides a HTTP web API for MathChallenge
# the API does not follow the REST architecture pattern


## global code; executed at plumb time

source("R/model.R")

TEST_MODE <- TRUE
LOG_FILE <- NULL

# create logfile in non interactive mode
if (!interactive()) {LOG_FILE <- "server.log"}

# holds details about players
player_table <- data.frame(
  id=character(),
  name=character(),
  country=character(),
  passwordHash=character(),
  salt=character(),
  stringsAsFactors = FALSE
)

# holds information about high scores
highscore_table <- data.frame(
  game=character(),
  player=character(),
  score=integer(),
  date=as.Date(character()),
  stringsAsFactors = FALSE
)

# holds a list of running games
game_list <- list()

#' logs x and returns x so no
#' additional statement is necessary
logger <- function(x, mode = "json") {
  if (mode == "plain") {
    out <- paste(as.character(Sys.time()), "-", x)
  } else {  # default json
    out <- paste(as.character(Sys.time()), "-", 
                 toJSON(x, auto_unbox = TRUE))
  }
  if (is.null(LOG_FILE)) {message(out)} else {write(x = out, file = LOG_FILE, append = TRUE)}
  return(x)
}

#' clean up outdated games
cleanUpGames <- function() {
  outdated <- -3600
  gameTime <- sapply(game_list, function(game) {game$getTime()})
  if (length(gameTime[gameTime <= outdated] > 0)) logger(paste("remove", length(gameTime[gameTime <= outdated]), "outdated games during clean up"))
  game_list[gameTime > outdated]
}

#' check input parameter in req$QUERY_STRING and req$postBody
#' returns true if all parameter are available
checkInputParameter <- function(req, expected_parameter) {
  str_detect(paste(req$QUERY_STRING, req$postBody), expected_parameter) %>% all()
}

#' parse parameters from post body
#' @return named list with given parameter
parsePostBody <- function(req) {
  tmp <- str_split(req$postBody, "&") %>% unlist() %>% str_split("=")
  parameter <-  sapply(tmp, function(x) {x[2]})
  names(parameter) <- sapply(tmp, function(x) {x[1]})
  parameter
} 


## deliver static content

#* @assets ./web /
list()


## web API

# TODO make sure not to log any passwords
# log some information about incoming requests
#* @filter requestLogger
function(req){
  query <- str_remove(str_replace_all(req$QUERY_STRING, "&", " "), "\\?")
  out <- paste0("\n", as.character(Sys.time()), " - ", 
      req$REQUEST_METHOD, " ", req$PATH_INFO, 
      if (str_length(query) > 0) paste(" -", query), " @ ", req$REMOTE_ADDR)
  if (is.null(LOG_FILE)) {message(out)} else {write(x = out, file = LOG_FILE, append = TRUE)}
  plumber::forward()
}

# register new player
#* @post /signUp
#* @param name
#* @param country
#* @param password
#* @serializer unboxedJSON
function(req, res) {
  if (!checkInputParameter(req, expected_parameter = c("name", "password"))) {
    res$status <- 400
    return(logger(list(error = "missing input parameter")))
  }
  
  parameter <- parsePostBody(req)
  name <- parameter[["name"]]
  password <- parameter[["password"]]
  country <- if ("country" %in% names(parameter)) {parameter[["country"]]} else {"unknown"}
  
  name <- str_squish(name)
  
  if (str_length(name) < 2 || str_length(password) <= 3) {
    res$status <- 400
    logger(list(error = "name or password invalid"))
  } else if (nrow(player_table[tolower(player_table$name) == tolower(name),]) == 1) {
    res$status <- 400
    logger(list(error = "name already assigned to another player"))
  } else {
    id <- UUIDgenerate()
    salt <- format(Sys.time(), "%s")
    hash <- digest(paste0(password, salt), algo = "sha512")
    player_table[nrow(player_table) + 1,] <<- c(id, name, country, hash, salt)
    logger(list(player = id, name = name))
  }
}

# signIn for registred player
#
# TODO: add some basic brute force and DOS protection, e.g. timeout or lock account
#
#* @post /signIn
#* @param name
#* @param password
#* @serializer unboxedJSON
function(req, res) {
  if (!checkInputParameter(req, expected_parameter = c("name", "password"))) {
    res$status <- 400
    return(logger(list(error = "missing input parameter")))
  }
  
  parameter <- parsePostBody(req)
  name <- parameter[["name"]]
  password <- parameter[["password"]]
  
  if (filter(player_table, name == name) %>% nrow() == 0) {
    res$status <- 400
    logger(list(error = "unknown user"))
  } else if (digest(paste0(password, player_table[player_table$name == name, "salt"]), algo = "sha512") == player_table[player_table$name==name,"passwordHash"]) {
    logger(list(player = player_table[player_table$name == name, "id"], name = name))
  } else {
    res$status <- 400
    logger(list(error = "invalid password"))
  }
}

# start a new game
#* @get /newGame/<player>
#* @serializer unboxedJSON
function(res, player){
  game_list <<- cleanUpGames() # first clean up game list
  game_list[player] <<- NULL # remove game associated with player if there is any
  
  if (nrow(player_table[player_table$id==player,])==0) {
    res$status <- 400
    logger(list(error = paste0("unknown user")))
  } else {
    newGame <- Game$new(mode = if (TEST_MODE) "test" else "default", duration = if (TEST_MODE) 2 else 30)
    game_list <<- append(game_list, newGame)
    names(game_list)[length(game_list)] <<- player
    logger(list(question = newGame$getChallenge()$getQuestion()))
  }
}

# answer a question
#* @get /answer/<player>/<answer>
#* @serializer unboxedJSON
function(res, player, answer) {
  if (!player %in% names(game_list)) {
    res$status <- 400
    logger(list(error = paste0("no game found")))
  } else {
    game <- game_list[[player]]
    if (game$getTime() > 0) { # the answer is valid, send next question
      result <- game$getChallenge()$setAnswer(answer)$checkAnswer()
      next_question <- game$createNextChallenge()$getChallenge()$getQuestion()
      logger(append(result, list(question = next_question)))
    } else { # the answer is not valid anymore, no new question, game ends
      game_list[player] <<- NULL
      highscore_table[nrow(highscore_table) + 1,] <<- list(game$id, filter(player_table, id == player)[["name"]], game$getScore(), Sys.Date())
      logger(list(score = game$getScore()))
    }
  }
}

# finish game
# this endpoint will be polled by the client to achieve a real time like behavior
#* @get /finish/<player>
#* @serializer unboxedJSON
function(res, player) {
  if (!player %in% names(game_list)) {
    res$status <- 400
    logger(list(error = paste0("no game found")))
  } else {
    game <- game_list[[player]]
    time_left <- game$getTime()
    if (time_left > 0) {
      logger(list(finished = FALSE))
    } else {
      game_list[player] <<-NULL
      highscore_table[nrow(highscore_table) + 1,] <<- list(game$id, filter(player_table, id == player)[["name"]], game$getScore(), Sys.Date())
      logger(list(finished = TRUE, score = game$getScore()))
    }
  }
}

# get highscore table
#* @get /highscoreTable
#* @serializer unboxedJSON
function() {
  if (nrow(highscore_table) == 0) {
    logger(list())
  } else {
    logger(select(highscore_table, score, player, date) %>% arrange(desc(score)))
  }
}
