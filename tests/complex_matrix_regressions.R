# Extra base-R regressions for complex-valued matrix inversion and RHS caching.
# This file does not modify the historical Coursera assignment source.
args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
if (length(file_arg) != 1L) stop("Run with Rscript", call. = FALSE)
script <- sub("^--file=", "", file_arg)
root <- normalizePath(file.path(dirname(normalizePath(script)), ".."))
source(file.path(root, "Rodri's R Programming Week 3 Peer-Graded Assignment (Lexical Scoping).R"), local = TRUE)

same <- function(actual, expected) {
    stopifnot(
        identical(dim(actual), dim(expected)),
        isTRUE(all.equal(actual, expected, tolerance = 1e-12))
    )
}

matrix_source <- matrix(c(2 + 1i, 1 - 2i, 3 + 0i, 4 + 1i), nrow = 2)
cache <- makeCacheMatrix(matrix_source)
original_inverse <- solve(matrix_source)
calculated <- cacheSolve(cache)
stopifnot(is.matrix(calculated), is.complex(calculated))
same(calculated, original_inverse)
same(cache$getInverse(), original_inverse)
same(suppressMessages(cacheSolve(cache)), original_inverse)

# The cache key includes the exact solve() arguments, including complex b.
rhs_one <- c(2 + 3i, 1 - 4i)
answer_one <- cacheSolve(cache, b = rhs_one)
same(answer_one, solve(matrix_source, b = rhs_one))
stopifnot(is.complex(answer_one), is.null(cache$getInverse()))
same(suppressMessages(cacheSolve(cache, b = rhs_one)), answer_one)

rhs_two <- c(4 - 2i, 3 + 2i)
answer_two <- cacheSolve(cache, b = rhs_two)
same(answer_two, solve(matrix_source, b = rhs_two))
stopifnot(!isTRUE(all.equal(answer_one, answer_two)))
stopifnot(is.null(cache$getInverse()))

# Named and positional RHS inputs are valid independent solve() keys.
positional <- cacheSolve(cache, rhs_one)
same(positional, solve(matrix_source, rhs_one))
stopifnot(is.null(cache$getInverse()))

rhs_matrix <- diag(c(1 + 1i, 2 - 1i))
same(cacheSolve(cache, b = rhs_matrix), solve(matrix_source, b = rhs_matrix))
stopifnot(is.null(cache$getInverse()))
same(cacheSolve(cache), original_inverse)
same(cache$getInverse(), original_inverse)

# The closure snapshots its input rather than observing later caller mutations.
matrix_source[1, 1] <- 999 + 4i
same(cache$get(), matrix(c(2 + 1i, 1 - 2i, 3 + 0i, 4 + 1i), nrow = 2))
same(suppressMessages(cacheSolve(cache)), original_inverse)

# Replacement invalidates both inverse and RHS results.
updated <- diag(c(2 + 1i, 3 - 2i))
cache$set(updated)
updated[1, 1] <- 999 + 0i
stopifnot(is.null(cache$getInverse()))
same(cache$get(), diag(c(2 + 1i, 3 - 2i)))
same(cacheSolve(cache), solve(cache$get()))

# A singular complex matrix must fail without caching an invalid inverse.
singular <- matrix(c(1 + 1i, 2 + 2i, 2 + 2i, 4 + 4i), nrow = 2)
cache$set(singular)
stopifnot(inherits(tryCatch(cacheSolve(cache), error = function(e) e), "error"))
stopifnot(is.null(cache$getInverse()))

# Recover after failure and keep manual inverse snapshots unchanged.
recovered <- diag(c(3 + 1i, 4 - 2i))
cache$set(recovered)
same(cacheSolve(cache), solve(recovered))
manual <- diag(c(0.25 + 0i, 0.5 - 0.25i))
cache$setInverse(manual)
manual[1, 1] <- 55 + 5i
same(cache$getInverse(), diag(c(0.25 + 0i, 0.5 - 0.25i)))

cat("PASS: complex matrix cache, RHS isolation, snapshotting and singular recovery\n")
