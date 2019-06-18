## ---- include = FALSE----------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "",
  fig.height = 5.5,
  fig.width = 5.5,
  fig.align = "center",
  out.width = "0.5\\textwidth")
setHook("plot.new",
        list(family = function() par(family = "sans")),
        "replace")

## ----setup---------------------------------------------------------------
library(sudokuAlt)
set.seed(2019)
seedGame(3) %>% solve() %>% regulariseGame() %>% plot()

## ------------------------------------------------------------------------
g <- makeGame() %>% solve() %>% plot()


## ---- fig.width=5, fig.height=5------------------------------------------
set.seed(2019)
g4 <- seedGame(4) %>% solve() %>% regulariseGame() %>% plot()

## ---- eval=FALSE, echo=FALSE---------------------------------------------
#  set.seed(1559347072)  ## chosen after some experimentation...
#  set.seed(1559368531)  ## chosen after some experimentation...
#  set.seed(1559686356)  ## chosen after some experimentation...

## ---- fig.width=7.25, fig.height=7.25------------------------------------
set.seed(1559707151)
g5 <- seedGame(5) %>% solve() %>% regulariseGame()
plot(g5, cex = 1)

## ------------------------------------------------------------------------
d5 <- designGame(g5)
head(d5); tail(d5)

## ---- fig.width=4.75, fig.height=4.75------------------------------------
g <- emptyGame(4)
diag(g) <- LETTERS[1:16]
g %>% 
  solve() %>% 
  plot() -> sg

## ------------------------------------------------------------------------
g <- emptyGame(3)
g[1:3, 1:3] <- matrix(1:9, nrow = 3, byrow = TRUE)
solve(g)

