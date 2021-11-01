#!/usr/bin/python

import argparse
import json
import sys
from collections import Counter
from collections import defaultdict
from operator import itemgetter

from multiset import FrozenMultiset
from multiset import Multiset

import inspect

from sys import getsizeof, stderr
from itertools import chain
from collections import deque
try:
    from reprlib import repr
except ImportError:
    pass
def total_size(o, handlers={}, verbose=False):
    """ Returns the approximate memory footprint an object and all of its contents.

    Automatically finds the contents of the following builtin containers and
    their subclasses:  tuple, list, deque, dict, set and frozenset.
    To search other containers, add handlers to iterate over their contents:

        handlers = {SomeContainerClass: iter,
                    OtherContainerClass: OtherContainerClass.get_elements}

    """
    dict_handler = lambda d: chain.from_iterable(d.items())
    all_handlers = {tuple: iter,
                    list: iter,
                    deque: iter,
                    dict: dict_handler,
                    set: iter,
                    frozenset: iter,
                    Multiset: iter,
                    FrozenMultiset: iter
                   }
    all_handlers.update(handlers)     # user handlers take precedence
    seen = set()                      # track which object id's have already been seen
    default_size = getsizeof(0)       # estimate sizeof object without __sizeof__

    def sizeof(o):
        if id(o) in seen:       # do not double count the same object
            return 0
        seen.add(id(o))
        s = getsizeof(o, default_size)

        if verbose:
            print(s, type(o), repr(o), file=stderr)

        for typ, handler in all_handlers.items():
            if isinstance(o, typ):
                s += sum(map(sizeof, handler(o)))
                break
        return s

    return sizeof(o)


# TODO: Update when bar level increases past 4
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
    'Orange Juice': {'cost': 20, 'num': 4},
    'Cream': {'cost': 20, 'num': 4},

    # Level 6 ingredient needed by level 5 drinks, put it in with num=0 to avoid crashes
    'Orange Curacao': {'cost': 20, 'num': 4}
}

def parse_args():
    parser = argparse.ArgumentParser(description="Find various maxima for bar menus")
    parser.add_argument("--barlevel", help="Level of the bar", type=int, default=4)
    return parser.parse_args()

materials_json = json.load(open("/home/ejwu/ff/ff20211026/com.egg.foodandroid/files/publish/conf/en-us/bar/material.json.pretty"))
bar_level_json = json.load(open("/home/ejwu/ff/ff20211026/com.egg.foodandroid/files/publish/conf/en-us/bar/levelUp.json.pretty"))
formula_json = json.load(open("/home/ejwu/ff/ff20211026/com.egg.foodandroid/files/publish/conf/en-us/bar/formula.json.pretty"))
drink_json = json.load(open("/home/ejwu/ff/ff20211026/com.egg.foodandroid/files/publish/conf/en-us/bar/drink.json.pretty"))

bar_level_data = defaultdict(dict)
drinks_data = defaultdict(dict)
drink_id_to_name = {}
material_costs = defaultdict(dict)
material_name_to_id = {}

# Populate stock limits for each bar level
for level in bar_level_json.values():
    bar_level_data[level["level"]] = int(level["stockNum"])

bar_level = parse_args().barlevel
print(f"Bar level: {bar_level}, max drinks: {bar_level_data[bar_level]}") 
    
# Populate material availability and cost in the market
for key, material in materials_json.items():
    mat_name = material["name"]
    material_costs[key]["name"] = mat_name
    material_name_to_id[mat_name] = key
    if mat_name in MAT_SHOP:
        material_costs[key]["cost"] = MAT_SHOP[mat_name]["cost"]
        material_costs[key]["num"] = MAT_SHOP[mat_name]["num"]
        material_costs[key]["type"] = material["materialType"]

# Populate drink rewards
for drink_obj in drink_json.values():
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
#for drink in drinks_by_level:
#    print(drink)

drink_setf = filter(lambda item: item[1]["barLevel"] <= bar_level, drinks_by_level)
#for drink in drink_set:
#    print(drink)

drink_set = []
for drink in drink_setf:
    drink_set.append(drink[1]["id"])

materials_available = {}
for key, material in material_costs.items():
    if "num" in material:
        materials_available[key] = material["num"]

ALL_MATERIALS_AVAILABLE = materials_available.copy()

def can_make_drinks(drinks):
    materials_used = defaultdict(int)
    for drink in drinks:
        for material in drinks_data[drink_id_to_name[drink]]["materials"]:
            materials_used[material[0]] += material[1]

    for material, num_used in materials_used.items():
        if num_used > ALL_MATERIALS_AVAILABLE[material]:
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
    for material, count in sorted(counter.items(), key=lambda x: material_costs[material_name_to_id[x[0]]]["type"]):
        ingredients.append(str(count) + " " + material)
    print("Uses: ", ", ".join(ingredients))
    [c, f, t] = get_drink_set_info(combo)
    print(f"Fame {f}, tickets {t}, cost {c}, fame/cost {f/c:.3}, tickets/cost {t/c:.3}")
    
def print_combos(combos):
    for combo in combos:
        print_combo(combo)

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

def check(drinks):
    print("Checking")
    drink_ids = []
    for drink_str in drinks:
        drink_ids.append(drinks_data[drink_str]["id"])
    print_combo(drink_ids)



DUPES = 0
PROCESSED = set()
PROCESSED2 = defaultdict(set)
CACHE_HITS = Counter()
print("Available drinks: ", len(drink_set), drink_set)

def all_combos(num_drinks_remaining, drinks_made, drink_set):
    global DUPES
    combos = []
    if num_drinks_remaining == 0:
        return drinks_made
    for drink in drink_set:
        made = tuple(sorted(drinks_made + (drink,)))
        if made not in PROCESSED2[len(made)]:
            # Skip caching leaf nodes with too many drinks to save memory but increase processing time
            # TODO: I think this puts a bunch of dupes in the final results?
            # TODO: Consider processing leaf nodes in place to avoid having to save a giant list of all of them
            if len(made) < 9:
                PROCESSED2[len(made)].add(made)
            if can_make_drinks(made):
                combos.append(made)
        else:
            CACHE_HITS[len(made)] += 1
            DUPES += 1
            if DUPES % 5000000 == 0:
                print(f"{DUPES:,} {total_size(PROCESSED2):,}")
                for i, s in PROCESSED2.items():
                    print(i, len(s))
                print(sorted(CACHE_HITS.items()))

    if num_drinks_remaining > 1:
        to_return = []
        for combo in combos:
            all_c = all_combos(num_drinks_remaining - 1, combo, drink_set)
            to_return += all_c
        return to_return
    else:
        return combos

all_c = all_combos(bar_level_data[bar_level], (), drink_set)

for i, d in PROCESSED2.items():
    print(i, total_size(d))

print(total_size(PROCESSED2))

print(f"{DUPES:,} dupes not processed")
print(f"All combos: {len(all_c):,}")
#print_combos(c)
print(f"size: {total_size(all_c):,}")

max_cost = 0
max_cost_drinks = []
max_fame = 0
max_fame_tickets = 0
max_fame_drinks = []
max_fame_efficiency = 0.0
max_fame_efficiency_tickets_efficiency = 0.0
max_fame_efficiency_drinks = []
max_tickets = 0
max_tickets_fame = 0
max_tickets_drinks = []
max_tickets_efficiency = 0.0
max_tickets_efficiency_fame_efficiency = 0.0
max_tickets_efficiency_drinks = []


for drinks in all_c:
    [cost, fame, tickets] = get_drink_set_info(drinks)
    if cost > max_cost:
        max_cost = cost
        max_cost_drinks = drinks

    # Max fame
    if fame > max_fame:
        max_fame = fame
        max_fame_tickets = tickets
        max_fame_drinks = drinks
    elif fame == max_fame:
        if tickets > max_fame_tickets:
            max_fame_tickets = tickets
            max_fame_drinks = drinks
        elif tickets == max_fame_tickets and cost < get_drink_set_info(max_fame_drinks)[0]:
                max_fame_drinks = drinks

    # Max fame efficiency
    if (fame / cost) > max_fame_efficiency:
        max_fame_efficiency = fame / cost
        max_fame_efficiency_ticket_efficiency = tickets / cost
        max_fame_efficiency_drinks = drinks
    elif (fame / cost) == max_fame_efficiency:
        if tickets / cost > max_fame_efficiency_tickets_efficiency:
            max_fame_efficiency_tickets_efficiency = tickets / cost
            max_fame_efficiency_drinks = drinks

    # Max tickets
    if tickets > max_tickets:
        max_tickets = tickets
        max_tickets_fame = fame
        max_tickets_drinks = drinks
    elif tickets == max_tickets:
        if fame > max_tickets_fame:
            max_tickets_fame = fame
            max_tickets_drinks = drinks
        elif fame == max_tickets_fame and cost < get_drink_set_info(max_tickets_drinks)[0]:
                max_tickets_drinks = drinks

    # Max ticket efficiency
    if (tickets / cost) > max_tickets_efficiency:
        max_tickets_efficiency = tickets / cost
        max_tickets_efficiency_fame_efficiency = fame / cost
        max_tickets_efficiency_drinks = drinks
    elif (tickets / cost) == max_tickets_efficiency:
        if fame / cost > max_tickets_efficiency_fame_efficiency:
            max_tickets_efficiency_fame_efficiency = fame / cost
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


#print("\n\ncheck")
#check(['Screwdriver', 'Honey Soda', 'Dirty Banana', 'Long Island Iced Tea', 'Long Island Iced Tea', 'Cuba Libre', 'Palm Beach', 'Zombie', 'Gin Basil Smash'])

