#!/usr/bin/python

import json

xp = json.load(open("/home/ejwu/ff/ff20231018/com.egg.foodandroid/files/res_sub/conf/en-us/player/level.json"))

for lvl, data in xp.items():
    print(lvl, ", ", data["exp"])
