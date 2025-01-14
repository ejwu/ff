#!/usr/bin/python

import json

formulas = json.load(open("/home/ejwu/ff/ff20240322/com.egg.foodandroid/files/publish/conf/en-us/anniversary2020/hangFormula.json"))
goods = json.load(open("/home/ejwu/ff/ff20240322/com.egg.foodandroid/files/publish/conf/en-us/goods/activity.json"))

for _, f in formulas.items():
    items = []
    for i, mat in f["material"].items():
        items.append(goods[str(mat)]["name"])
    print(items)
