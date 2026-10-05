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

## Status

Archived learning material; not maintained. My current work is in [csv-quality-report](https://github.com/rodrix91/csv-quality-report).
