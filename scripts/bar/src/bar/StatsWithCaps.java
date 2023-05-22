package bar;

import com.google.common.collect.Iterables;

import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/**
 * Multiple Stats objects with price caps.  Allows figuring out optimal stats across multiple stats levels in a single run.
 */
public class StatsWithCaps implements StatsInterface<StatsWithCaps> {
    Map<Integer, Stats> statsMap = new TreeMap<>();
    Map<Integer, Integer> rejectionCounts = new TreeMap<>();
    int lowestCap;

    public StatsWithCaps(List<Integer> caps) {
        if (caps.isEmpty()) {
            throw new IllegalArgumentException("Must have at least one cap");
        }
        for (Integer cap : caps) {
            statsMap.put(cap, new Stats());
            rejectionCounts.put(cap, 0);
        }

        lowestCap = Iterables.getFirst(statsMap.keySet(), 0);
    }

    @Override
    public void offerAll(Combo combo) {
        for (Integer cap : statsMap.keySet()) {
            if (combo.getCost() <= cap) {
                statsMap.get(cap).offerAll(combo);
            } else {
                rejectionCounts.put(cap, rejectionCounts.get(cap) + 1);
            }
        }
    }

    @Override
    public void mergeFrom(StatsWithCaps other) {
        for (Map.Entry<Integer, Stats> entry : other.statsMap.entrySet()) {
            this.statsMap.get(entry.getKey()).mergeFrom(entry.getValue());
            this.rejectionCounts.put(entry.getKey(), this.rejectionCounts.get(entry.getKey()) + other.rejectionCounts.get(entry.getKey()));
        }
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        if (!statsMap.get(lowestCap).hasCombo()) {
            if (!rejectionCounts.isEmpty()) {
                sb.append(rejectionCounts).append("\n");
            }
            sb.append("no stats yet");
            return sb.toString();
        }
        for (Map.Entry<Integer, Stats> entry : statsMap.entrySet()) {
            sb.append("Price cap: ").append(entry.getKey()).append("\n");
            sb.append("Rejected: ").append(rejectionCounts.get(entry.getKey())).append("\n");
            sb.append(entry.getValue().toString());
        }
        return sb.toString();
    }

    @Override
    public long getNumProcessed() {
        return statsMap.get(lowestCap).getNumProcessed();
    }
}
