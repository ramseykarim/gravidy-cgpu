
import numpy as np
import sys

# d0 = np.loadtxt('p256_ref.dat')[:,2:]
d0 = np.loadtxt(sys.argv[1])[:,2:]
args = sys.argv[2:]
for arg in args:
  d = np.loadtxt(arg)[:,2:]
  diffs = np.sum((d0-d)**2, axis=1)**0.5
  print(arg)
  print("average error: %.5e \nmaximum error: %.5e \n" % (np.mean(diffs), np.max(diffs)) )

