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

cat("PASS: original R matrix caching, independence, dimensions and errors\n")
