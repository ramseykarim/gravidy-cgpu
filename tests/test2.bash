# run tests for this code
# Usage: ./test1.bash

set -e 

# create a folder with current date and time in EST time
# date and time format in EST: YYYY-MM-DD_HH:MM:SS_EST
date_time=$(TZ=":US/Eastern" date +"%Y-%m-%d_%H:%M:%S_EST")
folder_name="test_$date_time"
mkdir -p "output/test2/$folder_name"
cd "output/test2/$folder_name"

for power in {1..4}
do
  N=$((2**($power+6)))
  echo "N = $N"
  input="0%power-nbody-p$N_m1.in"
  thedir="0%power-nbody-p$N_m1.in"
  mkdir -p $thedir
  cd $thedir
  ../../../../../src/gravidy-cpu -i ../../input/plummer/nbody_unit/plummer_N$N/gravidy.txt -o output.gravidy -t 50 2>&1 >> log.txt
  cd ..
done

python ../src/benchmark.py . benchmark.jpg
