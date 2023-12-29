#!/usr/bin/python

import json

data = json.load(open("/home/ejwu/ff/ff20230712b/com.egg.foodandroid/files/publish/conf/en-us/anniversary2021/plotFillQuestion.json"))

for question in data.values():
    s = question["summary"]
    s = s.replace("_target_num_1_", question["answer"]["1"].split(",")[0])
    s = s.replace("_target_num_2_", question["answer"]["2"].split(",")[0])
    print(s)

