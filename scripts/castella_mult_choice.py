#!/usr/bin/python

import json

data = json.load(open("/home/ejwu/ff/ff20240322/com.egg.foodandroid/files/publish/conf/en-us/anniversary2020/exploreOption.json"))

for index, question in data.items():
    print(question["question"])
    print(question["options"]["1"])
    print()
