#!/usr/bin/python

import glob
import json
from pathlib import Path
import sys

# Get the file in /publish if it exists, otherwise fall back to /res_sub
def get_file(path):
    pub_file = PUB_PATH / path
    if pub_file.exists():
        return pub_file
    return RES_PATH / path

PUB_PATH = Path("/home/ejwu/ff/ff20231221") / "com.egg.foodandroid" / "files" / "publish" / "conf" / "en-us"
RES_PATH = Path("/home/ejwu/ff/ff20231221") / "com.egg.foodandroid" / "files" / "res_sub" / "conf" / "en-us"

args = sys.argv[1:]

print(args)

for artifile in glob.glob("/home/ejwu/ff/ff20231221/com.egg.foodandroid/files/publish/conf/en-us/artifact/gemstoneSkill[0-9]*"):
    arti = json.load(open(artifile))
    for k, v in arti.items():
        if k == args[0]:
            print(json.dumps(v, indent=2))
            exit()
            
for artifile in glob.glob("/home/ejwu/ff/ff20231221/com.egg.foodandroid/files/res_sub/conf/en-us/artifact/gemstoneSkill[0-9]*"):
    arti = json.load(open(artifile))
    for k, v in arti.items():
        if k == args[0]:
            print(json.dumps(v, indent=2))

