#!/usr/bin/python

import json

BASE_PATH = "/home/ejwu/ff/ff20231115/com.egg.foodandroid/files/publish/conf/en-us/"

for i, data in json.load(open(BASE_PATH + "battleCard/schedule.json")).items():
    # 400003: Street Card Pack: Wonderland
    # 409040: Card Player Spoils
    # 900028: 200 Obsidian
    # 890044: 100 Magic Powder
    if int(i) > 1166:
        rewards = {}
        for reward, rate in zip(data["rewards"], data["dropRate"]):
            rewards[reward["goodsId"]] = rate
#        print(i, data["date"], data["rules"], rewards)

packs = json.load(open(BASE_PATH + "goods/battleCardPack.json"))
money = json.load(open(BASE_PATH + "goods/money.json"))
other = json.load(open(BASE_PATH + "goods/other.json"))


item_names = {}
for i, data in packs.items():
    item_names[i] = data["name"]
for i, data in money.items():
    item_names[i] = data["name"]
for i, data in other.items():
    item_names[i] = data["name"]

for i, data in json.load(open("/home/ejwu/ff/ff20231115/com.egg.foodandroid/files/publish/conf/en-us/battleCard/npc.json")).items():
    print()
    print(data["name"])
    for reward, rate in zip(data["rewards"], data["dropRate"]):
        print(rate, "rate,", reward["num"], item_names[str(reward["goodsId"])]) 
