#!/usr/bin/python

import json

data = json.load(open("exploreOption.json.pretty"))

for index, question in data.items():
    print(question["question"])
    print(question["options"]["1"])
    print()
