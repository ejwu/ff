package bar;


import com.google.common.collect.ImmutableList;
import org.junit.Test;

import java.util.Iterator;
import java.util.List;

import static junit.framework.Assert.assertFalse;
import static junit.framework.Assert.assertTrue;
import static junit.framework.Assert.fail;

public class TreeCacheTest {

    private void add(TreeCache treeCache, List<Integer> drinks) {
        treeCache.addCombo(new IndexListCombo(ImmutableList.copyOf(drinks)));
    }

    private void assertContains(TreeCache treeCache, List<Integer> drinks) {
        assertTrue(treeCache.contains(new IndexListCombo(ImmutableList.copyOf(drinks))));
    }

    private void assertDoesntContain(TreeCache treeCache, List<Integer> drinks) {
        assertFalse(treeCache.contains(new IndexListCombo(ImmutableList.copyOf(drinks))));
    }

    @Test
    public void testAddedComboMustMatchDepth() {
        TreeCache cache = new TreeCache(4);
        try {
            add(cache, List.of(1, 2, 3));
            fail();
        } catch (IllegalArgumentException expected) {
        }

        try {
            add(cache, List.of(1, 2, 3, 4, 5));
            fail();
        } catch (IllegalArgumentException expected) {
        }
    }

    @Test
    public void testAddAndContain() {
        TreeCache treeCache = new TreeCache(3);
        add(treeCache, List.of(1, 2, 3));
        add(treeCache, List.of(1, 2, 4));
        assertContains(treeCache, List.of(1, 2, 3));
        assertContains(treeCache, List.of(1, 2, 4));
        assertDoesntContain(treeCache, List.of(1, 2, 5));
    }

    @Test
    public void testIterator() {
        TreeCache treeCache = new TreeCache(3);
        add(treeCache, List.of(3, 5, 2));
        add(treeCache, List.of(1, 2, 3));
        add(treeCache, List.of(1, 2, 4));
        add(treeCache, List.of(3, 4, 2));
        add(treeCache, List.of(2, 3, 4));
        for (Combo combo : treeCache) {
            System.out.println(combo.toIndices());
        }

        for (Integer key : treeCache.getKeys()) {
            Iterator<Combo> it = treeCache.getSubtree(key);
            while (it.hasNext()) {
                Combo combo = it.next();
                System.out.println(key + ", " + combo.toIndices());
            }
        }
    }
}