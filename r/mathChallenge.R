# mathChallenge.R


# This script provides a HTTP web API for MathChallenge
# the API does not follow the REST architecture pattern


## global code; executed at plumb time

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


## deliver static content

#* @assets ./web /
#list()


## web API

# log some information about incoming requests
#* @filter logger
function(req){
  cat(as.character(Sys.time()), "-", 
      req$REQUEST_METHOD, req$PATH_INFO, "-", 
      req$HTTP_USER_AGENT, "@", req$REMOTE_ADDR, "\n")
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
    cat("\nname:", name, "passowrd:", password, "\n\n")
    res$status <- 400
    list(error = "name or password invalid")
  } else if (nrow(playerTable[playerTable$name==name,])==1) {
    res$status <- 400
    list(error = "name already assigned to another player")
  } else {
    id <- UUIDgenerate()
    salt <- format(Sys.time(), "%s")
    hash <- digest(paste0(password, salt), algo = "sha512")
    playerTable[nrow(playerTable)+1,] <<- c(id, name, country, hash, salt)
    list(player = id)
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
    list(error = "unknown user")
  } else if (digest(paste0(password, playerTable[playerTable$name==name,"salt"]), algo = "sha512") == playerTable[playerTable$name==name,"passwordHash"]) {
    list(player=playerTable[playerTable$name==name,"id"])
  } else {
    res$status <- 400
    list(error = "invalid password")
  }
}

# trigger a new game
#* @get /new
#function(){
#  
#}
