#!/usr/bin/python

from collections import defaultdict
import glob
import json
import math
from pathlib import Path
import pprint
import sys

PATH_DATE = "ff20230721"
BASE_PATH = Path("/") / "home" / "ejwu" / "ff" / PATH_DATE / "com.egg.foodandroid" / "files"
PUB_PATH = BASE_PATH / "publish" / "conf" / "en-us"
RES_PATH = BASE_PATH / "res_sub" / "cards" / "spine" / "effect"

cards = json.load(open(PUB_PATH / "card" / "card.json"))
cardSkins = json.load(open(PUB_PATH / "goods" / "cardSkin.json"))

fsid_to_name = {}
skinid_to_name = {}
spineid_to_name = {}
fsid_to_skinids = defaultdict(list)
# Really an ordered set
fsid_to_spineids = defaultdict(dict)

total_skins = 0

for card in cards:
    
    if len(cards[card]["skin"]) > 2:
#        print(cards[card]["name"])
#        print(card)
#        print(cards[card]["skin"])
        total_skins += len(cards[card]["skin"])
        fsid_to_name[card] = cards[card]["name"]
        for skins in cards[card]["skin"].values():
            for skin_id in skins:
                skinid_to_name[skin_id] = cardSkins[skin_id]["name"]
                if not cardSkins[skin_id]["spineId"] in spineid_to_name:
                    spineid_to_name[cardSkins[skin_id]["spineId"]] = cardSkins[skin_id]["name"]
                fsid_to_skinids[card].append(skin_id)
                fsid_to_spineids[card][cardSkins[skin_id]["spineId"]] = None

#        for skin_id in map(lambda s : next(iter(s)), cards[card]["skin"].values()):
#            skinid_to_name[skin_id] = cardSkins[skin_id]["name"]
#            spineid_to_name[cardSkins[skin_id]["spineId"]] = cardSkins[skin_id]["name"]
#            fsid_to_skinids[card].append(skin_id)
        if not (RES_PATH / f"{card}.json").exists():
            print("missing", cards[card]["name"], card, fsid_to_skinids[card])


            
#print(fsid_to_name)
#print(skinid_to_name)
#print(fsid_to_skinids)
#for fsid, skinids in fsid_to_skinids.items():
#    print(fsid_to_name[fsid])
#    for skinid in sorted(skinids):
#        print("   ", skinid_to_name[skinid])

print(len(fsid_to_name), "FS with multiple skins,", total_skins, "skins")



#250240, 250241, 250243, 250244
#252110, 252111, 252113

def get_total_time(animation):
    t = 0
    for frame in animation["attachment"]:
        t = max(t, frame["time"])
    return t

# interesting numbers in effectSpine.json


avatar_spine = json.load(open(PUB_PATH / "card" / "avatarSpine.json"))
not_found = set()
for spine_id, data in avatar_spine.items():
    if spine_id in spineid_to_name:
        print(spine_id)
        print(spineid_to_name[spine_id])
    else:
        not_found.add(spine_id)

print(len(not_found), "not found")


def get_average_time(effects, spine_id):
    weights = 0
    weight_error = False
    if len(effects) == 1:
        return effects[0]["time"]
    splits = []
    for effect in effects:
        if not "intValue" in effect:
            weight_error = True
            splits.append(f"{effect['time']}: 100%?")
        else:
            weights += effect['intValue']
            splits.append(f"{effect['time']}: {effect['intValue']}%")

    if weights != 100 and not weight_error:
        exit()

    return ", ".join(splits)


# Sake default no weights on basic, probably triggers twice for 200%
# Almond Tofu skin no time on basic, no heals
# see "100%?" or "Bugged" for more
for card in fsid_to_name:
    print()
    print(fsid_to_name[card])
    for spine in fsid_to_spineids[card]:
#        print(spine)
        animations = avatar_spine[spine]["animations"]
        attack = animations["attack"]["duration"]
        attack_trigger = "Bugged"
        if "events" in animations["attack"]:
            attack_trigger = get_average_time(animations["attack"]["events"]["cause_effect"], spine)
        basic = animations["skill1"]["duration"]
        basic_trigger = get_average_time(animations["skill1"]["events"]["cause_effect"], spine)
        energy = animations["skill2"]["duration"]
        energy_trigger = get_average_time(animations["skill2"]["events"]["cause_effect"], spine)
        print(f"{spineid_to_name[spine]:23} | {attack:8.2f} | {basic:8.2f} | {energy:8.2f} | {attack_trigger:8} | {basic_trigger:8} | {energy_trigger:8}")
            









