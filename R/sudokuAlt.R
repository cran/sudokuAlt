##' @importFrom magrittr %>%
##' @export 
magrittr::`%>%`

##' @importFrom stats runif
##' 
sample <- function(n, k) {
  (1:n)[order(runif(n))][1:k]
}

##' Construct a Sudoku Game Object
##'
##' Coerce an object to one that can be used as a sudoku game.
##' IMPORTANT: games are represented as n^2xn^2 character matrices,
##' using 1-9 for n=2 or 3, and LETTERS[1:(n^2)] for n = 4 or 5.
##' @title Generic Sudoku Game Constructor
##' @param x an n^2 x n^2 matrix object to represent the game
##' @param ... Other additional arguments (currently ignored)
##' @return An object of class 'sudoku'
##' @export as.sudoku
##' @rdname as.sudoku
##' @examples
##' M <- as.sudoku(matrix("", 16, 16))
##' M[1:4, 1:4] <- matrix(LETTERS[1:16], 4, 4, byrow = TRUE)
##' sM <- solve(M)
##' plot(sM)
##' @author Bill Venables
as.sudoku <- function(x, ...)
    UseMethod("as.sudoku")

##' Construct a Sudoku Game Object
##'
##' Coerce a matrix to an object that can be used as a sudoku game
##' @method as.sudoku matrix
##' @export
##' @title as.sudoku.matrix
##' @param x An n^2 x n^2 matrix
##' @param ... other arguments (currently ignored)
##' @return An object of class 'sudoku'
##' @author Bill Venables
as.sudoku.matrix <- function(x, ...) {
  n <- as.integer(round(sqrt(nrow(x))))
  if (nrow(x) != n^2 || !(n %in% 2:5))
      stop("invalid matrix")
  set <- if(n <= 3) as.character(1:(n^2)) else LETTERS[1:(n^2)]
  storage.mode(x) <- "character"
  is.na(x[!(x %in% set)]) <- TRUE
  structure(x, class = "sudoku")
}

##' Construct a Sudoku Game Object
##' 
##' Identity function for sudoku objects
##' @method as.sudoku sudoku
##' @export
##' @param x A sudoku object
##' @param ... other arguments (ignored)
##' @return the input sudoku object
##' @author Bill Venables
as.sudoku.sudoku <- function(x, ...) x

##' Format a Date Relative to the Current Date
##'
##' Internal function used by fetchUKGame().
##' @title Format a Past Date
##' @param n A positive integer for how many days ago
##' @param warn Issue a warning if n <= 0 or n > 30
##' @return A character string of the form "dd/mm/yy"
##' @export daysAgo
##' @examples
##' daysAgo()  ## today
##' daysAgo(7) ## a week ago 
##' @author Bill Venables
daysAgo <- function(n = 0, warn = TRUE) {
  if(warn && any(n > 30 | n < 0))
      warning("games for longer than 30 days ago are not retained.")
  then <- as.Date(strptime(date(), "%a %b %d %H:%M:%S %Y")) - as.integer(n)
  as.character(format(then, "%d/%m/%y"))
}

##' Retrieve a Sudoku Game
##'
##' Connects to \code{http://www.sudoku.org.uk/DailySudoku.asp} and retrieves
##' the sudoku game from \code{day} days ago.  Based on a function from a
##' related sudoku package, \code{sudoku::fetchSudokuUK} with minor changes.
##' @title Retrieve a Sudoku from the UK Site
##' @param day positive integer < 30, how many days ago? or NULL for
##' the most recently published game.
##' @return The published sudoku game as a sudoku object.
##' @examples
##' \dontrun{
##' (g0 <- fetchUKGame())  ## The game for today (according to GMT)
##' (g3 <- fetchUKGame(3)) ## game from 3 days ago (according to GMT)
##' if(require(sudoku)) {  ## the original solver
##'   g0a <- as.sudoku(fetchSudokuUK())  
##'   identical(g0, g0a)   ## should be TRUE
##' }
##' g0 %>% solve %>% plot -> sg0 ## spoil the game
##' }
##' @export fetchUKGame
##' @author Bill Venables
fetchUKGame <- function(day = NULL) {
  sudoku_UK <- "http://www.sudoku.org.uk/DailySudoku.asp"
  
  if(!is.null(day))
      sudoku_UK <- paste0(sudoku_UK, "?day=", daysAgo(day))
  con <- url(sudoku_UK)
  game <- tryCatch(readLines(con),
                   error = function(e) {
                     stop("\"", sudoku_UK, 
                          "\" appears to be offline.",
                          "  Try Australian game instead.")
                   })
  close(con)
  game <- grep("^<td .*</td>$", game, value = TRUE)
  if(length(game) != 81)
      stop("No game found. Check the date?")
  game <- sub("^<td .*(.)</td>$", "\\1", game)
  as.sudoku(matrix(game, 9, 9, byrow = TRUE))
}

##' Retrieve a Sudoku Game
##'
##' Connects to \url{http://www.sudoku.com.au} and retrieves
##' the sudoku game from \code{day} days ago.  Based on a function from a
##' related sudoku package, \code{sudoku::fetchSudokuUK} with minor changes.
##' @title Retrieve a Sudoku from the AU Site
##' @param day non-negative integer, how many days ago? zero for
##' today's game.
##' @param difficulty character string, how hard would you like it?
##' @return The published sudoku game as a sudoku object.
##' @examples
##' \dontrun{
##' fetchAUGame() %>% solve %>% plot -> gau           ## The 'tough' game for today 
##' fetchAUGame(3, "easy") %>% solve %>% plot -> eau  ## 'easy' game from 3 days ago
##' }
##' @export fetchAUGame
##' @author Bill Venables
fetchAUGame <- function(day = 0, difficulty = c("tough", "hard", "medium", "easy")) {
  stopifnot(is.numeric(day) && length(day) == 1 && day %% 1 == 0 && day >= 0)
  difficulty <- match.arg(difficulty)
  prefix <- c(easy = "5E", medium = "3M", hard = "2H", tough = "1V")
  pre <- prefix[difficulty]
  
  sudoku_AU <- "http://www.sudoku.com.au"
  sday <- as.Date(strptime(date(), "%a %b %d %H:%M:%S %Y")) - as.integer(day)
  sday <- as.POSIXlt(sday)
  game <- paste0(sudoku_AU, "/", pre, sday$mday, "-", sday$mon + 1, "-",
                 sday$year + 1900, "-sudoku.aspx")
  con <- url(game)
  txt <- tryCatch(readLines(con),
                  error = function(e) {
                    stop("\"", sudoku_AU, 
                         "\" appears to be offline.",
                         "  Try the UK game instead.")
                  })
  ## txt <- readLines(con)
  close(con)
  txt <- txt[grep("iGridUnsolved", txt)]
  txt <- sub("^.*\\(", "", txt)
  txt <- sub("\\);$", "", txt)
  txt <- as.numeric(strsplit(txt, ",")[[1]])
  txt <- matrix(txt, ncol = 9, byrow = TRUE)
  as.sudoku(txt)
}

##' Construct a Random Sudoku Game
##'
##' Construcs a sudoku game for given n, 2 <= n <= 5.
##' n = 5 can be problematical.
##' @title Make a New Sudoku Game
##' @param n Size of the game, n^2 x n^2
##' @param gaps Number of holes to leave for the solution
##' @param maxit Number of tries before giving up.
##' @examples 
##' set.seed(54321)
##' makeGame() %>% solve %>% plot -> sg
##' originalGame(sg)
##' 
##' @return a sudoku game
##' @export makeGame
##' @author Bill Venables
makeGame <- function(n = 3, gaps = ceiling(3*n^4/4), maxit = 25) {
  if(!missing(n) && (2 > n || n > 5))
      stop("Only cases n = 2, 3, 4 or 5 are implemented. Sorry!")
  solved <- NULL
  iter <- 0
  while(identical(solved, NULL) && (iter <- iter+1) < maxit) {
    solved <- solveGame(seedGame(n))
  }
  if(iter == maxit) {
    stop("Maximum number of tries exceeded.")
  }
  if(gaps > 0) is.na(solved[sample(length(solved), gaps)]) <- TRUE
  attr(solved, "game") <- NULL
  solved
}

##' Plot a Sudoku Game
##'
##' Present a graphical display of a sudoku game and its solution if
##' the game is solved
##' @title Plot a Sudoku Game
##' @import graphics
##' @method plot sudoku
##' @export
##' @param x The sudoku game
##' @param ... additional arguments
##' @param cex Character expansion factor 
##' @param colSolution colour to be used for the solution (if present)
##' @param colGame colour to be used for the original game
##' @return The sudoku game \code{x}, invisibly.
##' @examples
##' set.seed(20191)
##' makeGame(4, gaps = 0) %>% plot(cex=1) -> sg
##' @author Bill Venables
plot.sudoku <- function(x, ..., cex=1.5-(n-3)/2,
                        colSolution = "grey", colGame = "fire brick") {
  oldPar <- par(mar = rep(0, 4)+0.1, ...,
                xaxs = "i", xaxt = "n",
                yaxs = "i", yaxt = "n")
  on.exit(par(oldPar))
  n <- sqrt(nrow(x))
  xseq <- yseq <- 0:(n^2)
  plot(Y ~ X, data = expand.grid(X = xseq, Y = yseq), type = "n")
  abline(h = seq(0, n^2), v = seq(0, n^2), lty = "dotted", lwd = 0.5)
  abline(h = seq(0, n^2, by = n), v = seq(0, n^2, by = n), lwd=2)
  centres <- expand.grid(X = xseq[-1] - 0.5, Y = rev(yseq[-1]) - 0.5)
  game <- attr(x, "game")
  solved <- !is.null(game)
  with(centres, text(X, Y, t(x), cex = cex,
                     col = if(solved) colSolution else colGame,
                     font = if(solved) 1 else 2))
  if(solved) {
    with(centres, text(X, Y, t(game), cex = cex, col=colGame, font = 2))
  }
  invisible(x)
}

##' Print a Sudoku Object
##'
##' Prints a sudoku object in an easily recognisable form.
##' @title Print a Sudoku Object
##' @method print sudoku
##' @export
##' @param x The sudoku game object
##' @param ... extra arguments (ignored) 
##' @return the object, invisibly
##' @author Bill Venables
print.sudoku <- function(x, ...) {
  n <- sqrt(nrow(x))
  y <- unclass(x)
  attr(y, "game") <- NULL
  y[is.na(y)] <- ""
  z <- "|"
  n2 <- 0
  for(j in 1:n) {
    n1 <- n2+1
    n2 <- n2+n
    z <- cbind(z, y[, n1:n2], "|")
  }
  y <- "-"
  n2 <- 0
  for(i in 1:n) {
    n1 <- n2+1
    n2 <- n2+n
    y <- rbind(y, z[n1:n2, ], "-")
  }
  i <- seq(1, (nc <- ncol(y)), n+1)
  y[i, i] <- "+"
  dimnames(y) <- list(rep("", nrow(y)), rep("", ncol(y)))
  print(y, quote = FALSE, ...)
  invisible(x)
}

##' Generate a random sudoku game starting point
##'
##' Generates a game with one instance of each symbol in random
##' positions.
##' @title Starting Point to Make a Random Sudoku Game
##' @param n Size of the game, n^2 x n^2
##' @return A sparse unsolved sudoku game
##' @export seedGame
##' @examples
##' set.seed(2345)
##' g <- seedGame(3)
##' sg <- solve(g) ## a completed random game
##' plot(sg)
##' @author Bill Venables
seedGame <- function(n = 3) {
  if(length(n) != 1 || !is.numeric(n) || n %% 1 != 0 || n < 2 | n > 5)
    stop("n must be a single integer between 2 and 5 inclusive")
  values <- if(n <= 3) as.character(1:(n^2)) else LETTERS[1:(n^2)]
  n2 <- n^2
  game <- matrix(NA_character_, n2, n2)

  game[sample(length(game), n2)] <- values
  structure(game, class = "sudoku")
}

##' Solve a Sudoku Puzzle
##' 
##' An alternative front end to \code{solveGame} as a method for the base generic function \code{solve}.
##' @title Solve a Sudoku Puzzle
##' @method solve sudoku
##' @export
##' @param a A sudoku game object to be solved
##' @param ... Extra arguments (curently ignored)
##' @return a solved game, or NULL if no solution exists.
##' @examples
##' set.seed(1234)
##' makeGame(3, gaps = 59) %>% solve %>% plot -> sg
##' originalGame(sg)
##' 
##' g <- emptyGame(4)  # construct a patterned game
##' diag(g) <- LETTERS[1:16]
##' g %>% solve %>% plot -> sg
##' sg
##' @author Bill Venables
solve.sudoku <- function(a, ...) {
  solveGame(a)  
}

##' Solve a Sudoku Game
##'
##' Given a sudoku game to be solved, find the solution.  IMPORTANT:
##' games are represented as n^2 x n^2 character matrices, using 1-9 for
##' n=2 or 3, and LETTERS[1:(n^2)] for n = 4 or 5.
##' @title Solve a Sudoku Game
##' @param game The game to be solved
##' @return A solved sudoku game object if one found, or NULL if no
##' solution exists.  The original game is attached as an attribute if the game is solved.
##' @importFrom stats na.omit
##' @examples
##' set.seed(1234)
##' makeGame(3, gaps = 60) %>% solve %>% plot -> sg
##' (g <- originalGame(sg))
##' 
##' g <- emptyGame(4)  # construct a patterned game
##' diag(g) <- LETTERS[1:16]
##' sg <- solve(g)
##' plot(sg)
##' @export
##' @author Bill Venables
solveGame <- function(game) {
  n <- as.integer(round(sqrt(nrow(game))))  ## overkill?
  set <- if(n <= 3) {
    as.character(1:n^2)
  } else {
    LETTERS[1:n^2]
  }
  storage.mode(game) <- "character"
  is.na(game[!(game %in% set)]) <- TRUE
    
  nSet <- 1:(n^2)  ## work in integers
    
  toMatrix <- function(game) {  ## inverse of toArray
    game[] <- set[game]
    dim(game) <- c(n, n)^2
    game
  }
  
  toArray <- function(mat) {  ## inverse of toMatrix
    array(as.integer(match(mat, set)), dim = c(n,n,n,n))
  }
  
  conflict <- function(section) 
      any(duplicated(na.omit(as.vector(section))))
  
  invalid <- function(game) {
    for(i in 1:n) for(j in 1:n) {
      if(conflict(game[,i,,j]) ||  ## 'same block'
         conflict(game[i,j,,]) ||  ## 'same row'
         conflict(game[,,i,j]))    ## 'same column'
          return(TRUE)
    }
    FALSE
  }
    
  findSolution <- function(game) {
    if(invalid(game)) return(FALSE)
    
    while(anyNA(game)) {  ## anyNA() is only  in R 3.1.0 and later.
      holes <- which(is.na(game), arr.ind = TRUE)  ## a good trick!
      nr <- nrow(holes)
      fills <- vector("list", nr)
      lengths <- integer(nr)
      for(j in 1:nr) {
        i <- holes[j,]
        fills[[j]] <- setdiff(nSet,
                              c(game[    ,i[2],    ,i[4]],
                                game[i[1],i[2],    ,    ],
                                game[    ,    ,i[3],i[4]]))
        lengths[j] <- length(fills[[j]])
        if(lengths[j] == 0) return(FALSE)
      }
      if(any(h <- which(lengths == 1))) {
        game[holes[h,,drop = FALSE]] <- unlist(fills[h])
        if(invalid(game)) return(FALSE)
      } else {  ## only holes with multiple alternatives
        m <- which.min(lengths)
        entries <- fills[[m]]
        pos <- holes[m,,drop = FALSE]
        for(e in entries) {
          game[pos] <- e
          h <- findSolution(game)  ## recursive call
          if(!identical(h, FALSE)) return(h)
        }
        return(FALSE)  ## dud game, no solutions!
      }
    }
    game
  }
  
  ## the business starts here
  solution <- findSolution(toArray(game))
  if(identical(solution, FALSE)) NULL else
  structure(toMatrix(solution), game = game, class = "sudoku")
}

##' Retrieve the Original from a Solved Game
##' 
##' Convenience function for accessing an original from a solved game.
##' If the game is unsolved, the object itself is returned.
##' @title Retrieve the Original from a Solved Game
##' @param x a sudoku object
##' @export originalGame
##' @return The original sudoku game corresponding to the solution, 
##' or object itself if the game is unsolved
##' @examples
##' set.seed(666)
##' seedGame() %>% solve %>% plot -> sg ## %>% imported from magrittr
##' originalGame(sg)
##' @author Bill Venables
originalGame <- function(x) {
  if(!inherits(x, "sudoku"))
    stop(sprintf("%s is not a sudoku object", deparse(substitute(x))))
  g <- attr(x, "game")
  if(is.null(g)) x else g
}

##' Construct a Vacant Game Structure
##'
##' Returns a vacant game structure to allow special patterns to
##' be constructed, as shown in the example.
##' @title Construct an empty game
##' @param n an integer value between 2 and 5 inclusive.
##' @return An empty sudoku game structure
##' @examples
##' g <- emptyGame(4)
##' diag(g) <- LETTERS[1:16]
##' plot(g)
##' g %>% solve %>% plot -> sg ## %>% imported from magrittr 
##' @export emptyGame
##' @author Bill Venables
emptyGame <- function(n = 3) {
  if(length(n) != 1 || !is.numeric(n) || n %% 1 != 0 || n < 2 | n > 5)
    stop("n must be a single integer between 2 and 5 inclusive")
  structure(matrix(NA_character_, n^2, n^2), class = "sudoku")
}

##' Put a solved sudoku game into a canonical form
##'
##' If a solved sudoku game is to be used as an experimental
##' design it is sometimes useful to re-arrange the symbols
##' so that either the first row, first column or top left
##' block symbols are in sorted order.  This function accomplishes
##' this task.
##' 
##' @title regulariseGame
##' @param g a solved sudoku game
##' @param target character; which section do you want to be in sorted order?
##' @param ... additional arguments to methods (currently not used)
##' @return a regularised solved sudoku game
##' @export
##' @examples
##' set.seed(1234)
##' g <- makeGame() %>%
##'      solve() %>%    
##'      regulariseGame(target = "b") %>% 
##'      plot()
##' plot(originalGame(g))
regulariseGame <- function(g, ...) {
  UseMethod("regulariseGame")
}

##' @rdname regulariseGame
##' @export
regulariseGame.sudoku <- function(g, target = c("block", "col", "row"), ...) {
  if(anyNA(g))
    stop("only fully solved games can be regularised")
  target <- match.arg(target)
  n <- ncol(g)
  v <- switch(target,
              row = g[1, 1:n],
              col = g[1:n, 1],
              block = {
                n <- round(sqrt(n))
                as.vector(t(g[1:n, 1:n]))
              })
  s <- sort(v)
  names(s) <- v
  g[] <- s[as.vector(g)]
  if(!is.null(attr(g, "game"))) {
    game <- attr(g, "game")
    game[] <- s[as.vector(game)]
    attr(g, "game") <- game
  }
  g
}

##' @rdname regulariseGame
##' @export
regulariseGame.default <- function(g, ...) {
  stop("no applicable method for objects of class ", class(g))
}


#' Sudoku Design
#' 
#' Take a sudoku game and represent the information as a data
#' frame giving the row, column, square and symbol for each entry.
#' This is a useful form if the (complete) game is to be used as
#' an experimental design
#'
#' @param g a sudoku game, presumably solved
#' @param ... currently ignored
#'
#' @return a data frame with four colums, \code{Row}, \code{Col},
#'  \code{Square} and \code{Symbol}
#' @export
#'
#' @examples
#' set.seed(2019)
#' d <- seedGame(4) %>% solve() %>%
#'      regulariseGame(target = "b") %>%
#'      designGame()
#' rbind(head(d), tail(d))
designGame <- function(g, ...) {
  UseMethod("designGame")
}

#' @rdname designGame
#' @export
designGame.default <- function(g, ...) {
  stop("no applicable method for objects of class ", class(g))
}
  
.zf <- function(x) {
  m <- max(n <- nchar(x <- as.character(x)))
  paste0(strrep(0, m-n), x)
}

#' @rdname designGame
#' @export
designGame.sudoku <- function(g, ...) {
  n <- round(sqrt(nrow(g)))
  l <- ifelse(n > 3, "", "L")
  d <- data.frame(Row = paste0("R", .zf(row(g))),
                  Col = paste0("C", .zf(col(g))),
                  Square = paste0("S", 
                                  .zf(((row(g)-1) %/% n) + 1),
                                  .zf(((col(g)-1) %/% n) + 1)),
                  Symbol = paste0(l, as.vector(unclass(g))))
  d <- with(d, d[order(Square, Row, Col), ])
  row.names(d) <- .zf(seq(nrow(d)))
  d
}
  
  
