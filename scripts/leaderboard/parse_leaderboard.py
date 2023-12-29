#!/usr/bin/python

import argparse
from collections import Counter
from collections import defaultdict
from collections import OrderedDict
import datetime
from dateutil.parser import parse
import itertools
import json
import wcwidth

BASE_PATH = "/home/ejwu/ff/ff20231027/com.egg.foodandroid/files/"

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

def load_fa_map():
    fa_data = json.load(open(BASE_PATH + "publish/conf/en-us/pet/pet.json"))
    fa_map = {}
    for fa in fa_data:
        fa_map[fa] = fa_data[fa]["name"]
    return fa_map

togi_color_map = {"1": "Cyan", "2": "Blue", "3": "Red", "4": "Yellow", "5": "Purple", "6": "Green"}

def load_togi_map():
    togi_data = json.load(open(BASE_PATH + "res_sub/conf/en-us/artifact/gemstone.json"))
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
        return "     no FA"
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
    togis_str = "/".join(short_togis)
    if len(fs["artifactTalent"]) == 18:
        togis_str += " +"
    elif "11" in fs["artifactTalent"]:
        togis_str += " B"
    elif "13" in fs["artifactTalent"]:
        togis_str += " E"
    else:
        togis_str += " ?"

    return togis_str

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
    "1015412": 10,
    # 有五核大米無腦上即可
    "111684": 10,
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
                current = parse(node['createTime'])
                if current > latest:
                    latest = current
        if fs['marryTime']:
            current = datetime.datetime.fromtimestamp(int(fs['marryTime']))
            if current > latest:
                latest = current
        
    return latest.date()


def parse_disaster_snapshot():
    lk_data_202302 = json.load(open("lk_leaderboard_20230201.json.pretty"))["data"]["manual"]
    lk_data_202307 = json.load(open("monthly/202311_lk_disaster.json"))["data"]["manual"]

    glori_data_202302 = json.load(open("glori_leaderboard_20230201.json.pretty"))["data"]["manual"]
    glori_data_202307 = json.load(open("monthly/202311_glori_disaster.json"))["data"]["manual"]

    first = lk_data_202307
    second = glori_data_202307
    
    max_name_length = 1
    for i, lk_disaster in enumerate(first):
        for player in lk_disaster["topRank"]:
            if player["playerId"] in SPECIAL_NAME_LENGTHS:
                max_name_length = max(max_name_length, 2 * SPECIAL_NAME_LENGTHS[player["playerId"]])
            else:
                max_name_length = max(max_name_length, wcwidth.wcswidth(player["playerName"]))
        for player in second[i]["topRank"]:
            if player["playerId"] in SPECIAL_NAME_LENGTHS:
                max_name_length = max(max_name_length, 2 * SPECIAL_NAME_LENGTHS[player["playerId"]])
            else:
                max_name_length = max(max_name_length, wcwidth.wcswidth(player["playerName"]))
    
    print(f"{'lk':^35} {'glori':^35}")
    for i, disaster in enumerate(first):
        fs_togis = defaultdict(list)
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
            lk_length = max_name_length
            if lk_id in SPECIAL_NAME_LENGTHS:
                lk_length = SPECIAL_NAME_LENGTHS[lk_id]
            glori_length = max_name_length
            if glori_id in SPECIAL_NAME_LENGTHS:
                glori_length = SPECIAL_NAME_LENGTHS[glori_id]
            print(f"{first_players[i]['playerName']:{lk_length}} {first_players[i]['playerDamage']:<14,}   {second_players[i]['playerName']:{glori_length}} {second_players[i]['playerDamage']:12,}")
            if parse_args().show_secrets:
                print(f"After: {get_latest_date(first_players[i])}                     After:{get_latest_date(second_players[i])}")
            for j in range(0, 5):
                lk_fs = first_players[i]['playerCards'][j]
                glori_fs = second_players[i]['playerCards'][j]

                fs_togis[fs_map[lk_fs["cardId"]]].append(shortest_togi_str(lk_fs))
                fs_togis[fs_map[glori_fs["cardId"]]].append(shortest_togi_str(glori_fs))

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
        print()
    
if __name__ == '__main__':
    fs_map = load_fs_map()
    fa_map = load_fa_map()
    togi_map = load_togi_map()

#    parse_goose_barnacle_leaderboards()
#    parse_disaster_manual()
    parse_disaster_snapshot()
