package bar;

import bar.DataLoader.FormulaMaterial;
import com.google.common.base.Joiner;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableSet;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * A combo representation of a list of drinks according to their indices in descending order.
 */
public class IndexListCombo extends AbstractCombo implements Combo {
    // A list of indices in descending order
    final ImmutableList<Integer> drinks;

    // Strictly to support hasDrink to deal with 2\* and their corresponding 3\* drinks
//    final ImmutableSet<Integer> hasDrinks;

    public IndexListCombo() {
        drinks = ImmutableList.of();
//        hasDrinks = ImmutableSet.of();
    }

    public IndexListCombo(ImmutableList<Integer> drinks) {
        this.drinks = drinks;
//        this.hasDrinks = ImmutableSet.copyOf(drinks);
    }

    @Override
    public Combo mergeWith(Combo other) {
        IndexListCombo otherILC = (IndexListCombo) other;
        ImmutableList.Builder<Integer> builder = ImmutableList.builder();
        int lIndex = 0;
        int rIndex = 0;

        while (lIndex < drinks.size() || rIndex < otherILC.drinks.size()) {
            if (lIndex == drinks.size()) {
                builder.add(otherILC.drinks.get(rIndex));
                rIndex++;
            } else if (rIndex == otherILC.drinks.size()) {
                builder.add(drinks.get(lIndex));
                lIndex++;
            } else {
                if (drinks.get(lIndex) > otherILC.drinks.get(rIndex)) {
                    builder.add(drinks.get(lIndex));
                    lIndex++;
                } else {
                    builder.add(otherILC.drinks.get(rIndex));
                    rIndex++;
                }
            }
        }
        return new IndexListCombo(builder.build());
    }

    @Override
    public int getMin() {
        if (drinks.isEmpty()) {
            return Integer.MAX_VALUE;
        }
        return drinks.get(drinks.size() - 1);
    }

    @Override
    public int getMax() {
        if (drinks.isEmpty()) {
            return Integer.MIN_VALUE;
        }
        return drinks.get(0);
    }

    @Override
    public Combo plus(int index) {
        ImmutableList.Builder<Integer> builder = ImmutableList.builder();
        boolean inserted = false;
        if (drinks.isEmpty()) {
            return new IndexListCombo(ImmutableList.of(index));
        }
        for (Integer i : drinks) {
            if (!inserted && index >= i) {
                builder.add(index);
                inserted = true;
            }
            builder.add(i);
        }
        if (!inserted) {
            builder.add(index);
        }
        return new IndexListCombo(builder.build());
    }

    // Returns a map of materialId->numUsed
    public Map<Integer, Integer> getMaterialsUsed() {
        // 33 distinct materials
        Map<Integer, Integer> materialsUsed = new HashMap<>(33);
        for (Integer i : drinks) {
            for (FormulaMaterial material : DataLoader.getDrinkByIndex(i).materials()) {
                materialsUsed.put(material.id(), material.num() + materialsUsed.getOrDefault(material.id(), 0));
            }
        }
        return materialsUsed;
    }

    @Override
    public String toIndexString() {
        return Joiner.on(", ").join(drinks);
    }

    @Override
    public List<Integer> toIndices() {
        return drinks;
    }

    @Override
    public String toNames() {
        Map<String, Integer> names = new LinkedHashMap<>();
        for (Integer i : drinks) {
            names.put(DataLoader.getDrinkByIndex(i).name(), names.getOrDefault(DataLoader.getDrinkByIndex(i).name(), 0) + 1);
        }
        return counterToNames(names);
    }

    @Override
    public int getFame() {
        if (cachedFame != UNSET) {
            return cachedFame;
        }
        int fame = 0;
        for (Integer i : drinks) {
            fame += DataLoader.getDrinkByIndex(i).fame();
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
        for (Integer i : drinks) {
            tickets += DataLoader.getDrinkByIndex(i).tickets();
        }
        cachedTickets = tickets;
        return tickets;
    }

    @Override
    public int getSize() {
        return drinks.size();
    }

    @Override
    public boolean hasDrink(int index) {
        return drinks.contains(index);
//        return hasDrinks.contains(index);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        IndexListCombo that = (IndexListCombo) o;
        return Objects.equals(drinks, that.drinks);
    }

    @Override
    public int hashCode() {
        return Objects.hash(drinks);
    }
}
