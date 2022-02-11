#!/usr/bin/python

import argparse
import functools
import gc
import json
import multiprocessing
from stats import OVERALL_COEFF
from stats import Stats
import time
from collections import Counter
from collections import defaultdict
from multiprocessing import Pool

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
    'Chartreuse': {'cost': 40, 'num': 4, 'level': 12},

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
    'Fruit Syrup': {'cost': 40, 'num': 4, 'level': 11},

    # Assumptions
    # 13
    'Aperol': {'cost': 40, 'num': 4, 'level': 13},
    # 14
    'Wine': {'cost': 40, 'num': 4, 'level': 14},
    # 15
    'Fruit Liqueur': {'cost': 40, 'num': 4, 'level': 15},
    # 16
    'Ginger Beer': {'cost': 40, 'num': 4, 'level': 16},
    # 17, other
    'Soda': {'cost': 40, 'num': 4, 'level': 17},
    # 18
    'Benedictine': {'cost': 40, 'num': 4, 'level': 18},
    # 19, other
    'Fruit Juice': {'cost': 40, 'num': 4, 'level': 19},
    # 20, other
    'Hot Sauce': {'cost': 40, 'num': 4, 'level': 20},
    # 20, other
    'Tomato Juice': {'cost': 40, 'num': 4, 'level': 20},
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

def parse_int_csv(int_csv_string):
    return [int(x) for x in int_csv_string.split(",")]
        
def parse_args():
    parser = argparse.ArgumentParser(description="Find various maxima for bar menus")
    parser.add_argument("--barLevel", help="Level of the bar", type=int, default=4)
    parser.add_argument("--workerDepth", help="Depth of the subtrees to process from workers", type=int, default=6)
    parser.add_argument("--numWorkers", help="Number of worker threads", type=int, default=7)
    parser.add_argument("--cacheDepth", help="Depth of the valid subtrees to cache", type=int, default=5)
    parser.add_argument("--startFrom", help="Optional argument to only process drink combinations lexicographically after the given one, useful for stopping and restarting a calculation", type=parse_int_csv, default=[])
    return parser.parse_args()

bar_level = parse_args().barLevel
if bar_level >= 11:
    update_mat_shop_for_level_11()

max_drinks_by_bar_level = defaultdict(dict)
drinks_data = defaultdict(dict)
drink_id_to_name = {}
material_costs = defaultdict(dict)
material_name_to_id = {}

BASE_PATH = "data/"

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

# Sort by ingredients used first, in hopes of pruning the tree better.  May not do much after level 11
def ingredients_used(l, r):
    lmats = 0
    rmats = 0
    for mat in l[1]["materials"]:
        lmats += mat[1]
    for mat in r[1]["materials"]:
        rmats += mat[1]
    return rmats - lmats

# Just greedily sort by overall score, ignoring ingredients
def overall_score(l, r):
    l_overall = l[1]["barFame"] * OVERALL_COEFF + l[1]["tickets"]
    r_overall = r[1]["barFame"] * OVERALL_COEFF + r[1]["tickets"]
    return r_overall - l_overall

filtered_drinks = list(drink_setf)
overall_drinks_first = sorted(filtered_drinks, key=functools.cmp_to_key(overall_score))
drink_set = []
# Drink ID to index
drink_to_index = {}
for i, drink in enumerate(overall_drinks_first):
    drink_set.append(drink[1]["id"])
    drink_to_index[drink[1]["id"]] = i

DRINK_SET = tuple(drink_set)
    
print(f"Bar level: {bar_level}, max drinks: {max_drinks_by_bar_level[bar_level]}, available drinks: {len(drink_set)}, workers: {parse_args().numWorkers}") 

def print_index_and_mats(i, drink):
    mat_strings = []
    for material, count in drink["materials"]:
        mat_strings.append(f"{count} {material_costs[material]['name']}")
    print(f"{i:<3} {drink_id_to_name[drink['id']]:<20} - {', '.join(mat_strings)}")

for drink, index in drink_to_index.items():
    print_index_and_mats(index, drinks_data[drink_id_to_name[drink]])
#    print(index, drink_id_to_name[drink], drinks_data[drink_id_to_name[drink]])
#    exit()

materials_available = {}
for key, material in material_costs.items():
    materials_available[key] = material["num"]

def can_make_drinks(drinks):
    materials_used = defaultdict(int)
    for drink in drinks:
        for material in drinks_data[drink_id_to_name[drink]]["materials"]:
            materials_used[material[0]] += material[1]
# this slows things down
#            if materials_used[material[0]] > materials_available[material[0]]:
#                return False

    for material, num_used in materials_used.items():
        if num_used > materials_available[material]:
#            print("not enough", material_costs[material]["name"], "for")
#            print_names(drinks)
            return False
    return True

def coalesce_names(drink_names):
    counter = Counter(drink_names)
    drink_strs = []
    for drink, count in counter.items():
        if count > 1:
            drink_strs.append(f"{count}x {drink}")
        else:
            drink_strs.append(drink)
    return ", ".join(drink_strs)

def print_indices(combo):
    indices = []
    for drink in combo:
        indices.append(str(drink_to_index[drink]))
    print(",".join(indices))

def print_names(combo):
    drink_names = []
    for drink in combo:
        drink_names.append(drink_id_to_name[drink])
    print(coalesce_names(drink_names))
    
def print_combo(combo):
    drink_names = []
    counter = Counter()
    for drink in combo:
        drink_names.append(drink_id_to_name[drink])
        for material in drinks_data[drink_id_to_name[drink]]["materials"]:
            counter[material_costs[material[0]]["name"]] += material[1]
    print(coalesce_names(drink_names))

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

def print_stats(stats):
    print("------------------------------------------")
    print(f"max cost: {get_drink_set_info(stats.bdc_cost.best)[0]}")
    print_combo(stats.bdc_cost.best)

    [c, f, t] = get_drink_set_info(stats.bdc_fame.best)
    print(f"\n\nmax fame: {f}, tickets {t}, cost {c}")
    print_combo(stats.bdc_fame.best)

    [c, f, t] = get_drink_set_info(stats.bdc_fame_effic.best)
    print(f"\n\nmax fame efficiency: {f}, tickets {t}, cost {c}")
    print_combo(stats.bdc_fame_effic.best)

    [c, f, t] = get_drink_set_info(stats.bdc_tickets.best)
    print(f"\n\nmax tickets: {t}, fame {f}, cost {c}")
    print_combo(stats.bdc_tickets.best)

    [c, f, t] = get_drink_set_info(stats.bdc_tickets_effic.best)
    print(f"\n\nmax tickets efficiency: {t}, fame {f}, cost {c}")
    print_combo(stats.bdc_tickets_effic.best)

    [c, f, t] = get_drink_set_info(stats.bdc_overall.best)
    print(f"\n\nmax overall:")
    print_combo(stats.bdc_overall.best)

    [c, f, t] = get_drink_set_info(stats.bdc_tickets_effic.best)
    print(f"\n\nmax overall efficiency:")
    print_combo(stats.bdc_overall_effic.best)

    print(f"\n\n{stats.num_processed:,} combos processed")
    print("------------------------------------------")

DRINKS_TO_PROCESS = parse_args().workerDepth
FORK_LEVEL = DRINKS_TO_PROCESS + 1
MAX_DRINKS = max_drinks_by_bar_level[bar_level]
# Number of drinks in the combos from the generator
HELPER_DEPTH = MAX_DRINKS - DRINKS_TO_PROCESS

print(f"generating combos of size {HELPER_DEPTH}, pool processing subtrees of depth {DRINKS_TO_PROCESS}")

SKIPPED = defaultdict(int)

def combo_is_after_str(combo_str, thresholds):
    combo = [drinks_data[x]["id"] for x in combo_str]
    return combo_is_after(combo, thresholds)

def combo_is_after(combo, thresholds):
    for [drink_id, threshold] in zip(combo, thresholds):
        drink_index = drink_to_index[drink_id]
        if drink_index < threshold:
            return False
        if drink_index > threshold:
            return True
        # If current drink is at the threshold, continue looping
    return True

def all_combos_generator(num_drinks_remaining, drinks_made, worker_depth, thresholds=[], cache={}):
    global SKIPPED

    # Shouldn't ever get here
    if num_drinks_remaining == 0:
        raise Error()

    combos = []
    minimum = get_drink_set_min(drinks_made)

    if combo_is_after(drinks_made, thresholds):
        for drink in DRINK_SET:
            if drink_to_index[drink] <= minimum:
                made = drinks_made + (drink,)
                if can_make_drinks(made):
                    combos.append(made)
                else:
                    if num_drinks_remaining == worker_depth + 1:
                        SKIPPED[drink_to_index[drinks_made[0]]] += 1
    else:
        # Skip all combos that are lexicographically before the thresholds
        pass
        #print("skipping")
        #print_indices(drinks_made)

    if num_drinks_remaining == worker_depth + 1:
        for combo in combos:
            yield (combo, cache)
    else:
        for combo in combos:
            yield from all_combos_generator(num_drinks_remaining - 1, combo, worker_depth, thresholds, cache)

def precalculate_cache(num_drinks, startFrom=[]):
    start_time = time.time()
    cache = defaultdict(list)
    entries = 0
    for (combo, _) in all_combos_generator(num_drinks, (), 1, startFrom):
        key = drink_to_index[combo[0]]
        cache[key].append(combo)
        entries += 1

    for key in sorted(cache.keys()):
        print(key, len(cache[key]))
        # Try to squeeze out a little more memory and runtime efficiency
        cache[key] = tuple(cache[key])

    gc.collect()
    print(f"Initialized cache with {len(cache)} keys, {entries:,} total entries in {time.time() - start_time} seconds")
    return cache

CACHE_DEPTH = parse_args().cacheDepth

#print(SKIPPED)
#exit()

def partial_combo_handler(t):
    drinks_made = t[0]
    cache = t[1]
    combos = partial_combo_handler_helper(drinks_made, DRINKS_TO_PROCESS, cache)
    stats = Stats(drinks_data, drink_id_to_name, material_costs)
    for combo in combos:
        stats.offer_all(combo)
    first_combo = None
    if len(combos) > 0:
        first_combo = combos[0]
    else:
        pass
        #        print("nothing to process", drinks_made)

    return (stats, first_combo)

def partial_combo_handler_helper(drinks_made, num_drinks_remaining, cache):
    global CACHE_DEPTH

    combos = []
    if num_drinks_remaining == 0:
        return [drinks_made]

    minimum = get_drink_set_min(drinks_made)
    to_return = []

    if num_drinks_remaining + 1 == CACHE_DEPTH:
        for key, cached_partial_combos in cache.items():
            if key <= minimum:
                for partial_combo in cached_partial_combos:
                    made = drinks_made + partial_combo
                    if can_make_drinks(made):
                        to_return.append(made)
        return to_return
                    
    for drink in DRINK_SET:
        if drink_to_index[drink] <= minimum:
            made = drinks_made + (drink,)
            if can_make_drinks(made):
                combos.append(made)


    for combo in combos:
        to_return += partial_combo_handler_helper(combo, num_drinks_remaining - 1, cache)

    return to_return

if __name__ == '__main__':
    cache = precalculate_cache(CACHE_DEPTH)
    # Doesn't work under pypy, could save a lot of memory in python
    #    gc.freeze()
    
    pool = Pool(parse_args().numWorkers)
    stats = Stats(drinks_data, drink_id_to_name, material_costs)
    jobs = 0
    non_empty_jobs = 0
    combo_count = 0

    print("starting from", parse_args().startFrom)
    for partial_stats, first_combo in pool.imap_unordered(partial_combo_handler, all_combos_generator(MAX_DRINKS, (), DRINKS_TO_PROCESS, parse_args().startFrom, cache), chunksize=100):
        jobs += 1
        stats.add(partial_stats)
        combo_count += partial_stats.num_processed
        if first_combo is not None:
            non_empty_jobs += 1
            if non_empty_jobs % 5000 == 0:
                fc_drink_names = []
                for drink in first_combo:
                    fc_drink_names.append(drink_id_to_name[drink])
                print_stats(stats)
                print(jobs, non_empty_jobs, ", ".join(fc_drink_names))
                print_indices(first_combo)
                print(time.asctime())

        if jobs % 100000 == 0:
            print(f"{jobs:,} jobs processed, {non_empty_jobs:,} non-empty, {combo_count:,} combos processed, {time.asctime()}")

    print_stats(stats)
    print(f"Final: {jobs:,} jobs processed, {non_empty_jobs:,} non-empty, {combo_count:,} combos processed")

