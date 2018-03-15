# model

Challenge <- R6Class(
  classname = "Challenge",
  public = list(
    initialize = function(category = "mathematic"){
      self$category <- "mathematic"
      switch(self$category,
             mathematic = {
               self$content <- list(question = "1 + 2 =", solution = 3)
             },
             stop("invalid category"))
    },
    category = NULL,
    content = NULL,
    fuzzyAllowed = FALSE,
    answer = function(answer) {
      if (self$fuzzyAllowed) {
        return(amatch(answer, self$content[["solution"]]) == 1)
      } else {
        return(answer == self$content[["solution"]])
      }
    },
    toJSON = function() {
      toJSON(list(id=self$id, category=self$category, question=self$content[["question"]]), auto_unbox = TRUE)
    }
  )
)

Game <- R6Class(
  classname = "Game",
  list(
    initialize = function() {
      self$id <- UUIDgenerate()
    },
    id = NULL,
    challenges = list(),
    nextChallenge = function() {
      self$challenges <- append(self$challenges, list(Challenge$new()))
      return(self$challenges[length(self$challenges)])
    }
  )
)