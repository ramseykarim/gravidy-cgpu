
thedir=$(ls -t1 | head -n 1)
if [[ -d "$thedir"/gpu1 ]]; then
  cd "$thedir"/gpu1
  sbatch job.bash
fi

