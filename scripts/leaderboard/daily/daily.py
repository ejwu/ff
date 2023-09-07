#!/usr/bin/python

import argparse
from collections import defaultdict
from cycler import cycler
import glob
from itertools import cycle
import json
import math
import matplotlib
from matplotlib import font_manager
import matplotlib.pyplot as plt
import numpy as np
import re

def parse_args():
    parser = argparse.ArgumentParser(description="Parse collections of daily disaster leaderboards")
    parser.add_argument("--server", help="glori or lk", type=str, default="glori")
    parser.add_argument("--topN", help="Chart up to this many players", type=int, default=25)
    return parser.parse_args()

#matplotlib.font_manager._load_fontmanager(try_read_cache=False)

print(matplotlib.rcParams['font.family'])
matplotlib.rcParams['font.family'] = 'Noto Sans Mono'
print(matplotlib.rcParams['font.family'])

fig, ax = plt.subplots()

# Use comma separators and no scientific notation on y-axis
ax.yaxis.set_major_formatter(matplotlib.ticker.StrMethodFormatter('{x:,.0f}'))

#default_cycler = (cycler(color=['r', 'g', 'b', 'y']) +
#                  cycler(linestyle=['-', '--', ':']))
#style_cycler = cycle(["solid", "dashed", "dotted"])
style_cycler = cycler('linestyle', ['-', ':', '--'])
#plt.rc('axes', prop_cycle=style_cycler)
#ax.set_prop_cycle(style_cycler)

days = []
player_scores = defaultdict(list)
player_ranks = defaultdict(list)
topN_scores = defaultdict(list)
for i, filename in enumerate(glob.glob(f"data/*_{parse_args().server}.json")):
    with open(filename, 'r') as f:
        days.append(re.search("\d+", filename).group(0))
        for player in json.load(f)['data']['lastPersonalRank'][:parse_args().topN]:
            if player['playerName'] not in player_scores:
                player_scores[player['playerName']] = [math.nan] * i
            player_scores[player['playerName']].append(player['damage'])
            player_ranks[player['playerName']].append(player['rank'])
            if player['rank'] in (10, 25, 50):
                topN_scores[player['rank']].append(player['damage'])
        for player_name, scores in player_scores.items():
            if len(scores) != (i + 1):
                scores.append(math.nan)
                player_ranks[player_name].append(math.nan)



permanent = 0
line_styles = cycle(['-', ':', '--'])
for player, scores in sorted(player_scores.items(), key=lambda x: np.nanmean(x[1]), reverse=True):
    print(player, scores, np.nanmean(scores))
    ax.plot(days, scores, next(line_styles), label=player, marker='o', markersize=3)
    if not math.nan in scores:
        permanent += 1

#ax.plot(days, topN_scores[25], label="T25")
        
plt.title(f"Top {parse_args().topN}, {parse_args().server}\n({permanent} always in top {parse_args().topN}, {len(player_scores)} total players appearing)")

# Separation between ticks on the y-axis
round_to = 200000000
low, high = ax.get_ylim()
ax.yaxis.set_ticks(np.arange(max(0, math.floor(low / round_to) * round_to), math.ceil(high / round_to) * round_to, round_to))

# Squish graph to leave room for the legend outside of the graph
plt.subplots_adjust(right=0.7)
plt.legend(bbox_to_anchor=(1.03, 1), fontsize='x-small', ncol=(max(1, len(player_scores) / 50)), handlelength=3)
#font_props = font_manager.FontProperties(fname="/usr/share/fonts/google-noto/NotoSans-Regular.ttf")
#font_props.set_size(14)
#plt.legend(bbox_to_anchor=(1.03, 1), prop=font_props)

plt.tight_layout()
plt.show()
