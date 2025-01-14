#!/usr/bin/python

import json

data = json.load(open("/home/ejwu/ff/ff20241118/com.egg.foodandroid/files/publish/conf/en-us/anniversary2/exploreOption.json"))

for index, question in data["1"].items():
    print(question["question"])
    print(question["options"]["1"])
    print()
