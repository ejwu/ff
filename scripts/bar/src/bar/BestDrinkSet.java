package bar;

import java.util.Comparator;

public class BestDrinkSet {
    public Combo best;
    Comparator<Combo> comp;

    public BestDrinkSet(Comparator<Combo> comp) {
        this.comp = comp;
        best = Combo.of();
    }

    public void offer(Combo combo) {
        if (comp.compare(combo, best) > 0) {
            this.best = combo;
        }
    }

    @Override
    public String toString() {
        return best.toString();
    }
}
