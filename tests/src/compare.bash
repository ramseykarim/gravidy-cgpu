# set -x

thedir=$(ls -t1 | head -n 1)
if [[ $thedir == "Makefile" ]]; then
  thedir=$(ls -t1 | head -n 2 | tail -n 1)
fi
echo thedir = $thedir
if [[ -d "$thedir"/gpu1 ]]; then
  python ../src/diff.py reference/gpu1/out/output.out.snapshot_00003 $thedir/gpu1/out/output.out.snapshot_00003 
  # diff "$thedir"/gpu1/out/output.out.snapshot_00003 $1/gpu1/out/output.out.snapshot_00003 
fi
