import sys
import numpy as np
from glob import glob


def convert(ifmt, fi, ofmt, fo):

    # read
    if ifmt == "mcluster":
        particles = np.loadtxt(fi, skiprows=1)
    elif ifmt == "spacehub":
        data = np.loadtxt(fi, skiprow=1)
        particles = data[:, 2:]

    # write
    if ofmt == "gravidy":
        ids = np.arange(particles.shape[0])[:, np.newaxis]
        out = np.hstack((ids, particles))
        fmt = ["%d"] + ["%.18e"] * 7
        np.savetxt(fo, out, delimiter=' ', fmt=fmt)

    return

def main():
    for f in glob("*/*/test.txt"):
        convert("mcluster", f, "gravidy", f.replace("test.txt", "gravidy.txt"))
    return

main()