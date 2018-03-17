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
    getQuestion = function() {
      self$content[["question"]]
    },
    answer = function(answer) {
      self$content[["answer"]] <- answer
      invisible(self)
    },
    check = function() {
      answer <- self$content[["answer"]]
      solution <- self$content[["solution"]]
      if (self$fuzzyAllowed) {
        correct <- amatch(tolower(answer), tolower(solution)) == 1
      } else {
        correct <- answer == solution
      }
      return(list(correct = correct, solution = solution))
    },
    toJSON = function() {
      jsonlite::toJSON(list(category=self$category, question=self$content[["question"]]), auto_unbox = TRUE)
    }
  )
)

Game <- R6Class(
  classname = "Game",
  list(
    initialize = function(duration = 30) {
      self$id <- UUIDgenerate()
      self$startTime <- as.integer(format(Sys.time(), "%s"))
      self$duration <- duration
    },
    id = NULL,
    startTime = NULL,
    duration = NULL,
    challenges = list(),
    getNextChallenge = function() {
      self$challenges <- append(self$challenges, Challenge$new())
      return(self$challenges[[length(self$challenges)]])
    },
    getTime = function() {
      return(self$duration - (as.integer(format(Sys.time(), "%s")) - self$startTime))
    },
    getScore = function() {
      score <- 0
      for (challenge in self$challenges) {
        if (challenge$check()[["correct"]]) {
          score <- score + 1
        }
      }
      return(score)
    },
    toJSON = function() {
      jsonlite::toJSON(list(id = self$id,
                            startTime = self$startTime,
                            duration = self$duration,
                            score =self$score),auto_unbox = TRUE)
    }
  )
)