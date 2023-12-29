#!/usr/bin/python

import json

for i, data in json.load(open("/home/ejwu/ff/ff20231121/com.egg.foodandroid/files/publish/conf/en-us/skinCarnival/skinStory.json")).items():
    if int(i) >= 253673:
        print("\n----------------------------------------------\n")
        print(data["descr"])
