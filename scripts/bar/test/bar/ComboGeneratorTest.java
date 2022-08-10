package bar;

import com.google.common.collect.ImmutableList;
import org.junit.Test;

import static junit.framework.Assert.assertEquals;
import static junit.framework.Assert.assertFalse;
import static junit.framework.Assert.assertTrue;
import static junit.framework.Assert.fail;

public class ComboGeneratorTest {

    @Test
    public void testThree() {
        BarOptimizer.initForTest(4);
        DataLoader.init();
        ComboGenerator generator = new ComboGenerator(2, new IndexListCombo(ImmutableList.of(21)), true, ComboGenerator.RUN_FULLY);
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
        ComboGenerator generator = new ComboGenerator(2, new IndexListCombo(ImmutableList.of(21)), false, ComboGenerator.RUN_FULLY);
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
        ComboGenerator generator = new ComboGenerator(2, new IndexListCombo(), true, lastIndex);
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
        ComboGenerator generator = new ComboGenerator(2, new IndexListCombo(), false, lastIndex);
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
}