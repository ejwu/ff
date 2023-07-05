#!/usr/bin/python

import json

root = "ff20230703tl"
scenes = ['480']

data = json.load(open("/home/ejwu/ff/" + root + "/com.egg.foodandroid/files/publish/conf/en-us/activityQuest/cardWords.json"))

roles = {}
for role_id, role in json.load(open("/home/ejwu/ff/" + root + "/com.egg.foodandroid/files/publish/conf/en-us/quest/role.json")).items():
    roles[role_id] = role['roleName']

fss = {}
for fs_id, fs in json.load(open("/home/ejwu/ff/" + root + "/com.egg.foodandroid/files/publish/conf/en-us/card/card.json")).items():
    fss[str(fs_id)] = fs['name']
    # FS are named in the story files by id or by skin_id
    for i, skin in fs["skin"].items():
        for skin_id in skin.keys():
            if int(i) > 2:
                fss[str(skin_id)] = fs['name'] + ' (skin)'
            else:
                fss[str(skin_id)] = fs['name']


for i in data:
    if i in scenes:
        for scene in data[i]:
            if scene['name'] in roles:
                print(f"\n{roles[scene['name']]}: {scene['desc']}")
            else:
                print(f"\n{fss[scene['name']]}: {scene['desc']}")

