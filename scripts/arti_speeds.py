#!/usr/bin/python

from collections import defaultdict
import json

FS_RARITY = {"5": "SP", "4": "UR", "3": "SR", "2": " R", "1": " M"}
FS_TYPE = {"1": "Def", "2": "Str", "3": "Mag", "4": "Sup"}

fs_map = {}

speed_map = {}

final_speeds = defaultdict(list)

for fsid, fs in json.load(open("/home/ejwu/ff/ff20231225/com.egg.foodandroid/files/res_sub/conf/en-us/card/card.json")).items():
    fs_map[fsid] = FS_RARITY[fs["qualityId"]] + " " + FS_TYPE[fs["career"]] + " " + fs["name"]

for fsid, arti in json.load(open("/home/ejwu/ff/ff20231225/com.egg.foodandroid/files/res_sub/conf/en-us/artifact/talentPoint.json")).items():
    num_speed_nodes = 0
    total_speed = 0
    for i, node in arti.items():
        if node["artifactAttrType"] and node["artifactAttrType"][0] == "6":
            num_speed_nodes += 1
            total_speed += int(node["artifactAttrNum"][-1])

    if fsid in fs_map and (total_speed != 4940 or num_speed_nodes > 1):
        final_speeds[total_speed].append(f"{fs_map[fsid]:34} {num_speed_nodes} node(s) for {total_speed}")


for i in sorted(final_speeds):
    for fs in final_speeds[i]:
        print(fs)

#            print(f"{node['artifactAttrNum'][-1]} {fs_map[fsid]}")
#            print(fsid, i, len(node["artifactAttrType"]), node["artifactAttrNum"][-1])
