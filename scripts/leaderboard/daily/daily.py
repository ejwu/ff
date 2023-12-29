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
from pathlib import Path
import re
import unicodedata
import warnings

SERVER_LIST = ['glori', 'lk']
# 270B for Aluna
DISASTER_HP = 270000000000

# Hack to get a cursive font for a joke label
CURSIVE = Path(matplotlib.get_data_path(), Path.home() / ".local/share/fonts/Felipa-Regular.ttf")

def parse_args():
    parser = argparse.ArgumentParser(description="Parse collections of daily disaster leaderboards")
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

def add_dunhuang(ax):
    ax.axvline(x=912.5, color='black', ls=':')
    ax.text(912.55, 0.88, 'susurration begins', rotation=90, size='small', font=CURSIVE, transform=ax.get_xaxis_text1_transform(0)[0])
    ax.text(917, 0.97, 'susurration intensifies', font=CURSIVE, transform=ax.get_xaxis_text1_transform(0)[0])
    ax.axvline(x=923.5, color='black', ls=':')
    ax.text(923.05, 0.88, 'susurration ends', rotation=270, size='small', font=CURSIVE, transform=ax.get_xaxis_text1_transform(0)[0])
    ax.axvline(x=926.5, color='black', ls=':')
    ax.text(926.55, 0.88, 'gate begins', rotation=90, size='x-small', transform=ax.get_xaxis_text1_transform(0)[0])
    ax.axvline(x=929.5, color='black', ls=':')
    ax.text(929.55, 0.88, 'gate ends', rotation=90, size='x-small', transform=ax.get_xaxis_text1_transform(0)[0])

def dunhuang_ranks(servers):
    for server in SERVER_LIST:
        print(server)
        player_names = set(servers[server]['playerScores'].keys())
        scores = defaultdict(list)
        min_scores = []
        known_scores = defaultdict(int)
        max_possible_scores = defaultdict(int)
        ranking = json.load(open(f"data/dunhuang_{server}.json", 'r'))
        for i in range(1, 5):
            for score in ranking['data']['damageRank'][str(i)]['damagePointRanks']:
                scores[score['playerName']].append(score['playerScore'])
                player_names.add(score['playerName'])
                if score['playerRank'] == 100:
                    min_scores.append(score['playerScore'])
            for player in player_names:
                if len(scores[player]) < i:
                    scores[player].append(math.nan)
        print(len(servers[server]['playerScores']), "in top 100 disaster")
        print(len(player_names), "total players in dunhuang rankings")
        for player in servers[server]['playerScores'].keys():
            current_score = 0
            for i in range(0, 4):
                if math.isnan(scores[player][i]):
                    max_possible_scores[player] += min_scores[i]
                else:
                    current_score += scores[player][i]
            known_scores[player] = current_score

            print(player, scores[player], known_scores[player], max_possible_scores[player])

        print()
        print(f"T50 {server} players")
        print("           known score-max possible score")
        for player, _ in sorted(known_scores.items(), key=lambda item: item[1]):
            length_offset = 0
            if unicodedata.east_asian_width(player[0]) == "W":
                length_offset = len(player)
            print(f"{player:{20 - length_offset}} {known_scores[player]}-{known_scores[player] + max_possible_scores[player]}")
            
        print(min_scores)
            
#for fpath in sorted(matplotlib.font_manager.get_font_names()):
#    print(fpath)
    
# Allow Chinese glyphs
matplotlib.rcParams['font.family'] = ['Droid Sans Fallback', 'Noto Sans Mono']

servers = defaultdict(dict)
for server in SERVER_LIST:
    servers[server]['distinct'] = set()
    days = []
    player_scores = defaultdict(list)
    player_ranks = defaultdict(list)
    restricted_scores = defaultdict(list)
    topN_scores = defaultdict(list)
    for i, filename in enumerate(sorted(glob.glob(f"data/202309*_{server}.json"))):
        with open(filename, 'r') as f:
            days.append(int(re.search("\d+", filename).group(0)[4:]) - 1)
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
    print(days)
    servers[server]['playerScores'] = player_scores
    servers[server]['playerRanks'] = player_ranks
    servers[server]['topNScores'] = topN_scores

    # restrictedScores is just for estimating possible scores for the last day of dunhuang ranking
    for i, filename in enumerate(sorted(glob.glob(f"data/202309*_{server}.json"))):
        with open(filename, 'r') as f:
            for player in json.load(f)['data']['lastPersonalRank'][:parse_args().topN]:
                while len(restricted_scores[player['playerName']]) < i:
                    restricted_scores[player['playerName']].append(math.nan)
                restricted_scores[player['playerName']].append(player['damage'])
                
    for player in player_scores.keys():
        if player in restricted_scores:
            while len(restricted_scores[player]) <= i:
                restricted_scores[player].append(math.nan)
        
    servers[server]['restrictedScores'] = restricted_scores

#dunhuang_ranks(servers)
#exit()
    
for server in SERVER_LIST:
    fig = plt.figure(server)
    ax = fig.add_subplot()
    permanent = 0
    line_styles = cycle(['-', ':', '--'])
    marker_styles = cycle(['o', '+', '*', 'x'])
    # Figure for all player scores
    for player, scores in sorted(servers[server]['restrictedScores'].items(), key=lambda x: np.nanmean(x[1]), reverse=True):
        ax.plot(servers[server]['days'], scores, next(line_styles), label=player, marker=next(marker_styles), markersize=5)
        print(player)
        if not math.nan in scores:
            permanent += 1

    add_dunhuang(ax)
            
    plt.title(f"Top {parse_args().topN}, {server}\n({permanent} always in top {parse_args().topN}, {len(servers[server]['distinct'])} total players appearing)")

    start, end = ax.get_xlim()
    ax.xaxis.set_ticks(np.arange(int(start) + 1, int(end), 1))
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

add_dunhuang(ax2)
        
plt.title(f"TopN scores, cross-server")

start, end = ax2.get_xlim()
ax2.xaxis.set_ticks(np.arange(int(start) + 1, int(end) + 1, 1))
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
round_yaxis_ticks(ax3, 2000000000)
sec_ax3 = ax3.secondary_yaxis('right', functions=(dmg_to_pct, pct_to_dmg))
sec_ax3.yaxis.set_major_formatter(matplotlib.ticker.PercentFormatter(xmax=1.0, decimals=0))
round_yaxis_ticks(sec_ax3, .01)
        
warnings.filterwarnings('ignore')

plt.tight_layout()
plt.show()
