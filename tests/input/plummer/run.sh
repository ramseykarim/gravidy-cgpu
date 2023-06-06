set -e 

# use mcluster to generate a star cluster with the initial condtion: -N Kroupa (2001) IMF, -b % binary (Kroupa 1995 a,b Sana 2012 ..., see mcluster manual) 
# The initial condition for NBODY6++GPU is created with -C 5, this is used to generated initial condtion for PeTar; -C 3 is used for table of stars

mkdir nbody_unit
cd nbody_unit

for i in {3..18}
do
  N=$((2**$i))
  echo $N
  thedir="plummer_N$N"
  mkdir -p $thedir
  cd $thedir
  mcluster -N $N -C 3 -u 0 >mc.log
  cd ..
done

# convert
python convert.py

# mcluster -N 8 -C 3 -u 1 >mc.log
