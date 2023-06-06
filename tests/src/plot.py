import sys
import numpy as np
import pandas as pd

def read_log(log):
    headers = ["id",    "IteTime",           "Iter",         "Nsteps",              "Energy",           "RelE",           "CumE",     "ElapsedTime",      "GFLOPS"]
    npdata = np.loadtxt(log)
    data = {header: npdata[:, i] for i, header in enumerate(headers)}
    # data = pd.DataFrame(npdata, columns=headers)
    # print(data.id, data.Nsteps.values)
    return data

    
def get_tot_time(log):
    return read_log(log).ElapsedTime.values[-1]


def get_last_value(log, quant):
    # print(read_log(log).__dict__.item)
    return read_log(log)[quant][-1]

    
def main(log):
    print(get_tot_time(log))


def plot_gravidy_log(log):
    return


if __name__ == "__main__":
    main(sys.argv[1])
