#!/usr/bin/python

import json

root = "ff20230822"
path = "/home/ejwu/ff/" + root + "/com.egg.foodandroid/files"
scenes = ['497']
data = json.load(open(path + "/publish/conf/en-us/activityQuest/cardWords.json"))

roles = {}
for role_id, role in json.load(open(path + "/publish/conf/en-us/quest/role.json")).items():
    roles[role_id] = role['roleName']

roles["200368"] = "Pesto Pasta"
    
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
                    print(f"\n{roles[scene['name']]}: {scene['desc']}")
                else:
                    print(f"\n{fss[scene['name']]}: {scene['desc']}")
    exit()



                    
tomahawk_event_stories = json.load(open(path + "/publish/conf/en-us/anniversary2021/story.json"))
tomahawk_story_titles = json.load(open(path + "/publish/conf/en-us/anniversary2021/storyCollection.json"))

for key, story_title in tomahawk_story_titles.items():
    if story_title["chapterName"] == "Vanishing Guilt":
        print("\n-------------------------\n")
        print(key, story_title["name"])
        for scene in tomahawk_event_stories[key]:
            if scene['name'] in roles:
                print(f"\n{roles[scene['name']]}: {scene['desc']}")
            else:
                if scene['name']:
                    print(f"\n{fss[scene['name']]}: {scene['desc']}")
                else:
                    print(f"\n{scene['desc']}")

