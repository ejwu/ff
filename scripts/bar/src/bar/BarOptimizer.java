package bar;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;
import com.google.common.base.Stopwatch;
import com.google.common.collect.ImmutableList;

import java.time.LocalDateTime;
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
    public int barLevel = 21;
    @Parameter(names={"--cacheDepth"})
    int cacheDepth = 8;
    @Parameter(names={"--workerDepth"})
    int workerDepth = 9;
    @Parameter(names={"--allowDuplicateDrinks"})
    boolean allowDuplicateDrinks = false;
    // Stop running after processing all combos using drinks <= this index.
    // This allows reducing cache size (and increasing cache depth).
    // -1 to run to completion (ComboGenerator.RUN_FULLY)
    @Parameter(names={"--runUntil"})
    int lastDrinkIndex = 50;
    static DataLoader.SortOrder sortOrder = DataLoader.SortOrder.OVERALL;

    static boolean allowImperfectDrinks = true;

    long cantBeMade = 0;
    long rejectedForDupes = 0;

    public static Combo START_FROM = new IndexListCombo(ImmutableList.of());

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
        ComboGenerator generator = new ComboGenerator(MAX_DRINKS - WORKER_DEPTH - CACHE_DEPTH, prefix, allowDuplicateDrinks, ComboGenerator.RUN_FROM_START, lastDrinkIndex);
        Stats stats = new Stats();

        Combo partialAtCacheLevel = generator.next();
        while (partialAtCacheLevel != null) {
            for (Integer cachePrefix : DataLoader.TREE_CACHE.getKeys()) {
                if (partialAtCacheLevel.getMin() >= cachePrefix) {
                    Iterator<Combo> it = DataLoader.TREE_CACHE.getSubtree(cachePrefix);
                    while (it.hasNext()) {
                        Combo combined = partialAtCacheLevel.mergeWith(
                                new IndexListCombo(ImmutableList.<Integer>builder()
                                        .add(cachePrefix)
                                        .addAll(it.next().toIndices()).build()));
                        if (combined.toIndices().size() != MAX_DRINKS) {
                            throw new IllegalStateException(combined.toIndexString() + " doesn't have " + MAX_DRINKS + " drinks");
                        }
                        // TODO: optimize this, should be able to do nodupes without extra checks
                        if (combined.canBeMade()) {
                            if (allowDuplicateDrinks || !hasDupes(combined)) {
                                stats.offerAll(combined);
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
        setTempValues(21, 9, 9, false, List.of(), 53, DataLoader.SortOrder.CHEAPEST, true);

        Stopwatch sw = Stopwatch.createStarted();
        // This needs to happen before any reference to DataLoader is made
        BAR_LEVEL = barLevel;
        CACHE_DEPTH = cacheDepth;
        WORKER_DEPTH = workerDepth;

        System.out.println("Started at: " + LocalDateTime.now());
        System.out.printf("Bar level: %d, %d max drinks, %d workerDepth, cacheDepth: %d, allowDuplicateDrinks: %b, startFrom: %s, runUntil: %s%n",
                barLevel, DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel), workerDepth, cacheDepth, allowDuplicateDrinks, START_FROM.toIndexString(), lastDrinkIndex);

        // Some contortions here to pretend that an argument is constant
        DataLoader.init();
        ArrayCombo.init(DataLoader.getDrinksByLevel(barLevel).size());

        MAX_DRINKS = DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(BAR_LEVEL);
        if (workerDepth + cacheDepth >= DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel)) {
            throw new IllegalArgumentException("worker + cache is too deep");
        }

        int cacheLastDrinkIndex = lastDrinkIndex;
        if (!allowDuplicateDrinks && lastDrinkIndex > 0) {
            int maxDrinks = DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel);
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
                        System.out.printf("%,d submitted, %,d jobs processed, %,d empty jobs, %,d combos processed, %,d can't be made, %,d rejected for dupes, %,d non-empty jobs processed/minute, %,d rejected combos processed/minute, %,d valid combos processed/minute%n",
                                jobCount.longValue(), numProcessed.longValue(), empty, stats.numProcessed, cantBeMade, rejectedForDupes, (numProcessed.longValue() - empty) / minutes, cantBeMade / minutes, stats.numProcessed / minutes);
                    }
                } catch (InterruptedException | ExecutionException e) {
                    e.printStackTrace();
                }
            }
            System.out.println("--------------------------done?");
            System.out.println("%,d submitted, %,d jobs processed, %,d empty jobs, %,d combos processed, %,d can't be made, %,d rejected for dupes".formatted(jobCount.longValue(), numProcessed.longValue(), empty, stats.numProcessed, cantBeMade, rejectedForDupes));

        });

        consumer.start();

        ComboGenerator generator = new ComboGenerator(WORKER_DEPTH, new IndexListCombo(), allowDuplicateDrinks, START_FROM, lastDrinkIndex);
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
            System.out.println("starting from " + prefix);
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
