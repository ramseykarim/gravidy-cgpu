#!/bin/bash
#SBATCH --partition=mig
#SBATCH --nodes=1         # Max is 1
#SBATCH --ntasks=16       # Max is 16 (1/8 of 2x 64 AMD EPYC CPUs)
#SBATCH --cpus-per-task=2 # Max is 2 (Clustered Multithreading is on)
##SBATCH --gres=gpu:1      # Max is 1 (1 single A100)
#SBATCH --time=00:20:00    # Max is 4 hours

module purge > /dev/null 2>&1
module load conda
module load gcc/11.2.0
module load openmpi/gcc/64/4.1.2

export OMP_NUM_THREADS=16
mkdir -p out
../../../../src/gravidy-mpi -i ../../../../input/07-nbody-p8192_m1.in -o out/output.gravidy -t 5 2>&1 >> "out/log.txt"

