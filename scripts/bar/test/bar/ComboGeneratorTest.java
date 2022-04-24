package bar;

import com.google.common.collect.ImmutableList;
import org.junit.Test;

import static junit.framework.Assert.assertTrue;
import static junit.framework.Assert.fail;

public class ComboGeneratorTest {

    @Test
    public void testThree() {
        int x = BarOptimizer.CACHE_DEPTH;
        BarOptimizer.initForTest(4);
        DataLoader.init();
        ComboGenerator generator = new ComboGenerator(2, new IndexListCombo(ImmutableList.of(21)));
        Combo combo = generator.next();
        boolean hasSeen22 = false;
        while (combo != null) {
            if (combo.toIndexString().startsWith("22")) {
                hasSeen22 = true;
            }
            System.out.println(combo.toIndexString());
            combo = generator.next();
        }
        assertTrue(hasSeen22);
    }
}