#!/usr/bin/python
from collections import Counter
import math
import random
from statistics import quantiles

pity = 2

def get_result(roll, rates):
    for threshold in rates.keys():
        if roll < threshold:
            return rates[threshold]

def get_pity(roll, rates):
    return max(get_result(roll, rates[0]), rates[1])

def get_togi_value(ten_roll):
    roll_value = 0
    for togi_level in ten_roll:
        roll_value += math.pow(3, togi_level - 1)
    return int(roll_value)

# rates, minimum togi at pity, costs, labels

# .92, .05, .03
base = [{0.92: 1, 0.97: 2, 1: 3}, 2, "normal",
        [15, 10, 20 / 1.7 / 6],
        ["shop", "monopoly event", "dunhuang shop"]]
# .905, .05, .03, .015
advanced = [{0.905: 2, 0.955: 3, 0.985: 4, 1: 5}, 3, "advanced",
            [45, 59 / 1.5, 36, 59 / 3, 80 / 1.7 / 2],
            ["shop", "sweep", "monopoly event", "sweep + double drop", "dunhuang shop"]]
cat = [{ 0.905: 3, 0.955: 4, 0.985: 5, 1: 6}, 4, "cat paw", [125], ["shop"]]

overall_values = {}

ten_rolls = 1000000

arrays = {}

for r in [base, advanced, cat]:
    roll_values = []
    hit_pity = 0
    levels = Counter()
    for i in range(ten_rolls):
        current_ten_roll = []
        has_good_result = False
        for j in range(9):
            x = random.random()
            result = get_result(x, r[0])
            current_ten_roll.append(result)
            levels[result] += 1
            if result != r[1] - 1:
                has_good_result = True

        if not has_good_result:
            result = get_pity(x, r)
            levels[result] += 1
            hit_pity += 1
            current_ten_roll.append(result)
        else:
            result = get_result(x, r[0])
            levels[result] += 1
            current_ten_roll.append(result)
        roll_values.append(get_togi_value(current_ten_roll))

#    print(levels)

    print(r[2])
    print(f"{ten_rolls} x10 rolls, hit pity {hit_pity} times")
    roll_value = 0
    for togi_level in sorted(levels.keys()):
        print(f"{togi_level}: {levels[togi_level] / (ten_rolls * 10)}")
        roll_value += levels[togi_level] * math.pow(3, togi_level - 1)
    print(f"Equivalent to {roll_value / ten_rolls:.2f} level 1 togis per 10x roll")
    print(quantiles(roll_values, n=50))
    for i, cost in enumerate(r[3]):
        source = ""
        if len(r) > 4:
            source = f"({r[4][i]})"
        crystal_cost = "{:.2f}".format(cost * 10 / (roll_value / ten_rolls))
        print(f"At cost {cost:.2f}, {crystal_cost} crystals per level 1 togi {source}")
        overall_values[float(crystal_cost)] = f"{r[2]:8} - {source}"
    print()

print(sorted(overall_values))
print(overall_values)
print()
print("Crystals per level 1 togi equivalent")
for cost in sorted(overall_values):
    print(f"{cost:5} - {overall_values[cost]}")

print(get_togi_value([2, 2, 2, 2, 2, 2, 2, 2, 4, 5]))
