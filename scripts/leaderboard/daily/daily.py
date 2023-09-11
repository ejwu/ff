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
import warnings

SERVER_LIST = ['glori', 'lk']
DISASTER_HP = 270000000000

def parse_args():
    parser = argparse.ArgumentParser(description="Parse collections of daily disaster leaderboards")
    parser.add_argument("--server", help="glori or lk", type=str, default="glori")
    parser.add_argument("--topN", help="Chart up to this many players", type=int, default=25)
    return parser.parse_args()

def round_yaxis_ticks(ax, round_to):
    # Separation between ticks on the y-axis
    low, high = ax.get_ylim()
    ax.yaxis.set_ticks(np.arange(max(0, math.floor(low / round_to) * round_to), math.ceil(high / round_to) * round_to, round_to))

def format_yaxis(ax):
    # Use comma separators and no scientific notation on y-axis
    ax.yaxis.set_major_formatter(matplotlib.ticker.StrMethodFormatter('{x:,.0f}'))

def dmg_to_pct(dmg):
    return dmg / DISASTER_HP

def pct_to_dmg(pct):
    return pct * DISASTER_HP

#matplotlib.font_manager._load_fontmanager(try_read_cache=False)

print(matplotlib.rcParams['font.family'])
matplotlib.rcParams['font.family'] = 'Noto Sans Mono'
print(matplotlib.rcParams['font.family'])



#default_cycler = (cycler(color=['r', 'g', 'b', 'y']) +
#                  cycler(linestyle=['-', '--', ':']))
#style_cycler = cycle(["solid", "dashed", "dotted"])
style_cycler = cycler('linestyle', ['-', ':', '--'])
#plt.rc('axes', prop_cycle=style_cycler)
#ax.set_prop_cycle(style_cycler)

servers = defaultdict(dict)
for server in SERVER_LIST:
    servers[server]['distinct'] = set()
    days = []
    player_scores = defaultdict(list)
    player_ranks = defaultdict(list)
    topN_scores = defaultdict(list)
    for i, filename in enumerate(glob.glob(f"data/*_{server}.json")):
        with open(filename, 'r') as f:
            days.append(re.search("\d+", filename).group(0)[4:])
            for player in json.load(f)['data']['lastPersonalRank']:
                if player['playerName'] not in player_scores:
                    player_scores[player['playerName']] = [math.nan] * i
                player_scores[player['playerName']].append(player['damage'])
                player_ranks[player['playerName']].append(player['rank'])
                topN_scores[player['rank']].append(player['damage'])
                if player['rank'] <= parse_args().topN:
                    servers[server]['distinct'].add(player['playerName'])
            for player_name, scores in player_scores.items():
                if len(scores) != (i + 1):
                    scores.append(math.nan)
                    player_ranks[player_name].append(math.nan)
    servers[server]['days'] = days                
    servers[server]['playerScores'] = player_scores
    servers[server]['playerRanks'] = player_ranks
    servers[server]['topNScores'] = topN_scores


for server in SERVER_LIST:
    fig = plt.figure(server)
    ax = fig.add_subplot()
    permanent = 0
    line_styles = cycle(['-', ':', '--'])
    # Figure for all player scores
    for player, scores in sorted(servers[server]['playerScores'].items(), key=lambda x: np.nanmean(x[1]), reverse=True)[:parse_args().topN]:
        print(player, scores, np.nanmean(scores))
        ax.plot(servers[server]['days'], scores, next(line_styles), label=player, marker='o', markersize=3)
        if not math.nan in scores:
            permanent += 1
        
    plt.title(f"Top {parse_args().topN}, {server}\n({permanent} always in top {parse_args().topN}, {len(servers[server]['distinct'])} total players appearing)")

    format_yaxis(ax)
    round_yaxis_ticks(ax, 200000000)

    # Squish graph to leave room for the legend outside of the graph
    plt.subplots_adjust(right=0.8)

    plt.legend(bbox_to_anchor=(1.03, 1), fontsize='x-small', ncol=(max(1, len(servers[server]['distinct']) / 25)), handlelength=3)


#font_props = font_manager.FontProperties(fname="/usr/share/fonts/google-noto/NotoSans-Regular.ttf")
#font_props.set_size(14)
#plt.legend(bbox_to_anchor=(1.03, 1), prop=font_props)


# Figure for topN scores
fig2 = plt.figure('topN')
ax2 = fig2.add_subplot()

line_styles = cycle(['-', ':'])
colors = cycle(['g', 'b', 'r', 'c', 'm', 'y', 'k'])
for i in [1, 2, 3, 10, 25, 50, 100]:
    color = next(colors)
    for server in SERVER_LIST:
        ax2.plot(days, servers[server]['topNScores'][i], next(line_styles), color=color, label=f"T{i} {server}")

plt.title(f"TopN scores, cross-server")

format_yaxis(ax2)
round_yaxis_ticks(ax2, 100000000)
plt.grid(visible=True, axis='y')

plt.subplots_adjust(right=0.8)
plt.legend(bbox_to_anchor=(1.03, 1), fontsize='x-small')


# Figure for total damage done
fig3 = plt.figure('total damage')
ax3 = fig3.add_subplot()

averages = defaultdict(list)
bottoms = [0, 0]
prev = 0
for bucket in [1, 2, 3, 10, 25, 50, 100]:
    for server in SERVER_LIST:
        total = 0
        for i in range(prev, bucket):
            for score in servers[server]['topNScores'][bucket]:
                total += score
        ave = (total / len(servers[server]['topNScores'][bucket]))
        averages[bucket].append(ave)

    label = ""
    if bucket - prev == 1:
        label = f"T{bucket}"
    else:
        label = f"T{prev + 1}-{bucket}"
    prev = bucket

    p = ax3.bar(SERVER_LIST, averages[bucket], bottom=bottoms)
    ax3.bar_label(p, [label] * 2, label_type = 'center')
    for i, av in enumerate(averages[bucket]):
        bottoms[i] += av
    
plt.title("Damage done by rank")
format_yaxis(ax3)
round_yaxis_ticks(ax3, 1000000000)
sec_ax3 = ax3.secondary_yaxis('right', functions=(dmg_to_pct, pct_to_dmg))
sec_ax3.yaxis.set_major_formatter(matplotlib.ticker.PercentFormatter(xmax=1.0, decimals=0))
round_yaxis_ticks(sec_ax3, .01)
        
warnings.filterwarnings('ignore')

plt.tight_layout()
plt.show()
