package bar;

import com.google.common.base.Joiner;
import com.google.common.collect.ImmutableSet;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public abstract class AbstractCombo implements Combo {
    // Approximate ratio of max tickets to max fame
    public static final double OVERALL_COEFF = 3.25;

    static final int UNSET = -1;
    int cachedCost = UNSET;
    int cachedFame = UNSET;
    int cachedTickets = UNSET;

    // Going to make a lot of assumptions that all the degenerate materials that appear multiple times in the shop
    // behave the same way.  For now, that means they exist twice at 4x for 60 and 6x for 90.
    // Bad things will happen if these two collections get out of sync.
    // TODO: See if there's a sane way to store all this, including the actual cost breakdowns
    private static final ImmutableSet<String> MULTI_MAT_NAMES = ImmutableSet.<String>builder()
            .add("Fruit Liqueur")
            .add("Ginger Beer")
            .add("Soda")
            .add("Benedictine")
            .add("Fruit Juice")
            .add("Hot Sauce")
            .add("Tomato Juice").build();

    private static final ImmutableSet<Integer> MULTI_MAT_IDS = ImmutableSet.<Integer>builder()
            .add(410210)
            .add(410211)
            .add(410312)
            .add(410212)
            .add(410304)
            .add(410315)
            .add(410314).build();

    abstract public Map<Integer, Integer> getMaterialsUsed();

    @Override
    @SuppressWarnings("ConstantConditions")
    public boolean canBeMade() {
        for (int i : toIndices()) {
            if (DataLoader.TWO_TO_THREE.containsKey(i) && !hasDrink(DataLoader.TWO_TO_THREE.get(i))) {
//                System.out.println("rejecting for missing 3* " + i + ": " + toString());
                return false;
            }
            if (DataLoader.ONE_STAR_DUPES.containsKey(i)) {
                for (int dupeIndex : DataLoader.ONE_STAR_DUPES.get(i)) {
                    if (hasDrink(dupeIndex)) {
                        return false;
                    }
                }
            }
        }

        for (Map.Entry<Integer, Integer> entry : getMaterialsUsed().entrySet()) {
            if (DataLoader.MATERIALS_AVAILABLE.get(entry.getKey()) < entry.getValue()) {
                return false;
            }
        }
        return true;
    }

    String counterToNames(Map<String, Integer> namesCounter) {
        List<String> countAndNames = new ArrayList<>();
        for (Map.Entry<String, Integer> entry : namesCounter.entrySet()) {
            if (entry.getValue() > 1) {
                countAndNames.add(entry.getValue() + "x " + entry.getKey());
            } else {
                countAndNames.add(entry.getKey());
            }
        }
        // It's helpful to sort drink names so that different versions of the same drink are consecutive
        return countAndNames.stream().sorted().collect(Collectors.joining(", "));
    }

    @Override
    public String toMaterials() {
        Map<String, Integer> materialsUsed = new HashMap<>();
        for (Map.Entry<Integer, Integer> entry : getMaterialsUsed().entrySet()) {
            materialsUsed.put(DataLoader.getMaterialById(entry.getKey()).name(), entry.getValue());
        }
        List<String> toReturn = new ArrayList<>();
        List<String> buyAllExcept = new ArrayList<>();
        for (String material : DataLoader.MAT_SHOP.keySet()) {
            if (materialsUsed.containsKey(material)) {
                if (materialsUsed.get(material) > 1) {
                    toReturn.add(materialsUsed.get(material) + "x " + material);
                } else {
                    toReturn.add(material);
                }
                if (MULTI_MAT_NAMES.contains(material)) {
                    // Hot Sauce and Tomato Juice (still 6+4) diverge from Soda and Fruit Juice (6+8) starting at level 23
                    if (BarOptimizer.BAR_LEVEL <= 22 || "Hot Sauce".equals(material) || "Tomato Juice".equals(material)) {
                        if (materialsUsed.get(material) <= 4) {
                            buyAllExcept.add("6x " + material);
                        } else if (materialsUsed.get(material) <= 6) {
                            buyAllExcept.add("4x " + material);
                        }
                    } else {
                        if (materialsUsed.get(material) <= 6) {
                            buyAllExcept.add("8x " + material);
                        } else if (materialsUsed.get(material) <= 8) {
                            buyAllExcept.add("6x " + material);
                        }
                    }
                }
            } else {
                buyAllExcept.add(material);
            }
        }

        StringBuilder sb = new StringBuilder();
        sb.append(Joiner.on(", ").join(toReturn)).append("\n");
        sb.append("Buy everything except ").append(buyAllExcept).append("\n");

        return sb.toString();
    }

    @Override
    public int getCost() {
        if (cachedCost != UNSET) {
            return cachedCost;
        }
        int cost = 0;

        for (Integer materialId : getMaterialsUsed().keySet()) {
            // Special case for Fruit Liqueur, Ginger Beer, and Soda because the market is dumb and has them twice
            // 4 for 60, or 6 for 90
            if (MULTI_MAT_IDS.contains(materialId)) {
                int quantity = getMaterialsUsed().get(materialId);
                // Hot sauce and Tomato Juice don't change quantities at 23 for whatever reason
                if (BarOptimizer.BAR_LEVEL <= 22 || materialId == 410315 || materialId == 410314) {
                    if (quantity <= 4) {
                        cost += 60;
                    } else if (quantity <= 6) {
                        cost += 90;
                    } else {
                        cost += 150;
                    }
                } else {
                    if (quantity <= 6) {
                        cost += 90;
                    } else if (quantity <= 8) {
                        cost += 120;
                    } else {
                        cost += 210;
                    }
                }
            } else {
                cost += DataLoader.getMaterialById(materialId).cost();
            }
        }
        cachedCost = cost;
        return cost;
    }

    @Override
    public double getFameEfficiency() {
        int cost = getCost();
        if (cost == 0) {
            return 0;
        }
        return (double) getFame() / cost;
    }

    @Override
    public double getTicketsEfficiency() {
        int cost = getCost();
        if (cost == 0) {
            return 0;
        }
        return (double) getTickets() / cost;
    }

    @Override
    public double getOverall() {
        return (OVERALL_COEFF * getFame()) + getTickets();
    }

    @Override
    public double getOverallEfficiency() {
        int cost = getCost();
        if (cost == 0) {
            return 0;
        }
        return getOverall() / cost;
    }

    @Override
    public int getSize() {
        return toIndices().size();
    }

    @Override
    public boolean isBefore(Combo other) {
        int position = 0;
        for (Integer drinkIndex : this.toIndices()) {
            // Threshold not specified to this level
            if (other.getSize() <= position) {
                return false;
            }
            // Current drink comes before the matching leveled drink in the threshold
            if (drinkIndex < other.toIndices().get(position)) {
                return true;
            }
            position++;
        }

        // No reason to skip?
        return false;
    }

    @Override
    public boolean hasDrink(int index) {
        return toIndices().contains(index);
    }

    @Override
    public String toString() {
        if (getSize() == 0) {
            return "empty combo";
        }
        StringBuilder sb = new StringBuilder();
        sb.append(toIndexString()).append("\n");
        sb.append(toNames()).append("\n");
        sb.append(toMaterials()).append("\n");
        sb.append(String.format("Cost %d, fame %d, tickets %d, overall %.1f, %.3f fame/cost, %.3f tickets/cost, %.3f overall/cost\n",
                getCost(), getFame(), getTickets(), getOverall(), getFameEfficiency(), getTicketsEfficiency(), getOverallEfficiency()));
        return sb.toString();
    }


}
