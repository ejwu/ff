#!/usr/bin/python

import argparse
import json
import multiprocessing
import resource
import sys
import time
from collections import Counter
from collections import defaultdict
from multiprocessing import Pool
from multiprocessing import Process
from multiprocessing import JoinableQueue

# TODO: Update when bar level increases
MAT_SHOP = {
     # Base Spirits
    'Rum': {'cost': 50, 'num': 10, 'level': 1},
    'Vodka': {'cost': 50, 'num': 10, 'level': 1},
    'Brandy': {'cost': 50, 'num': 10, 'level': 1},
    'Tequila': {'cost': 50, 'num': 10, 'level': 1},
    'Gin': {'cost': 50, 'num': 10, 'level': 1},
    'Whisky': {'cost': 50, 'num': 10, 'level': 1},

    # Flavor Spirits
    'Coffee Liqueur': {'cost': 20, 'num': 4, 'level': 2},
    # This is annoying because a level 5 drink (Singapore Sling) requires a level 6 ingredient,
    # which can break things when running this at bar_level=5
    'Orange Curacao': {'cost': 20, 'num': 4, 'level': 6},
    'Vermouth': {'cost': 20, 'num': 4, 'level': 7},
    'Bitters': {'cost': 40, 'num': 4, 'level': 8},
    'Baileys': {'cost': 40, 'num': 4, 'level': 9},
    'Campari': {'cost': 40, 'num': 4, 'level': 10},

    # Other
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

    # Assumptions
    # 11, other
    'Fruit Syrup': {'cost': 40, 'num': 4, 'level': 11},
    # 12
    'Chartreuse': {'cost': 40, 'num': 4, 'level': 12},
    # 13
    'Aperol': {'cost': 40, 'num': 4, 'level': 13},
    # 14
    'Wine': {'cost': 40, 'num': 4, 'level': 14},
    # 15
    'Fruit Liqueur': {'cost': 40, 'num': 4, 'level': 15},
    # 16
    'Ginger Beer': {'cost': 40, 'num': 4, 'level': 16},
    # 17, other
    'Soda': {'cost': 20, 'num': 4, 'level': 17},
    # 18
    'Benedictine': {'cost': 40, 'num': 4, 'level': 18},
    # 19, other
    'Fruit Juice': {'cost': 20, 'num': 4, 'level': 19},
    # 20, other
    'Hot Sauce': {'cost': 20, 'num': 4, 'level': 20},
    # 20, other
    'Tomato Juice': {'cost': 20, 'num': 4, 'level': 20},
}

def update_mat_shop_for_level_11():
    # bar level 11
    # spirits: 75 for 15
    # flavor: 6 for 60 for baileys/bitters, 6 for 30 for vermouth/orange curacao/coffee, 4/40 for campari
    # other: 6/30, 4/40 for fruit syrup
    for spirit in ['Rum', 'Vodka', 'Brandy', 'Gin', 'Tequila', 'Whisky']:
        MAT_SHOP[spirit]['cost'] = 75
        MAT_SHOP[spirit]['num'] = 15

    for flavor in ['Baileys', 'Bitters']:
        MAT_SHOP[flavor]['cost'] = 60
        MAT_SHOP[flavor]['num'] = 6
    for flavor in ['Vermouth', 'Orange Curacao', 'Coffee Liqueur']:
        MAT_SHOP[flavor]['cost'] = 30
        MAT_SHOP[flavor]['num'] = 6

    for other in ['Cola', 'Orange Juice', 'Pineapple Juice', 'Soda Water', 'Cane Syrup', 'Lemon Juice', 'Mint Leaf', 'Honey', 'Sugar', 'Cream']:
        MAT_SHOP[other]['cost'] = 30
        MAT_SHOP[other]['num'] = 6

def parse_args():
    parser = argparse.ArgumentParser(description="Find various maxima for bar menus")
    parser.add_argument("--barlevel", help="Level of the bar", type=int, default=4)
    return parser.parse_args()

bar_level = parse_args().barlevel
if bar_level >= 11:
    update_mat_shop_for_level_11()

max_drinks_by_bar_level = defaultdict(dict)
drinks_data = defaultdict(dict)
drink_id_to_name = {}
material_costs = defaultdict(dict)
material_name_to_id = {}

BASE_PATH = "/home/ejwu/ff/ff20211202/com.egg.foodandroid/files/publish/conf/en-us/bar/"

# Populate stock limits for each bar level
with open(BASE_PATH + "levelUp.json.pretty") as bar_level_file:
    for level in json.load(bar_level_file).values():
        max_drinks_by_bar_level[level["level"]] = int(level["stockNum"])

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
        
drinks_by_level = sorted(drinks_data.items(), reverse=True, key=lambda item: item[1]["barLevel"])
drink_setf = filter(lambda item: item[1]["barLevel"] <= bar_level, drinks_by_level)

drink_set = []
drink_to_index = {}
for i, drink in enumerate(drink_setf):
    drink_set.append(drink[1]["id"])
    drink_to_index[drink[1]["id"]] = i
    
print(f"Bar level: {bar_level}, max drinks: {max_drinks_by_bar_level[bar_level]}, available drinks: {len(drink_set)}") 
    
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
    print("\nUses:", ", ".join(ingredients))
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

class Stats:
    def __init__(self):
        self.bdc_cost = BestDrinkSet(sort_by_cost)
        self.bdc_fame = BestDrinkSet(sort_by_fame)
        self.bdc_fame_effic = BestDrinkSet(sort_by_fame_effic)
        self.bdc_tickets = BestDrinkSet(sort_by_tickets)
        self.bdc_tickets_effic = BestDrinkSet(sort_by_tickets_effic)
        self.bdc_overall = BestDrinkSet(sort_by_overall)
        self.bdc_overall_effic = BestDrinkSet(sort_by_overall_effic)
        self.num_processed = 0

    def offer_all(self, drinks):
        self.bdc_cost.offer(drinks)
        self.bdc_fame.offer(drinks)
        self.bdc_fame_effic.offer(drinks)
        self.bdc_tickets.offer(drinks)
        self.bdc_tickets_effic.offer(drinks)
        self.bdc_overall.offer(drinks)
        self.bdc_overall_effic.offer(drinks)
        self.num_processed += len(drinks)

    def add(self, stats):
        self.bdc_cost.offer(stats.bdc_cost.best)
        self.bdc_fame.offer(stats.bdc_fame.best)
        self.bdc_fame_effic.offer(stats.bdc_fame_effic.best)
        self.bdc_tickets.offer(stats.bdc_tickets.best)
        self.bdc_tickets_effic.offer(stats.bdc_tickets_effic.best)
        self.bdc_overall.offer(stats.bdc_overall.best)
        self.bdc_overall_effic.offer(stats.bdc_overall_effic.best)
        self.num_processed += stats.num_processed

    def print(self):
        print("------------------------------------------")
        print(f"max cost: {get_drink_set_info(self.bdc_cost.best)[0]}")
        print_combo(self.bdc_cost.best)

        [c, f, t] = get_drink_set_info(self.bdc_fame.best)
        print(f"\n\nmax fame: {f}, tickets {t}, cost {c}")
        print_combo(self.bdc_fame.best)

        [c, f, t] = get_drink_set_info(self.bdc_fame_effic.best)
        print(f"\n\nmax fame efficiency: {f}, tickets {t}, cost {c}")
        print_combo(self.bdc_fame_effic.best)

        [c, f, t] = get_drink_set_info(self.bdc_tickets.best)
        print(f"\n\nmax tickets: {t}, fame {f}, cost {c}")
        print_combo(self.bdc_tickets.best)

        [c, f, t] = get_drink_set_info(self.bdc_tickets_effic.best)
        print(f"\n\nmax tickets efficiency: {t}, fame {f}, cost {c}")
        print_combo(self.bdc_tickets_effic.best)

        [c, f, t] = get_drink_set_info(self.bdc_overall.best)
        print(f"\n\nmax overall:")
        print_combo(self.bdc_overall.best)

        [c, f, t] = get_drink_set_info(self.bdc_tickets_effic.best)
        print(f"\n\nmax overall efficiency:")
        print_combo(self.bdc_overall_effic.best)

        print(f"\n\n{self.num_processed:,} combos processed")
        print("------------------------------------------")
        
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
    if l_info[0] == 0:
        return -1
    return (l_info[1] / l_info[0]) - (r_info[1] / r_info[0])

# 3.25 is close to the ratio of max_tickets to max_fame at bar level 9
OVERALL_COEFF = 3.25
def get_overall_diff(l_info, r_info):
    return (l_info[1] * OVERALL_COEFF + l_info[2]) - (r_info[1] * OVERALL_COEFF + r_info[2])

def get_overall_effic_diff(l_info, r_info):
    # The starting empty drink set has no cost
    if r_info[0] == 0:
        return 1
    if l_info[0] == 0:
        return -1
    return ((l_info[1] * OVERALL_COEFF + l_info[2]) / l_info[0]) - ((r_info[1] * OVERALL_COEFF + r_info[2]) / r_info[0])
    
def get_tickets_diff(l_info, r_info):
    return l_info[2] - r_info[2]

def get_tickets_effic_diff(l_info, r_info):
    # The starting empty drink set has no cost
    if r_info[0] == 0:
        return 1
    if l_info[0] == 0:
        return -1
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


MAX_DRINKS = max_drinks_by_bar_level[bar_level]
# Number of drinks in the combos from the generator
HELPER_DEPTH = 8
# Indexing in the recursion is weird
FORK_LEVEL = MAX_DRINKS - HELPER_DEPTH + 1
DRINKS_TO_PROCESS = MAX_DRINKS - HELPER_DEPTH
DRINK_SET = drink_set

print(f"generating combos of size {HELPER_DEPTH}, pool processing subtrees of depth {DRINKS_TO_PROCESS}")

def all_combos_generator(num_drinks_remaining, drinks_made, drink_set):
    if num_drinks_remaining == 0:
        raise Error()
    combos = []
    minimum = get_drink_set_min(drinks_made)
    for drink in drink_set:
        if drink_to_index[drink] <= minimum:
            made = drinks_made + (drink,)
            if can_make_drinks(made):
                combos.append(made)

    if num_drinks_remaining == FORK_LEVEL:
        for combo in combos:
            yield combo
    else:
        for combo in combos:
            yield from all_combos_generator(num_drinks_remaining - 1, combo, drink_set)

def partial_combo_handler(drinks_made):
    combos = partial_combo_handler_helper(drinks_made, DRINKS_TO_PROCESS)
    stats = Stats()
    for combo in combos:
        stats.offer_all(combo)
    return stats

def partial_combo_handler_helper(drinks_made, num_drinks_remaining):
    combos = []
    if num_drinks_remaining == 0:
        return [drinks_made]
    
    minimum = get_drink_set_min(drinks_made)
    for drink in DRINK_SET:
        if drink_to_index[drink] <= minimum:
            made = drinks_made + (drink,)
            if can_make_drinks(made):
                combos.append(made)

    to_return = []

    for combo in combos:
        to_return += partial_combo_handler_helper(combo, num_drinks_remaining - 1)

    return to_return

if __name__ == '__main__':
    pool = multiprocessing.Pool(7)
    stats = Stats()
    jobs = 0
    combo_count = 0

    for i in pool.imap_unordered(partial_combo_handler, all_combos_generator(MAX_DRINKS, (), drink_set), chunksize=100):
        jobs += 1
        stats.add(i)
        combo_count += i.num_processed
        if jobs % 1000000 == 0:
            print(f"{jobs:,} jobs processed, {combo_count:,} combos processed, {time.asctime()}")
        if jobs % 10000000 == 0:
            stats.print()

    stats.print()
    print(f"Final: {jobs:,} jobs processed, {combo_count:,} combos processed")


