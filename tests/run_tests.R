# Repeatable base-R checks for preserved 2020 coursework.
# Rscript --vanilla tests/run_tests.R
args <- commandArgs(trailingOnly = FALSE)
path_arg <- grep("^--file=", args, value = TRUE)
if (length(path_arg) != 1L) stop("Use Rscript to run these tests")
script <- sub("^--file=", "", path_arg)
root <- normalizePath(file.path(dirname(normalizePath(script)), ".."))
source(file.path(root, "Rodri's R Programming Week 3 Peer-Graded Assignment (Lexical Scoping).R"), local = TRUE)

check_inverse <- function(actual, expected) {
    stopifnot(is.matrix(actual),
              identical(dim(actual), dim(expected)),
              isTRUE(all.equal(actual, expected, tolerance = 1e-12)))
}

original <- matrix(c(2, 1, 1, 3), nrow = 2)
cache <- makeCacheMatrix(original)
stopifnot(identical(sort(names(cache)), sort(c("set", "get", "setInverse", "getInverse"))),
          identical(cache$get(), original),
          is.null(cache$getInverse()))
first <- cacheSolve(cache)
check_inverse(first, solve(original))
check_inverse(cache$getInverse(), first)
check_inverse(suppressMessages(cacheSolve(cache)), first)

# A cache hit skips even a solver that would fail on the source matrix.
singular <- matrix(c(1, 2, 2, 4), nrow = 2)
sentinel_cache <- makeCacheMatrix(singular)
sentinel_cache$setInverse(diag(2))
check_inverse(suppressMessages(cacheSolve(sentinel_cache)), diag(2))

second <- matrix(c(4, 1, 2, 3), nrow = 2)
cache$set(second)
stopifnot(identical(cache$get(), second), is.null(cache$getInverse()))
check_inverse(cacheSolve(cache), solve(second))
stopifnot(!isTRUE(all.equal(first, cache$getInverse())))

# Independent lexical closures must not share their inverse caches.
a <- makeCacheMatrix(diag(c(2, 3)))
b <- makeCacheMatrix(diag(c(5, 7)))
check_inverse(cacheSolve(a), solve(a$get()))
b_inverse <- cacheSolve(b)
a$set(diag(c(6, 9)))
stopifnot(is.null(a$getInverse()))
check_inverse(suppressMessages(cacheSolve(b)), b_inverse)

# 1x1 and non-symmetric 3x3 inverses are valid.
small <- makeCacheMatrix(matrix(8, nrow = 1))
check_inverse(cacheSolve(small), matrix(1 / 8, nrow = 1))
large_matrix <- matrix(c(3, 0, 0, 1, 4, 0, 2, 1, 5), nrow = 3)
large <- makeCacheMatrix(large_matrix)
check_inverse(cacheSolve(large), solve(large_matrix))
stopifnot(isTRUE(all.equal(large_matrix %*% large$getInverse(), diag(3), tolerance = 1e-12)))

# Failures are not cached; the optional solve() tolerance is forwarded.
bad <- makeCacheMatrix(singular)
stopifnot(inherits(tryCatch(cacheSolve(bad), error = function(e) e), "error"),
          is.null(bad$getInverse()))
tolerant <- makeCacheMatrix(diag(c(1, 1000)))
stopifnot(inherits(tryCatch(cacheSolve(tolerant, tol = 0.5),
                            error = function(e) e), "error"),
          is.null(tolerant$getInverse()))
check_inverse(cacheSolve(tolerant, tol = 0), solve(tolerant$get(), tol = 0))

# R evaluates function arguments lazily. A newly created cache must
# preserve the matrix at construction time even before its first get().
initial_source <- diag(c(3, 4))
unread_cache <- makeCacheMatrix(initial_source)
initial_source[1, 1] <- 99
check_inverse(unread_cache$get(), diag(c(3, 4)))
check_inverse(cacheSolve(unread_cache), diag(c(1 / 3, 1 / 4)))
check_inverse(suppressMessages(cacheSolve(unread_cache)), unread_cache$getInverse())

# Rebinding the caller's variable must not change an unread closure either.
initial_reassigned <- diag(c(5, 6))
unread_reassigned <- makeCacheMatrix(initial_reassigned)
initial_reassigned <- diag(c(10, 12))
check_inverse(unread_reassigned$get(), diag(c(5, 6)))
check_inverse(cacheSolve(unread_reassigned), diag(c(1 / 5, 1 / 6)))


# Results computed with different solve() options must not share a cache.
# A strict tolerance should still fail after a previously successful lenient solve.
ill_conditioned <- diag(c(1, 1000))
options_cache <- makeCacheMatrix(ill_conditioned)
lenient <- cacheSolve(options_cache, tol = 0)
check_inverse(lenient, solve(ill_conditioned, tol = 0))
stopifnot(inherits(
    tryCatch(cacheSolve(options_cache, tol = 0.5), error = function(e) e),
    "error"
))
# The failed attempt must not overwrite the valid, matching cached entry.
check_inverse(options_cache$getInverse(list(tol = 0)), lenient)
stopifnot(is.null(options_cache$getInverse(list(tol = 0.5))))
check_inverse(suppressMessages(cacheSolve(options_cache, tol = 0)), lenient)

# A solve(A, b) solution is not the inverse: distinguish RHS values and
# avoid exposing a RHS solution through the original getInverse() accessor.
rhs_cache <- makeCacheMatrix(original)
rhs_one <- cacheSolve(rhs_cache, b = c(3, 5))
stopifnot(isTRUE(all.equal(rhs_one, solve(original, b = c(3, 5)))))
stopifnot(is.null(rhs_cache$getInverse()))
stopifnot(isTRUE(all.equal(
    suppressMessages(cacheSolve(rhs_cache, b = c(3, 5))), rhs_one
)))
rhs_two <- cacheSolve(rhs_cache, b = c(7, 11))
stopifnot(isTRUE(all.equal(rhs_two, solve(original, b = c(7, 11)))))
stopifnot(!isTRUE(all.equal(rhs_one, rhs_two)), is.null(rhs_cache$getInverse()))
positional <- cacheSolve(rhs_cache, c(3, 5))
stopifnot(isTRUE(all.equal(positional, rhs_one)), is.null(rhs_cache$getInverse()))
rhs_matrix <- diag(2)
check_inverse(cacheSolve(rhs_cache, b = rhs_matrix), solve(original, b = rhs_matrix))
stopifnot(is.null(rhs_cache$getInverse()))
check_inverse(cacheSolve(rhs_cache), solve(original))
check_inverse(rhs_cache$getInverse(), solve(original))

# Lazy setter and manual inverse arguments must snapshot their inputs.
replacement <- diag(c(3, 7))
rhs_cache$set(replacement)
replacement <- diag(c(99, 99))
check_inverse(rhs_cache$get(), diag(c(3, 7)))
stopifnot(is.null(rhs_cache$getInverse()))
check_inverse(cacheSolve(rhs_cache), diag(c(1 / 3, 1 / 7)))
manual_inverse <- diag(c(0.25, 0.5))
rhs_cache$setInverse(manual_inverse)
manual_inverse <- diag(c(9, 9))
check_inverse(rhs_cache$getInverse(), diag(c(0.25, 0.5)))
manual_args <- list(tol = 0)
rhs_cache$setInverse(diag(c(0.25, 0.5)), manual_args)
manual_args$tol <- 0.5
check_inverse(rhs_cache$getInverse(list(tol = 0)), diag(c(0.25, 0.5)))
stopifnot(is.null(rhs_cache$getInverse(list(tol = 0.5))))

cat("PASS: solve options and RHS remain cache-safe; setters snapshot values\\n")

cat("PASS: original R matrix caching, independence, dimensions and errors\n")
