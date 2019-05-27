# mnlogit

* I recovered this code from the CRAN archives.
* I am not the author of the package.
* I am not the maintainer of it either.

## installation

* you need a c compiler that can handle the `-fopenmp` flag for openMP support. 
* to test for that, you should copy this into a text file:
    ```c
    #include <omp.h>
    #include <stdio.h>
    int main() {
        #pragma omp parallel
        printf("Hello from thread %d, nthreads %d\n", omp_get_thread_num(), omp_get_num_threads());
    }
    ```
* and compile it with a command like
    ```
    gcc -fopenmp test.c -o test.x
    ```
* If that worked you should see this upon execution of that program:
    ```
    ➜  ~ ./test.x
    Hello from thread 3, nthreads 8
    Hello from thread 1, nthreads 8
    Hello from thread 2, nthreads 8
    Hello from thread 4, nthreads 8
    Hello from thread 5, nthreads 8
    Hello from thread 6, nthreads 8
    Hello from thread 0, nthreads 8
    Hello from thread 7, nthreads 8
    ```
* If not, you need to get a modern c-compiler. a good option for mac users is to via [homebrew](http://brew.sh/). just type `brew install gcc`.
* Depending on the version you get (most recent), you will have something like `gcc-x.y` available on your command line. I have `gcc-9.2` for example. We need to tell `R` to use *that* particular compiler when we build `mnlogit` (or any other package). 
* You achieve that by editing the file `~/.R/Makevars`. You probably have to create `~/.R`.
* You could just copy my version. there is a bunch of comments to build different packages. you could just comment out different things for different builds.
    ```
    # floswald 2019
    # based on http://lists.r-forge.r-project.org/pipermail/rcpp-devel/2012-May/003845.html

    ## for C code
    #CFLAGS=-g -O3 -Wall -pipe -pedantic -std=gnu99 -march=native
    #CFLAGS=-O3 -g0 -Wall -pipe -pedantic -std=gnu99 -I/usr/local/cuda/include
    #CFLAGS=-ggdb
    CFLAGS=-g -O3 -w -fopenmp -mtune=native

    ## for C++ code
    #CXXFLAGS=-g  -Wall -O0 -gmodules
    #CXXFLAGS=-g0 -O3 -Wall -pipe -pedantic -Wno-variadic-macros
    #CXXFLAGS=-std=c++0x -g  -O3 -Wall -pipe -pedantic -Wno-variadic-macros
    #CXXFLAGS=-ggdb -w -DBZ_DEBUG
    #CXXFLAGS=-O3 -w -DN_DEBUG -UNDEBUG -DARMA_NO_DEBUG
    CXXFLAGS= -O3 -Wall -pedantic -mtune=native -pipe -fopenmp


    # just a test before RcppArmadillo undef'ed thispp
    #PKG_CPPFLAGS=        -UNDEBUG

    ## for Fortran code
    #FFLAGS=-g -O3 -Wall -pipe
    FFLAGS=-O3 -g0 -Wall -pipe
    ## for Fortran 95 code
    #FCFLAGS=-g -O3 -Wall -pipe
    FCFLAGS=-O3 -g0 -Wall -pipe
    FLIBS=-L/usr/local/lib/gcc/9 -lgfortran -lquadmath -lm


    ## Choose C and C++ compiler versions

    # gcc 9.2
    VER=9
    CC=gcc-$(VER)
    CXX=g++-$(VER)
    #CXX=clang
    FC=gfortran
    F77=gfortran
    ```
