package bar;

import com.google.common.base.Joiner;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public abstract class AbstractCombo implements Combo {
    // Approximate ratio of max tickets to max fame
    public static final double OVERALL_COEFF = 3.25;

    static final int UNSET = -1;
    int cachedCost = UNSET;
    int cachedFame = UNSET;
    int cachedTickets = UNSET;

    abstract Map<Integer, Integer> getMaterialsUsed();

    @Override
    @SuppressWarnings("ConstantConditions")
    public boolean canBeMade() {
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
        return Joiner.on(", ").join(countAndNames);
    }

    @Override
    public String toMaterials() {
        Map<String, Integer> materialsUsed = new HashMap<>();
        for (Map.Entry<Integer, Integer> entry : getMaterialsUsed().entrySet()) {
            materialsUsed.put(DataLoader.getMaterialById(entry.getKey()).name(), entry.getValue());
        }
        List<String> toReturn = new ArrayList<>();
        List<String> buyAllExcept = new ArrayList<>();
        boolean includeNegativeForm = DataLoader.MAT_SHOP.size() - materialsUsed.size() <= 5;
        for (String material : DataLoader.MAT_SHOP.keySet()) {
            if (materialsUsed.containsKey(material)) {
                if (materialsUsed.get(material) > 1) {
                    toReturn.add(materialsUsed.get(material) + "x " + material);
                } else {
                    toReturn.add(material);
                }
            } else if (includeNegativeForm) {
                buyAllExcept.add(material);
            }
        }

        StringBuilder sb = new StringBuilder();
        sb.append(Joiner.on(", ").join(toReturn)).append("\n");
        if (includeNegativeForm) {
            sb.append("Buy everything except ").append(buyAllExcept).append("\n");
        }

        return sb.toString();
    }

    @Override
    public int getCost() {
        if (cachedCost != UNSET) {
            return cachedCost;
        }
        int cost = 0;

        for (Integer materialId : getMaterialsUsed().keySet()) {
            cost += DataLoader.getMaterialById(materialId).cost();
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
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append(toIndexString()).append("\n");
        sb.append(toNames()).append("\n");
        sb.append(toMaterials()).append("\n");
        sb.append(String.format("Cost %d, fame %d, tickets %d, overall %.1f, %.3f fame/cost, %.3f tickets/cost, %.3f overall/cost\n",
                getCost(), getFame(), getTickets(), getOverall(), getFameEfficiency(), getTicketsEfficiency(), getOverallEfficiency()));
        return sb.toString();
    }


}
