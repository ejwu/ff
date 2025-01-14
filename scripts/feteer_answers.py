#!/usr/bin/python

import json

data = json.load(open("/home/ejwu/ff/ff20240930/com.egg.foodandroid/files/publish/conf/en-us/anniversary2023/boss.json"))
option_data = json.load(open("/home/ejwu/ff/ff20240930/com.egg.foodandroid/files/publish/conf/en-us/anniversary2023/bossOptions.json"))
skill_data = json.load(open("/home/ejwu/ff/ff20240930/com.egg.foodandroid/files/publish/conf/en-us/anniversary2023/roleSkill.json"))

skills = {}
options = {}

for i, v in skill_data.items():
    skills[i] = v

for _, v in option_data.items():
    for i, v2 in v.items():
        options[i] = v2

for _, v in data.items():
    print("\n----------------------------")
    print(v['descr'])
    print()
    for optionId in v['optionIds']:
        option = options[optionId]
        print(f"  {option['descr']}")
        print(f"    {option['diceCondition']} {option['diceNum']}")
        print(f"    {skills[option['skills'][0]]['descr']} / {skills[option['skills'][1]]['descr']}")


