#!/usr/bin/python

import argparse
from collections import Counter
from collections import defaultdict
from ffutil.secret import (combined_fa_str, fa_str, fa_lines, fs_name, fs_arti_level_str, fs_str, short_fa_str, mirror_value, short_togi_str, shortest_togi_str, togis, togi_value, togi_value_str, update_togi_counts)
import json
import os
import re

def parse_args():
    parser = argparse.ArgumentParser("Analyze teams for whaledown")
    parser.add_argument("--show_secrets", help="show nonpublic information", action="store_true", required=False)
    parser.add_argument("--show_diffs", help="Show player differences over time", action="store_true", required=False)
    parser.add_argument("--month", help="Path to the month of data to show", default="data/202411", required=False)
    parser.add_argument("--all_months", help="Show aggregates over all months", action="store_true", required=False)
    return parser.parse_args()

def load_player(name, month=parse_args().month):
    return json.load(open(f"{month}/{name}"))["data"]

def print_player(player):
    print()
    print(player["team1"][0]["playerId"])
    total_togis = 0
    total_mirrors = 0
    for team_index in ["team1", "team2", "team3"]:
        team_togis = 0
        team_mirrors = 0
        print()
        print(team_index)
        for fs in player[team_index]:
            print(f"{fs_str(fs):25}", fa_lines(fs))
            team_mirrors += mirror_value(fs)
            # technically secret
            team_togis += togi_value(fs)
            if parse_args().show_secrets:
                print(shortest_togi_str(fs))
        total_mirrors += team_mirrors
        total_togis += team_togis
        print()
        print(f"~{team_mirrors:,} mirrors/FAs, or ~{float(team_mirrors) / 4551:.4} +20s")
        print(togi_value_str(team_togis))

        
    print()
    print("All teams")
    print(f"~{total_mirrors:,} mirrors/FAs, or ~{float(total_mirrors) / 4551:.4} +20s")
    print(togi_value_str(total_togis))
#    if parse_args().show_secrets:
#        print(togi_value_str(total_togis))

def fa_sorter(counter_tuple):
    m = re.search("\+(\d*)", counter_tuple[0])
    if m:
        return int(m.group(1))
    return 0
            
def print_aggregate_stats():
    fs_to_globalids = defaultdict(list)
    fa_counter = Counter()
    togi_counter = Counter()
    togi_by_color_counter = defaultdict(Counter)
    fs_to_togis = defaultdict(list)

    month = parse_args().month
    
    for player_filename in sorted(os.listdir(month)):
        print(player_filename)
        player = json.load(open(f"{month}/{player_filename}"))["data"]
        for team_index in ["team1", "team2", "team3"]:
            for fs in player[team_index]:
                fs_to_globalids[fs["cardId"]].append(int(fs["id"]))
                fa_counter[short_fa_str(fs)] += 1
                print(short_fa_str(fs))
                update_togi_counts(togi_by_color_counter, fs)
                for togi in togis(fs):
                    togi_counter[togi] += 1
                fs_to_togis[fs["cardId"]].append(shortest_togi_str(fs))

    for fsid, ids in sorted(fs_to_globalids.items(), key=lambda item: min(item[1])):
        print(fs_name(fsid), sorted(ids))

    print()
    for fa in fa_counter.most_common():
        print(f"{fa[1]:2}", fa[0])

    print()
    for fa, count in sorted(fa_counter.items(), key=fa_sorter, reverse=True):
        print(f"{count:2}", fa)

    print()
    for togi in togi_counter.most_common():
        print(f"{togi[1]:3}", togi[0])

    print()
    for color, counter in sorted(togi_by_color_counter.items(), key=lambda togi: togi[::-1], reverse=True):
        print(color, sorted(counter.items(), key=lambda entry: entry[0][::-1], reverse=True))

    print()
    for fs, togi_list in fs_to_togis.items():
        print(fs_name(fs))
        for togi in togi_list:
            print(f"  {togi}")
        print()

def print_player_diff(player_name, month1, month2):
    print(player_name[:-5])
    player1 = load_player(player_name, month1) 
    player2 = load_player(player_name, month2)
    print_player(player1)
    print_player(player2)

    print(f"{month1[5:]:40} {month2[5:]:40}")
    for team_index in ["team1", "team2", "team3"]:
        for fs_index in range(5):
            fs1 = player1[team_index][fs_index]
            fs2 = player2[team_index][fs_index]
            print(f"{fs_name(fs1['cardId']):40} {fs_name(fs2['cardId']):40}")
            print(f"  {combined_fa_str(fs1):40}   {combined_fa_str(fs2):40}")
        print()

def show_monthly_summary():
    for month in ["202407", "202408", "202409", "202411"]:
        print(f"--------------------------{month}-------------------------")
        fs_used = Counter()
        full_fs_used = Counter()
        for player in os.listdir(f"data/{month}"):
            player_data = load_player(player, f"data/{month}")
            print()
            print(player[:-5])
            print_player(player_data)
            for team_index in ["team1", "team2", "team3"]:
                for fs_index in range(5):
                    fs = player_data[team_index][fs_index]
                    fs_used[fs_name(fs['cardId'])] += 1
                    if parse_args().show_secrets:
                        full_fs_used[fs_arti_level_str(fs)] += 1
                    else:
                        full_fs_used[fs_str(fs)] += 1
                print()
                    
        print(month)
        print(fs_used.most_common())
        print(full_fs_used.most_common())
        
def show_diffs():
    prev_month_players = set()
    for month in os.listdir("data"):
        curr_month_players = set()
        for player in os.listdir(f"data/{month}"):
            curr_month_players.add(player)
        if len(prev_month_players) > 0:
            print(f"From {prev_month} to {month}:")
            print(f"Added: {sorted(curr_month_players.difference(prev_month_players))}")
            print(f"Lost: {sorted(prev_month_players.difference(curr_month_players))}\n")

        for player in sorted(curr_month_players.intersection(prev_month_players)):
            print_player_diff(player, f"data/{prev_month}", f"data/{month}")
            
        prev_month = month
        prev_month_players = curr_month_players

if __name__ == '__main__':
    if parse_args().all_months:
        show_monthly_summary()
    elif parse_args().show_diffs:
        show_diffs()
    else:
        print_aggregate_stats()

