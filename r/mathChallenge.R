# mathChallenge.R


# This script provides a HTTP web API for MathChallenge
# the API does not follow the REST architecture pattern


## global code; executed at plumb time

source("r/model.R")

TEST_MODE <- TRUE

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

#' logs the message and returns the message so no
#' additional statement is necessary
logger <- function(message) {
  out <- paste(as.character(Sys.time()), "-", 
      toJSON(message, auto_unbox = TRUE), "\n")
  cat(out)
  return(message)
}


## deliver static content

#* @assets ./web /
#list()


## web API

# log some information about incoming requests
#* @filter logger
function(req){
  cat(as.character(Sys.time()), "-", 
      req$REQUEST_METHOD, req$PATH_INFO, "-", 
      str_remove(str_replace_all(req$QUERY_STRING, "&", " "), "\\?"), "@", req$REMOTE_ADDR, "\n")
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
# TODO: add some brute force protection, e.g. timeout or lock account
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
  if (nrow(playerTable[playerTable$id==player,])==0) {
    res$status <- 400
    list(error = paste0("invalid player id: '", player, "'"))
  } else {
    newGame <- Game$new(mode = ifelse(TEST_MODE, "test", "default"))
    gameList <- append(gameList, newGame)
    names(gameList)[length(gameList)] <- player
    list(question = newGame$getChallenge()$getQuestion())
  }
}
