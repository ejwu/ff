#!/usr/bin/python

import random

rates = {
    11: [2, 0.066, 15],
    12: [4, 0.062, 16],
    13: [6, 0.058, 17],
    14: [8, 0.055, 18],
    15: [10, 0.052, 19],
    16: [15, 0.050, 20],
    17: [18, 0.043, 23],
    18: [22, 0.035, 28],
    19: [26, 0.035, 28],
    20: [30, 0.030, 33]
    }


for next_level, data in rates.items():
    print(next_level)
    print(data)
    # Chance to enhance at exactly this level
    current_pct = 0.0
    cum_pct = 0.0
    expected_fas = 0.0
    for i in range(1, data[2]):
        current_pct = (1 - cum_pct) * data[1]
        cum_pct += current_pct
        expected_fas += data[0] * i * current_pct
        print(i, f"{current_pct:.3f}", f"{cum_pct:.3f}", f"{expected_fas:.3f}")
    expected_fas += data[2] * data[0]
    print(f"pity chance: {1 - cum_pct:.4f}")
    print(expected_fas)
