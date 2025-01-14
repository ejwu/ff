#!/usr/bin/python

from ffutil.secret import (fa_str, fs_str, short_fa_str, short_togi_str, shortest_togi_str)

import argparse
from collections import Counter
from collections import defaultdict
from collections import OrderedDict
import datetime
from dateutil.parser import parse
import itertools
import json
import wcwidth

BASE_PATH = "/home/ejwu/ff/ff20240627/com.egg.foodandroid/files/"

FA_NATURES = {"1": "Brave", "2": "unknown2", "3": "Cautious", "4": "unknown4", "5": "unknown5", "6": "Resolute"}

def parse_args():
    parser = argparse.ArgumentParser(description="Parse leaderboards for Goose Barnacle event")
    parser.add_argument("--server", help="glori or lk", type=str, default="glori")
    parser.add_argument("--show_secrets", help="show nonpublic information", action="store_true", required=False)
    return parser.parse_args()

def load_fs_map():
    fs_data = json.load(open(BASE_PATH + "publish/conf/en-us/card/card.json"))
    fs_map = {}
    for fs in fs_data:
        fs_map[fs] = fs_data[fs]["name"]
        if fs_data[fs]["qualityId"] == "5":
            fs_map[fs] = "SP " + fs_data[fs]["name"]
    return fs_map

def zfs_skills(fs):
    skill_levels = []
    for skill in fs["skill"].values():
        skill_levels.append(str(skill["level"]))
    return "/".join(skill_levels)


SHORT_TOGI_COLORS = {
    "Green": "Gr",
    "Cyan": "Cy",
    "Red": "Re",
    "Blue": "Bl",
    "Purple": "Pu",
    "Yellow": "Ye"
}

SHORT_TOGI_COLORS_REVERSED = {v:k for k, v in SHORT_TOGI_COLORS.items()}

def ztogis(fs):
    togis = []
    if not fs["artifactTalent"]:
        return togis

    for i in ["3", "6", "9", "14", "18"]:
        if not i in fs["artifactTalent"]:
            togis.append("LOCKED")
        else:
            node = fs["artifactTalent"][str(i)]
            if node["gemstoneId"]:
                togis.append(togi_map[str(node["gemstoneId"])])
            else:
                togis.append("EMPTY")
    return togis


def zartifact_nodes(fs):
    if not fs["artifactTalent"]:
        return "no arti"

    togis = 0
    togi_strs = []
    for i in sorted(int(x) for x in fs["artifactTalent"]):
        node = fs["artifactTalent"][str(i)]
        if node["gemstoneId"]:
            # long form
            #            print(i, togi_map[str(node["gemstoneId"])])
            # short form
            print(togi_map[str(node["gemstoneId"])])
            togi_str = togi_map[str(node["gemstoneId"])].split()[1]
            togi_strs.append(togi_str if togi_str else "xx")
#            togi_strs.append(togi_map[str(node["gemstoneId"])].split()[1])
            togis += 1
    print(",".join(togi_strs))
            
    nodes = len(fs["artifactTalent"])
    if nodes == 0:
        return "no arti"
    if nodes == 1 or nodes == 2:
        return "T0+"
    if nodes == 3:
        return "T1"
    if nodes == 4 or nodes == 5:
        return "T1+"
    if nodes == 6:
        return "T2"
    if nodes == 7 or nodes == 8:
        return "T2+"
    if nodes == 9:
        return "T3"
    # From here on out, making assumptions that nobody's filling both paths instead of the togi node
    if nodes == 10 or nodes == 11:
        return "T3+"
    if nodes == 12:
        if togis < 4:
            return "T4-?"
        return "T4"
    if nodes == 13 or nodes == 14 or nodes == 15:
        return "T4+"
    if nodes == 16:
        if togis < 5:
            return "T5-?"
        return "T5"
    if nodes == 17:
        return "T5+"
    if nodes == 18:
        # check if both paths are fully leveled
        return "T5++"
    raise

    
def parse_goose_barnacle_leaderboards():
    glori_cap = 0
    lk_cap = 0
    max_score = 0
    max_player = ''''''''''''
    high_scores = {}
    counters = defaultdict(dict)
    for server in ["glori", "lk"]:
        lb = json.load(open(server + "_goose_leaderboard.json"))["data"]["rank"]

        counters[server]["fa"] = Counter()
        counters[server]["faLevel"] = Counter()
        counters[server]["fs"] = Counter()
        counters[server]["togi"] = Counter()
        counters[server]["togiLevel"] = Counter()
    
        for player in lb:
            damage = int(player["playerMaxDamage"])
            high_scores[damage] = player["playerName"]
            if damage > 60000000:
                if server == "glori":
                    glori_cap += 1
                if server == "lk":
                    lk_cap += 1
                if damage > max_score:
                    max_score = damage
                    max_player = player["playerName"]

            print(player["playerRank"], player["playerName"])
            for fs in player["playerCards"].values():
                counters[server]["fs"][fs_map[fs["cardId"]]] += 1
                counters[server]["fa"][fa_str(fs)] += 1
                counters[server]["faLevel"][fa_str(fs)[:3].strip()] += 1
                for togi in togis(fs):
                    counters[server]["togi"][togi] += 1
                    counters[server]["togiLevel"][togi[-1]] += 1
                nickname = ','
                if fs["cardName"]:
                    nickname = ' (' + fs["cardName"] + '),'
                print(f"{fs['breakLevel']}* {artifact_nodes(fs)} {fs_map[fs['cardId']]}{nickname} level {fs['level']}, skills {fs_skills(fs)}, {fa_str(fs)}")
        
                if fs["favorabilityLevel"] != "6":
                    print(f"(unpledged, fondness level {fs['favorabilityLevel']})")
            print()


    print(f"         glori                           lk")

    print("glori|fs|lk|fs")
    print("-|-|-|-")
    for [gl, lk] in itertools.zip_longest(counters["glori"]["fs"].most_common(), counters["lk"]["fs"].most_common()):
#    print(f"{gl[1]:2} {gl[0]:27} | {lk[1] if lk else ' '} {lk[0] if lk else ''}")
        print(f"{gl[1]:2}| {gl[0]:27} | {lk[1] if lk else ' '}| {lk[0] if lk else ''}")
    print()

    for faLevel in range(20, 0, -1):
        print(f"{faLevel:3} {counters['glori']['faLevel']['+' + str(faLevel)]:4} | {counters['lk']['faLevel']['+' + str(faLevel)]:3}")

    for [gl, lk] in itertools.zip_longest(counters["glori"]["togi"].most_common(), counters["lk"]["togi"].most_common()):
        print(f"{gl[1]:3} {gl[0]:13} | {lk[1] if lk else ' '} {lk[0] if lk else ''}")
    print()

    for togiLevel in range(10, 0, -1):
        print(f"{togiLevel:4} {counters['glori']['togiLevel'][str(togiLevel)]:5} | {counters['lk']['togiLevel'][str(togiLevel)]:5}")
    print(f"Total {counters['glori']['togiLevel'].total()} | {counters['lk']['togiLevel'].total():5}\n")

    print(glori_cap, lk_cap)
    print(max_player, max_score)
    print(sorted(high_scores.items()))
    print(len(high_scores))

DISASTER_NAMES = {"20001": "Aluna", "20002": "Durga", "20003": "Devouroth", "20004": "Bonepain", "20005": "Minamata", "20006": "Jellyfish", "20007": "Dreamer", "20008": "Qiongqi"}

def parse_disaster_manual():
    disaster_manual = json.load(open("lk_leaderboard_20230201.json.pretty"))
    print("lk")
    for disaster in disaster_manual["data"]["manual"]:
        print(DISASTER_NAMES[str(disaster["questId"])], disaster["totalNumbers"])
    disaster_manual = json.load(open("glori_leaderboard_20230201.json.pretty"))
    print("glori")
    for disaster in disaster_manual["data"]["manual"]:
        print(DISASTER_NAMES[str(disaster["questId"])], disaster["totalNumbers"])

    for disaster in disaster_manual["data"]["manual"]:
        print(DISASTER_NAMES[str(disaster["questId"])], disaster["totalNumbers"])
        for player in disaster["topRank"]:
            print(f"    {player['playerName']:20} {player['playerDamage']:12}")
            for fs in player["playerCards"]:
                if "Orecchiette" == fs_map[fs['cardId']]:
                    print(f"        {fs_map[fs['cardId']]} {artifact_nodes(fs)}")
                
        print()

SPECIAL_NAME_LENGTHS = {
    # 오리너구리
    "1738235": 5,
    # 有五核烤鴨無腦上即可
    #《紅豆冰》
    "1015412": 5,
    # 有五核大米無腦上即可
    #《藍天使》
    "111684": 5,
    # 신야옹이
    "1690538": 4
}

def get_latest_date(player):
    latest = None
    for fs in player['playerCards']:
        current = parse(fs['createTime'])
        if latest == None or current > latest:
            latest = current
        if fs['artifactTalent']:
            for node in fs['artifactTalent'].values():
                if node:
                    current = parse(node['createTime'])
                    if current > latest:
                        latest = current
        if fs['marryTime']:
            current = datetime.datetime.fromtimestamp(int(fs['marryTime']))
            if current > latest:
                latest = current
        
    return latest.date()

def update_togi_counts(counts, fs):
    togi_str = short_togi_str(fs)
    for togi in togi_str.split('/'):
        if togi != 'EMPTY' and not togi.startswith('LOCKED'):
            counts[SHORT_TOGI_COLORS_REVERSED[togi[0:2]]][togi[3:5]] += 1

def parse_disaster_snapshot():
    lk_data_202302 = json.load(open("lk_leaderboard_20230201.json.pretty"))["data"]["manual"]
    lk_data_202307 = json.load(open("monthly/202406_lk_disaster.json"))["data"]["manual"]

    glori_data_202302 = json.load(open("glori_leaderboard_20230201.json.pretty"))["data"]["manual"]
    glori_data_202307 = json.load(open("monthly/202406_glori_disaster.json"))["data"]["manual"]

    first = lk_data_202307
    second = glori_data_202307
    
    max_name_length = 1
    for i, lk_disaster in enumerate(first):
        for player in lk_disaster["topRank"]:
            if player["playerId"] in SPECIAL_NAME_LENGTHS:
                max_name_length = max(max_name_length, SPECIAL_NAME_LENGTHS[player["playerId"]])
            else:
                max_name_length = max(max_name_length, wcwidth.wcswidth(player["playerName"]))
        for player in second[i]["topRank"]:
            if player["playerId"] in SPECIAL_NAME_LENGTHS:
                max_name_length = max(max_name_length, SPECIAL_NAME_LENGTHS[player["playerId"]])
            else:
                max_name_length = max(max_name_length, wcwidth.wcswidth(player["playerName"]))

    COLUMN_WIDTH = 35
                
    print(f"{'lk':^{COLUMN_WIDTH}} {'glori':^{COLUMN_WIDTH}}")
    for i, disaster in enumerate(first):
        fs_togis = defaultdict(list)
        lk_togi_levels_by_color = defaultdict(Counter)
        glori_togi_levels_by_color = defaultdict(Counter)
        print()
        print(DISASTER_NAMES[str(disaster["questId"])])
        print()
        
        first_players = disaster["topRank"]
        second_players = second[i]["topRank"]
        players = 3
        if parse_args().show_secrets:
            players = 4
        for i in range(0, players):
            lk_id = first_players[i]["playerId"]
            glori_id = second_players[i]["playerId"]

            glori_name_length = max_name_length
            if glori_id in SPECIAL_NAME_LENGTHS:
                glori_name_length = SPECIAL_NAME_LENGTHS[glori_id]
            
            remaining_width = COLUMN_WIDTH - max_name_length - 1
            
            print(f"{first_players[i]['playerName']:{max_name_length}} {first_players[i]['playerDamage']:<{remaining_width},}   {second_players[i]['playerName']:{glori_name_length}} {second_players[i]['playerDamage']:{remaining_width},}")
            if parse_args().show_secrets:
                print(f"After: {get_latest_date(first_players[i])}                     After:{get_latest_date(second_players[i])}")
            for j in range(0, 5):
                lk_fs = first_players[i]['playerCards'][j]
                glori_fs = second_players[i]['playerCards'][j]

                fs_togis[fs_map[lk_fs["cardId"]]].append(shortest_togi_str(lk_fs))
                fs_togis[fs_map[glori_fs["cardId"]]].append(shortest_togi_str(glori_fs))

                update_togi_counts(lk_togi_levels_by_color, lk_fs)
                update_togi_counts(glori_togi_levels_by_color, glori_fs)
                
                print(f"  {fs_str(lk_fs):23} {short_fa_str(lk_fs)}    {fs_str(glori_fs):23} {short_fa_str(glori_fs)}")
                if parse_args().show_secrets:
#                    print(fs_skills(lk_fs))
                    print(f"    {shortest_togi_str(lk_fs):29}         {shortest_togi_str(glori_fs)}")
            print()
        print()

        # Listing all the togis by FS
        if parse_args().show_secrets:
            for fs, togis in fs_togis.items():
                print(fs)
                for togi in togis:
                    print("  ", togi)
            print("\nlk togi counts in T4", DISASTER_NAMES[str(disaster["questId"])], '\n')
            for color, counter in sorted(lk_togi_levels_by_color.items(), key=lambda togi: togi[::-1], reverse=True):
                print(color, sorted(counter.items(), key=lambda entry: entry[0][::-1], reverse=True))
            print("\nglori togi counts in T4", DISASTER_NAMES[str(disaster["questId"])], '\n')
            for color, counter in sorted(glori_togi_levels_by_color.items()):
                print(color, sorted(counter.items(), key=lambda entry: entry[0][::-1], reverse=True))
        print()
    
if __name__ == '__main__':
    # Look into not duplicating this with secret.py
    fs_map = load_fs_map()

#    parse_goose_barnacle_leaderboards()
#    parse_disaster_manual()
    parse_disaster_snapshot()
