package bar;

import bar.DataLoader.Drink;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableSet;

import java.util.*;

/**
 * ComboGenerators with 1 drink remaining eagerly generate all possible combos.
 * ComboGenerators with 2 or more drinks remaining lazily recursively generate more ComboGenerators with n-1 drinks remaining to avoid blowing out all the memory.
 */
public class ComboGenerator implements Iterator<Combo> {
    public static final int RUN_FULLY = -1;
    public static final Combo RUN_FROM_START = new IndexListCombo(ImmutableList.of());

    private final int numDrinksRemaining;
    private final Combo drinksMade;
    private final boolean allowDuplicateDrinks;
    // Don't generate any combos using drinks with indices higher than this.
    private final int lastDrinkIndex;
    // Don't generate any combos that come lexicographically before this.
    private final Combo startFrom;
    // Don't generate any combos using any drinks in this set
    private final ImmutableSet<Integer> disallowedDrinks;

    // Internal queue of fully constructed Combos to be yielded
    private final Deque<Combo> toYield = new ArrayDeque<>();

    private boolean createdGenerators = false;
    private final Deque<ComboGenerator> generatorsToYield = new ArrayDeque<>();
    private ComboGenerator currentGenerator = null;

    // It's not always clear when a generator has nothing more to yield, but we can sometimes short-circuit when it's obvious
    private boolean definitelyEmpty = false;
    int returnedSoFar = 0;

    // Only use if numDrinksRemaining > 1?
    private Combo nextToReturn = null;

    private int getStartIndex() {
        if (startFrom != null && startFrom.getSize() > 0) {
            return startFrom.toIndices().get(0);
        }
        return -1;
    }

    // TODO: Verify that startFrom combos with more than 1 element actually work right
    private Combo poppedStartFrom() {
        if (startFrom == null || startFrom.getSize() == 0) {
            return startFrom;
        }
        return new IndexListCombo(ImmutableList.copyOf(startFrom.toIndices().subList(1, startFrom.getSize())));
    }

    public ComboGenerator(int numDrinksRemaining, Combo drinksMade, boolean allowDuplicateDrinks, Combo startFrom, int lastDrinkIndex) {
        this(numDrinksRemaining, drinksMade, allowDuplicateDrinks, startFrom, lastDrinkIndex, Collections.emptySet());
    }

    /**
     *
     * @param numDrinksRemaining Generated combos should all be of this size
     * @param drinksMade Prefix for all generated combos
     * @param allowDuplicateDrinks Whether duplicate drinks are allowed
     * @param startFrom If set, all generated drinks should be lexicographically after this
     * @param lastDrinkIndex If set, do not generate any drinks with indices > this.  -1 to run completely
     */
    @SuppressWarnings("ConstantConditions")
    public ComboGenerator(int numDrinksRemaining, Combo drinksMade, boolean allowDuplicateDrinks, Combo startFrom, int lastDrinkIndex, Set<Integer> disallowedDrinks) {
        if (numDrinksRemaining == 0) {
            throw new IllegalStateException();
        }

        this.numDrinksRemaining = numDrinksRemaining;
        this.drinksMade = drinksMade;
        this.allowDuplicateDrinks = allowDuplicateDrinks;
        this.startFrom = startFrom;
        this.lastDrinkIndex = lastDrinkIndex;
        this.disallowedDrinks = ImmutableSet.copyOf(disallowedDrinks);

        int startIndex = getStartIndex();

        // Fully materialize this generator if it's at the final level and only creates combos instead of generators
        if (numDrinksRemaining == 1) {
            for (Drink toAdd : DataLoader.DRINKS_BY_LEVEL) {
                int toAddIndex = DataLoader.INDEX_DRINK.inverse().get(toAdd);
                if (shouldSkip(drinksMade, allowDuplicateDrinks, lastDrinkIndex, disallowedDrinks, startIndex, toAddIndex)) {
                    continue;
                }
                if (toAddIndex <= drinksMade.getMin()) {
                    Combo potential = drinksMade.plus(toAddIndex);
                    if (potential.canBeMade()) {
//                        System.out.println("can make combo " + potential.toIndexString());
                        toYield.add(potential);
                    }
                }
            }
            if (toYield.isEmpty()) {
                definitelyEmpty = true;
//                System.out.println(drinksMade.toIndexString() + " will have nothing to yield");
            }
        }
    }

    private boolean shouldSkip(Combo drinksMade, boolean allowDuplicateDrinks, int lastDrinkIndex, Set<Integer> disallowedDrinks, int startIndex, int toAddIndex) {
        // Drink comes before the start point
        if (toAddIndex < startIndex) {
            return true;
        }
        // Drink comes after the end point
        if (lastDrinkIndex != RUN_FULLY && toAddIndex > lastDrinkIndex) {
            return true;
        }
        // Drink is in the disallowed set
        if (disallowedDrinks.contains(toAddIndex)) {
            return true;
        }
        // No dupes allowed and drink is a dupe
        // TODO: avoiding duplicates could be faster than this hack
        if (!allowDuplicateDrinks && drinksMade.toIndices().contains(toAddIndex)) {
            return true;
        }
        return false;
    }

    private boolean isDefinitelyEmpty() {
        return definitelyEmpty;
    }

    public boolean mightHaveNext() {
        boolean a = !definitelyEmpty;
        boolean b = (numDrinksRemaining == 1 && !toYield.isEmpty());
        boolean c = (numDrinksRemaining > 1 && !generatorsToYield.isEmpty());

        return nextToReturn != null || !definitelyEmpty && ((numDrinksRemaining == 1 && !toYield.isEmpty()) || (numDrinksRemaining > 1 && !generatorsToYield.isEmpty()) || !createdGenerators);
    }

    @Override
    public boolean hasNext() {
        return !definitelyEmpty &&
                // numDrinksRemaining = 1, only returning combos
                (!toYield.isEmpty() ||
                // numDrinksRemaining > 1, has cached value ready to yield
                 nextToReturn != null);
//                // Generators not obviously empty
//                (createdGenerators && !generatorsToYield.isEmpty()) ||
//                // Just created, no knowledge of whether generators will exist or be empty
//                (!createdGenerators && numDrinksRemaining > 1);
    }

    @Override
    public Combo next() {
//        System.out.println("next from " + drinksMade.toIndexString() + ", numDrinksRemaining " + numDrinksRemaining + ", " + returnedSoFar + " returned so far");
        if (numDrinksRemaining == 0) {
            throw new IllegalStateException();
        }
        // Skip the nextToReturn value since this path is easy
        if (numDrinksRemaining == 1) {
            returnedSoFar += 1;
            if (toYield.isEmpty()) {
                definitelyEmpty = true;
                return null;
            }
            Combo toReturn = toYield.pop();
//            System.out.println("returning " + toReturn.toIndexString() + ", more? " + hasNext());
            return toReturn;
        } else { // 2 or more drinks remaining
            if (!createdGenerators) {
                initializeGenerators();
                initializeNext();
            }

            return populateNextToReturn();
        }
    }

    private boolean hasDupes(Combo combo) {
        int lastIndex = -1;
        for (int index : combo.toIndices()) {
            if (index == lastIndex) {
                return true;
            }
            lastIndex = index;
        }
        return false;
    }

    @SuppressWarnings("ConstantConditions")
    private void initializeGenerators() {
//        System.out.println("----init generators---- " + drinksMade);
        int startIndex = getStartIndex();

        for (Drink toAdd : DataLoader.DRINKS_BY_LEVEL) {
            int toAddIndex = DataLoader.INDEX_DRINK.inverse().get(toAdd);
            if (toAddIndex <= drinksMade.getMin()) {
                if (shouldSkip(drinksMade, allowDuplicateDrinks, lastDrinkIndex, disallowedDrinks, startIndex, toAddIndex)) {
                    continue;
                }
                Combo potential = drinksMade.plus(toAddIndex);
                if (potential.canBeMade()) {
//                    System.out.println("can make generator " + potential.toIndexString());
                    ComboGenerator generator = new ComboGenerator(numDrinksRemaining - 1, potential, allowDuplicateDrinks, poppedStartFrom(), lastDrinkIndex, disallowedDrinks);
                    // Prune some generators early if possible
                    // TODO: Precaching next value means this will dive all the way down, which could be very expensive
                    // TODO: maybe only do this for the first one?
//                            if (generator.hasNext()) {
                        generatorsToYield.add(generator);
//                            }
                } else {
//                    System.out.println("cannot make " + potential.toIndexString());
                }
            }
        }
        createdGenerators = true;
//        System.out.println("created " + generatorsToYield.size() + " generators");
        if (generatorsToYield.size() == 0) {
            definitelyEmpty = true;
        }
    }

    private void initializeNext() {
//        System.out.println("----init start---- " + drinksMade);

        boolean first = true;
        boolean emptiedGenerator = false;
        while (first || emptiedGenerator) {
            first = false;
            emptiedGenerator = false;
            while (currentGenerator == null || currentGenerator.isDefinitelyEmpty()) {
                if (generatorsToYield.isEmpty()) {
//                    System.out.println("out of generators, next is null");
                    nextToReturn = null;
                    definitelyEmpty = true;
                    return;
                }
//                System.out.println("popping generator");
                currentGenerator = generatorsToYield.pop();
            }
            if (currentGenerator.mightHaveNext()) {
                nextToReturn = currentGenerator.next();
                if (nextToReturn == null) {
                    emptiedGenerator = true;
                }
            }
        }

//        System.out.println("------init end------" + drinksMade + " next is " + nextToReturn);
    }

    private Combo populateNextToReturn() {
        Combo toReturn = nextToReturn;

        boolean first = true;
        boolean emptiedGenerator = false;
        while (first || emptiedGenerator) {
            first = false;
            emptiedGenerator = false;
            while (currentGenerator == null || currentGenerator.isDefinitelyEmpty()) {
                if (generatorsToYield.isEmpty()) {
//                    System.out.println("out of generators, next is null, return is " + toReturn);
                    nextToReturn = null;
                    definitelyEmpty = true;
                    return toReturn;
                }
//                System.out.println("popping generator");
                currentGenerator = generatorsToYield.pop();
            }
            boolean mightHaveNext = currentGenerator.mightHaveNext();
            if (currentGenerator.mightHaveNext()) {
                nextToReturn = currentGenerator.next();
                if (nextToReturn != null) {
                    return toReturn;
                }
                emptiedGenerator = true;
            }
        }

        // In theory, this generator is done
        nextToReturn = null;
        return toReturn;
    }
}
