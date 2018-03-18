# mathChallenge.R


# This script provides a HTTP web API for MathChallenge
# the API does not follow the REST architecture pattern

# custom status codes
# 520 "name already assigned to another player"


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
function(res, name, country, password) {
  squishedName <- str_squish(name)
  if (squishedName=="" || length(password) <= 3) {
    res$status <- 400
    return(list(error = "name or password invalid"))
  } else if (nrow(playerTable[playerTable$name==name,])==1) {
    res$status <- 520
    return(list(error = "name already assigned to another player"))
  } else {
    id <- UUIDgenerate()
    salt <- format(Sys.time(), "%s")
    hash <- digest(paste0(password, salt), algo = "sha512")
    playerTable[nrow(playerTable)+1,] <<- c(id, name, country, hash, salt)
    res$status <- 200
    return(list(player = id))
  }
}

# trigger a new game
#* @get /new
#function(){
#  
#}
