import sys
from plot import get_tot_time, get_last_value
from glob import glob
import numpy as np
import matplotlib.pyplot as plt

# try:
#     plt.style.use(["science", "grid"])
# except FileNotFoundError:
plt.style.use(["ggplot"])

def main(folder, fig=None):
    style = 'gravidy'
    # formatter = {'gravidy': "*-nbody-*.out", 'base': "N*"}[style]
    Ns = []
    coll = {"ElapsedTime": [], "Nsteps": [], "GFLOPS": []}
    for f in glob(f"{folder}/N*"):
        N = int(f.split('/')[-1][1:])
        Ns.append(N)
        for item in coll:
            coll[item].append(get_last_value(f"{f}/output.gravidy.out.log", item))
    f, axs = plt.subplots(3, 1, figsize=[4, 6], sharex='all')
    ax = axs[0]
    Ns = np.log10(Ns)
    ax.scatter(Ns, coll["ElapsedTime"])
    ax.set(ylabel="Wall time (s)", yscale='log')
    ax = axs[1]
    ax.scatter(Ns, coll["Nsteps"])
    ax.set(ylabel="Nsteps", yscale='log')
    ax = axs[2]
    ax.scatter(Ns, coll["GFLOPS"])
    ax.set(xlabel="$\log_{10} N$", ylabel="GFLOPS", yscale='log')
    plt.tight_layout(h_pad=0.02)
    if fig is None:
        plt.show()
    else:
        plt.savefig(fig, dpi=300)

    # also write this as a table for alternate processing
    # note the first column (logN) is not sorted
    table = folder + '/benchmark.tab'
    np.savetxt(table, np.transpose([Ns,coll["ElapsedTime"],coll["Nsteps"],coll["GFLOPS"]]),
               header='log(N) ElapsedTime  Nsteps  GFLOPS')
    print("Wrote ",table)

if __name__ == "__main__":
    if len(sys.argv) >= 3:
        fig = sys.argv[2]
    else:
        fig = None
    main(sys.argv[1], fig)
