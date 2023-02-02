#!/usr/bin/python

import argparse
from collections import Counter
from collections import defaultdict
from collections import OrderedDict
import itertools
import json
import wcwidth

FA_NATURES = {"1": "Brave", "2": "unknown2", "3": "Cautious", "4": "unknown4", "5": "unknown5", "6": "Resolute"}

def parse_args():
    parser = argparse.ArgumentParser(description="Parse leaderboards for Goose Barnacle event")
    parser.add_argument("--server", help="glori or lk", type=str, default="glori")
    parser.add_argument("--show_secrets", help="show nonpublic information", action="store_true", required=False)
    return parser.parse_args()

def load_fs_map():
    fs_data = json.load(open("/home/ejwu/ff/ff20221124/com.egg.foodandroid/files/publish/conf/en-us/card/card.json.pretty"))
    fs_map = {}
    for fs in fs_data:
        fs_map[fs] = fs_data[fs]["name"]
        if fs_data[fs]["qualityId"] == "5":
            fs_map[fs] = "SP " + fs_data[fs]["name"]
    return fs_map

def load_fa_map():
    fa_data = json.load(open("/home/ejwu/ff/ff20221124/com.egg.foodandroid/files/publish/conf/en-us/pet/pet.json.pretty"))
    fa_map = {}
    for fa in fa_data:
        fa_map[fa] = fa_data[fa]["name"]
    return fa_map

togi_color_map = {"1": "Cyan", "2": "Blue", "3": "Red", "4": "Yellow", "5": "Purple", "6": "Green"}

def load_togi_map():
    togi_data = json.load(open("/home/ejwu/ff/ff20221124/com.egg.foodandroid/files/res_sub/conf/en-us/artifact/gemstone.json.pretty"))
    togi_map = {}
    for togi in togi_data:
        togi_map[togi] = f"{togi_color_map[togi_data[togi]['color']]} {togi_data[togi]['name'][0]}{togi_data[togi]['grade']}"
    return togi_map

def fs_skills(fs):
    skill_levels = []
    for skill in fs["skill"].values():
        skill_levels.append(str(skill["level"]))
    return "/".join(skill_levels)

def fs_str(fs_json):
    return fs_json["breakLevel"] + "* " + fs_map[fs_json["cardId"]]

def fa_str(fs):
    if not "pets" in fs:
        return "no FA"
    fa = fs["pets"]["1"]

    if fa['level'] != '30':
        print("weird")
        print(fa)
        raise
    return f"+{fa['breakLevel']} {FA_NATURES[fa['character']]} {fa_map[fa['petId']]}"

SHORT_FA_STRS = {
    "Brave" : "Br",
    "Resolute": "Re",
    "Tsuchigumo": "Tsu",
    "Thundaruda": "Thu",
    "Leaf Ocean Queen": "LOQ",
    "Uke Mochi (Enhanced)": "UME",
    "Queen Conch": "Con",
    "Inugami": "Inu",
    "Spectra": "Spe",
    "Uke Mochi": "Uke",
    "Orochi": "Oro",
    "Aizen": "Aiz"
    }

def short_fa_str(fs_json):
    fa_string = fa_str(fs_json)
    for original, replacement in SHORT_FA_STRS.items():
        fa_string = fa_string.replace(original, replacement)
    return fa_string

SHORT_TOGI_COLORS = {
    "Green": "Gr",
    "Cyan": "Cy",
    "Red": "Re",
    "Blue": "Bl",
    "Purple": "Pu",
    "Yellow": "Ye"
}

import pprint

def togis(fs):
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

def short_togi_str(fs):
    short_togis = []
    for togi in togis(fs):
        for color, short in SHORT_TOGI_COLORS.items():
            togi = togi.replace(color, short)
        short_togis.append(togi)
    return "/".join(short_togis)

def shortest_togi_str(fs):
    s = short_togi_str(fs)
    for color in SHORT_TOGI_COLORS.values():
        s = s.replace(color + " ", "") 
    return s

def artifact_nodes(fs):
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

def parse_disaster_snapshot():
    lk_data = json.load(open("lk_leaderboard_20230201.json.pretty"))["data"]["manual"]
    glori_data = json.load(open("glori_leaderboard_20230201.json.pretty"))["data"]["manual"]

    max_name_length = 1
    for i, lk_disaster in enumerate(lk_data):
        for player in lk_disaster["topRank"]:
            if player["playerId"] != "1738235":
                max_name_length = max(max_name_length, wcwidth.wcswidth(player["playerName"]))
        for player in glori_data[i]["topRank"]:
#            print(player["playerName"], player["playerId"], wcwidth.wcswidth(player["playerName"]))
            max_name_length = max(max_name_length, wcwidth.wcswidth(player["playerName"]))
    
    print(f"{'lk':^35} {'glori':^35}")
    for i, disaster in enumerate(lk_data):
        print()
        print(DISASTER_NAMES[str(disaster["questId"])])
        print()
        
        lk_players = disaster["topRank"]
        glori_players = glori_data[i]["topRank"]
        players = 3
        if parse_args().show_secrets:
            players = 4
        for i in range(0, players):
            # Some brutal one off hacks due to fstrings and wcwidth not measuring lengths of unicode strings correctly
            if lk_players[i]["playerId"] == "1738235":
                print(f"{lk_players[i]['playerName']:{max_name_length - 5}} {lk_players[i]['playerDamage']:<14,}   {glori_players[i]['playerName']:20} {glori_players[i]['playerDamage']:12,}")
            else:
                if glori_players[i]["playerId"] == "111684":
                    print(f"{lk_players[i]['playerName']:{max_name_length}} {lk_players[i]['playerDamage']:<14,}   {glori_players[i]['playerName']:10} {glori_players[i]['playerDamage']:12,}")
                else:
                    print(f"{lk_players[i]['playerName']:{max_name_length}} {lk_players[i]['playerDamage']:<14,}   {glori_players[i]['playerName']:20} {glori_players[i]['playerDamage']:12,}")
            for j in range(0, 5):
                lk_fs = lk_players[i]['playerCards'][j]
                glori_fs = glori_players[i]['playerCards'][j]
                print(f"  {fs_str(lk_fs):23} {short_fa_str(lk_fs)}    {fs_str(glori_fs):23} {short_fa_str(glori_fs)}")
                if parse_args().show_secrets:
#                    print(fs_skills(lk_fs))
                    print(f"    {shortest_togi_str(lk_fs):29}         {shortest_togi_str(glori_fs)}")
            print()
        print()
        
if __name__ == '__main__':
    fs_map = load_fs_map()
    fa_map = load_fa_map()
    togi_map = load_togi_map()

#    parse_goose_barnacle_leaderboards()
#    parse_disaster_manual()
    parse_disaster_snapshot()
