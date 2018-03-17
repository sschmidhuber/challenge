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
  salt=character()
)

# holds information about high scores
highscoreTable <- data.frame(
  player=character(),
  score=integer(),
  date=as.Date(character())
)

# holds a list of running games
gameList <- list()


# deliver static content
#* @assets ./web /
list()


# trigger a new game
#* @get /new
function(){
  
}
