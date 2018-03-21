# mathChallenge.R


# This script provides a HTTP web API for MathChallenge
# the API does not follow the REST architecture pattern


## global code; executed at plumb time

source("r/model.R")

TEST_MODE <- TRUE
LOG_FILE <- NULL

# create logfile in non interactive mode
if (!interactive()) {LOG_FILE <- "server.log"}

# holds details about players
playerTable <- data.frame(
  id=character(),
  name=character(),
  country=character(),
  passwordHash=character(),
  salt=character(),
  stringsAsFactors = FALSE
)

# holds information about high scores
highscoreTable <- data.frame(
  player=character(),
  score=integer(),
  date=as.Date(character()),
  stringsAsFactors = FALSE
)

# holds a list of running games
gameList <- list()

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
  gameTime <- sapply(gameList, function(game) {game$getTime()})
  if (length(gameTime[gameTime <= outdated] > 0)) logger(paste("remove", length(gameTime[gameTime <= outdated]), "outdated games during clean up"))
  gameList[gameTime > outdated]
}


## deliver static content

#* @assets ./web /
list()


## web API

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
function(res, name, country="unknown", password) {
  name <- str_squish(name)
  if (str_length(name) < 2 || str_length(password) <= 3) {
    res$status <- 400
    logger(list(error = "name or password invalid"))
  } else if (nrow(playerTable[tolower(playerTable$name) == tolower(name),])==1) {
    res$status <- 400
    logger(list(error = "name already assigned to another player"))
  } else {
    id <- UUIDgenerate()
    salt <- format(Sys.time(), "%s")
    hash <- digest(paste0(password, salt), algo = "sha512")
    playerTable[nrow(playerTable)+1,] <<- c(id, name, country, hash, salt)
    logger(list(player = id))
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
function(res, name, password) {
  if (nrow(playerTable[playerTable$name==name,]) == 0) {
    res$status <- 400
    logger(list(error = "unknown user"))
  } else if (digest(paste0(password, playerTable[playerTable$name==name,"salt"]), algo = "sha512") == playerTable[playerTable$name==name,"passwordHash"]) {
    logger(list(player=playerTable[playerTable$name==name,"id"]))
  } else {
    res$status <- 400
    logger(list(error = "invalid password"))
  }
}

# start a new game
#* @get /newGame/<player>
#* @serializer unboxedJSON
function(res, player){
  gameList <<- cleanUpGames() # first clean up game list
  gameList[player] <<- NULL # remove game associated with player if there is any
  
  if (nrow(playerTable[playerTable$id==player,])==0) {
    res$status <- 400
    logger(list(error = paste0("unknown user")))
  } else {
    newGame <- Game$new(mode = ifelse(TEST_MODE, "test", "default"))
    gameList <<- append(gameList, newGame)
    names(gameList)[length(gameList)] <<- player
    logger(list(question = newGame$getChallenge()$getQuestion()))
  }
}

# answer a question
#* @get /answer/<player>/<answer>
#* @serializer unboxedJSON
function(res, player, answer) {
  if (!player %in% names(gameList)) {
    res$status <- 400
    logger(list(error = paste0("no game found")))
  } else {
    game <- gameList[[player]]
    if (game$getTime() > 0) { # the answer is valid, send next question
      result <- game$getChallenge()$setAnswer(answer)$checkAnswer()
      nextQuestion <- game$createNextChallenge()$getChallenge()$getQuestion()
      logger(append(result, list(question = nextQuestion)))
    } else { # the answer is not valid anymore, no new question, game ends
      logger(list(score = game$getScore()))
    }
  }
}

