#!/usr/bin/python

import json

data = json.load(open("/home/ejwu/ff/ff20230801/com.egg.foodandroid/files/publish/conf/en-us/anniversary2021/storyCollection.json"))

for i in range(7, 27):
    print(data[str(i)]["resume"])
