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
    public int barLevel = 22;
    @Parameter(names={"--cacheDepth"})
    int cacheDepth = 12;
    @Parameter(names={"--workerDepth"})
    int workerDepth = 8;
    @Parameter(names={"--allowDuplicateDrinks"})
    boolean allowDuplicateDrinks = false;
    // Stop running after processing all combos using drinks <= this index.
    // This allows reducing cache size (and increasing cache depth).
    // -1 to run to completion (ComboGenerator.RUN_FULLY)
    @Parameter(names={"--runUntil"})
    int lastDrinkIndex = 47;
    static DataLoader.SortOrder sortOrder = DataLoader.SortOrder.OVERALL;

    static boolean allowImperfectDrinks = true;
    public static Combo START_FROM = new IndexListCombo(ImmutableList.of(46));

    // Oden - spritz < copper illusion < paloma
    // Takoyaki - pjuice, honey soda < refreshing soda
    // Snowskin - matador < fog cutter
    // mashed - mojito, margarita - no space for any with above
    // salt and pepper - lynchburg < ginger cola < sidecar


    List<String> requiredDrinks = new ArrayList<>();
    List<String> additionalDisallowedDrinks = new ArrayList<>();
//    List<String> requiredDrinks = List.of(
//            "Paloma", "Paloma", "Paloma", "Paloma", "Spritz",
//            "Refreshing Soda", "Refreshing Soda", "Refreshing Soda", "Pineapple Juice", "Pineapple Juice",
//        "Margarita");

    ////    List<String> additionalDisallowedDrinks = List.of("Honey Soda");
//    List<String> additionalDisallowedDrinks = List.of("Paloma", "Spritz", "Refreshing Soda", "Pineapple Juice", "Margarita");
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

    Stats getAllCompletions(Combo prefix) {
        int maxDrinks = MAX_DRINKS;
        // Hack to workaround requiredDrinks messing with the total number of drinks we want
        if (requiredDrinks != null) {
            maxDrinks -= requiredDrinks.size();
        }
        int numDrinksRemaining = maxDrinks - WORKER_DEPTH - CACHE_DEPTH;

        ComboGenerator generator = new ComboGenerator(numDrinksRemaining, prefix, allowDuplicateDrinks, ComboGenerator.RUN_FROM_START, lastDrinkIndex, DataLoader.getDisallowedDrinks());
        Stats stats = new Stats();

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
//        setTempValues(8, 6, 4, false, List.of(76), -1, DataLoader.SortOrder.TICKETS, true);

        Stopwatch sw = Stopwatch.createStarted();
        // This needs to happen before any reference to DataLoader is made
        BAR_LEVEL = barLevel;
        CACHE_DEPTH = cacheDepth;
        WORKER_DEPTH = workerDepth;

        System.out.println("Started at: " + LocalDateTime.now());
        System.out.printf("Bar level: %d, %d max drinks, workerDepth %d, cacheDepth: %d, allowDuplicateDrinks: %b, allowImperfectDrinks: %b, startFrom: %s, runUntil: %s%n",
                barLevel, DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel), workerDepth, cacheDepth, allowDuplicateDrinks, allowImperfectDrinks, START_FROM.toIndexString(), lastDrinkIndex);
        System.out.printf("Requiring %d drinks: %s%n", requiredDrinks.size(), requiredDrinks);
        System.out.printf("Disallowing %s%n", additionalDisallowedDrinks);

        // Some contortions here to pretend that an argument is constant
        DataLoader.init(requiredDrinks, additionalDisallowedDrinks);
        ArrayCombo.init(DataLoader.getDrinksByLevel(barLevel).size());

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
        DataLoader.precalculateCache(allowDuplicateDrinks, cacheLastDrinkIndex);

        final CompletionService<Stats> cs = new ExecutorCompletionService<>(Executors.newWorkStealingPool());


        final AtomicLong jobCount = new AtomicLong(0);
        final AtomicLong numProcessed = new AtomicLong(0);
        final AtomicBoolean doneSubmitting = new AtomicBoolean(false);
        final Stats stats = new Stats();
        Thread consumer = new Thread(() -> {
            int empty = 0;
            while (!doneSubmitting.get() || jobCount.longValue() != numProcessed.longValue()) {
                try {
                    Stats processed = cs.take().get();
                    numProcessed.incrementAndGet();
                    if (processed.numProcessed == 0) {
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
                                jobCount.longValue(), numProcessed.longValue(), empty, stats.numProcessed, cantBeMade, rejectedForDupes, rejectedForNoThreeStar, (numProcessed.longValue() - empty) / minutes, cantBeMade / minutes, stats.numProcessed / minutes);
                    }
                } catch (InterruptedException | ExecutionException e) {
                    e.printStackTrace();
                }
            }
            System.out.println("--------------------------done?");
            System.out.println("%,d submitted, %,d jobs processed, %,d empty jobs, %,d combos processed, %,d can't be made, %,d rejected for dupes".formatted(jobCount.longValue(), numProcessed.longValue(), empty, stats.numProcessed, cantBeMade, rejectedForDupes));

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
        try {
            while (prefix != null) {
                while (prefix != null && jobCount.longValue() - numProcessed.longValue() < 10000) {
                    if (!isValidNoDupePrefix(prefix)) {
//                        System.out.println("Skipping " + prefix.toIndexString() + " because last index smaller than " + (MAX_DRINKS - prefix.toIndices().size()));
                        skippedNoDupe++;
                        prefix = generator.next();
                        continue;
                    }
                    int batchCount = 0;
                    while (prefix != null && batchCount < 20000) {
                        // effectively final for use as lambda argument
                        Combo finalPrefix = prefix;
                        cs.submit(() -> getAllCompletions(finalPrefix));
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
