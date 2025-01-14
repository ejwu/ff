from collections import Counter
import json
import re

BASE_PATH = "/home/ejwu/ff/ff20241218/com.egg.foodandroid/files/"

FA_NATURES = {"1": "Brave", "2": "unknown2", "3": "Cautious", "4": "unknown4", "5": "unknown5", "6": "Resolute"}
TOGI_COLORS = {"1": "Cyan", "2": "Blue", "3": "Red", "4": "Yellow", "5": "Purple", "6": "Green"}
STATS = {"1": "Atk", "2": "?", "3": "HP", "4": "?", "5": "?", "6": "Spd"}
FA_LINE_QUALITY = {"1": "1", "2": "2", "3": "3", "4": "Purple", "5": "Orange"}

def blah():
    print("blah")
    exit()

def load_fs_map():
    fs_data = json.load(open(BASE_PATH + "publish/conf/en-us/card/card.json"))
    fs_map = {}
    for fs in fs_data:
        fs_map[fs] = fs_data[fs]["name"]
        if fs_data[fs]["qualityId"] == "5":
            fs_map[fs] = "SP " + fs_data[fs]["name"]
    return fs_map

def load_fa_map():
#    fa_data = json.load(open(BASE_PATH + "publish/conf/en-us/pet/pet.json"))
    fa_data = json.load(open(BASE_PATH + "res_sub/conf/en-us/pet/pet.json"))
    fa_map = {}
    for fa in fa_data:
        fa_map[fa] = fa_data[fa]["name"]
    return fa_map

def load_togi_map():
    togi_data = json.load(open(BASE_PATH + "res_sub/conf/en-us/artifact/gemstone.json"))
    togi_map = {}
    for togi in togi_data:
        togi_map[togi] = f"{TOGI_COLORS[togi_data[togi]['color']]} {togi_data[togi]['name'][0]}{togi_data[togi]['grade']}"
    return togi_map

def fs_skills(fs):
    skill_levels = []
    for skill in fs["skill"].values():
        skill_levels.append(str(skill["level"]))
    return "/".join(skill_levels)

# "5* Dunhuang Dogbane Tea"
def fs_str(fs_json):
    return str(fs_json["breakLevel"]) + "* " + fs_map[fs_json["cardId"]]

# "5* T5 Dunhuang Dogbane Tea"
def fs_arti_level_str(fs_json):
    return f"{fs_json['breakLevel']}* {artifact_nodes(fs_json)} {fs_map[fs_json['cardId']]}"

def fs_name(fsid):
    return fs_map[fsid]

def combined_fa_str(fs):
    return f"{short_fa_str(fs)} -{fa_lines(fs, short=True)[33:]}"

def fa_str(fs):
    if not "pets" in fs:
        return "     no FA"
    fa = fs["pets"]["1"]

    if str(fa['level']) != '30':
        return f"Lvl {fa['level']} +{fa['breakLevel']} {FA_NATURES[str(fa['character'])]} {fa_map[str(fa['petId'])]}"

    # For some crazy reason fa['character'] and fa['petId'] are sometimes ints instead of strings.
    # Cast them so we can look them up
    return f"+{fa['breakLevel']} {FA_NATURES[str(fa['character'])]} {fa_map[str(fa['petId'])]}"

# "+14 Cautious Thundaruda 3x Orange Atk 1x Purple Spd"
def fa_lines(fs, short=False):
    lines = Counter()
    line_str = ""
    if "pets" in fs:
        if len(fs["pets"]) != 1:
            print(len(fs["pets"]))

        for attr in fs["pets"]["1"]["attr"]:
            # For some insane reason quality and type are sometimes strings and sometimes int, so just cast them all
            lines[f"{FA_LINE_QUALITY[str(attr['quality'])]} {STATS[str(attr['type'])]}"] += 1
        for line, count in lines.most_common():
            if short:
                line_str += f"{count}x {line.lstrip('Orange ')} "
            else:
                line_str += f"{count}x {line} "
        
    return f"{fa_str(fs):33} {line_str}"

SHORT_FA_STRS = {
    "Brave" : "Br",
    "Resolute": "Re",
    "Cautious": "Ca",
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

# "+15 Re UME"
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

SHORT_TOGI_COLORS_REVERSED = {v:k for k, v in SHORT_TOGI_COLORS.items()}

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

# A6/B4/A7/S6/S7
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
            #print(togi_map[str(node["gemstoneId"])])
            togi_str = togi_map[str(node["gemstoneId"])].split()[1]
            togi_strs.append(togi_str if togi_str else "xx")
#            togi_strs.append(togi_map[str(node["gemstoneId"])].split()[1])
            togis += 1
#    print(",".join(togi_strs))
            
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

def update_togi_counts(counts, fs):
    togi_str = short_togi_str(fs)
    for togi in togi_str.split('/'):
        if not togi.startswith('EMPTY') and not togi.startswith('LOCKED') and togi is not " ?":
            counts[SHORT_TOGI_COLORS_REVERSED[togi[0:2]]][togi[3:5]] += 1

def togi_value(fs):
    total = 0
    for level in re.finditer("\d+", shortest_togi_str(fs)):
        total += pow(3, int(level.group(0)) - 1)
    return total

def togi_value_str(level_1_count):
    return f"{level_1_count:,} L1 togis, or ~{float(level_1_count) / pow(3, 9):.3} L10 togis"

FA_TO_MIRRORS = {"0": 0, "1": 1, "2": 2, "3": 3, "4": 5, "5": 6, "6": 8, "7": 11, "8": 16, "9": 23, "10": 33, "11": 71, "12": 151, "13": 280, "14": 462, "15": 702, "16": 1081, "17": 1604, "18": 2381, "19": 3300, "20": 4551} 

def mirror_value(fs):
    total = 0
    m = re.search(r"\+(\d+)", short_fa_str(fs))
    if m:
        total += FA_TO_MIRRORS[m.group(1)]
    return total

def mirror_value_str(num_mirrors):
    return f"~{num_mirrors:,} mirrors/FAs, or ~{float(num_mirrors) / FA_TO_MIRRORS['20']:.4} +20s"


# init somehow?
fs_map = load_fs_map()
fa_map = load_fa_map()
togi_map = load_togi_map()
