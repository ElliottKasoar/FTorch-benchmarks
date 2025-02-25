# Benchmark the fortran to pytorch coupling library

Recent results using
[MiMA](https://github.com/DataWaveProject/MiMA-machine-learning) showed a
moderate _slowdown_ when using our Fortran to PyTorch direct coupling library.
This repository contains code to investigate that surprising result.

## Requirements

1) [FTorch](https://github.com/Cambridge-ICCS/FTorch) repository.
2) CMake >= 3.14
3) Python<sup>*</sup>
4) a virtual environment with PyTorch and NumPy installed

<sup>*</sup> _You may need to download header files for the Python C API. On Ubuntu, this can be done using `sudo apt-get install python-dev` (replacing `python` with `python3.x` for specific Python versions)._

## Build instructions
Install the [FTorch](https://github.com/Cambridge-ICCS/FTorch) library if you haven't already got it. Follow the installation instructions on the README of that repository. 

In your FTorch-benchmark repository, create a build directory and run `cmake` as follows, noting the cmake options below:

```
mkdir build
cd build
cmake ..
```
You may need to specify the path to PyTorch with the option `-DCMAKE_PREFIX_PATH=<full-path-to-PyTorch>`.

You may also need to specify the path to the CMake library files by using the option `-DFTorch_DIR=<full-path-to-cmake-lib-files>/lib/cmake/`. This is the location you specified when installing FTorch, if you used `-DCMAKE_INSTALL_PREFIX`. The default location is /usr/local. 

You can specify `cmake` options like `-DCMAKE_BUILD_TYPE=RelWithDebInfo`
or `-DCMAKE_Fortran_COMPILER=ifort` if you need.

Then, run `make` and the program(s) should build.

### Profiling build type
There is now a custom build type for `cmake` you can set with
`-DCMAKE_BUILD_TYPE=Profile`.  This will add the necessary options
for instrumented profiling, in the `gprof` style.

## Running instructions
You'll need the Python virtual environment loaded.  Run the program:
```
benchmarker_forpy <path-to-model-dir> <python-module-to-load> <N>
```
Where `<path-to-model-dir>` is the path to where the PyTorch model resides,
`<python-module-to-load>` is the Python file to load.  It should export
`initialize` and `compute_reshape_drag` methods.  See the Wavenet 2 model
provided.  `<N>` is the number of times to run the inference.

### Profiling using `-DCMAKE_BUILD_TYPE=Profile`
Run `cmake` with the `-DCMAKE_BUILD_TYPE=Profile` option and make the code.
Then, after you run it, a `gmon.out` file will be created in the current
directory.  To process this file you must do:
```
gprof <path-to-benchmarker_forpy> <path-to-gmon.out>
```
By default this gets you the default flat profile followed by the call
graph.  Check the other options to `gprof`.

## Large stride models

There are two programs `./benchmarker_large_stride_torch` and `./benchmarker_large_stride_forpy` that produce a synthetic
benchmark of the forpy and direct coupled approaches. These cases are as simple as possible -- designed to only focus on the
implementations and not the content. They take a random NxN tensor (rank 2) as input and then multiply this by 2. Because this
would be entirely symmetric we have also multiple the first off-diagonal element `(1,2)` (in fortran notation) of the tensor.

After the forward models are run, there is an assert which checks the Neural Net has indeed run correctly.

These tests are built as part of the benchmark suite. I recommend making a simple bash script for compiling and running the two
tests.

```bash

#!/usr/bin/env bash

mkdir -p build
cd build

cmake -D CMAKE_Fortran_COMPILER="$FC" \
    -D CMAKE_PREFIX_PATH="..." \
    -D FTorch_DIR="..." \
    -D CMAKE_BUILD_TYPE=Debug \
    -D USETS=1 \
    ..

make

N=10      #number of times to run forward model
NSIZE=128  #size of N x N tensor
./benchmarker_large_stride_torch ../large_stride_model saved_large_stride_model_cpu.pt $N $NSIZE
./benchmarker_large_stride_forpy ../large_stride_model run_emulator_stride             $N $NSIZE

```

The preprocessor macro `USETS` can be enabled by passing CMake the option `-D USETS=1`. This will enable the forpy test to use a
pre-saved torchscript `.pt` file. If this is omitted then forpy will generate a model in the python runtime environment.


## Results

The results for a 512 x 512 tensor are shown below. These tests were run on an `Intel(R) Core(TM) i5-6400` cpu `@ 2.70GHz`,
using `gcc version 11.3.0 (Ubuntu 11.3.0-1ubuntu1~22.04.1)` - built in `Debug` mode.

For the synthetic test they appear to show that the forpy and directly-coupled approaches are essentially the same speed.

### Directly coupled approach
```
 ====== DIRECT COUPLED ======
Running model: ../large_stride_model/saved_large_stride_model.pt 10 times.
PASSED :: [check iteration        1 (     3.237 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        2 (     2.023 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        3 (     2.027 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        4 (     1.994 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        5 (     2.008 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        6 (     2.088 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        7 (     2.052 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        8 (     2.038 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        9 (     2.033 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration       10 (     2.081 s)] maximum relative error =  0.0000E+00
 min  time taken (s):    1.99393845
 max  time taken (s):    3.23659897
 mean time taken (s):    2.15805435
```

### Forpy approach (using torchscript saved model)
```
 ====== FORPY ======
Running model: ../large_stride_model/run_emulator_stride 10 times.
 load torchscript model
PASSED :: [check iteration        1 (     3.141 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        2 (     1.952 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        3 (     1.956 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        4 (     1.960 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        5 (     1.973 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        6 (     1.987 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        7 (     1.979 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        8 (     1.971 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        9 (     1.970 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration       10 (     1.958 s)] maximum relative error =  0.0000E+00
 min  time taken (s):    1.95231390
 max  time taken (s):    3.14081192
 mean time taken (s):    2.08462572
```

### Forpy approach (using python runtime)
```
 ====== FORPY ======
Running model: ../large_stride_model/run_emulator_stride 10 times.
 generate model in python runtime
PASSED :: [check iteration        1 (     3.468 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        2 (     3.474 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        3 (     3.476 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        4 (     3.451 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        5 (     3.444 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        6 (     3.502 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        7 (     3.451 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        8 (     3.480 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration        9 (     3.440 s)] maximum relative error =  0.0000E+00
PASSED :: [check iteration       10 (     3.442 s)] maximum relative error =  0.0000E+00
 min  time taken (s):    3.43997002
 max  time taken (s):    3.50229836
 mean time taken (s):    3.46279597
```
