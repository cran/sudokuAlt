% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sudokuAlt.R
\name{designGame}
\alias{designGame}
\alias{designGame.default}
\alias{designGame.sudoku}
\title{Sudoku Design}
\usage{
designGame(g, ...)

\method{designGame}{default}(g, ...)

\method{designGame}{sudoku}(g, ...)
}
\arguments{
\item{g}{a sudoku game, presumably solved}

\item{...}{currently ignored}
}
\value{
a data frame with four colums, \code{Row}, \code{Col},
 \code{Square} and \code{Symbol}
}
\description{
Take a sudoku game and represent the information as a data
frame giving the row, column, square and symbol for each entry.
This is a useful form if the (complete) game is to be used as
an experimental design
}
\examples{
set.seed(2019)
d <- seedGame(4) \%>\% solve() \%>\%
     regulariseGame(target = "b") \%>\%
     designGame()
rbind(head(d), tail(d))
}
