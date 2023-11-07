package bar;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;
import com.google.common.base.Stopwatch;
import com.google.common.collect.ImmutableList;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.CompletionService;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorCompletionService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;


@Parameters(separators="=")
public class BarOptimizer {
    @Parameter(names={"--barLevel"})
    public int barLevel = 25;
    @Parameter(names={"--cacheDepth"})
    int cacheDepth = 8;
    @Parameter(names={"--workerDepth"})
    int workerDepth = 6;
    @Parameter(names={"--allowDuplicateDrinks"})
    boolean allowDuplicateDrinks = false;
    // Stop running after processing all combos using drinks <= this index.
    // This allows reducing cache size (and increasing cache depth).
    // -1 to run to completion (ComboGenerator.RUN_FULLY)
    @Parameter(names={"--runUntil"})
    int lastDrinkIndex = -1;
    @Parameter(names={"--priceCaps"})
//    List<Integer> caps = List.of(1000, 1200, 1500);
    List<Integer> caps = List.of(1500);
    private int highestCap = -1;

    static DataLoader.SortOrder sortOrder = DataLoader.SortOrder.CHEAPEST;

    static boolean allowImperfectDrinks = true;
    public static Combo START_FROM = new IndexListCombo(ImmutableList.of());

    List<String> requiredDrinks = new ArrayList<>();
//    List<String> requiredDrinks = List.of("Lemon Soda Water", "Lemon Soda Water-2", "Mistake", "Mistake-2", "Moscow Mule", "Depth Charge", "San Francisco", "San Francisco-2", "Americano", "Americano-2");

    List<String> additionalDisallowedDrinks = new ArrayList<>();

    List<String> disallowedMaterials = List.of();


    private void setVodkaDrinks() {
        disallowedMaterials = List.of("Whisky", "Rum", "Gin", "Tequila", "Brandy");
        setTempValues(25, 8, 6, false, List.of(117), -1, DataLoader.SortOrder.CHEAPEST, true);

    }

    // buddha - brandy alexander (3) < zombie, tequila sunset
    // champagne - mayan (3) < daiquiri, lemon soda water
    // beggar - fitzgerald (3) < bobby burns

    // 3x Tequila sunset due to fruit syrup
    // Zombie uses lemon juice

    // Required/disallowed drinks for level 21 and the Beggar's Chicken/Champagne/Buddha's Temptation rotation
    private void setLevel21BeggarDrinks() {
        requiredDrinks = List.of("Tequila Sunset", "Tequila Sunset", "Zombie", "Zombie", "Zombie",
                "Lemon Soda Water", "Lemon Soda Water", "Lemon Soda Water", "Lemon Soda Water", "Lemon Soda Water",
                "Bobby Burns", "Bobby Burns", "Bobby Burns", "Bobby Burns", "Bobby Burns");
        additionalDisallowedDrinks = List.of("Brandy Alexander", "Mayan", "Fitzgerald",
                "Brandy Alexander-2", "Mayan-2", "Fitzgerald-2",
                "Tequila Sunset-2", "Zombie-2",
                "Lemon Soda Water-2",
                "Bobby Burns-2");
    }

    private void setLevel23BeggarDrinks() {
        // 23 allows one more Tequila Sunset due to larger ingredient stacks
        requiredDrinks = List.of("Tequila Sunset", "Tequila Sunset", "Tequila Sunset", "Zombie", "Zombie",
                "Lemon Soda Water", "Lemon Soda Water", "Lemon Soda Water", "Lemon Soda Water", "Lemon Soda Water",
                "Bobby Burns", "Bobby Burns", "Bobby Burns", "Bobby Burns", "Bobby Burns");
        additionalDisallowedDrinks = List.of("Brandy Alexander", "Mayan", "Fitzgerald",
                "Brandy Alexander-2", "Mayan-2", "Fitzgerald-2",
                "Tequila Sunset-2", "Zombie-2",
                "Lemon Soda Water-2",
                "Bobby Burns-2");
        setTempValues(24, 7, 2, false, List.of(), -1, DataLoader.SortOrder.OVERALL, true);
    }

    // Oden - spritz < copper illusion < paloma
    // Takoyaki - pjuice, honey soda < refreshing soda
    // Snowskin - matador < fog cutter - these all use lemon juice, which is all used up by Palomas
    // mashed - mojito, margarita < americano - all used up by oden/takoyaki

    // same drinks for 24, both level 24 drinks aren't favored by anyone
    private void setLevel23OdenDrinks2Star() {
        requiredDrinks = List.of(
                "Paloma", "Paloma", "Paloma", "Paloma", "Paloma",
                "Refreshing Soda", "Refreshing Soda", "Refreshing Soda", "Refreshing Soda", "Pineapple Juice");
        additionalDisallowedDrinks = List.of("Paloma", "Spritz", "Copper Illusion",
                "Paloma-2", "Spritz-2", "Copper Illusion-2",
                "Refreshing Soda", "Honey Soda", "Pineapple Juice",
                "Refreshing Soda-2", "Honey Soda-2",
                "Fog Cutter", "Matador",
                "Fog Cutter-2", "Matador-2",
                "Americano", "Margarita", "Mojito",
                "Americano-2", "Margarita-2", "Mojito-2");
        setTempValues(25, 6, 7, false, List.of(149), 149, DataLoader.SortOrder.TICKETS, true);
    }

    private void setLevel23OdenDrinks() {
        requiredDrinks = List.of(
                "Paloma", "Paloma", "Paloma", "Paloma", "Paloma",
                "Refreshing Soda", "Refreshing Soda", "Refreshing Soda", "Refreshing Soda", "Pineapple Juice");
        additionalDisallowedDrinks = List.of("Paloma", "Spritz", "Copper Illusion",
                "Refreshing Soda", "Honey Soda", "Pineapple Juice",
                "Fog Cutter", "Matador",
                "Americano", "Margarita", "Mojito");
        setTempValues(25, 10, 4, false, List.of(), -1, DataLoader.SortOrder.TICKETS, false);
    }

    ////    List<String> additionalDisallowedDrinks = List.of("Honey Soda");
//    List<String> additionalDisallowedDrinks = List.of(
//            "Paloma-2", "Paloma-0", "Copper Illusion-2", "Copper Illusion-0", "Spritz-2", "Spritz-0",
//            "Refreshing Soda-2", "Refreshing Soda-0", "Pineapple Juice-0", "Honey Soda", "Honey Soda-2", "Honey Soda-0");

    long cantBeMade = 0;
    long rejectedForDupes = 0;
    long rejectedForNoThreeStar = 0;


    private void setTempValues(int barLevel, int cacheDepth, int workerDepth, boolean allowDuplicateDrinks, List<Integer> startFrom, int lastDrinkIndex, DataLoader.SortOrder localSortOrder, boolean allowImperfectDrinks) {
        this.barLevel = barLevel;
        this.cacheDepth = cacheDepth;
        this.workerDepth = workerDepth;
        this.allowDuplicateDrinks = allowDuplicateDrinks;
        this.START_FROM = new IndexListCombo(ImmutableList.copyOf(startFrom));
        this.lastDrinkIndex = lastDrinkIndex;
        sortOrder = localSortOrder;
        this.allowImperfectDrinks = allowImperfectDrinks;
    }


    public static void main(String... argv) {
        BarOptimizer barOptimizer = new BarOptimizer();
        JCommander.newBuilder()
                .addObject(barOptimizer)
                .build()
                .parse(argv);
        barOptimizer.run();
    }


    public static int BAR_LEVEL;
    public static int CACHE_DEPTH;
    public static int WORKER_DEPTH;
    public static int MAX_DRINKS;

    StatsInterface createEmptyStats(List<Integer> caps) {
        if (caps.isEmpty()) {
            return new Stats();
        } else {
            return new StatsWithCaps(caps);
        }
    }

    StatsInterface getAllCompletions(Combo prefix, List<Integer> caps) {
        int maxDrinks = MAX_DRINKS;
        // Hack to workaround requiredDrinks messing with the total number of drinks we want
        if (requiredDrinks != null) {
            maxDrinks -= requiredDrinks.size();
        }
        int numDrinksRemaining = maxDrinks - WORKER_DEPTH - CACHE_DEPTH;

        ComboGenerator generator = new ComboGenerator(numDrinksRemaining, prefix, allowDuplicateDrinks, ComboGenerator.RUN_FROM_START, lastDrinkIndex, DataLoader.getDisallowedDrinks());
        StatsInterface stats = createEmptyStats(caps);

        Combo partialAtCacheLevel = generator.next();
        while (partialAtCacheLevel != null) {
            // TODO: if imperfect drinks are allowed, can optimize by disallowing many combos that have 2* drinks without the corresponding 3* drink.
            int minAllowableCache = -1;
            if (allowImperfectDrinks) {
                // TODO: Does this need to be cached on creation?  Could be expensive processing for every combo
                for (Integer drink : partialAtCacheLevel.toIndices()) {
                    if (DataLoader.TWO_TO_THREE.containsKey(drink)) {
                        Integer threeStar = DataLoader.TWO_TO_THREE.get(drink);
                        if (!partialAtCacheLevel.toIndices().contains(threeStar)) {
                            // Completions must include the 3 star version of the drink, so bypass all cache levels
                            // that are too low to include it
                            minAllowableCache = Math.max(minAllowableCache, threeStar);
                        }
                    }
                }
            }
            for (Integer cachePrefix : DataLoader.TREE_CACHE.getKeys()) {
                if (cachePrefix < minAllowableCache) {
                    rejectedForNoThreeStar += DataLoader.TREE_CACHE.getSubtreeSize(cachePrefix);
                }
                if (partialAtCacheLevel.getMin() >= cachePrefix && cachePrefix >= minAllowableCache) {
                    Iterator<Combo> it = DataLoader.TREE_CACHE.getSubtree(cachePrefix);
                    while (it.hasNext()) {
                        Combo combined = partialAtCacheLevel.mergeWith(
                                new IndexListCombo(ImmutableList.<Integer>builder()
                                        .add(cachePrefix)
                                        .addAll(it.next().toIndices()).build()));
                        if (combined.toIndices().size() != maxDrinks) {
                            throw new IllegalStateException(combined.toIndexString() + " doesn't have " + maxDrinks + " drinks");
                        }
                        // TODO: optimize this, should be able to do nodupes without extra checks
                        if (combined.canBeMade()) {
                            if (allowDuplicateDrinks || !hasDupes(combined)) {
                                if (requiredDrinks.isEmpty()) {
                                    stats.offerAll(combined);
                                } else {
                                    stats.offerAll(combined.mergeWith(DataLoader.getRequiredDrinks()));
                                }
                            } else {
                                if (!allowDuplicateDrinks) {
                                    rejectedForDupes++;
                                }
                            }
                        } else {
                            cantBeMade++;
                        }
                    }
                }
            }

            partialAtCacheLevel = generator.next();
        }
//        System.out.println("last processed: %s".formatted(lastProcessed.toIndexString()));
        return stats;
    }

    public static void initForTest(int barLevel) {
        BAR_LEVEL = barLevel;
    }

    private boolean hasDupes(Combo combo) {
        int lastIndex = -1;
        for (int index : combo.toIndices()) {
            if (index == lastIndex) {
                return true;
            }
            lastIndex = index;
        }
        return false;
    }

    private boolean isValidNoDupePrefix(Combo combo) {
        if (!allowDuplicateDrinks && combo.toIndices().get(combo.getSize() - 1) < MAX_DRINKS - combo.getSize()) {
            return false;
        }
        return true;
    }

    @SuppressWarnings("ConstantConditions")
    public void run() {
        // barLevel, cacheLevel, workerDepth, allowDuplicateDrinks, startFrom, runUntil, sortOrder, allowImperfectDrinks
//        setTempValues(24, 10, 9, false, List.of(49), 49, DataLoader.SortOrder.OVERALL, false);
//        setLevel23OdenDrinks();
//        setLevel23BeggarDrinks();
//        setLevel23OdenDrinks2Star();
        setVodkaDrinks();
        Stopwatch sw = Stopwatch.createStarted();
        // This needs to happen before any reference to DataLoader is made
        BAR_LEVEL = barLevel;
        CACHE_DEPTH = cacheDepth;
        WORKER_DEPTH = workerDepth;

        if (!caps.isEmpty()) {
            for (Integer cap : caps) {
                highestCap = Math.max(highestCap, cap);
            }
        } else {
            highestCap = Integer.MAX_VALUE;
        }

        System.out.println("Started at: " + LocalDateTime.now());
        System.out.printf("Bar level: %d, %d max drinks, workerDepth %d, cacheDepth: %d, allowDuplicateDrinks: %b, allowImperfectDrinks: %b, startFrom: %s, runUntil: %s, priceCaps: %s, sortOrder: %s%n",
                barLevel, DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel), workerDepth, cacheDepth, allowDuplicateDrinks, allowImperfectDrinks, START_FROM.toIndexString(), lastDrinkIndex, caps, sortOrder);
        System.out.printf("Requiring %d drinks: %s%n", requiredDrinks.size(), requiredDrinks);
        System.out.printf("Disallowing %s%n", additionalDisallowedDrinks);
        System.out.printf("Diallowing materials %s%n", disallowedMaterials);

        // Some contortions here to pretend that an argument is constant
        DataLoader.init(requiredDrinks, additionalDisallowedDrinks, disallowedMaterials);
        ArrayCombo.init(DataLoader.getDrinksByLevel(barLevel).size());

        List<Integer> checkDrinks = new ArrayList<>();
//        for (String drink : List.of("Bernice", "Vodka", "Vodka Sour", "Black Russian", "Moscow Mule",
//                "Depth Charge", "Mistake", "Mistake-2", "Garibaldi", "Garibaldi-2", "Ginger Cola", "Ginger Cola-2", "San Francisco", "San Francisco-2", "Coffee Martini", "Coffee Martini-2", "Screwdriver", "Screwdriver-2", "Americano", "Americano-2", "Lemon Soda Water", "Lemon Soda Water-2", "Sour Pineapple Juice", "Sour Pineapple Juice-2")) {
//            System.out.println(drink + " " + DataLoader.DRINK_DATA.get(drink).tickets() + " " + DataLoader.DRINK_DATA.get(drink).fame());
//            checkDrinks.add(DataLoader.NAME_TO_INDEX.get(drink));
//        }
//        Combo check = new IndexListCombo(ImmutableList.copyOf(checkDrinks));
//        System.out.println(check);
//        System.exit(1);

        MAX_DRINKS = DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(BAR_LEVEL);
        if (workerDepth + cacheDepth >= DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel)) {
            throw new IllegalArgumentException("worker + cache is too deep");
        }
        if (requiredDrinks != null &&
                requiredDrinks.size() + workerDepth + cacheDepth >= DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel)) {
            throw new IllegalArgumentException("worker + cache + required is too deep, is " + (requiredDrinks.size() + workerDepth + cacheDepth));
        }

        int cacheLastDrinkIndex = lastDrinkIndex;
        if (!allowDuplicateDrinks) {
            if (lastDrinkIndex <= 0) {
                lastDrinkIndex = DataLoader.getDrinksByLevel(BAR_LEVEL).size() - 1;
                System.out.println("setting last drink to " + lastDrinkIndex);
            }
            int maxDrinks = DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel);
            if (requiredDrinks != null) {
                maxDrinks -= requiredDrinks.size();
            }
            cacheLastDrinkIndex = lastDrinkIndex - (maxDrinks - workerDepth - cacheDepth) - workerDepth;
            System.out.println("Building cache to %d, last drink %d, prefix depth %d, worker depth %d, max drinks %d".formatted(
                    cacheLastDrinkIndex, lastDrinkIndex, maxDrinks - workerDepth - cacheDepth, workerDepth, maxDrinks));
        }
        DataLoader.precalculateCache(allowDuplicateDrinks, cacheLastDrinkIndex, highestCap);

        final CompletionService<StatsInterface> cs = new ExecutorCompletionService<>(Executors.newWorkStealingPool());


        final AtomicLong jobCount = new AtomicLong(0);
        final AtomicLong numProcessed = new AtomicLong(0);
        final AtomicBoolean doneSubmitting = new AtomicBoolean(false);
        final StatsInterface stats = createEmptyStats(caps);
        Thread consumer = new Thread(() -> {
            int empty = 0;
            while (!doneSubmitting.get() || jobCount.longValue() != numProcessed.longValue()) {
                try {
                    StatsInterface processed = cs.take().get();
                    numProcessed.incrementAndGet();
                    if (processed.getNumProcessed() == 0) {
                        empty++;
                    } else {
                        stats.mergeFrom(processed);
                    }
                    //100k for dupes
                    if (numProcessed.longValue() % 5000 == 0) {
                        System.out.println(stats);
                        System.out.println(LocalDateTime.now());
                        long minutes = Math.max(1, sw.elapsed(TimeUnit.MINUTES));
                        System.out.printf("%,d submitted, %,d jobs processed, %,d empty jobs, %,d combos processed, %,d can't be made, %,d rejected for dupes, %,d skipped for missing 3*, %,d non-empty jobs processed/minute, %,d rejected combos processed/minute, %,d valid combos processed/minute%n",
                                jobCount.longValue(), numProcessed.longValue(), empty, stats.getNumProcessed(), cantBeMade, rejectedForDupes, rejectedForNoThreeStar, (numProcessed.longValue() - empty) / minutes, cantBeMade / minutes, stats.getNumProcessed() / minutes);
                    }
                } catch (InterruptedException | ExecutionException e) {
                    e.printStackTrace();
                }
            }
            System.out.println("--------------------------done?");
            System.out.println("%,d submitted, %,d jobs processed, %,d empty jobs, %,d combos processed, %,d can't be made, %,d rejected for dupes".formatted(jobCount.longValue(), numProcessed.longValue(), empty, stats.getNumProcessed(), cantBeMade, rejectedForDupes));

        });

        consumer.start();

        ComboGenerator generator = new ComboGenerator(WORKER_DEPTH, new IndexListCombo(), allowDuplicateDrinks, START_FROM, lastDrinkIndex, DataLoader.getDisallowedDrinks());
        Combo prefix = generator.next();
        long skipped = 0;
        if (START_FROM.getSize() > 0) {
            System.out.println("skipping from " + START_FROM);
            Stopwatch skipwatch = Stopwatch.createStarted();
            while (prefix.isBefore(START_FROM)) {
                prefix = generator.next();
                skipped++;
            }
            if (skipped > 0) {
                throw new IllegalStateException("Shouldn't have skipped anything");
            }
            System.out.println(skipped);
            System.out.println(skipwatch.elapsed(TimeUnit.SECONDS));
            System.out.println("starting from " + prefix.toIndexString());
        }
        String lastProcessed = "";
        long skippedNoDupe = 0;
        long skippedPrefixTooExpensive = 0;
        try {
            while (prefix != null) {
                while (prefix != null && jobCount.longValue() - numProcessed.longValue() < 10000) {
                    if (!isValidNoDupePrefix(prefix)) {
//                        System.out.println("Skipping " + prefix.toIndexString() + " because last index smaller than " + (MAX_DRINKS - prefix.toIndices().size()));
                        skippedNoDupe++;
                        prefix = generator.next();
                        continue;
                    }
                    if (prefix.getCost() > highestCap) {
                        skippedPrefixTooExpensive++;
                        prefix = generator.next();
//                        System.out.println(prefix.toIndices() + " skipped for being too expensive at cost " + prefix.getCost());
                        continue;
                    }
                    int batchCount = 0;
                    while (prefix != null && batchCount < 20000) {
                        // effectively final for use as lambda argument
                        Combo finalPrefix = prefix;
                        cs.submit(() -> getAllCompletions(finalPrefix, caps));
                        jobCount.incrementAndGet();
                        prefix = generator.next();
                        while (prefix != null && !isValidNoDupePrefix(prefix)) {
                            prefix = generator.next();
                            skippedNoDupe++;
                        }
                        batchCount++;
                    }

                }
                if (prefix != null) {
                    boolean noChange = prefix.toIndexString().equals(lastProcessed);
                    lastProcessed = prefix.toIndexString();
                    if (!noChange) {
                        System.out.println(jobCount.longValue() + " " + numProcessed.longValue());
                        System.out.println(jobCount.longValue() - numProcessed.longValue() + " excess jobs, done submitting for now: " + prefix.toIndexString());
                        if (skippedNoDupe > 0) {
                            System.out.println("Skipped submitting " + skippedNoDupe + " jobs with no chance of completion");
                        }
                        if (skippedPrefixTooExpensive > 0) {
                            System.out.println("Skipped submitting " + skippedPrefixTooExpensive + " jobs with expensive prefixes");
                        }
                        Thread.sleep(1000);
                        System.out.println(jobCount.longValue() + " " + numProcessed.longValue());
                        System.out.println(jobCount.longValue() - numProcessed.longValue() + " excess jobs, maybe submitting more");
                    } else {
                        Thread.sleep(1000);
                    }
                }
            }
            doneSubmitting.set(true);
            System.out.println(skippedNoDupe + " skipped jobs for no dupes");
        } catch (Exception e) {
            e.printStackTrace();
        }


        System.out.println(stats);
        System.out.println("Ended generating: " + LocalDateTime.now());
        System.out.println(sw.elapsed(TimeUnit.SECONDS) + " seconds taken");

        System.out.println("not actually done yet");
        try {
            System.out.println("joining");
            System.out.println("%,d submitted, %,d processed".formatted(jobCount.longValue(), numProcessed.longValue()));
            consumer.join();
        } catch (Exception e) {
            e.printStackTrace();
        }
        System.out.println(stats);
        System.out.printf("%,d can't be made, %,d rejected for dupes%n", cantBeMade, rejectedForDupes);
        System.out.println("Ended: " + LocalDateTime.now());
        System.out.println(sw.elapsed(TimeUnit.SECONDS) + " seconds taken");


    }
}
