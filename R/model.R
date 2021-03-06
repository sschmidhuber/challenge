# data model

Challenge <- R6Class(
  "Challenge",
  public = list(
    getQuestion = function() {
      private$question
    },
    setAnswer = function(answer) {
      private$answer <- tolower(answer)
      invisible(self)
    },
    checkAnswer = function() {
      if (private$fuzzy_allowed) {
        correct <- amatch(private$answer, private$solution) == 1
      } else {
        correct <- private$answer == private$solution
      }
      list(correct = correct, solution = as.character(private$solution))
    },
    toJSON = function() {
      jsonlite::toJSON(list(category=self$category, question=self$content[["question"]]), auto_unbox = TRUE)
    }
  ),
  private = list(
    question = NULL,
    solution = NULL,
    answer = "",
    fuzzy_allowed = FALSE
  )
)

MathChallenge <- R6Class(
  "MathChallenge",
  inherit = Challenge,
  public = list(
    initialize = function() {
      operands <- sample(20, size = 2, replace = TRUE)
      operator <- sample(c("+", "-"), size = 1)
      private$question <- paste(operands[1], operator, operands[2], "=")
      private$solution <- eval(parse(text = paste0(operands[1], operator, operands[2])))
    }
  )
)

Game <- R6Class(
  "Game",
  public = list(
    initialize = function(mode = "default", duration = 30) {
      self$id <- UUIDgenerate()
      private$mode <- mode
      private$start_time <- as.integer(format(Sys.time(), "%s"))
      private$duration <- duration
      self$createNextChallenge()
    },
    id = NULL,
    createNextChallenge = function() {
      if (private$mode == "math") {
        private$challenges <- append(private$challenges, MathChallenge$new())
      } else {
        private$challenges <- append(private$challenges, MathChallenge$new())
      }
      invisible(self)
    },
    getChallenge = function() {
      private$challenges[[length(private$challenges)]]
    },
    getTime = function() {
      private$duration - (as.integer(format(Sys.time(), "%s")) - private$start_time)
    },
    getScore = function() {
      correct <- sapply(private$challenges, function(x) {x$checkAnswer()[["correct"]]}, USE.NAMES = FALSE)
      sum(correct[correct==TRUE])
    },
    toJSON = function() {
      jsonlite::toJSON(list(id = self$id,
                            start_time = self$start_time,
                            duration = self$duration,
                            score =self$score),auto_unbox = TRUE)
    }
  ),
  private = list(
    mode = "default",
    challenges = list(),
    start_time = NULL,
    duration = NULL
  )
)