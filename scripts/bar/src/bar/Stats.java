package bar;

import java.util.Comparator;

public class Stats {
    BestDrinkSet cost;
    BestDrinkSet cheap;
    BestDrinkSet fame;
    BestDrinkSet fameEfficiency;
    BestDrinkSet tickets;
    BestDrinkSet ticketsEfficiency;
    BestDrinkSet overall;
    BestDrinkSet overallEfficiency;
    public long numProcessed;

    private int doubleToComparatorReturn(double d) {
        if (d > 0.0) {
            return 1;
        } else if (d < 0.0) {
            return -1;
        }
        return 0;
    }
    private final Comparator<Combo> costComparator = (o1, o2) -> {
        int costDiff = o1.getCost() - o2.getCost();
        if (costDiff != 0) {
            return costDiff;
        }
        int fameDiff = o1.getFame() - o2.getFame();
        if (fameDiff != 0) {
            return fameDiff;
        }
        return o1.getTickets() - o2.getTickets();
    };

    // Cheap comparator isn't just costComparator reversed because we still want fame and tickets as tiebreakers
    private final Comparator<Combo> cheapComparator = (o1, o2) -> {
        // Annoying fix for the empty combo having 0 cost and always sorting to the top
        if (o1.getCost() == 0) {
            return -1;
        } else if (o2.getCost() == 0) {
            return 1;
        }

        int costDiff = o2.getCost() - o1.getCost();
        if (costDiff != 0) {
            return costDiff;
        }
        int fameDiff = o1.getFame() - o2.getFame();
        if (fameDiff != 0) {
            return fameDiff;
        }
        return o1.getTickets() - o2.getTickets();
    };

    private final Comparator<Combo> fameComparator = (o1, o2) -> {
        int fameDiff = o1.getFame() - o2.getFame();
        if (fameDiff != 0) {
            return fameDiff;
        }
        int ticketDiff = o1.getTickets() - o2.getTickets();
        if (ticketDiff != 0) {
            return ticketDiff;
        }
        // Reverse sort for cost
        return o2.getCost() - o1.getCost();
    };

    private final Comparator<Combo> fameEfficiencyComparator = (o1, o2) -> {
        int fameEfficDiff = doubleToComparatorReturn(o1.getFameEfficiency() - o2.getFameEfficiency());
        if (fameEfficDiff != 0) {
            return fameEfficDiff;
        }
        int fameDiff = o1.getFame() - o2.getFame();
        if (fameDiff != 0) {
            return fameDiff;
        }
        int ticketDiff = o1.getTickets() - o2.getTickets();
        if (ticketDiff != 0) {
            return ticketDiff;
        }
        // I guess return the highest cost combo if the efficiency is the same?
        return o1.getCost() - o2.getCost();
    };

    private final Comparator<Combo> ticketComparator = (o1, o2) -> {
        int ticketDiff = o1.getTickets() - o2.getTickets();
        if (ticketDiff != 0) {
            return ticketDiff;
        }
        int fameDiff = o1.getFame() - o2.getFame();
        if (fameDiff != 0) {
            return fameDiff;
        }
        // Reverse sort for cost
        return o2.getCost() - o1.getCost();
    };

    private final Comparator<Combo> ticketEfficiencyComparator = (o1, o2) -> {
        int ticketEfficDiff = doubleToComparatorReturn(o1.getTicketsEfficiency() - o2.getTicketsEfficiency());
        if (ticketEfficDiff != 0) {
            return ticketEfficDiff;
        }
        int ticketDiff = o1.getTickets() - o2.getTickets();
        if (ticketDiff != 0) {
            return ticketDiff;
        }
        int fameDiff = o1.getFame() - o2.getFame();
        if (fameDiff != 0) {
            return fameDiff;
        }
        // I guess return the highest cost combo if the efficiency is the same?
        return o1.getCost() - o2.getCost();
    };

    private final Comparator<Combo> overallComparator = (o1, o2) -> {
        int overallDiff = doubleToComparatorReturn(o1.getOverall() - o2.getOverall());
        if (overallDiff != 0) {
            return overallDiff;
        }
        // Reverse sort for cost
        return o2.getCost() - o1.getCost();
    };

    private final Comparator<Combo> overallEfficiencyComparator = (o1, o2) -> {
        int overallEfficDiff = doubleToComparatorReturn(o1.getOverallEfficiency() - o2.getOverallEfficiency());
        if (overallEfficDiff != 0) {
            return overallEfficDiff;
        }
        // I guess return the highest cost combo if the efficiency is the same?
        return o1.getCost() - o2.getCost();
    };

    public Stats() {
        cost = new BestDrinkSet(costComparator);
        cheap = new BestDrinkSet(cheapComparator);
        fame = new BestDrinkSet(fameComparator);
        fameEfficiency = new BestDrinkSet(fameEfficiencyComparator);
        tickets = new BestDrinkSet(ticketComparator);
        ticketsEfficiency = new BestDrinkSet(ticketEfficiencyComparator);
        overall = new BestDrinkSet(overallComparator);
        overallEfficiency = new BestDrinkSet(overallEfficiencyComparator);
        numProcessed = 0;
    }

    public void offerAll(Combo combo) {
        cost.offer(combo);
        cheap.offer(combo);
        fame.offer(combo);
        fameEfficiency.offer(combo);
        tickets.offer(combo);
        ticketsEfficiency.offer(combo);
        overall.offer(combo);
        overallEfficiency.offer(combo);
        numProcessed++;
    }

    public void mergeFrom(Stats other) {
        cost.offer(other.cost.best);
        cheap.offer(other.cheap.best);
        fame.offer(other.fame.best);
        fameEfficiency.offer(other.fameEfficiency.best);
        tickets.offer(other.tickets.best);
        ticketsEfficiency.offer(other.ticketsEfficiency.best);
        overall.offer(other.overall.best);
        overallEfficiency.offer(other.overallEfficiency.best);
        numProcessed += other.numProcessed;
    }

    public boolean hasCombo() {
        return cost.best.getCost() != 0;
    }

    @Override
    public String toString() {
        if (!hasCombo()) {
            return "no stats yet";
        }
        StringBuilder sb = new StringBuilder();
        sb.append("----------------------------------------------------------------\n");
        sb.append("Highest cost: %d\n".formatted(cost.best.getCost()));
        sb.append(cost.best);
        sb.append("\nLowest cost: %d\n".formatted(cheap.best.getCost()));
        sb.append(cheap.best);
        sb.append("\nBest fame: %d\n".formatted(fame.best.getFame()));
        sb.append(fame.best);
        sb.append("\nBest fame efficiency: %.3f\n".formatted(fameEfficiency.best.getFameEfficiency()));
        sb.append(fameEfficiency.best);
        sb.append("\nBest tickets: %d\n".formatted(tickets.best.getTickets()));
        sb.append(tickets.best);
        sb.append("\nBest ticket efficiency: %.3f\n".formatted(ticketsEfficiency.best.getTicketsEfficiency()));
        sb.append(ticketsEfficiency.best);
        sb.append("\nBest overall: %.2f\n".formatted(overall.best.getOverall()));
        sb.append(overall.best);
        sb.append("\nBest overall efficiency: %.3f\n".formatted(overallEfficiency.best.getOverallEfficiency()));
        sb.append(overallEfficiency.best);
        sb.append("\nTotal combos: %,d\n".formatted(numProcessed));
        sb.append("----------------------------------------------------------------\n");
        return sb.toString();
    }
}
