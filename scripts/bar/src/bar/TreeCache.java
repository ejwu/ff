package bar;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.Iterables;

import java.util.Comparator;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.TreeMap;

public class TreeCache implements Iterable<Combo> {
    private final Map<Integer, Map> tree;
    private Map<Integer, Integer> subtreeSizes = new HashMap<>();
    private final int depth;
    private long size;
    public TreeCache(int depth) {
        this.depth = depth;
        this.size = 0;
        tree = new TreeMap<>(Comparator.reverseOrder());
    }

    private class CacheIterator implements Iterator<Combo> {
        private Map<Integer, Map> root;
        private Map<Integer, CacheIterator> children;
        private Combo next;

        CacheIterator(Map<Integer, Map> root) {
            this.root = root;
            children = new TreeMap<>(Comparator.reverseOrder());
            if (root != null) {
                for (Integer key : root.keySet()) {
                    CacheIterator toAdd = new CacheIterator(root.get(key));
                    children.put(key, toAdd);
                }
            } else {
                next = null;
            }
            next = getNext();
        }

        private Combo getNext() {
            if (children.isEmpty()) {
                return null;
            }
            Integer firstKey = Iterables.getFirst(children.keySet(), -1);
            ImmutableList.Builder<Integer> builder = ImmutableList.builder();
            builder.add(firstKey);
            CacheIterator subtree = children.get(firstKey);

            if (subtree.hasNext()) {
                builder.addAll(subtree.next().toIndices());
            }
            if (!subtree.hasNext()) {
                children.remove(firstKey);
            }
            return new IndexListCombo(builder.build());
        }

        public Combo next() {
            Combo toReturn = null;
            if (next != null) {
                toReturn = next;
                next = getNext();
            }
            return toReturn;
        }

        public boolean hasNext() {
            return next != null;
        }
    }

    @Override
    public Iterator<Combo> iterator() {
        return new CacheIterator(tree);
    }

    public void addCombo(Combo combo) {
        if (combo.toIndices().size() != depth) {
            throw new IllegalArgumentException("Combo is size " + combo.toIndices().size() + " cache depth is " + depth);
        }

        Map<Integer, Map> currentMap = tree;
        int comboIndex = 0;
        for (Integer index : combo.toIndices()) {
            if (!currentMap.containsKey(index)) {
                if (comboIndex + 1 == depth) {
                    currentMap.put(index, null);
                } else {
                    currentMap.put(index, new TreeMap<>());
                }
            }

            comboIndex += 1;
            if (comboIndex < depth) {
                currentMap = (Map<Integer, Map>) currentMap.get(index);
            }
        }
        size++;
        subtreeSizes.put(combo.getMax(), subtreeSizes.getOrDefault(combo.getMax(), 0) + 1);
    }

    public boolean contains(Combo combo) {
        if (combo.toIndices().size() != depth) {
            throw new IllegalArgumentException("Combo is size " + combo.toIndices().size() + " cache depth is " + depth);
        }
        Map<Integer, Map> current = tree;
        for (Integer index : combo.toIndices()) {
            if (!current.containsKey(index)) {
                return false;
            }
            current = (Map<Integer, Map>) current.get(index);
        }
        return true;
    }

    public long getSize() {
        return size;
    }

    public int getSubtreeSize(Integer key) {
        return subtreeSizes.get(key);
    }

    private long getSubtreeSize(Map<Integer, Map> subtree) {
        long size = 0;
        if (subtree != null) {
            for (Integer key : subtree.keySet()) {
                if (subtree.get(key) != null) {
                    size += getSubtreeSize(subtree.get(key));
                } else {
                    size += 1;
                }
            }
        }
        return size;
    }

    public long getSlowSize() {
        return getSubtreeSize(tree);
    }

    public Iterable<Integer> getKeys() {
        return tree.keySet();
    }

    public Iterator<Combo> getSubtree(Integer prefix) {
        return new CacheIterator(tree.get(prefix));
    }
}
