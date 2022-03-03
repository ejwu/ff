package bar;

import java.util.List;

public interface Combo {

    Combo mergeWith(Combo other);

    // Get the minimum index of a drink set
    int getMin();

    int getMax();

    // Add one drink to a combo
    Combo plus(int index);

    @SuppressWarnings("ConstantConditions")
    boolean canBeMade();

    String toIndexString();

    List<Integer> toIndices();

    String toNames();

    String toMaterials();

    int getCost();

    int getFame();

    double getFameEfficiency();

    int getTickets();

    double getTicketsEfficiency();

    double getOverall();

    double getOverallEfficiency();
}
