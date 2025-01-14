#!/usr/bin/python

from collections import Counter
from collections import defaultdict
import numpy as np
import random
from scipy.stats import percentileofscore

def result(fs, shards):
    if fs > 0:
        shards += 80
        shards += 25 * (fs - 1)
    if shards < 80:
        return f"{shards} shards"
    elif shards < 95:
        return f"0* +{shards - 80:02d} shards"
    elif shards < 130:
        return f"1* +{shards - 95:02d} shards"
    elif shards < 210:
        return f"2* +{shards - 130:02d} shards"
    elif shards < 320:
        return f"3* +{shards - 210:03d} shards"
    elif shards < 470:
        return f"4* +{shards - 320:03d} shards"
    else:
        return f"5* +{shards - 470:03d} shards"

def print_counter(counter):
    counts = []
    for k in sorted(counter.keys()):
        counts.append(counter[k])
    count_sum = 0
    print(f"Percentile |  Count | Result")
    for k in sorted(counter.keys()):
        print(f"{count_sum / sum(counter.values()):10.4f} | {counter[k]:6} | {k}")
        count_sum += counter[k]

        
# triple rate
# 50 free pulls for 3x
# 50 ember pulls
# 5 free pulls after 30
def triple_rate(pull_to=105):
    fs = 0
    shards = 0
    embers = 0
    crystals = 0
    URS = 0
    TRIPLE_RATE = 0.0903
    TRIPLE_M_RATE = 0.036
    pulls = 0
    triple_rate_embers = 0
    triple_rate_crystals = 0
    for i in range(pull_to):
        triple_rate_embers += 150
        pulls += 1
        r = random.random()
        if URS < 5:
            if r < TRIPLE_RATE:
                URS += 1
                if r < TRIPLE_M_RATE:
                    fs += 1
        else:
            if r < (TRIPLE_RATE / 3):
                URS += 1
            if r < (TRIPLE_M_RATE / 3):
                fs += 1
            
    if pulls >= 30:
        triple_rate_embers -= 750
    if pulls >= 50:
        triple_rate_embers = min(triple_rate_embers, (50 * 150))
    embers += triple_rate_embers

    # 30 shards after 70
    # 1 fs after 100
    # Assume at least 105 pulls

    shards += 30
    fs += 1
    if pull_to > 105:
        crystals = (pull_to - 105) * 100
        if pull_to >= 150:
            shards += 50
        if pull_to >= 200:
            shards += 50
#    print(f"3x rate: {result(fs, shards)}, {embers} embers")

    return fs, shards, embers, crystals

# 50 crystal pulls
# 50 shards after 150
# 50 shards after 200



embers = 0
crystals = 0

# 40 ember pulls
# 40 crystal pulls
# 3 free
# 3 pulls for 6 FS
# 5 pulls for 10 FS
# 10 pulls for 10 FS
# 10 pulls for 10 FS
# 10 pulls for 10 FS + guarantee

def cycle(second_cycle=False):
    CYCLE_M_RATE = 0.012
    cycle_ms = 0
    cycles = 1
    if second_cycle:
        cycles = 2
    for c in range(cycles):
        # 39 non guaranteed pulls for steps 1-5, then the extra 3 freebies
        # -2 pulls for the guaranteed SR and UR
        for i in range(40):
            if random.random() < CYCLE_M_RATE:
                cycle_ms += 1

        pulled_m = False
        for i in range(9):
            if random.random() < CYCLE_M_RATE:
                cycle_ms += 1
                pulled_m = True
        if pulled_m:
            if random.random() < CYCLE_M_RATE:
                cycle_ms += 1
        else:
            cycle_ms += 1

    embers = 38 * 150
    crystals = 0
    if second_cycle:
        embers = 40 * 150
        crystals = 36 * 100
            
    return cycle_ms, 0, embers, crystals

      
# Option - spend 300 embers + 100 crystals for 6 pulls


# Double pick
# 20 free pulls
# 40 ember pulls
# 70 crystal pulls
# 20 shards after 50 pulls
# 30 shards after 70 pulls
def double_pick():
    DOUBLE_PICK_RATE = 0.012
    double_pick_ms = 0
    for i in range(70):
        if random.random() < DOUBLE_PICK_RATE:
            double_pick_ms += 1
    return double_pick_ms, 50, (40 * 150), (10 * 100)




# UR/SR
# 20 pulls at 300 embers each
# 30 pulls at 150 crystals
# 5 pulls for 70% UR chance
# Assume 1/6 chance for Mulukhiyah as UR
def ur_sr():
    ur_sr_ms = 0
    for i in range(4):
        if random.random() < 0.7:
            if random.random() < (1.0/6):
                ur_sr_ms += 1
    return ur_sr_ms, 0, (20 * 300), 0



# Set up swap distribution
SWAP_FS = []
SWAP_PROBS = []
prob_sum = (0.05 * 61) + (0.06 * 15)
for k in range(61):
    if k == 0:
        SWAP_FS.append("Mulukiyah")
    else:
        SWAP_FS.append(f".05-{k}")
    SWAP_PROBS.append(.05 / prob_sum)
for k in range(15):
    SWAP_FS.append(f".06-{k}")
    SWAP_PROBS.append(.06 / prob_sum)


# Swap
# 30 free pulls
# 30 ember pulls
# 60 crystal pulls
def swap():
    SWAP_M_RATE = 0.0005
    # 61 FS at 0.05%, including M
    SWAP_05_RATE = 0.0305
    # 16 FS at 0.06%
    SWAP_UR_RATE = 0.0401
    swap_ms = 0

    # 10 pulls at a time, 2 refreshes per 10 pull
    for i in range(6):
        swappable_05_urs = 0
        swappable_06_urs = 0
        refreshes = 2
        for j in range(10):
            r = random.random()
            if r < SWAP_M_RATE:
                swap_ms += 1
            elif r < SWAP_05_RATE:
                swappable_05_urs += 1
            elif r < SWAP_UR_RATE:
                swappable_06_urs += 1
        # Brutal hack for now
        if (swappable_05_urs + swappable_06_urs) > 0:
            for j in range(swappable_06_urs + swappable_05_urs + 2):
                available_swaps = np.random.choice(SWAP_FS, 3, replace=False, p=SWAP_PROBS)
                if "Mulukhiyah" in available_swaps:
                    swap_ms += 1
                
    return swap_ms, 0, (30 * 150), 0


GALAXY_UR_CHANCE = 0.0301
def galaxy_urs():
    urs = 0
    for i in range(10):
        if random.random() < GALAXY_UR_CHANCE:
            urs += 1
    return urs

# Galaxy
# 10 free items
# 30 ember items at 300
# 50 crystal pulls
# 300 embers to pull a pool
# 1 free refresh/pool
# 3 items to reset all pools
# 20% chance for Mulukhiyah pool
# 6 items to pull Mulukhiyah pool
def galaxy():
    galaxy_ms = 0
    embers_used = 0
    items_remaining = 40

    POOL_CHANCE = 0.2
    UR_CHANCE = 0.0301
    M_CHANCE = 0.012
    
    while items_remaining >= 6:
        m_pools = 0
        to_refresh = 0
        for i in range(3):
            embers_used += 300
            if random.random() < POOL_CHANCE:
                pool_urs = galaxy_urs()
                for j in range(pool_urs):
                    if random.random() < (M_CHANCE / UR_CHANCE):
                        galaxy_ms += 1
                if pool_urs == 0:
                    to_refresh += 1
                else:
                    items_remaining -= 6
            else:
                to_refresh += 1
        for i in range(to_refresh):
            if random.random() < POOL_CHANCE:
                pool_urs = galaxy_urs()
                for j in range(pool_urs):
                    if random.random() < (M_CHANCE / UR_CHANCE):
                        galaxy_ms += 1
                if pool_urs > 0:
                    items_remaining -= 6
        if items_remaining >= 9:
            items_remaining -= 3
        else:
            continue
    crystals = 0
    if items_remaining < 0:
        crystals = -150 * items_remaining
    return galaxy_ms, 0, ((30 - items_remaining) * 300) + embers_used, crystals, items_remaining


def all_pools(pull_3x_to=105, second_cycle=False):
    trials = 100000
    counters = defaultdict(Counter)

    #total_embers = 0
    #total_items_left = 0
    #total_crystals = 0
    #for i in range(trials):
    #    fs, shards, embers, crystals, items_left = galaxy()
    #    result_str = result(fs, shards)
    #    counters['galaxy'][result_str] += 1
    #    total_embers += embers
    #    total_crystals += crystals
    #    total_items_left += items_left
    #print_counter(counters['galaxy'])
    #print(total_embers / trials)
    #print(total_crystals / trials)
    #print(total_items_left / trials)
    
    for i in range(trials):
        total_fs = 0
        total_shards = 0
        fs, shards = triple_rate(pull_to=pull_3x_to)[:2]
        triple_result_str = result(fs, shards)
        counters['triple_rate'][triple_result_str] += 1
        total_fs += fs
        total_shards += shards
    
        fs, shards = cycle(second_cycle)[:2]
        cycle_result_str = result(fs, shards)
        counters['cycle'][cycle_result_str] += 1
        total_fs += fs
        total_shards += shards

        fs, shards = double_pick()[:2]
        double_pick_result_str = result(fs, shards)
        counters['double_pick'][double_pick_result_str] += 1
        total_fs += fs
        total_shards += shards

        fs, shards = ur_sr()[:2]
        ur_sr_result_str = result(fs, shards)
        counters['ur_sr'][ur_sr_result_str] += 1
        total_fs += fs
        total_shards += shards

        fs, shards = swap()[:2]
        swap_result_str = result(fs, shards)
        counters['swap'][swap_result_str] += 1
        total_fs += fs
        total_shards += shards

        fs, shards = galaxy()[:2]
        galaxy_result_str = result(fs, shards)
        counters['galaxy'][galaxy_result_str] += 1
        total_fs += fs
        total_shards += shards
        
        total_result_str = result(total_fs, total_shards)
        counters['total'][total_result_str] += 1

    print(f"Triple rate, 55 free pulls + {triple_rate()[2]} embers")
    if pull_3x_to != 105:
        print(f"Pulling to {pull_3x_to} for {triple_rate(pull_to=pull_3x_to)[3]} crystals")
    print_counter(counters['triple_rate'])
    print()
    print(f"One cycle, {cycle()[2]} embers")
    print_counter(counters['cycle'])
    print()
    print(f"Double pick, 20 free pulls + {double_pick()[2]} embers + {double_pick()[3]} crystals")
    print_counter(counters['double_pick'])
    print()
    print(f"UR/SR, {ur_sr()[2]} embers")
    print_counter(counters['ur_sr'])
    print()
    print(f"Swap, 30 free pulls + {swap()[2]} embers")
    print_counter(counters['swap'])
    print()
    print(f"Galaxy, 10 free pulls + ~17780 embers + ~72 crystals")
    print_counter(counters['galaxy'])
    print()
    print(f"Combined results, {triple_rate()[2] + cycle(second_cycle)[2] + double_pick()[2] + ur_sr()[2] + swap()[2] + 17780} embers, {triple_rate(pull_3x_to)[3] + cycle(second_cycle)[3] + double_pick()[3] + 72} crystals")
    if pull_3x_to != 105:
        print(f"Triple rate pulled {pull_3x_to} times")
    if second_cycle:
        print(f"Cycle pool finished twice")
    print_counter(counters['total'])


all_pools()

all_pools(second_cycle=True)
all_pools(pull_3x_to=150)
all_pools(pull_3x_to=150, second_cycle=True)
all_pools(pull_3x_to=120)

