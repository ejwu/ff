#!/usr/bin/python

import argparse
import json
import multiprocessing
import resource
import sys
from collections import Counter
from collections import defaultdict
from multiprocessing import Pool
from multiprocessing import Process

# TODO: Update when bar level increases
MAT_SHOP = {
    'Rum': {'cost': 50, 'num': 10, 'level': 1},
    'Vodka': {'cost': 50, 'num': 10, 'level': 1},
    'Brandy': {'cost': 50, 'num': 10, 'level': 1},
    'Tequila': {'cost': 50, 'num': 10, 'level': 1},
    'Gin': {'cost': 50, 'num': 10, 'level': 1},
    'Whisky': {'cost': 50, 'num': 10, 'level': 1},
    
    'Coffee Liqueur': {'cost': 20, 'num': 4, 'level': 2},
    # This is annoying because a level 5 drink (Singapore Sling) requires a level 6 ingredient,
    # which can break things when running this at bar_level=5
    'Orange Curacao': {'cost': 20, 'num': 4, 'level': 6},
    'Vermouth': {'cost': 20, 'num': 4, 'level': 7},
    'Bitters': {'cost': 40, 'num': 4, 'level': 8},
    'Baileys': {'cost': 40, 'num': 4, 'level': 9},

    'Cola': {'cost': 20, 'num': 4, 'level': 1},
    'Orange Juice': {'cost': 20, 'num': 4, 'level': 1},
    'Pineapple Juice': {'cost': 20, 'num': 4, 'level': 1},
    'Soda Water': {'cost': 20, 'num': 4, 'level': 1},
    'Cane Syrup': {'cost': 20, 'num': 4, 'level': 2},
    'Lemon Juice': {'cost': 20, 'num': 4, 'level': 2},
    'Mint Leaf': {'cost': 20, 'num': 4, 'level': 3},
    'Honey': {'cost': 20, 'num': 4, 'level': 4},
    'Sugar': {'cost': 20, 'num': 4, 'level': 4},
    'Cream': {'cost': 20, 'num': 4, 'level': 5},

    # Estimates
    # 10
    'Campari': {'cost': 40, 'num': 4, 'level': 10},
    # 11, other
    'Fruit Syrup': {'cost': 40, 'num': 4, 'level': 11},
    # 12
    'Chartreuse': {'cost': 40, 'num': 4, 'level': 12},
    # 13
    'Aperol': {'cost': 40, 'num': 4, 'level': 13},
    # 14
    'Wine': {'cost': 40, 'num': 4, 'level': 14},
}

def parse_args():
    parser = argparse.ArgumentParser(description="Find various maxima for bar menus")
    parser.add_argument("--barlevel", help="Level of the bar", type=int, default=4)
    return parser.parse_args()

bar_level_data = defaultdict(dict)
drinks_data = defaultdict(dict)
drink_id_to_name = {}
material_costs = defaultdict(dict)
material_name_to_id = {}

BASE_PATH = "/home/ejwu/ff/ff20211202/com.egg.foodandroid/files/publish/conf/en-us/bar/"

# Populate stock limits for each bar level
with open(BASE_PATH + "levelUp.json.pretty") as bar_level_file:
    for level in json.load(bar_level_file).values():
        bar_level_data[level["level"]] = int(level["stockNum"])

# Populate material availability and cost in the market
with open(BASE_PATH + "material.json.pretty") as material_file:
    for key, material in json.load(material_file).items():
        mat_name = material["name"]
        material_costs[key]["name"] = mat_name
        material_name_to_id[mat_name] = key
        if mat_name in MAT_SHOP:
            material_costs[key]["cost"] = MAT_SHOP[mat_name]["cost"]
            material_costs[key]["num"] = MAT_SHOP[mat_name]["num"]
            material_costs[key]["type"] = material["materialType"]
            material_costs[key]["level"] = MAT_SHOP[mat_name]["level"]

with open(BASE_PATH + "formula.json.pretty") as formula_file, open(BASE_PATH + "drink.json.pretty") as drink_file:
    formula_json = json.load(formula_file)
    # Populate drink rewards
    for drink_obj in json.load(drink_file).values():
        drink = drinks_data[drink_obj["name"]]
        drink["barFame"] = int(drink_obj["barPopularity"])
        drink["tickets"] = int(drink_obj["barPoint"])
        drink["barLevel"] = int(formula_json[str(drink_obj["formulaId"])]["openBarLevel"])
        drink["id"] = int(drink_obj["id"])
        drink_id_to_name[drink["id"]] = drink_obj["name"]
        drink["materials"] = []

    # Populate drink requirements
    for formula in formula_json.values():
        for material, quantity in zip(formula["materials"], formula["matching"]):
            drinks_data[formula["name"]]["materials"].append([material, int(quantity)])
        
bar_level = parse_args().barlevel
drinks_by_level = sorted(drinks_data.items(), reverse=True, key=lambda item: item[1]["barLevel"])
drink_setf = filter(lambda item: item[1]["barLevel"] <= bar_level, drinks_by_level)

drink_set = []
drink_to_index = {}
for i, drink in enumerate(drink_setf):
    drink_set.append(drink[1]["id"])
    drink_to_index[drink[1]["id"]] = i
    
print(f"Bar level: {bar_level}, max drinks: {bar_level_data[bar_level]}, available drinks: {len(drink_set)}") 
    
materials_available = {}
for key, material in material_costs.items():
    if "num" in material:
        materials_available[key] = material["num"]
        
def can_make_drinks(drinks):
    materials_used = defaultdict(int)
    for drink in drinks:
        for material in drinks_data[drink_id_to_name[drink]]["materials"]:
            materials_used[material[0]] += material[1]

    for material, num_used in materials_used.items():
        if num_used > materials_available[material]:
            return False
    return True

def print_combo(combo):
    drink_names = []
    counter = Counter()
    for drink in combo:
        drink_names.append(drink_id_to_name[drink])
        for material in drinks_data[drink_id_to_name[drink]]["materials"]:
            counter[material_costs[material[0]]["name"]] += material[1]
    print(drink_names)
    ingredients = []
    unused_ingredients = [mat[0] for mat in MAT_SHOP.items() if mat[1]["level"] <= bar_level]
    for material, count in sorted(counter.items(), key=lambda x: material_costs[material_name_to_id[x[0]]]["type"]):
        ingredients.append(str(count) + " " + material)
        unused_ingredients.remove(material)
    print("\nUses: ", ", ".join(ingredients))
    if len(unused_ingredients) <= 4:
        print(f"(Buy everything except {unused_ingredients})")
    [c, f, t] = get_drink_set_info(combo)
    print(f"\nFame {f}, tickets {t}, cost {c}, fame/cost {f/c:.3}, tickets/cost {t/c:.3}")
    
def get_drink_set_info(drinks):
    cost = 0
    fame = 0
    tickets = 0
    materials_used = set()
    for drink in drinks:
        drink_data = drinks_data[drink_id_to_name[drink]]
        fame += drink_data["barFame"]
        tickets += drink_data["tickets"]
        for material in drink_data["materials"]:
            materials_used.add(material[0])

    for material in materials_used:
        cost += material_costs[material]["cost"]
    return [cost, fame, tickets]

def get_drink_set_min(drinks):
    minimum = 999
    for drink in drinks:
        if drink_to_index[drink] < minimum:
            minimum = drink_to_index[drink]
    return minimum

def drink_strs_to_ids(drink_strs):
    drink_ids = []
    for drink_str in drink_strs:
        drink_ids.append(drinks_data[drink_str]["id"])
    return drink_ids

def check(drinks):
    print("Checking")
    print_combo(drink_strs_to_ids(drinks))

class BestDrinkSet:
    def __init__(self, comp):
        # Comparator for drink sets
        self.comp = comp
        # Best drink set so far
        self.best = []

        
    def offer(self, drinks):
        """
        Compare the given set of drinks to the currently known best one according to the comparator and replace it if afppropriate.
        """
        if self.comp(drinks, self.best) > 0:
            self.best = drinks

# Drink info is [cost, fame, tickets]
def get_cost_diff_desc(l_info, r_info):
    return l_info[0] - r_info[0]

# In the usual case we want lowest cost
def get_cost_diff(l_info, r_info):
    return get_cost_diff_desc(l_info, r_info) * -1

def get_fame_diff(l_info, r_info):
    return l_info[1] - r_info[1]

def get_fame_effic_diff(l_info, r_info):
    # The starting empty drink set has no cost
    if r_info[0] == 0:
        return 1
    return (l_info[1] / l_info[0]) - (r_info[1] / r_info[0])

# 3.25 is close to the ratio of max_tickets to max_fame at bar level 9
OVERALL_COEFF = 3.25
def get_overall_diff(l_info, r_info):
    return (l_info[1] * OVERALL_COEFF + l_info[2]) - (r_info[1] * OVERALL_COEFF + r_info[2])

def get_overall_effic_diff(l_info, r_info):
    # The starting empty drink set has no cost
    if r_info[0] == 0:
        return 1
    return ((l_info[1] * OVERALL_COEFF + l_info[2]) / l_info[0]) - ((r_info[1] * OVERALL_COEFF + r_info[2]) / r_info[0])
    
def get_tickets_diff(l_info, r_info):
    return l_info[2] - r_info[2]

def get_tickets_effic_diff(l_info, r_info):
    # The starting empty drink set has no cost
    if r_info[0] == 0:
        return 1
    return (l_info[2] / l_info[0]) - (r_info[2] / r_info[0])

def sort_by_cost(l, r):
    l_info = get_drink_set_info(l)
    r_info = get_drink_set_info(r)
    
    if get_cost_diff_desc(l_info, r_info) != 0:
        return get_cost_diff_desc(l_info, r_info)
    if get_fame_diff(l_info, r_info) != 0:
        return get_fame_diff(l_info, r_info)
    if get_tickets_diff(l_info, r_info) != 0:
        return get_tickets_diff(l_info, r_info)
    return 0

def sort_by_fame(l, r):
    l_info = get_drink_set_info(l)
    r_info = get_drink_set_info(r)
    
    if get_fame_diff(l_info, r_info) != 0:
        return get_fame_diff(l_info, r_info)
    if get_tickets_diff(l_info, r_info) != 0:
        return get_tickets_diff(l_info, r_info)
    if get_cost_diff(l_info, r_info) != 0:
        return get_cost_diff(l_info, r_info)
    return 0

def sort_by_fame_effic(l, r):
    l_info = get_drink_set_info(l)
    r_info = get_drink_set_info(r)
    
    if get_fame_effic_diff(l_info, r_info) != 0:
        return get_fame_effic_diff(l_info, r_info)
    if get_fame_diff(l_info, r_info) != 0:
        return get_fame_diff(l_info, r_info)
    if get_tickets_diff(l_info, r_info) != 0:
        return get_tickets_diff(l_info, r_info)
    # Fairly sure ticket_effic and cost don't matter here
    if get_cost_diff(l_info, r_info) != 0:
        return get_cost_diff(l_info, r_info)
    return 0

def sort_by_tickets(l, r):
    l_info = get_drink_set_info(l)
    r_info = get_drink_set_info(r)
    
    if get_tickets_diff(l_info, r_info) != 0:
        return get_tickets_diff(l_info, r_info)
    if get_fame_diff(l_info, r_info) != 0:
        return get_fame_diff(l_info, r_info)
    if get_cost_diff(l_info, r_info) != 0:
        return get_cost_diff(l_info, r_info)
    return 0

def sort_by_tickets_effic(l, r):
    l_info = get_drink_set_info(l)
    r_info = get_drink_set_info(r)
    
    if get_tickets_effic_diff(l_info, r_info) != 0:
        return get_tickets_effic_diff(l_info, r_info)
    if get_tickets_diff(l_info, r_info) != 0:
        return get_tickets_diff(l_info, r_info)
    if get_fame_diff(l_info, r_info) != 0:
        return get_fame_diff(l_info, r_info)
    # Fairly sure ticket_effic and cost don't matter here
    if get_cost_diff(l_info, r_info) != 0:
        return get_cost_diff(l_info, r_info)
    return 0

def sort_by_overall(l, r):
    l_info = get_drink_set_info(l)
    r_info = get_drink_set_info(r)

    if get_overall_diff(l_info, r_info) != 0:
        return get_overall_diff(l_info, r_info)
    if get_overall_effic_diff(l_info, r_info) != 0:
        return get_overall_effic_diff(l_info, r_info)
    if get_fame_diff(l_info, r_info) != 0:
        return get_fame_diff(l_info, r_info)
    return 0

def sort_by_overall_effic(l, r):
    l_info = get_drink_set_info(l)
    r_info = get_drink_set_info(r)

    if get_overall_effic_diff(l_info, r_info) != 0:
        return get_overall_effic_diff(l_info, r_info)
    if get_overall_diff(l_info, r_info) != 0:
        return get_overall_diff(l_info, r_info)
    return 0
    
bdc_cost = BestDrinkSet(sort_by_cost)
bdc_fame = BestDrinkSet(sort_by_fame)
bdc_fame_effic = BestDrinkSet(sort_by_fame_effic)
bdc_tickets = BestDrinkSet(sort_by_tickets)
bdc_tickets_effic = BestDrinkSet(sort_by_tickets_effic)
bdc_overall = BestDrinkSet(sort_by_overall)
bdc_overall_effic = BestDrinkSet(sort_by_overall_effic)

combos_processed = 0

def process_leaf_nodes(all_c):
    global combos_processed

    for drinks in all_c:
        combos_processed += 1
        if combos_processed % 10000000 == 0:
            print(f"{combos_processed:,} processed, {resource.getrusage(resource.RUSAGE_SELF).ru_maxrss:,}K memory in use")
        bdc_cost.offer(drinks)
        bdc_fame.offer(drinks)
        bdc_fame_effic.offer(drinks)
        bdc_tickets.offer(drinks)
        bdc_tickets_effic.offer(drinks)
        bdc_overall.offer(drinks)
        bdc_overall_effic.offer(drinks)
        
def all_combos(num_drinks_remaining, drinks_made, drink_set):
    combos = []
    if num_drinks_remaining == 0:
        return drinks_made
    
    minimum = get_drink_set_min(drinks_made)
    for drink in drink_set:
        if drink_to_index[drink] <= minimum:
            made = drinks_made + (drink,)
            if can_make_drinks(made):
                combos.append(made)

    if num_drinks_remaining > 1:
        to_return = []

        for combo in combos:
            all_c = all_combos(num_drinks_remaining - 1, combo, drink_set)
            to_return += all_c

        return to_return
    else:
        process_leaf_nodes(combos)
        return []

all_combos(bar_level_data[bar_level], (), drink_set)

print(f"\n\nmax cost: {get_drink_set_info(bdc_cost.best)[0]}")
print_combo(bdc_cost.best)

[c, f, t] = get_drink_set_info(bdc_fame.best)
print(f"\n\nmax fame: {f}, tickets {t}, cost {c}")
print_combo(bdc_fame.best)

[c, f, t] = get_drink_set_info(bdc_fame_effic.best)
print(f"\n\nmax fame efficiency: {f}, tickets {t}, cost {c}")
print_combo(bdc_fame_effic.best)

[c, f, t] = get_drink_set_info(bdc_tickets.best)
print(f"\n\nmax tickets: {t}, fame {f}, cost {c}")
print_combo(bdc_tickets.best)

[c, f, t] = get_drink_set_info(bdc_tickets_effic.best)
print(f"\n\nmax tickets efficiency: {t}, fame {f}, cost {c}")
print_combo(bdc_tickets_effic.best)

[c, f, t] = get_drink_set_info(bdc_overall.best)
print(f"\n\nmax overall:")
print_combo(bdc_overall.best)

[c, f, t] = get_drink_set_info(bdc_tickets_effic.best)
print(f"\n\nmax overall efficiency:")
print_combo(bdc_overall_effic.best)
