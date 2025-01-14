#!/usr/bin/python

import json
from pathlib import Path

root = "ff20241218"

path = str(Path.home()) + "/ff/" + root + "/com.egg.foodandroid/files"

# TODO: Fix 606 to include MC insert
scenes = ['624']
data = json.load(open(path + "/publish/conf/en-us/activityQuest/cardWords.json"))
#data = json.load(open("cardWords-cn.json"))

roles = {}
for role_id, role in json.load(open(path + "/publish/conf/en-us/quest/role.json")).items():
    roles[role_id] = role['roleName']

roles["200368"] = "Pesto Pasta"
roles["300005"] = "Amazake"
roles["300017"] = "Tanuki"
    
fss = {}
for fs_id, fs in json.load(open(path + "/publish/conf/en-us/card/card.json")).items():
    fss[str(fs_id)] = fs['name']
    # FS are named in the story files by id or by skin_id
    for i, skin in fs["skin"].items():
        for skin_id in skin.keys():
            if int(i) > 2:
                fss[str(skin_id)] = fs['name'] + ' (skin)'
            else:
                fss[str(skin_id)] = fs['name']

if True:
    for i in data:
        if i in scenes:
            for scene in data[i]:
                if not scene['name'] or scene['name'] == "role_0000":
                    print(f"\n\n    {scene['desc'].replace('_when_', '-')}\n")
                elif scene['name'] in roles:
                    print(f"\n{roles[scene['name']]}: {scene['desc'].replace('_when_', '-')}")
                else:
                    print(f"\n{fss[scene['name']]}: {scene['desc'].replace('_when_', '-')}")
    exit()



                    
#tomahawk_event_stories = json.load(open(path + "/publish/conf/en-us/anniversary2021/story.json"))
#tomahawk_story_titles = json.load(open(path + "/publish/conf/en-us/anniversary2021/storyCollection.json"))

vidal_event_stories = json.load(open(path + "/publish/conf/en-us/newSummerActivity/story.json"))
vidal_story_titles = json.load(open(path + "/publish/conf/en-us/newSummerActivity/branchStoryCollection.json"))

for key, story_title in vidal_story_titles.items():
    if story_title["name"] == "Unvanquished Heart":
        print("\n-------------------------\n")
        print(key, story_title["name"])
        for scene in vidal_event_stories[key]:
            if scene['name'] in roles:
                print(f"\n{roles[scene['name']]}: {scene['desc']}")
            else:
                if scene['name']:
                    print(f"\n{fss[scene['name']]}: {scene['desc']}")
                else:
                    print(f"\n{scene['desc'].replace('_when_', '-')}")

