package bar;

import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.ImmutableMultimap;
import com.google.common.collect.Multimap;

import java.util.AbstractCollection;
import java.util.Collection;
import java.util.Map;
import java.util.TreeMap;
import java.util.TreeSet;

public class TreeCache {
    private ImmutableMultimap<Integer, Object> tree;
    private Multimap<Integer, Object> builder = ArrayListMultimap.create();
    private int depth;
    public TreeCache(int depth) {
        this.depth = depth;
        for (int i = 0 ; i < depth; i++) {

        }
    }

    public void addCombo(Combo combo) {
        int currentDepth = 0;
        Multimap<Integer, Object> currentMap = builder;
        TreeSet<Integer> leafSet = null;
        for (Integer index : combo.toIndices()) {

            if (!currentMap.containsKey(index)) {
                if (currentDepth == depth - 1) {
                    currentMap.put(index, new TreeSet<Integer>());
                } else {
                    currentMap.put(index, ArrayListMultimap.<Integer, Object>create());
                }
            }

            if (currentDepth == depth) {
                leafSet.add(index);
            } else if (currentDepth == depth - 1) {
                leafSet = (TreeSet) currentMap.get(index);
            } else {
                currentMap = (Multimap<Integer, Object>) currentMap.get(index);
            }
        }
    }

    public void freeze() {
        tree = ImmutableMultimap.copyOf(builder);
    }
}
