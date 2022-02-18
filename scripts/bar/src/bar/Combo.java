package bar;

import bar.DataLoader.Drink;
import bar.DataLoader.FormulaMaterial;
import com.google.common.base.Joiner;

import java.util.*;

/**
 * A set of drinks of arbitrary size.
 */
public final class Combo {
    // Approximate ratio of max tickets to max fame
    public static final double OVERALL_COEFF = 3.25;

    static int NUM_DRINKS_AVAILABLE;

    // An array with one slot for every drink available, storing the number of drinks in each slot
    private final int[] drinks;

    // TODO: See if this representation is faster
    //    private final List<Integer> drinkIndices;

    public static void init(int numDrinksAvailable) {
        NUM_DRINKS_AVAILABLE = numDrinksAvailable;
    }

    private Combo() {
        // Default values of 0
        drinks = new int[NUM_DRINKS_AVAILABLE];
//        drinkIndices = new ArrayList<>(NUM_DRINKS_AVAILABLE);
    }

    private Combo(Combo original, int indexToAdd) {
        drinks = Arrays.copyOf(original.getArray(), NUM_DRINKS_AVAILABLE);
        drinks[indexToAdd] += 1;
//        drinkIndices = List.copyOf(original.drinkIndices);
//        // TODO: sort?
//        drinkIndices.add(indexToAdd);
    }

    private int[] getArray() {
        return drinks;
    }

    public static Combo of() {
        Combo combo = new Combo();
        return combo;
    }

    public static Combo fromIndices(int... indices) {
        Combo combo = new Combo();
        for (int i : indices) {
            combo.getArray()[i] += 1;
        }
        return combo;
    }

    // Get the minimum index of a drink set
    public int getMin() {
        for (int i = 0; i < drinks.length; i++) {
            if (drinks[i] != 0) {
                return i;
            }
        }
        // Hopefully an empty set
        return Integer.MAX_VALUE;
    }

    public Combo plus(int index) {
        return new Combo(this, index);
    }

    // Returns a map of materialId->numUsed
    private Map<Integer, Integer> getMaterialsUsed() {
        Map<Integer, Integer> materialsUsed = new HashMap<>();
        for (int i = 0; i < drinks.length; i++) {
            if (drinks[i] != 0) {
                for (FormulaMaterial material : DataLoader.getDrinkByIndex(i).materials()) {
                    materialsUsed.put(material.id(), drinks[i] * material.num() + materialsUsed.getOrDefault(material.id(), 0));
                }
            }
        }
        return materialsUsed;
    }

    public boolean canBeMade() {
        for (Map.Entry<Integer, Integer> entry : getMaterialsUsed().entrySet()) {
            if (DataLoader.MATERIALS_AVAILABLE.get(entry.getKey()) < entry.getValue()) {
                return false;
            }
        }
        return true;
    }

    public String toIndexString() {
        List<Integer> indices = new ArrayList<>();
        for (int i = drinks.length - 1; i >= 0; i--) {
            if (drinks[i] != 0) {
                for (int j = 0; j < drinks[i]; j++) {
                    indices.add(i);
                }
            }
        }
        return Joiner.on(", ").join(indices);
    }

    public String toNames() {
        Map<String, Integer> names = new LinkedHashMap<>();
        for (int i = drinks.length - 1; i >= 0; i--) {
            if (drinks[i] != 0) {
                String name = DataLoader.getDrinkByIndex(i).name();
                names.put(name, drinks[i]);
            }
        }
        List<String> countAndNames = new ArrayList<>();
        for (Map.Entry<String, Integer> entry : names.entrySet()) {
            if (entry.getValue() > 1) {
                countAndNames.add(entry.getValue() + "x " + entry.getKey());
            } else {
                countAndNames.add(entry.getKey());
            }
        }
        return Joiner.on(", ").join(countAndNames);
    }

    public int getCost() {
        int cost = 0;

        for (Integer materialId : getMaterialsUsed().keySet()) {
            cost += DataLoader.getMaterialById(materialId).cost();
        }
        return cost;
    }

    public int getFame() {
        int fame = 0;
        for (int i = 0; i < drinks.length; i++) {
            if (drinks[i] > 0) {
                Drink drink = DataLoader.getDrinkByIndex(i);
                fame += DataLoader.getDrinkByIndex(i).fame() * drinks[i];
            }
        }
        return fame;
    }

    public double getFameEfficiency() {
        int cost = getCost();
        if (cost == 0) {
            return 0;
        }
        return (double) getFame() / cost;
    }

    public int getTickets() {
        int tickets = 0;
        for (int i = 0; i < drinks.length; i++) {
            if (drinks[i] > 0) {
                tickets += DataLoader.getDrinkByIndex(i).tickets() * drinks[i];
            }
        }
        return tickets;
    }

    public double getTicketsEfficiency() {
        int cost = getCost();
        if (cost == 0) {
            return 0;
        }
        return (double) getTickets() / cost;
    }

    public double getOverall() {
        return (OVERALL_COEFF * getFame()) + getTickets();
    }

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
        sb.append(String.format("Cost %d, fame %d, tickets %d, overall %.1f, %.3f fame/cost, %.3f tickets/cost, %.3f overall/cost\n",
                getCost(), getFame(), getTickets(), getOverall(), getFameEfficiency(), getTicketsEfficiency(), getOverallEfficiency()));
        return sb.toString();
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Combo combo = (Combo) o;
        return Arrays.equals(drinks, combo.drinks);
    }

    @Override
    public int hashCode() {
        return Arrays.hashCode(drinks);
    }
}
