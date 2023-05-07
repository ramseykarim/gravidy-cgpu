# GraviDy -  Gravitational Dynamics

Check the original README in the master branch, or the original repo (https://github.com/cmaureir/gravidy).

## About

**GraviDy** is a new GPU, direct-summation N-body integrator written from scratch and based on the
Hermite scheme. The most important features of the code are:

 * Written in C/C++,
 * Using parallel computing techniques and libraries like OpenMP, MPI and CUDA,
 * full double-precision resolution,
 * its high modularity, which allows users to readily introduce new physics into it,
 * the exploitation of all high-performance computing resources available,
 * its maintenance and improvement cycle,
 * the fact that the code is publicly released under a BSD license and will be maintained via planned, public, regular updates.

Publication reference

Maureira-Fredes, C and Amaro-Seoane, P. ["GraviDy, a GPU modular, parallel direct-summation N−body integrator: Dynamics with softening"](https://arxiv.org/abs/1702.00440), MNRAS, vol. 473, pp. 3113-3127, Jan . 2018.

## How to compile?

### On UMD Astronomy machines

```sh
git clone https://github.com/chongchonghe/gravidy
cd gravidy/src
make cpu CXX="g++11"
```

## Licence

```
Copyright 2014 Cristián Maureira-Fredes

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
