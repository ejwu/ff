#!/usr/bin/python

import json

rewards = json.load(open("/home/ejwu/ff/ff20230721/com.egg.foodandroid/files/publish/conf/en-us/cardSkinCollection/skinRewards.json"))

goods = json.load(open("/home/ejwu/ff/ff20230721/com.egg.foodandroid/files/publish/conf/en-us/goods/other.json"))
achieves = json.load(open("/home/ejwu/ff/ff20230721/com.egg.foodandroid/files/publish/conf/en-us/goods/achieveReward.json"))

for reward in rewards.values():
    print(reward["name"].replace("_target_num_", reward["targetNum"]))
    if len(reward["rewards"]) > 1:
        exit()
    item = reward["rewards"][0]
    goodsId = str(item["goodsId"])
    if item["type"] == 89:
        print(item["num"], goods[goodsId]["name"])
    elif item["type"] == 50:
        print(achieves[goodsId]["name"])
        print(achieves[goodsId]["descr"])
    else:
        print("error", reward)
    print()
