makeCacheMatrix <- function(x = matrix()) {
      # Evaluate the original matrix before R's lazy argument can change.
      force(x)
      inv <- NULL
      invArgs <- list()

      set <- function(y) {
            force(y)
            x <<- y
            inv <<- NULL
            invArgs <<- list()
      }
      get <- function() x

      # Keep the four historical accessors while tracking which solve()
      # options produced the cached result.
      setInverse <- function(inverse, solveArgs = list()) {
            force(inverse)
            force(solveArgs)
            inv <<- inverse
            invArgs <<- solveArgs
      }
      getInverse <- function(solveArgs) {
            if (missing(solveArgs)) {
                  # The public accessor is for inverses, not solve(A, b)
                  # solutions. A right-hand side may be named or positional.
                  labels <- names(invArgs)
                  hasRhs <- length(invArgs) > 0L &&
                        (is.null(labels) ||
                         any(is.na(labels) | labels == "" | labels == "b"))
                  if (hasRhs) return(NULL)
                  return(inv)
            }
            if (identical(solveArgs, invArgs)) return(inv)
            NULL
      }
      list(set = set, get = get, setInverse = setInverse, getInverse = getInverse)
}

cacheSolve <- function(x, ...) {
      solveArgs <- list(...)
      inv <- x$getInverse(solveArgs)
      if (!is.null(inv)) {
            message("getting cached data")
            return(inv)
      }
      # A changed tolerance or RHS must run solve() again. Only successful
      # results replace the cached value and its exact argument list.
      inv <- do.call(solve, c(list(x$get()), solveArgs))
      x$setInverse(inv, solveArgs)
      inv
}
