#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --nodes=1         # Max is 1
#SBATCH --ntasks=1        # Max is 16 (1/8 of 2x 64 AMD EPYC CPUs)
#SBATCH --cpus-per-task=1 # Max is 2 (Clustered Multithreading is on)
#SBATCH --gres=gpu:1      # Max is 1 (1 single A100)
#SBATCH --time=00:20:00   # Max is 4 hours

# module purge > /dev/null 2>&1
module load conda
module load gcc/11.2.0
module load cuda-11.7.1
module load cuda11.7/toolkit/11.7.1

export OMP_NUM_THREADS=1
export TMPDIR=$(pwd)
mkdir -p out
nsys profile --trace=cuda,nvtx,osrt ../../../../src/gravidy-gpu -i ../../../input/gravidy-default-input/09-nbody-p32768_m1.in -o out/output -t 1.0

