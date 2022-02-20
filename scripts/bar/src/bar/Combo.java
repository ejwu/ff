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

    private static final int UNSET = -1;
    private int cachedCost = UNSET;
    private int cachedFame = UNSET;
    private int cachedTickets = UNSET;

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

    private Combo(int[] drinks) {
        this.drinks = Arrays.copyOf(drinks, NUM_DRINKS_AVAILABLE);
    }

    public Combo mergeWith(Combo other) {
        int[] mergedDrinks = Arrays.copyOf(drinks, NUM_DRINKS_AVAILABLE);
        for (int i = 0; i < drinks.length; i++) {
            if (other.getArray()[i] != 0) {
                mergedDrinks[i] += other.getArray()[i];
            }
        }
        return new Combo(mergedDrinks);
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

    public int getMax() {
        for (int i = drinks.length - 1; i >= 0; i--) {
            if (drinks[i] != 0) {
                return i;
            }
        }
        return Integer.MIN_VALUE;
    }

    // Add one drink to a combo
    public Combo plus(int index) {
        return new Combo(this, index);
    }

    // Returns a map of materialId->numUsed
    private Map<Integer, Integer> getMaterialsUsed() {
        Map<Integer, Integer> materialsUsed = new HashMap<>(32);
        for (int i = 0; i < drinks.length; i++) {
            if (drinks[i] != 0) {
                for (FormulaMaterial material : DataLoader.getDrinkByIndex(i).materials()) {
                    materialsUsed.put(material.id(), drinks[i] * material.num() + materialsUsed.getOrDefault(material.id(), 0));
                }
            }
        }
        return materialsUsed;
    }

    @SuppressWarnings("ConstantConditions")
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

    public String toMaterials() {
//        Set<String> materialsUsed = new HashSet<>();
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

    public int getFame() {
        if (cachedFame != UNSET) {
            return cachedFame;
        }
        int fame = 0;
        for (int i = 0; i < drinks.length; i++) {
            if (drinks[i] > 0) {
                fame += DataLoader.getDrinkByIndex(i).fame() * drinks[i];
            }
        }
        cachedFame = fame;
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
        if (cachedTickets != UNSET) {
            return cachedTickets;
        }
        int tickets = 0;
        for (int i = 0; i < drinks.length; i++) {
            if (drinks[i] > 0) {
                tickets += DataLoader.getDrinkByIndex(i).tickets() * drinks[i];
            }
        }
        cachedTickets = tickets;
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
        sb.append(toMaterials()).append("\n");
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
