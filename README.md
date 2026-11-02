# datasciencecoursera

Coursework from 2020 for the Johns Hopkins **Data Science Specialization** on Coursera, kept as a record of where my R learning started.

## Contents

| File | What it is |
|---|---|
| `Rodri's R Programming Week 3 Peer-Graded Assignment (Lexical Scoping).R` | *R Programming*, week 3: `makeCacheMatrix()` and `cacheSolve()`, which cache the inverse of a matrix using closures and the `<<-` operator, so the inverse is computed once and reused |
| `HelloWorld.md` | First Markdown file created for the *Data Scientist's Toolbox* course |

## Try the caching functions

```r
source("Rodri's R Programming Week 3 Peer-Graded Assignment (Lexical Scoping).R")

m <- makeCacheMatrix(matrix(c(2, 1, 1, 3), nrow = 2))
cacheSolve(m)  # computes and stores the inverse
cacheSolve(m)  # prints "getting cached data" and returns the stored inverse
```

The matrix must be square and invertible.

## Automated verification

The historical assignment is preserved, with a small correctness fix to evaluate the initial matrix immediately. Run the [base-R regression suite](tests/run_tests.R) from the repository root:

```bash
Rscript --vanilla tests/run_tests.R
```

The tests verify cached reuse, invalidation, independence of separate closures, 1×1 and non-symmetric 3×3 matrices, failure handling, forwarding of `solve()` tolerance, and preservation of the initial matrix even if the caller changes its variable before the first read. [GitHub Actions](.github/workflows/r-tests.yml) runs these checks on Linux, Windows and macOS without additional R packages. This validates educational examples, not a production numerical library.

## Status

Historical learning material; the original assignment structure is preserved with minimal correctness fixes, documentation and regression tests. Current work is in [csv-quality-report](https://github.com/rodrix91/csv-quality-report), [ops-field-brief](https://github.com/rodrix91/ops-field-brief), and [inventory-policy-lab](https://github.com/rodrix91/inventory-policy-lab).
