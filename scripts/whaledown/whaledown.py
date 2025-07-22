#!/usr/bin/python

import argparse
from collections import Counter
from collections import defaultdict
from ffutil.secret import (combined_fa_str, fa_str, fa_lines, fs_name, fs_arti_level_str, fs_str, short_fa_str, mirror_value, mirror_value_str, short_togi_str, shortest_togi_str, togis, togi_value, togi_value_str, update_togi_counts)
import json
import matplotlib
import matplotlib.pyplot as plt
import os
import re

# Use playerId as the key for overrides.
PLAYER_ID_TO_NAME = {"111684": "《藍天使》", "1015412": "《紅豆冰》"}
PLAYER_NAME_LENGTHS = {"《藍天使》": 5, "《紅豆冰》": 5}

def parse_args():
    parser = argparse.ArgumentParser("Analyze teams for whaledown")
    parser.add_argument("--show_secrets", help="show nonpublic information", action="store_true", required=False)
    parser.add_argument("--show_diffs", help="Show player differences over time", action="store_true", required=False)
    parser.add_argument("--month", help="Path to the month of data to show", default="data/202411", required=False)
    parser.add_argument("--all_months", help="Show aggregates over all months", action="store_true", required=False)
    return parser.parse_args()

def get_player_id_from_data(data):
    return data['team1'][0]['playerId']

def load_all_data(data_dir="data"):
    """
    Loads all player data from all month directories, keyed by month and then by playerId.
    This function is the single source of truth for player data.
    """
    all_data = defaultdict(dict)
    player_id_map = {}  # Maps playerId to the preferred display name

    months = sorted([m for m in os.listdir(data_dir) if os.path.isdir(os.path.join(data_dir, m)) and re.match(r'^\d{6}$', m)])

    for month in months:
        month_path = os.path.join(data_dir, month)
        for filename in sorted(os.listdir(month_path)): # Sort for deterministic name selection
            file_path = os.path.join(month_path, filename)
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f).get("data")

            player_id = get_player_id_from_data(data)

            if player_id in all_data[month]:
                print(f"Warning: Duplicate playerId {player_id} found in {month}. Ignoring {filename}.")
                raise Exception("bad data")

            all_data[month][player_id] = data

            # First time seeing this player ID.
            if player_id not in player_id_map:
                # The canonical name is the filename by default.
                base_name = filename.removesuffix(".json")
                # Override with the hardcoded name if it exists for this player ID.
                player_name = PLAYER_ID_TO_NAME.get(player_id, base_name)
                player_id_map[player_id] = player_name

    return all_data, player_id_map

def print_player(player_data, show_secrets=False):
    print()
    print(get_player_id_from_data(player_data))
    total_togis = 0
    total_mirrors = 0
    for team_index in ["team1", "team2", "team3"]:
        team_togis = 0
        team_mirrors = 0
        print()
        print(team_index)
        for fs in player_data[team_index]:
            print(f"{fs_str(fs):25}", fa_lines(fs))
            team_mirrors += mirror_value(fs)
            # technically secret
            team_togis += togi_value(fs)
            if show_secrets:
                print(shortest_togi_str(fs))
        total_mirrors += team_mirrors
        total_togis += team_togis
        print()
        print(mirror_value_str(team_mirrors))
        print(togi_value_str(team_togis))

    print()
    print("All teams")
    print(mirror_value_str(total_mirrors))
    print(togi_value_str(total_togis))
#    if show_secrets:
#        print(togi_value_str(total_togis))
    return total_togis, total_mirrors


def fa_sorter(counter_tuple):
    m = re.search(r"\+(\d*)", counter_tuple[0])
    if m:
        return int(m.group(1))
    return 0

def print_aggregate_stats(args, all_data, player_id_map):
    fs_to_globalids = defaultdict(list)
    fa_counter = Counter()
    togi_counter = Counter()
    togi_by_color_counter = defaultdict(Counter)
    fs_to_togis = defaultdict(list)

    month_key = os.path.basename(args.month)
    month_data = all_data.get(month_key)

    for player_id, player_data in sorted(month_data.items()):
        player_name = player_id_map.get(player_id, player_id)
        print(player_name)
        for team_index in ["team1", "team2", "team3"]:
            for fs in player_data[team_index]:
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

def print_player_diff(player_name, player_data1, player_data2, month1_str, month2_str):
    print(player_name)
    print_player(player_data1)
    print_player(player_data2)

    print(f"{month1_str[5:]:40} {month2_str[5:]:40}")
    for team_index in ["team1", "team2", "team3"]:
        for fs_index in range(len(player_data1[team_index])):
            fs1 = player_data1[team_index][fs_index]
            fs2 = player_data2[team_index][fs_index]
            print(f"{fs_name(fs1['cardId']):40} {fs_name(fs2['cardId']):40}")
            print(f"  {combined_fa_str(fs1):40}   {combined_fa_str(fs2):40}")
        print()

def show_monthly_summary(args, all_data, player_id_map):
    for month, month_data in sorted(all_data.items()):
        print(f"--------------------------{month}-------------------------")
        fs_used = Counter()
        full_fs_used = Counter()
        fa_used = Counter()
        togi_rankings = {}
        mirror_rankings = {}
        for player_id, player_data in sorted(month_data.items()):
            player_name = player_id_map.get(player_id, player_id)
            print()
            print(player_name)
            [togis, mirrors] = print_player(player_data, args.show_secrets)
            togi_rankings[player_name] = togis
            mirror_rankings[player_name] = mirrors
            for team_index in ["team1", "team2", "team3"]:
                for fs in player_data[team_index]:
                    fs_used[fs_name(fs['cardId'])] += 1
                    if args.show_secrets:
                        full_fs_used[fs_arti_level_str(fs)] += 1
                    else:
                        full_fs_used[fs_str(fs)] += 1
                    fa_used[fa_str(fs)] += 1
                print()

        print(month)
        print()
        print("Togi rankings:")
        for k in sorted(togi_rankings, key=lambda x:togi_rankings[x], reverse=True):
            print(f"{k:{13 - PLAYER_NAME_LENGTHS.get(k, 0)}}: {togi_value_str(togi_rankings[k])}")
        print()
        print("Mirror rankings:")
        for k in sorted(mirror_rankings, key=lambda x:mirror_rankings[x], reverse=True):
            print(f"{k:{13 - PLAYER_NAME_LENGTHS.get(k, 0)}}: {mirror_value_str(mirror_rankings[k])}")
        print()

        print("FS rankings:")
        for [fs, count] in fs_used.most_common():
            print(f"{count:3} {fs}")
        print()

        print("FS + ascension rankings:")
        for [fs, count] in full_fs_used.most_common():
            print(f"{count:3} {fs}")

        print("FA rankings:")
        for [fa, count] in fa_used.most_common():
            print(f"{count:3} {fa}")

def show_diffs(all_data, player_id_map):
    sorted_months = sorted(all_data.keys())
    for i in range(len(sorted_months) - 1):
        month1_str, month2_str = sorted_months[i], sorted_months[i+1]
        players1 = set(all_data[month1_str].keys())
        players2 = set(all_data[month2_str].keys())

        print(f"From {month1_str} to {month2_str}:")
        print(f"Added: {sorted([player_id_map.get(pid, pid) for pid in players2.difference(players1)])}")
        print(f"Lost: {sorted([player_id_map.get(pid, pid) for pid in players1.difference(players2)])}\n")

        for player_id in sorted(players1.intersection(players2)):
            player_name = player_id_map.get(player_id, player_id)
            player_data1 = all_data[month1_str][player_id]
            player_data2 = all_data[month2_str][player_id]
            print_player_diff(player_name, player_data1, player_data2, month1_str, month2_str)

def plot_mirror_rankings(all_data, player_id_map):
    """
    Gathers mirror data across all months and plots the change over time for each player.
    """
    existing_months = sorted(all_data.keys())

    if not existing_months:
        print("Warning: No valid month data found.")
        return

    start_month_str = existing_months[0]
    end_month_str = existing_months[-1]

    start_year, start_month = int(start_month_str[:4]), int(start_month_str[4:])
    end_year, end_month = int(end_month_str[:4]), int(end_month_str[4:])

    all_months_in_range = []
    cy, cm = start_year, start_month
    while (cy, cm) <= (end_year, end_month):
        all_months_in_range.append(f"{cy}{cm:02d}")
        cm += 1
        if cm > 12:
            cm = 1
            cy += 1

    player_mirror_history = defaultdict(dict)

    for month, month_data in all_data.items():
        for player_id, player_data in month_data.items():
            player_name = player_id_map.get(player_id, player_id)
            total_mirrors = 0
            for team_index in ["team1", "team2", "team3"]:
                for fs in player_data[team_index]:
                    total_mirrors += mirror_value(fs)
            player_mirror_history[player_name][month] = total_mirrors

    # --- FONT CONFIGURATION FOR CJK CHARACTERS ---
    # Set a font that supports the characters in PLAYER_NAMES. Matplotlib will
    # use the first font it finds in this list from your system.
    #
    # Common font names by OS:
    # - Windows: 'Microsoft JhengHei', 'SimHei'
    # - macOS:   'Heiti TC', 'PingFang TC', 'Arial Unicode MS'
    # - Linux:   'WenQuanYi Zen Hei', 'Noto Sans CJK TC' (may need to be installed)
    matplotlib.rcParams['font.family'] = ['Noto Sans CJK JP', 'sans-serif']

    # This setting resolves a common issue where minus signs are displayed as boxes.
    plt.rcParams['axes.unicode_minus'] = False
    # --- END FONT CONFIGURATION ---

    fig, ax = plt.subplots(figsize=(12, 8))
    # Create a mapping from month string to a numerical index for plotting
    month_to_index = {month: i for i, month in enumerate(all_months_in_range)}

    for player_name, history in sorted(player_mirror_history.items()):
        if not history:
            continue
        # Create lists of the months and scores where data exists for this player.
        player_months, player_scores = zip(*sorted(history.items()))
        # Convert the player's months to their corresponding numerical indices
        player_indices = [month_to_index[m] for m in player_months]
        # Plot using the numerical indices for x-axis, which ensures correct ordering
        ax.plot(player_indices, player_scores, marker='o', linestyle='-')
        # Add the player name as a label to the right of the last data point
        ax.text(player_indices[-1] + 0.1, player_scores[-1], player_name, verticalalignment='center')

    # Formatting the graph
    ax.set_xlabel("Month")
    ax.set_ylabel("Total Mirror Value")
    ax.set_title("Player Mirror Value Change Over Time")
    ax.grid(True, which='both', linestyle='--', linewidth=0.5)

    # Set the ticks to the numerical indices and the labels to the month strings.
    # This ensures the x-axis is ordered correctly and labeled meaningfully.
    if all_months_in_range:
        ax.set_xticks(range(len(all_months_in_range)))
        ax.set_xticklabels(all_months_in_range, rotation=45, ha="right")

    # Adjust plot margins to make space for the labels on the right
    ax.margins(x=0.15)
    plt.tight_layout()
    plt.show()

if __name__ == '__main__':
    args = parse_args()
    all_data, player_id_map = load_all_data()

    if not all_data:
        print("Exiting: No data loaded.")
        exit()

    if args.all_months:
        show_monthly_summary(args, all_data, player_id_map)
        plot_mirror_rankings(all_data, player_id_map)
    elif args.show_diffs:
        show_diffs(all_data, player_id_map)
    else:
        print_aggregate_stats(args, all_data, player_id_map)
