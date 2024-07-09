#!/usr/bin/python

from collections import defaultdict
from collections import OrderedDict
import glob
import json
import math
from pathlib import Path
import pprint
import sys

PATH_DATE = "ff20240529"
BASE_PATH = Path("/") / "home" / "ejwu" / "ff" / PATH_DATE / "com.egg.foodandroid" / "files"
PUB_PATH = BASE_PATH / "publish" / "conf" / "en-us"
RES_PATH = BASE_PATH / "res_sub" / "cards" / "spine" / "effect"

cards = json.load(open(PUB_PATH / "card" / "card.json"))
cardSkins = json.load(open(PUB_PATH / "goods" / "cardSkin.json"))

fsid_to_name = {}
skinid_to_name = {}
spineid_to_name = {}
skinid_to_value = {}
fsid_to_skinids = defaultdict(list)
# Really an ordered set
fsid_to_spineids = defaultdict(dict)

total_skins = 0

for cardId, card in cards.items():
    
    if len(card["skin"]) > 2:
#        print(cards[card]["name"])
#        print(card)
#        print(cards[card]["skin"])
        total_skins += len(card["skin"])
        fsid_to_name[cardId] = card["name"]
        for skins in card["skin"].values():
            for skin_id in skins:
                cardSkin = cardSkins[skin_id]
                skinid_to_name[skin_id] = cardSkin["name"]
                if not cardSkins[skin_id]["spineId"] in spineid_to_name:
                    spineid_to_name[cardSkin["spineId"]] = cardSkin["name"]
                fsid_to_skinids[cardId].append(skin_id)
                fsid_to_spineids[cardId][cardSkin["spineId"]] = None
                if cardSkin["changeGoods"]:
                    skinid_to_value[skin_id] = cardSkin["changeGoods"][0]["num"]
                    if cardSkin["changeGoods"][0]["goodsId"] != 890006:
                        print("weird skin value", cardSkin["name"])
                        print(cardSkin)
                    if len(cardSkin["changeGoods"]) != 1:
                        print(cardSkin)
                        exit()
                

#        for skin_id in map(lambda s : next(iter(s)), cards[card]["skin"].values()):
#            skinid_to_name[skin_id] = cardSkins[skin_id]["name"]
#            spineid_to_name[cardSkins[skin_id]["spineId"]] = cardSkins[skin_id]["name"]
#            fsid_to_skinids[card].append(skin_id)
        if not (RES_PATH / f"{cardId}.json").exists():
            print("missing", card["name"], cardId, fsid_to_skinids[cardId])
    else:
        # No skins, still want to show default
        fsid_to_name[cardId] = card["name"]
        print(card["skin"].values())
        skin_id = next(iter(next(iter(card["skin"].values())).keys()))
        skinid_to_name[skin_id] = cardSkins[skin_id]["name"]
        if not cardSkins[skin_id]["spineId"] in spineid_to_name:
            spineid_to_name[cardSkins[skin_id]["spineId"]] = cardSkins[skin_id]["name"]
        fsid_to_skinids[cardId].append(skin_id)
        fsid_to_spineids[cardId][cardSkins[skin_id]["spineId"]] = None
        if not (RES_PATH / f"{cardId}.json").exists():
            print("missing", card["name"], cardId, fsid_to_skinids[cardId])

            
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
        print(effects)
        print(weights)
        print("weights are wonky")
        splits.append(f" total is {weights}%?!?")
#        exit()

    return ", ".join(splits)


# Sake default no weights on basic, probably triggers twice for 200%
# Almond Tofu skin no time on basic, no heals
# see "100%?" or "Bugged" for more
num_spines = 0

def print_timings(spine, outfile, skip=False):
    animations = avatar_spine[spine]["animations"]
    attack = animations["attack"]["duration"]
    attack_trigger = "Bugged"
    if "events" in animations["attack"]:
        attack_trigger = get_average_time(animations["attack"]["events"]["cause_effect"], spine)
    basic = animations["skill1"]["duration"]
    basic_trigger = get_average_time(animations["skill1"]["events"]["cause_effect"], spine)
    energy = animations["skill2"]["duration"]
    energy_trigger = get_average_time(animations["skill2"]["events"]["cause_effect"], spine)
    if not skip:
        print(f"{spineid_to_name[spine]:23} | {attack:8.2f} | {basic:8.2f} | {energy:8.2f} | {attack_trigger:8} | {basic_trigger:8} | {energy_trigger:8}")
    if outfile:
        outfile.write(f"{spineid_to_name[spine]:23} | {attack:8.2f} | {basic:8.2f} | {energy:8.2f} | {attack_trigger:8} | {basic_trigger:8} | {energy_trigger:8}\n")
    return attack, basic

def output_fsdb_row(fsid, spine, outfile):
#    print("spine is", spine)
    row = [spine, spineid_to_name[spine], fsid, fsid_to_name[fsid]]

    animations = avatar_spine[spine]["animations"]
#    print(avatar_spine[spine])
    row.append(str(animations["attack"]["duration"]))
    row.append(str(animations["skill1"]["duration"]))
    row.append(str(animations["skill2"]["duration"]))
    attack_trigger = "Bugged"
    if "events" in animations["attack"]:
        attack_trigger = get_average_time(animations["attack"]["events"]["cause_effect"], spine)
    row.append(str(attack_trigger))
    row.append(str(get_average_time(animations["skill1"]["events"]["cause_effect"], spine)))
    row.append(str(get_average_time(animations["skill2"]["events"]["cause_effect"], spine)))
#    print("|".join(row))
    outfile.write("|".join(row))
    outfile.write("\n")

skin_outputs = open("skin_speeds.txt", "w")
default_outputs = open("default_speeds.txt", "w")
voucher_outputs = open("skin_values.txt", "w")
fsdb_outputs = open("fsdb_data.psv", "w")

print(skinid_to_value)

for card in fsid_to_name:
    if len(fsid_to_spineids[card]) > 1:
        print()
        print(fsid_to_name[card])
        skin_outputs.write("\n")
        skin_outputs.write(fsid_to_name[card] + "\n")
        for spine in fsid_to_spineids[card]:
            num_spines += 1
            print_timings(spine, skin_outputs, True)
            output_fsdb_row(card, spine, fsdb_outputs)
            

        for skinid in fsid_to_skinids[card]:
            if skinid in skinid_to_value:
                voucher_outputs.write("\n")
                voucher_outputs.write(fsid_to_name[card] + "\n")
                voucher_outputs.write(f"{skinid_to_name[skinid]} {skinid_to_value[skinid]}\n")
    else:
        assert len(fsid_to_spineids[card]) == 1, "shouldn't have more than one skin"
        print()
        print(fsid_to_name[card])
        default_outputs.write("\n")
        default_outputs.write(fsid_to_name[card] + "\n")
        for spine in fsid_to_spineids[card]:
            num_spines += 1
            print_timings(spine, default_outputs, True)
            output_fsdb_row(card, spine, fsdb_outputs)

skin_outputs.close()
default_outputs.close()
voucher_outputs.close()
fsdb_outputs.close()
print()
print(f"{len(fsid_to_name)} FS, {num_spines} spines ({num_spines - len(fsid_to_name)} skins)")

worst_autos = defaultdict(list)
worst_basics = defaultdict(list)

for card in fsid_to_name:
    if len(fsid_to_spineids[card]) > 1:
        print()
        print(fsid_to_name[card])
        default_attack = 0
        default_basic = 0
        for spine in fsid_to_spineids[card]:
            skin_name = spineid_to_name[spine]
            attack, basic = print_timings(spine, None)
            if "Default" == skin_name:
                default_attack = attack
                default_basic = basic
        # Hack for cases where Default doesn't come first
        for spine in fsid_to_spineids[card]:
            skin_name = spineid_to_name[spine]
            attack, basic = print_timings(spine, None)
            if "Default" != skin_name:
                worst_autos[round((float(attack - default_attack)), 3)].append(f"{fsid_to_name[card]}: {skin_name}")
                worst_basics[round((float(basic - default_basic)), 3)].append(f"{fsid_to_name[card]}: {skin_name}")

                print()
print("Worst autoattack slowdowns")
for i in list(reversed(sorted(worst_autos.items())))[:15]:
    print(i)

print()
print("Worst basic slowdowns")
for i in list(reversed(sorted(worst_basics.items())))[:15]:
    print(i)

print()
print("Best autoattack speedups")
for i in list(sorted(worst_autos.items()))[:14]:
    print(i)

print()
print("Best basic speedups")
for i in list(sorted(worst_basics.items()))[:15]:
    print(i)




print(skinid_to_value)
print(len(skinid_to_value))
