#!/usr/bin/python

from collections import defaultdict
from operator import itemgetter
import json

BAR_LEVEL = 4

# TODO: Update when bar level increases
MAT_SHOP = {
    'Rum': {'cost': 50, 'num': 10},
    'Vodka': {'cost': 50, 'num': 10},
    'Brandy': {'cost': 50, 'num': 10},
    'Tequila': {'cost': 50, 'num': 10},
    'Gin': {'cost': 50, 'num': 10},
    'Whisky': {'cost': 50, 'num': 10},
    'Coffee Liqueur': {'cost': 20, 'num': 4},
    'Cola': {'cost': 20, 'num': 4},
    'Cane Syrup': {'cost': 20, 'num': 4},
    'Honey': {'cost': 20, 'num': 4},
    'Lemon Juice': {'cost': 20, 'num': 4},
    'Mint Leaf': {'cost': 20, 'num': 4},
    'Soda Water': {'cost': 20, 'num': 4},
    'Pineapple Juice': {'cost': 20, 'num': 4},
    'Sugar': {'cost': 20, 'num': 4},
    'Orange Juice': {'cost': 20, 'num': 4}}


materials_json = json.load(open("/home/ejwu/ff/ff20211026/com.egg.foodandroid/files/publish/conf/en-us/bar/material.json.pretty"))
bar_level_json = json.load(open("/home/ejwu/ff/ff20211026/com.egg.foodandroid/files/publish/conf/en-us/bar/levelUp.json.pretty"))
formula_json = json.load(open("/home/ejwu/ff/ff20211026/com.egg.foodandroid/files/publish/conf/en-us/bar/formula.json.pretty"))
drink_json = json.load(open("/home/ejwu/ff/ff20211026/com.egg.foodandroid/files/publish/conf/en-us/bar/drink.json.pretty"))

bar_level = defaultdict(dict)
drinks = defaultdict(dict)
material_costs = defaultdict(dict)

# Populate stock limits for each bar level
for level in bar_level_json.values():
    bar_level[level["level"]] = int(level["stockNum"])

# Populate material availability and cost in the market
for key, material in materials_json.items():
    mat_name = material["name"]
    material_costs[key]["name"] = mat_name
    if mat_name in MAT_SHOP:
        material_costs[key]["cost"] = MAT_SHOP[mat_name]["cost"]
        material_costs[key]["num"] = MAT_SHOP[mat_name]["num"]

# Populate drink rewards
for drink_obj in drink_json.values():
    drink = drinks[drink_obj["name"]]
    drink["barFame"] = int(drink_obj["barPopularity"])
    drink["tickets"] = int(drink_obj["barPoint"])
    drink["barLevel"] = int(formula_json[str(drink_obj["formulaId"])]["openBarLevel"])
    drink["materials"] = []

# Populate drink requirements
for formula in formula_json.values():
    for material, quantity in zip(formula["materials"], formula["matching"]):
        drinks[formula["name"]]["materials"].append([material, int(quantity)])

        

#print(material_costs)

        
drinks_by_level = sorted(drinks.items(), reverse=True, key=lambda item: item[1]["barLevel"])
#for drink in drinks_by_level:
#    print(drink)

drink_setf = filter(lambda item: item[1]["barLevel"] <= BAR_LEVEL, drinks_by_level)
#for drink in drink_set:
#    print(drink)

drink_set = []
for drink in drink_setf:
    drink_set.append(drink)

materials_available = {}
for key, material in material_costs.items():
    if "num" in material:
        materials_available[key] = material["num"]

ALL_MATERIALS_AVAILABLE = materials_available.copy()

def can_make_drink(drink, materials_available):
    for material in drink[1]["materials"]:
        print(material)
        if materials_available[material[0]] < material[1]:
            return False
    return True

def can_make_drinks(drinks):
    materials_used = defaultdict(int)
    for drink in drinks:
        for material in drink[1]["materials"]:
            materials_used[material[0]] += material[1]

    for material, num_used in materials_used.items():
        if num_used > ALL_MATERIALS_AVAILABLE[material]:
            return False
    return True

def print_combo(combo):
    d = []
    for drink in combo:
        d.append(drink[0])
    print(d)

def print_combos(combos):
    for combo in combos:
        print_combo(combo)

def get_drink_set_info(drinks):
    cost = 0
    fame = 0
    tickets = 0
    for drink in drinks:
        fame += drink[1]["barFame"]
        tickets += drink[1]["tickets"]
        for material in drink[1]["materials"]:
            cost += material_costs[material[0]]["cost"] * material[1]
    return [cost, fame, tickets]

def all_combos(num_drinks_remaining, drinks_made, drink_set):
#    print(f"all: {num_drinks_remaining} {drinks_made} {len(drink_set)}\n")
    combos = []
    if num_drinks_remaining == 0:
        return drinks_made
#    print(f"num remaining: {num_drinks_remaining}")
    for drink in drink_set:
#        print(f"\nnum made before: {len(drinks_made)}")
        made = drinks_made.copy()
        made.append(drink)
#        print(f"num made after: {len(made)}")
#        print("potential: ", made)
        if can_make_drinks(made):
#            print("valid")
            combos.append(made)
#            print_combos(combos)
#        else:
#            print("invalid")

    if num_drinks_remaining > 1:
        to_return = []
        for combo in combos:
#            print(f"made: {combo}")
            all_c = all_combos(num_drinks_remaining - 1, combo, drink_set)
#            print(f"after making {combo}")
#            print_combos(all_c)
            to_return += all_c
#            print(f"to_return after making {combo}")
#            for line in to_return:
#                for line2 in line:
#                    print(line2)
        return to_return
    else:
#        print("ndr <= 1, returning combos")
#        print_combos(combos)
        return combos

print(f"Bar level: {BAR_LEVEL}, max drinks: {bar_level[BAR_LEVEL]}") 
all_c = all_combos(7, [], drink_set)

print("All combos")
#print_combos(c)
print(len(all_c))


max_cost = 0
max_cost_drinks = []
max_fame = 0
max_fame_drinks = []
max_fame_efficiency = 0.0
max_fame_efficiency_drinks = []
max_tickets = 0
max_tickets_drinks = []
max_tickets_efficiency = 0.0
max_tickets_efficiency_drinks = []

for drinks in all_c:
    [cost, fame, tickets] = get_drink_set_info(drinks)
    if cost > max_cost:
        max_cost = cost
        max_cost_drinks = drinks
    if fame > max_fame:
        max_fame = fame
        max_fame_drinks = drinks
    if (float(fame) / float(cost)) > max_fame_efficiency:
        max_fame_efficiency = float(fame) / cost
        max_fame_efficiency_drinks = drinks
    if tickets > max_tickets:
        max_tickets = tickets
        max_tickets_drinks = drinks
    if (float(tickets) / float(cost)) > max_tickets_efficiency:
        max_tickets_efficiency = float(tickets) / cost
        max_tickets_efficiency_drinks = drinks

print("\nmax cost: ", max_cost)
print_combo(max_cost_drinks)

[c, f, t] = get_drink_set_info(max_fame_drinks)
print(f"\nmax fame: {max_fame}, tickets {t}, cost {c}")
print_combo(max_fame_drinks)

[c, f, t] = get_drink_set_info(max_fame_efficiency_drinks)
print(f"\nmax fame efficiency: {f}, tickets {t}, cost {c}")
print_combo(max_fame_efficiency_drinks)

[c, f, t] = get_drink_set_info(max_tickets_drinks)
print(f"\nmax tickets: {max_tickets}, fame {f}, cost {c}")
print_combo(max_tickets_drinks)

[c, f, t] = get_drink_set_info(max_tickets_efficiency_drinks)
print(f"\nmax tickets efficiency: {t}, fame {f}, cost {c}")
print_combo(max_tickets_efficiency_drinks)
