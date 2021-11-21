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
from operator import itemgetter

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
    # Can't use this with pypy
    if True:
        return 0
    dict_handler = lambda d: chain.from_iterable(d.items())
    all_handlers = {tuple: iter,
                    list: iter,
                    deque: iter,
                    dict: dict_handler,
                    set: iter,
                    frozenset: iter,
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

# Hack for perfect hashing
PRIMES = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199]


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
    'Orange Curacao': {'cost': 20, 'num': 4},
    'Vermouth': {'cost': 20, 'num': 4},
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

# Populate stock limits for each bar level
with open("/home/ejwu/ff/ff20211026/com.egg.foodandroid/files/publish/conf/en-us/bar/levelUp.json.pretty") as bar_level_file:
    for level in json.load(bar_level_file).values():
        bar_level_data[level["level"]] = int(level["stockNum"])

# Populate material availability and cost in the market
with open("/home/ejwu/ff/ff20211026/com.egg.foodandroid/files/publish/conf/en-us/bar/material.json.pretty") as material_file:
    for key, material in json.load(material_file).items():
        mat_name = material["name"]
        material_costs[key]["name"] = mat_name
        material_name_to_id[mat_name] = key
        if mat_name in MAT_SHOP:
            material_costs[key]["cost"] = MAT_SHOP[mat_name]["cost"]
            material_costs[key]["num"] = MAT_SHOP[mat_name]["num"]
            material_costs[key]["type"] = material["materialType"]

with open("/home/ejwu/ff/ff20211026/com.egg.foodandroid/files/publish/conf/en-us/bar/formula.json.pretty") as formula_file, open("/home/ejwu/ff/ff20211026/com.egg.foodandroid/files/publish/conf/en-us/bar/drink.json.pretty") as drink_file:
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

# Hacky perfect hash for drink multisets
drink_to_prime = {}
drink_set = []
for i, drink in enumerate(drink_setf):
    drink_set.append(drink[1]["id"])
    drink_to_prime[drink[1]["id"]] = PRIMES[i]

print(f"Bar level: {bar_level}, max drinks: {bar_level_data[bar_level]}, available drinks: {len(drink_set)}") 
    
def hash_drinks(drinks):
    value = 1
    for drink in drinks:
        value *= drink_to_prime[drink]
    return value


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
PROCESSED = defaultdict(set)
CACHE_HITS = Counter()

def print_cache_info():
    print(f"{DUPES:,} dupes found, cache_size {total_size(PROCESSED):,}")
    print("Cache by level:")
    for count, subcache in PROCESSED.items():
        print(f"{count:>2} num: {len(subcache):>15,}  |  size: {total_size(subcache):>15,}")
    print("Cache hits: ", sorted(CACHE_HITS.items()))
    print(f"{resource.getrusage(resource.RUSAGE_SELF).ru_maxrss:,}K memory used")

# Various facets to optimize against
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
combos_processed = 0

def process_leaf_nodes(all_c):
    global max_cost
    global max_cost_drinks
    global max_fame
    global max_fame_tickets
    global max_fame_drinks
    global max_fame_efficiency
    global max_fame_efficiency_tickets_efficiency
    global max_fame_efficiency_drinks
    global max_tickets
    global max_tickets_fame
    global max_tickets_drinks
    global max_tickets_efficiency
    global max_tickets_efficiency_fame_efficiency
    global max_tickets_efficiency_drinks
    global combos_processed
    
    for drinks in all_c:
        combos_processed += 1
        if combos_processed % 10000000 == 0:
            print(f"{combos_processed:,} processed, {resource.getrusage(resource.RUSAGE_SELF).ru_maxrss:,}K memory in use")

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

def all_combos(num_drinks_remaining, drinks_made, drink_set):
    global DUPES
    combos = []
    if num_drinks_remaining == 0:
        return drinks_made
    for drink in drink_set:
        made = drinks_made + (drink,)
        if hash_drinks(made) not in PROCESSED[len(made)]:
            # Skip caching leaf nodes with too many drinks to save memory but increase processing time
            # TODO: I think this puts a bunch of dupes in the final results?

            # Pypy might let us use 10 here instead of 9
            if len(made) < 10:
                PROCESSED[len(made)].add(hash_drinks(made))
            if can_make_drinks(made):
                combos.append(made)
        else:
            CACHE_HITS[len(made)] += 1
            DUPES += 1
            if DUPES % 5000000 == 0:
                print_cache_info()

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

print_cache_info()
print(f"{total_size(PROCESSED):,} bytes used for cache")

print(f"{DUPES:,} dupes not processed")
print(f"{combos_processed:,} combos processed, possibly including dupes")

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
