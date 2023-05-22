package bar;

/**
 * Interface to abstract single Stats instances and StatsWithCaps instances
 */
public interface StatsInterface<T> {
    void offerAll(Combo combo);
    void mergeFrom(T other);
    long getNumProcessed();
}
