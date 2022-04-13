from matplotlib import offsetbox
import seaborn as sns
import matplotlib as mpl
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import os
from matplotlib.ticker import MaxNLocator

# Get data
cwd = os.path.dirname(os.path.abspath(__file__))
df = pd.read_csv(os.path.join(cwd, 'data.csv'))
sns.set_theme()
df = df[df.Nodes > 25]
df["Nodes"] = (df["Nodes"] / 6)**(0.5)

df.loc[df.Language == 'GT4Py & DaCe', 'Language'] = 'Python'

average_ftn = np.average(df[(df.Language == "FORTRAN")].Time)
dfpython = df[df.Language != "FORTRAN"]


def plot_single(df: pd.DataFrame, name: str):
    plt.figure(figsize=(7, 4))
    ax = sns.lineplot(data=df,
                      x='Nodes',
                      y='Time',
                      hue='Language',
                      style='Language',
                      markers=True,
                      estimator=np.median,
                      ci=95)

    # Plot speedups
    grid_sizes = list(df[(df.Language == 'Python')]['Nodes'].unique())
    grid_sizes = list(sorted(grid_sizes))
    grid_sizes2 = ['54', '96', '150', '216', '600', '1944']
    kms = ['15.62', '11.72', '9.38', '7.81', '4.69', '2.6']
    plt.xticks(grid_sizes, grid_sizes2)
    plt.xlabel('Number of Nodes')
    plt.ylabel('Time per Step [s]')
    plt.xlim(2.5, 20.5)
    plt.ylim(0)
    ax.yaxis.set_major_locator(MaxNLocator(integer=True))

    for i, gs in enumerate(grid_sizes):
        ourval = np.median(df[(df.Language == 'Python')
                              & (df['Nodes'] == gs)]['Time'])
        speedup = average_ftn / ourval
        plt.text(gs,
                 7.0 + 2 * i,
                 '%skm' % kms[i],
                 ha='center',
                 va="bottom",
                 fontsize=10)
        if i >= 1 and i < len(grid_sizes):  # - 1
            plt.text(gs,
                     6.0,
                     '%.1fx' % speedup,
                     ha='center',
                     va="bottom",
                     fontsize=10)
    plt.tight_layout()
    print(os.path.join(cwd, f'{name}.pdf'))
    plt.savefig(os.path.join(cwd, f'{name}.pdf'))


plot_single(df, "out")