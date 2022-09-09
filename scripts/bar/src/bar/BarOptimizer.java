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
    public int barLevel = 19;
    @Parameter(names={"--cacheDepth"})
    int cacheDepth = 6;
    @Parameter(names={"--workerDepth"})
    int workerDepth = 8;
    @Parameter(names={"--allowDuplicateDrinks"})
    boolean allowDuplicateDrinks = false;
    // Stop running after processing all combos using drinks <= this index.
    // This allows reducing cache size (and increasing cache depth).
    // -1 to run to completion (ComboGenerator.RUN_FULLY)
    @Parameter(names={"--runUntil"})
    int lastDrinkIndex = -1;

    private void setTempValues(int barLevel, int cacheDepth, int workerDepth, boolean allowDuplicateDrinks, int lastDrinkIndex) {
        this.barLevel = barLevel;
        this.cacheDepth = cacheDepth;
        this.workerDepth = workerDepth;
        this.allowDuplicateDrinks = allowDuplicateDrinks;
        this.lastDrinkIndex = lastDrinkIndex;
    }

    public static final ImmutableList<Integer> START_FROM = ImmutableList.of();

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

    // 31, 31, 26, 26, 24, 18, 13, 13, 8, 8, 6, 4, 3, 1, 1

    Stats getAllCompletions(Combo prefix) {
        ComboGenerator generator = new ComboGenerator(MAX_DRINKS - WORKER_DEPTH - CACHE_DEPTH, prefix, allowDuplicateDrinks, lastDrinkIndex);
        Stats stats = new Stats();

//        Combo lastProcessed = prefix;

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
                            throw new IllegalStateException();
                        }
                        if (combined.canBeMade() && (allowDuplicateDrinks || !hasDupes(combined))) {
                            stats.offerAll(combined);
                        }
                    }
                }
            }

//            for (Integer cachePrefix : DataLoader.CACHE.keySet().stream().sorted(Collections.reverseOrder()).toList()) {
//                if (partialAtCacheLevel.getMin() >= cachePrefix) {
//                    System.out.println("Cache at " + cachePrefix + ": " + DataLoader.CACHE.get(cachePrefix));
//                    for (Combo toAdd : DataLoader.CACHE.get(cachePrefix)) {
//                        Combo combined = partialAtCacheLevel.mergeWith(toAdd);
//                        if (combined.canBeMade()) {
//                            stats.offerAll(combined);
//                        }
////                        lastProcessed = combined;
//                    }
//                }
//            }
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

    private boolean shouldSkip(Combo combo, ImmutableList<Integer> threshold) {
        int position = 0;
        for (Integer drinkIndex : combo.toIndices()) {
            // Threshold not specified to this level
            if (threshold.size() <= position) {
                return false;
            }
            // Current drink comes before the matching leveled drink in the threshold
            if (drinkIndex < threshold.get(position)) {
                return true;
            }
            position++;
        }

        // No reason to skip?
        return false;
    }

    @SuppressWarnings("ConstantConditions")
    public void run() {
        // barLevel, cacheLevel, workerDepth, allowDuplicateDrinks, runUntil
//        setTempValues(6, 5, 2, false, -1);

        Stopwatch sw = Stopwatch.createStarted();
        // This needs to happen before any reference to DataLoader is made
        BAR_LEVEL = barLevel;
        CACHE_DEPTH = cacheDepth;
        WORKER_DEPTH = workerDepth;

        System.out.println("Started at: " + LocalDateTime.now());
        System.out.printf("Bar level: %d, %d max drinks, %d workerDepth, cacheDepth: %d, allowDuplicateDrinks: %b%n",
                barLevel, DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel), workerDepth, cacheDepth, allowDuplicateDrinks);

        // Some contortions here to pretend that an argument is constant
        DataLoader.init();
        ArrayCombo.init(DataLoader.getDrinksByLevel(barLevel).size());

        MAX_DRINKS = DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(BAR_LEVEL);
        if (workerDepth + cacheDepth >= DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel)) {
            throw new IllegalArgumentException("worker + cache is too deep");
        }

        DataLoader.precalculateCache(allowDuplicateDrinks, lastDrinkIndex);

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
                    if (numProcessed.longValue() % 100000 == 0) {
                        System.out.println(stats);
                        System.out.println(LocalDateTime.now());
                        System.out.println("%,d jobs processed, %,d empty jobs, %,d combos processed, %,d submitted, %d jobs processed/minute, %d combos processed/minute".formatted(numProcessed.longValue(), empty, stats.numProcessed, jobCount.longValue(), numProcessed.longValue() / sw.elapsed(TimeUnit.MINUTES), stats.numProcessed / sw.elapsed(TimeUnit.MINUTES)));
                    }
                } catch (InterruptedException | ExecutionException e) {
                    e.printStackTrace();
                }
            }
            System.out.println("--------------------------done?");
            System.out.println("%,d jobs processed, %,d empty jobs, %,d combos processed, %,d submitted".formatted(numProcessed.longValue(), empty, stats.numProcessed, jobCount.longValue()));

        });

        consumer.start();

        ComboGenerator generator = new ComboGenerator(WORKER_DEPTH, new IndexListCombo(START_FROM), allowDuplicateDrinks, lastDrinkIndex);
        Combo prefix = generator.next();
        long skipped = 0;
        if (!START_FROM.isEmpty()) {
            System.out.println("skipping from " + START_FROM);
            Stopwatch skipwatch = Stopwatch.createStarted();
            while (shouldSkip(prefix, START_FROM)) {
                prefix = generator.next();
                skipped++;
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
                    if (!allowDuplicateDrinks && prefix.toIndices().get(prefix.toIndices().size() - 1) < MAX_DRINKS - prefix.toIndices().size()) {
//                        System.out.println("Skipping " + prefix.toIndices() + " because last index smaller than " + (MAX_DRINKS - prefix.toIndices().size()));
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
//        while (jobCount.longValue() != numProcessed.longValue()) {
//            try {
//                System.out.println(stats);
//                System.out.println(LocalDateTime.now());
//                System.out.println("waiting on %d submitted, %d processed".formatted(jobCount.longValue(), numProcessed.longValue()));
//                Thread.sleep(60000);
//            } catch (Exception e) {
//                e.printStackTrace();;
//            }
//        }
        try {
            System.out.println("joining");
            System.out.println("%d submitted, %d processed".formatted(jobCount.longValue(), numProcessed.longValue()));
            consumer.join();
        } catch (Exception e) {
            e.printStackTrace();
        }
        System.out.println(stats);
        System.out.println("Ended: " + LocalDateTime.now());
        System.out.println(sw.elapsed(TimeUnit.SECONDS) + " seconds taken");


    }
}
