

# Notes and Documentation

This document is intended to record pertinent details, discoveries, or
investigations of this code.


This is a work-in-progress.

I might even want to break this into sub-documents.


# Checking Reducibility

This is done in the file `reduce.c`

## How to Invoke

Invoking `reduce` is quite simple. For example, to check reducibility of
Robertson et al's unavoidable set, run:

```bash
$ reduce robertson/unavoidable.conf
```

## Data structures

This program makes use of several data structures, but those data structures
take the form of a large two-dimensional array of `long` values. This is
unfortunate for two reasons: the data structure is opaque without external
explanation, and the fact that the size of `long` is platform-dependent.

An important thing to note is that **many arrays are 1-indexed**, with index zero
representing a "length" or other metadata.

### `tp_confmat`

See section 1, "Configurations", of `RSST/reduce.pdf`.

This data structure represents a configuration.

Assume the declaration `tp_confmat A;` has been made.

#### The header

`A[0]` serves a different purpose from the rest of the entries: it is like a
header, giving information about the configuration.

The first four values of the header, `A[0][0..3]` have the following meanings:

1. `A[0][0]`: This is the number of vertices in the configuration. This is also
   frequently named `n` in the code.
2. `A[0][1]`: This is the number of vertices in the outer ring. This is also
   frequently named `r` in the code.
3. `A[0][2]`: The number of canonical colourings in \cal{C}(K). Apparently, this
   is the number of colourings that can be extended to the configuration.
4. `A[0][3]`: The number of canonical colourings in \cal{C}'(K). Apparently,
   this is the number of colourings in the maximal consistent subset.

#### The contract

The values `A[0][4..12]` (inclusive) specify the "contract" of the
configuration. This is related to C- versus D- reducibility, I believe.
D-Reducible configurations do not need a contract, and `A[0][4] == 0`.

`A[0][4]` is the number of edges in the contract (range: `0..4` inclusive). The
remaining values are that many edges, specified as pairs of vertices.

#### Vertices

The remaining rows of the matrix (`A[i]` for `i > 0`) are the vertices of the
configuration.

The ring vertices are listed first, from `A[1]` to `A[A[0][1]]`.

Each vertex is as follows:

* `A[i][0]` is the number of neighbors this vertex has.
* `A[i][j]`, `j > 0` is the index of a neighboring vertex, listed clockwise.

Additionally, for ring vertices,

* `A[i][1]` is the following ring vertex
* `A[i][2]` is the previous ring vertex.

#### Well-Formedness

`RSST/reduce.pdf` specifies 7 conditions for a well-formed configuration matrix.

`n` is the number of vertices, and `r` is the number of ring vertices. `d(i)` is
an alias for `A[i][0]`, the degree of vertex `i`.

1. `2 <= r < n`
2. For ring vertices, `3 <= d(i) <= n-1`. For non-ring vertices,
   `5 <= d(i) <= n-1`
3. All vertex indices are in bounds (`1 <= A[i][j] <= n`)
4. For ring vertices `i`, `A[i][1]` is the next ring vertex (`i+1`), and
   `A[i][d(i)]` is the previous ring vertex (`i-1`). (both wrap around to
   zero/`r`)
5. The sum of all `d(i)` is `6*n - 6 - 2*r`
6. For non-ring vertices, there are at most two neighbors `j` such that:
    * `j` is not a ring vertex
    * `j+1` is a ring vertex
   If there are two such `j`, for both `j+2` is not a ring vertex
7. a
   * Let `i` be a vertex.
   * If `i` is a ring vertex, let `j` be any neighbor index of `i` except the
     last.

   * Otherwise let `j` be any neighbor index of `i`.

   * Let `k` be the vertex `A[i][j]`.

   * There exists some neighbor index `p` of `k` such that

    1. `A[i][j+1] == A[k][p]` (wrap around `j` if `j = d(i)`)
    2. `A[k][p+1] == i` (wrap around `p` if `p = d(k)`)

   Because this definition is still hard to understand, have a diagram.

   In this diagram, an edge labeled `j` from `i` to `k` means `A[i][j] = k`.

   ![Graph Demonstrating Property 7](property7.svg)

### `tp_edgeno`

An "edge numbering". For some reason, it is defined as having dimensions
suitable for indexing with edges (`typedef long tp_edgeno[EDGES][EDGES]`), but
the comment on the function `strip()` states that `tp_edgeno` is indexed by
vertices. (The code of `strip()` corroborates this.)

Assume the declaration `tp_edgeno E;`

Much like `tp_confmat`, `E[0]` is sort of like a header.

### `tp_angle`

I'm not sure what this is for.


## Implicit data structures

However, there are several other data structures that were not given names.

### The live set, `live`

I dunno.

### `real`

A bitset. Used for something.

### Contracts

A contract has two meanings in the program:

1. for `tp_confmat A`, the values `A[0][4..12]`.
2. An array of long values. (used as paramter to `findangles`, etc.).

This section discusses the latter definition.

### `simatchnumber`

An array of magic numbers. The name is probably derived from "[number] of
[si]gned [match]ings". The values of the numbers are significant, but I do not
know how they were computed, so therefore, they are magic.

TODO: RSST vs. JPS definitions of `simatchnumber`.

Robertson et al and Steinberger have slightly different definitions of
`simatchnumber`. Steinberger's contains two extra entries (17 instead of 15),
most likely related to the fact that Steinberger uses configurations with larger
ring sizes. In fact, in `main()`, `simatchnumber` is indexed by the ring size to
compute the size of `real`.

## That one place with the `char`

The function `checkreality()`.

There is one place in the program that uses a `char` to select bits from an
array of `char`s (an index into the `live` set?). Unfortunately, the method by
which this is done is to repeatedly left-shift the char, and if the char
overflows wrapping to zero, to increment the index to the next byte.

Doubly annoying is the fact that this char is hidden behind a pointer that is
threaded through a lot of stuff, especially augment, so it is hard to understand
its provenance and purpose.

## How the program works

I'm still working on this part.


* * *


# Discharging

This is done in the file `discharge.c`.

## How to Invoke

Most relevantly, the input to `discharge` is a *presentation file*, along with
an unavoidable set and a set of *rules*.

for example, to test Robertson et al's proof script of degree 7, the following
command would be invoked.

```bash
$ discharge robertson/present7 robertson/unavoidble.conf robertson/rules 0 1
#           ^                  ^                         ^               ^ ^
#           |                  |                         |               | |
#           |                  The unavoidable set       The rules file  | printing mode
#           The presentation file                                        line number
```

The final two parameters need explanation, which can be found by looking at the
definition of `main()`, in particular the parsing of the command line arguments.

### Printing mode

This option controls the verbosity. It takes values 1, 2, 3, or 4.

1. Print only the input line.
2. Print "basic" information.
3. Print hubcaps but not reducibility.
4. Print hubcaps and reducibility.

### Line number

This option controls what lines have information about them printed.

* If this option is `0`, information is printed about all lines (as above).
* If positive, only that line has its information printed.
* If negative, no line has information printed. However, I suspect that this
  behavior is accidental, and thus should not be relied upon.


## How it works

I have negligible idea.

Each line of the presentation file is like a command or an operation:

TODO: Enumerate operations (see the `switch` statement in `main()`)
TODO: Describe each operation and how it works


* * *


# References

Mostly, these notes come the code itself and the documents bundled with this
code, in the directory `RSST/`.

* `reduce.pdf`: Reducibility in the Four-Color Theorem
* `discharge.pdf`: Discharging Cartwheels

Additionally, it may be helpful to look at other papers on proofs of the
Four-Color Theorem, such as:

* Robertson et al: The Four Color Theorem (1997)
* Steinberger: An Unavoidable Set of D-Reducible Configurations (2009)


* * *


# File Formats

The files used as input to `reduce` and `discharge` have particular formats. I
shall attempt to document them here.

### Configuration File

(As a side note, this is a file containing configurations, not a file that
configures something)

A configuration file is a series of configurations, separated by blank lines.
The configuration file is read by the function `ReadConf()`, which is duplicated
across `reduce.c` and `discharge.c`.

The format for each configuration closely mirrors the definition of a
configuration matrix.

The first line of a configuration is the name of the configuration. The code
does not make use of it.

The next line is the header: four integers. These integers correspond exactly to
the header of a configuration matrix.

The next line is the contract. It is an integer followed by twice as many
integers. These are read into `A[0][5..13]`, as specified in the definition of a
configuration matrix.

The next rows are the vertices. Row `i` of the vertices starts with the integer
`i`, then the degree `d` of the vertex, then `d` integers.

There are then *coordinates*, one for each vertex. The coordinates are stored 8
to a line, but the last may have fewer. I do not understand the purpose of these
"coordinates", especially because `reduce.c` completely ignores them.
Furthermore, while RSST include coordinate data, Steinberger sets each
coordinate value to 1024.

Finally, a configuration must be followed by a blank line.

### Presentation File

### Rules File




* * *

# The `augment()` crash

Initially, when running `reduce` on Steinberger's unavoidable set
(`U_2822.conf`), some machines would see the program crash with `Abort trap: 6`.

This error was eventually localized to indexing the parameter `weight` of
`augment()` out-of-bounds.

The function `augment()` passes its parameters `depth` and `weight` into the
function `checkreality()`. `checkreality()` then uses `depth` to index `weight`.
Because `depth` is equal to the recursion depth of `augment()`, a configuration
that caused `augment()` to recurse more than eight levels caused a
index-out-of-bounds on `weight`, which was declared `long *weight[8]`.

To fix the problem, the constant `8` in the declaration (and several other
places) were extracted out to a constant `AUGMENT_WEIGHT_SIZE` (a better name
would be good) and `AUGMENT_WEIGHT_SIZE` was increased from 8 to 16.

Explain why it was crashing, augment recursion, `weights`, the fix.


<!-- vim: set et sts=4 sw=4 tw=80: -->
