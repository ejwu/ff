#!/usr/bin/python
from collections import Counter
import math
import random

pity = 2

def get_pity(rates):
    return rates[1]

def get_result(roll, rates):
    for threshold in rates.keys():
        if roll < threshold:
            return rates[threshold]

# rates, then pity
# .92, .05, .03
base = [{0.92: 1, 0.97: 2, 1: 3}, 2]
# .905, .05, .03, .015
advanced = [{0.905: 2, 0.955: 3, 0.985: 4, 1: 5}, 3]
cat = [{ 0.905: 3, 0.955: 4, 0.985: 5, 1: 6}, 4]


ten_rolls = 1000000

for r in [base, advanced, cat]:
    hit_pity = 0
    levels = Counter()
    for i in range(ten_rolls):
        has_good_result = False
        for j in range(9):
            x = random.random()
            result = get_result(x, r[0])
            levels[result] += 1
            if result != get_pity(r) - 1:
                has_good_result = True

        if not has_good_result:
            levels[get_pity(r)] += 1
            hit_pity += 1
        else:
            levels[get_result(x, r[0])] += 1

#    print(levels)

    print(f"{ten_rolls} x10 rolls, hit pity {hit_pity} times")
    roll_value = 0
    for togi_level in levels.keys():
        print(f"{togi_level}: {levels[togi_level] / (ten_rolls * 10)}")
        roll_value += levels[togi_level] * math.pow(3, togi_level - 1)
    print(f"Equivalent to {roll_value / ten_rolls:.2f} level 1 togis per 10x roll")

