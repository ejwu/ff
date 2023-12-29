#!/usr/bin/python

import matplotlib
import matplotlib.pyplot as plt

damage = [[4146314, 3812858, 3848635, 3548817, 3052330, 3920999, 4243238, 4004874, 3912372, 3943344],
          [5464309, 5241265, 4819473, 4764802, 5134685, 4992859, 4947317, 5579181, 5559844, 5744592],
          [7377032, 7979873, 7540738, 8281323, 5383889, 6388014, 7132040, 6575005, 5367337, 6790545]]
labels = ['T3', 'T4', 'T5']

fig, ax = plt.subplots(nrows=1, ncols=1)

bplot = ax.boxplot(damage,
                   notch=True,  # notch shape
                   vert=True,  # vertical box alignment
                   patch_artist=True,  # fill with color
                   labels=labels)  # will be used to label x-ticks
ax.set_title('Rum/Stollen (T5) battle drills, L7 togis for Rum T3/4/5')

ax.yaxis.set_major_formatter(matplotlib.ticker.StrMethodFormatter('{x:,.0f}'))

colors = ['red', 'yellow', 'cyan']
for patch, color in zip(bplot['boxes'], colors):
    patch.set_facecolor(color)

plt.show()
