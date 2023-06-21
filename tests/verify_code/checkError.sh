#!/bin/bash

#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH -t 2:00:00
#SBATCH --cpus-per-task=1
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1

if test -f "./gravidy-gpu"; then
  echo "testing gpu version"
  ./gravidy-gpu -i p256.in -t 1 -z 1 > p256.in.out.txt
  mv p256.in.out.snapshot_00002 gpuFinal.dat
  rm p256.in.out*
  python diff.py gpuFinal.dat
fi

if test -f "./gravidy-cpu"; then
  echo "testing cpu version"
  ./gravidy-cpu -i p256.in -t 1 -z 1 > p256.in.out.txt
  mv p256.in.out.snapshot_00002 cpuFinal.dat
  rm p256.in.out*
  python diff.py cpuFinal.dat
fi

if test -f "./gravidy-mpi"; then
  echo "testing mpi version"
  mpirun ./gravidy-mpi -i p256.in -t 1 -z 1 > p256.in.out.txt
  mv p256.in.out.snapshot_00002 mpiFinal.dat
  rm p256.in.out*
  python diff.py mpiFinal.dat
fi
