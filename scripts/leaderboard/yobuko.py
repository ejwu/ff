#!/usr/bin/python

from ffutil.secret import (fa_str, fs_str, short_fa_str, short_togi_str, shortest_togi_str)
import json
import sys

def main():
    data = json.load(open('yobuko_glori.json'))['data']['rank']
    for i, player in enumerate(data):
        print(i, player['playerName'])
        for _, fs in player['playerCards'].items():
            print(f"{fs_str(fs)} {fa_str(fs)}")
            print(f"  {short_togi_str(fs)}")
            print()

if __name__ == '__main__':
    sys.exit(main())
