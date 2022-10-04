package bar;

import com.google.common.collect.ImmutableList;
import org.junit.Test;

import java.util.List;

import static junit.framework.Assert.assertEquals;
import static junit.framework.Assert.assertFalse;
import static junit.framework.Assert.assertTrue;
import static junit.framework.Assert.fail;

public class ComboGeneratorTest {

    @Test
    public void testThree() {
        BarOptimizer.initForTest(4);
        DataLoader.init();
        // All combos starting with 21 followed by 2 more drinks, with dupes
        ComboGenerator generator = new ComboGenerator(2, new IndexListCombo(ImmutableList.of(21)), true, ComboGenerator.RUN_FROM_START, ComboGenerator.RUN_FULLY);
        Combo combo = generator.next();
        boolean hasSeen22 = false;
        int count = 0;
        while (combo != null) {
            count++;
            if (combo.toIndexString().startsWith("22")) {
                hasSeen22 = true;
            }
            combo = generator.next();
        }
        // This generator starts with 21, so it should never see 22.
        assertFalse(hasSeen22);
        // No idea if this is actually the correct count, but at least we'll know if it changes.
        assertEquals(219, count);
    }

    @Test
    public void testNoDupes() {
        BarOptimizer.initForTest(4);
        DataLoader.init();
        // All combos starting with 21 followed by 2 more drinks, without dupes
        ComboGenerator generator = new ComboGenerator(2, new IndexListCombo(ImmutableList.of(21)), false, ComboGenerator.RUN_FROM_START, ComboGenerator.RUN_FULLY);
        Combo combo = generator.next();
        int count = 0;
        // First non-dupe
        assertEquals("21, 3, 0", combo.toIndexString());
        boolean hasSeenLast = false;
        while (combo != null) {
            // Last non-dupe
            if ("21, 20, 19".equals(combo.toIndexString())) {
                hasSeenLast = true;
            }
            count++;
            combo = generator.next();
        }

        assertTrue(hasSeenLast);
        // No idea if this is actually the correct count, but at least we'll know if it changes.
        assertEquals(192, count);
    }

    @Test
    public void testLastIndex() {
        // Level 16 at bar level 4 is Brandy, which verifies that dupes still work correctly
        int lastIndex = 16;
        BarOptimizer.initForTest(4);
        DataLoader.init();
        ComboGenerator generator = new ComboGenerator(2, new IndexListCombo(), true, ComboGenerator.RUN_FROM_START, lastIndex);
        Combo combo = generator.next();
        int count = 0;
        boolean hasSeenNextIndex = false;
        boolean hasSeenLastIndex = false;
        while (combo != null) {
            assertEquals(2, combo.getSize());
            if (combo.toIndices().get(0) == lastIndex) {
                hasSeenLastIndex = true;
            }
            if (combo.toIndices().get(0) - 1 == lastIndex) {
                hasSeenNextIndex = true;
            }
            count++;
            combo = generator.next();
        }

        assertTrue(hasSeenLastIndex);
        // Make sure we're not going past the index
        assertFalse(hasSeenNextIndex);
        // No idea if this is actually the correct count, but at least we'll know if it changes.
        assertEquals(122, count);
    }

    @Test
    public void testLastIndexNoDupes() {
        // Level 16 at bar level 4 is Brandy, which verifies that dupes still work correctly
        int lastIndex = 16;
        BarOptimizer.initForTest(4);
        DataLoader.init();
        ComboGenerator generator = new ComboGenerator(2, new IndexListCombo(), false, ComboGenerator.RUN_FROM_START, lastIndex);
        Combo combo = generator.next();
        int count = 0;
        boolean hasSeenNextIndex = false;
        boolean hasSeenLastIndex = false;
        while (combo != null) {
            if (combo.toIndices().get(0) == lastIndex) {
                hasSeenLastIndex = true;
            }
            if (combo.toIndices().get(0) - 1 == lastIndex) {
                hasSeenNextIndex = true;
            }
            System.out.println(combo.toIndexString());
            count++;
            combo = generator.next();
        }

        assertTrue(hasSeenLastIndex);
        // Make sure we're not going past the index
        assertFalse(hasSeenNextIndex);
        // No idea if this is actually the correct count, but at least we'll know if it changes.
        assertEquals(120, count);
    }

    @Test
    public void testStartFromNoDupes() {
        int earliestIndex = 15;
        int numDrinksRemaining = 2;
        Combo startFrom = new IndexListCombo(ImmutableList.of(earliestIndex));
        BarOptimizer.initForTest(4);
        DataLoader.init();
        ComboGenerator generator = new ComboGenerator(numDrinksRemaining, new IndexListCombo(), false, startFrom, ComboGenerator.RUN_FULLY);
        Combo combo = generator.next();
        int count = 0;
        boolean indexTooEarly = false;
        while (combo != null) {
            if (combo.toIndices().get(0) < earliestIndex) {
                indexTooEarly = true;
            }
            if (combo.getSize() != numDrinksRemaining) {
                throw new IllegalStateException("Should be " + numDrinksRemaining + " drinks");
            }
            System.out.println(combo.toIndexString());
            count++;
            combo = generator.next();
        }

        assertFalse(indexTooEarly);
        // No idea if this is actually the correct count, but at least we'll know if it changes.
        assertEquals(145, count);
    }

    @Test
    public void testSumsAddUpWithDupes() {
        // Last drink is 22
        BarOptimizer.initForTest(4);
        DataLoader.init();
        ComboGenerator generator = new ComboGenerator(4, new IndexListCombo(), true, ComboGenerator.RUN_FROM_START, ComboGenerator.RUN_FULLY);
        Combo combo = generator.next();
        int totalCount = 0;
        while (combo != null) {
            System.out.println(combo.toIndexString());
            totalCount++;
            combo = generator.next();
        }
        System.out.println(totalCount);
        assertEquals(7062, totalCount);

        int threshold = 14;
        ComboGenerator first = new ComboGenerator(4, new IndexListCombo(), true, ComboGenerator.RUN_FROM_START, threshold);
        combo = first.next();
        int firstCount = 0;
        while (combo != null) {
            System.out.println(combo.toIndexString());
            firstCount++;
            combo = first.next();
        }
        System.out.println(firstCount);
        assertEquals(455, firstCount);

        ComboGenerator second = new ComboGenerator(4, new IndexListCombo(), true, new IndexListCombo(ImmutableList.of(threshold + 1)), ComboGenerator.RUN_FULLY);
        combo = second.next();
        int secondCount = 0;
        while (combo != null) {
            System.out.println(combo.toIndexString());
            secondCount++;
            combo = second.next();
        }
        System.out.println(secondCount);
        assertEquals(6607, secondCount);

        assertEquals(totalCount, firstCount + secondCount);
    }

    @Test
    public void testSumsAddUpNoDupes() {
        // Last drink is 22
        BarOptimizer.initForTest(4);
        DataLoader.init();
        ComboGenerator generator = new ComboGenerator(4, new IndexListCombo(), false, ComboGenerator.RUN_FROM_START, ComboGenerator.RUN_FULLY);
        Combo combo = generator.next();
        int totalCount = 0;
        while (combo != null) {
            System.out.println(combo.toIndexString());
            totalCount++;
            combo = generator.next();
        }
        System.out.println(totalCount);
        assertEquals(5493, totalCount);

        int threshold = 14;
        ComboGenerator first = new ComboGenerator(4, new IndexListCombo(), false, ComboGenerator.RUN_FROM_START, threshold);
        combo = first.next();
        int firstCount = 0;
        while (combo != null) {
            System.out.println(combo.toIndexString());
            firstCount++;
            combo = first.next();
        }
        System.out.println(firstCount);
        assertEquals(411, firstCount);

        ComboGenerator second = new ComboGenerator(4, new IndexListCombo(), false, new IndexListCombo(ImmutableList.of(threshold + 1)), ComboGenerator.RUN_FULLY);
        combo = second.next();
        int secondCount = 0;
        while (combo != null) {
            System.out.println(combo.toIndexString());
            secondCount++;
            combo = second.next();
        }
        System.out.println(secondCount);
        assertEquals(5082, secondCount);

        assertEquals(totalCount, firstCount + secondCount);
    }

    @Test
    public void testSameStartAndLastIndexNoDupes() {
        // startFrom = x, runUntil = x should be equivalent to --numDrinksRemaining, drinksMade = x and no thresholds
        BarOptimizer.initForTest(6);
        DataLoader.initForTests();
        int numDrinks = 6;
        for (int threshold = 0; threshold < DataLoader.getDrinksByLevel(6).size(); threshold++) {
            System.out.println(threshold);
            ComboGenerator generator = new ComboGenerator(numDrinks, new IndexListCombo(), false, new IndexListCombo(ImmutableList.of(threshold)), threshold);
            Combo combo = generator.next();
            int totalCount = 0;
            while (combo != null) {
                System.out.println(combo.toIndexString());
                totalCount++;
                combo = generator.next();
            }
            System.out.println(totalCount);

            generator = new ComboGenerator(numDrinks - 1, new IndexListCombo(ImmutableList.of(threshold)), false, ComboGenerator.RUN_FROM_START, ComboGenerator.RUN_FULLY);
            int premadeCount = 0;
            combo = generator.next();
            while (combo != null) {
                System.out.println(combo.toIndexString());
                premadeCount++;
                combo = generator.next();
            }
            System.out.println(premadeCount);
            assertEquals(totalCount, premadeCount);
        }
    }

    @Test
    public void testSameStartAndLastIndexWithDupes() {
        // startFrom = x, runUntil = x should be equivalent to --numDrinksRemaining, drinksMade = x and no thresholds
        BarOptimizer.initForTest(6);
        DataLoader.initForTests();
        int numDrinks = 6;
        for (int threshold = 0; threshold < DataLoader.getDrinksByLevel(6).size(); threshold++) {
            System.out.println(threshold);
            ComboGenerator generator = new ComboGenerator(numDrinks, new IndexListCombo(), true, new IndexListCombo(ImmutableList.of(threshold)), threshold);
            Combo combo = generator.next();
            int totalCount = 0;
            while (combo != null) {
                System.out.println(combo.toIndexString());
                totalCount++;
                combo = generator.next();
            }
            System.out.println(totalCount);

            generator = new ComboGenerator(numDrinks - 1, new IndexListCombo(ImmutableList.of(threshold)), true, ComboGenerator.RUN_FROM_START, ComboGenerator.RUN_FULLY);
            int premadeCount = 0;
            combo = generator.next();
            while (combo != null) {
                System.out.println(combo.toIndexString());
                premadeCount++;
                combo = generator.next();
            }
            System.out.println(premadeCount);
            assertEquals(totalCount, premadeCount);
        }
    }
}