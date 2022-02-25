package bar;

import bar.DataLoader.FormulaMaterial;
import com.google.common.base.Joiner;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * A set of drinks of arbitrary size.
 */
public final class ArrayCombo extends AbstractCombo implements Combo {

    static int NUM_DRINKS_AVAILABLE;

    // An array with one slot for every drink available, storing the number of drinks in each slot
    private final int[] drinks;

    // TODO: See if this representation is faster
    //    private final List<Integer> drinkIndices;

    public static void init(int numDrinksAvailable) {
        NUM_DRINKS_AVAILABLE = numDrinksAvailable;
    }

    private ArrayCombo() {
        // Default values of 0
        drinks = new int[NUM_DRINKS_AVAILABLE];
//        drinkIndices = new ArrayList<>(NUM_DRINKS_AVAILABLE);
    }

    private ArrayCombo(int[] drinks) {
        this.drinks = Arrays.copyOf(drinks, NUM_DRINKS_AVAILABLE);
    }

    @Override
    public Combo mergeWith(Combo other) {
        int[] mergedDrinks = Arrays.copyOf(drinks, NUM_DRINKS_AVAILABLE);
        ArrayCombo otherAC = (ArrayCombo) other;
        for (int i = 0; i < drinks.length; i++) {
            if (otherAC.getArray()[i] != 0) {
                mergedDrinks[i] += otherAC.getArray()[i];
            }
        }
        return new ArrayCombo(mergedDrinks);
    }

    private ArrayCombo(ArrayCombo original, int indexToAdd) {
        drinks = Arrays.copyOf(original.getArray(), NUM_DRINKS_AVAILABLE);
        drinks[indexToAdd] += 1;
//        drinkIndices = List.copyOf(original.drinkIndices);
//        // TODO: sort?
//        drinkIndices.add(indexToAdd);
    }

    int[] getArray() {
        return drinks;
    }

    public static Combo of() {
        Combo combo = new ArrayCombo();
        return combo;
    }

    public static Combo fromIndices(int... indices) {
        ArrayCombo combo = new ArrayCombo();
        for (int i : indices) {
            combo.getArray()[i] += 1;
        }
        return combo;
    }

    // Get the minimum index of a drink set
    @Override
    public int getMin() {
        for (int i = 0; i < drinks.length; i++) {
            if (drinks[i] != 0) {
                return i;
            }
        }
        // Hopefully an empty set
        return Integer.MAX_VALUE;
    }

    @Override
    public int getMax() {
        for (int i = drinks.length - 1; i >= 0; i--) {
            if (drinks[i] != 0) {
                return i;
            }
        }
        return Integer.MIN_VALUE;
    }

    // Add one drink to a combo
    @Override
    public Combo plus(int index) {
        return new ArrayCombo(this, index);
    }

    // Returns a map of materialId->numUsed
    @Override
    Map<Integer, Integer> getMaterialsUsed() {
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

    @Override
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

    @Override
    public String toNames() {
        Map<String, Integer> names = new LinkedHashMap<>();
        for (int i = drinks.length - 1; i >= 0; i--) {
            if (drinks[i] != 0) {
                String name = DataLoader.getDrinkByIndex(i).name();
                names.put(name, drinks[i]);
            }
        }
        return counterToNames(names);
    }



    @Override
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

    @Override
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

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ArrayCombo that = (ArrayCombo) o;
        return Arrays.equals(drinks, that.drinks);
    }

    @Override
    public int hashCode() {
        return Arrays.hashCode(drinks);
    }
}
