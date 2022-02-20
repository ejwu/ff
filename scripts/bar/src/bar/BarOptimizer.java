package bar;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;
import com.google.common.base.Stopwatch;

import java.time.LocalDateTime;
import java.util.Collections;
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
    public int barLevel = 11;
    @Parameter(names={"--cacheDepth"})
    int cacheDepth = 6;
    @Parameter(names={"--workerDepth"})
    int workerDepth = 6;

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
        ComboGenerator generator = new ComboGenerator(MAX_DRINKS - WORKER_DEPTH - CACHE_DEPTH, prefix);
        Stats stats = new Stats();

        Combo partialAtCacheLevel = generator.next();
        while (partialAtCacheLevel != null) {
            for (Integer cachePrefix : DataLoader.CACHE.keySet().stream().sorted(Collections.reverseOrder()).toList()) {
                if (partialAtCacheLevel.getMin() >= cachePrefix) {
                    for (Combo toAdd : DataLoader.CACHE.get(cachePrefix)) {
                        Combo combined = partialAtCacheLevel.mergeWith(toAdd);
                        if (combined.canBeMade()) {
                            stats.offerAll(combined);
                        }
                    }
                }
            }
            partialAtCacheLevel = generator.next();
        }
        return stats;
    }

    @SuppressWarnings("ConstantConditions")
    public void run() {
        Stopwatch sw = Stopwatch.createStarted();
        // This needs to happen before any reference to DataLoader is made
        BAR_LEVEL = barLevel;
        CACHE_DEPTH = cacheDepth;
        WORKER_DEPTH = workerDepth;

        System.out.println("Started at: " + LocalDateTime.now());
        System.out.printf("Bar level: %d, %d max drinks, %d workerDepth, cacheDepth: %d%n", barLevel, DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel), workerDepth, cacheDepth);

        // Some contortions here to pretend that an argument is constant
        DataLoader.init();
        Combo.init(DataLoader.getDrinksByLevel(barLevel).size());

        MAX_DRINKS = DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(BAR_LEVEL);
        if (workerDepth + cacheDepth > DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel)) {
            throw new IllegalArgumentException("worker + cache is too deep");
        }

        DataLoader.precalculateCache();

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
                        System.out.println("%,d jobs processed, %,d empty jobs, %,d combos processed, %,d submitted".formatted(numProcessed.longValue(), empty, stats.numProcessed, jobCount.longValue()));
                    }
                } catch (InterruptedException | ExecutionException e) {
                    e.printStackTrace();
                }
            }
            System.out.println("--------------------------done?");
            System.out.println("%,d jobs processed, %,d empty jobs, %,d combos processed, %,d submitted".formatted(numProcessed.longValue(), empty, stats.numProcessed, jobCount.longValue()));

        });

        consumer.start();

        ComboGenerator generator = new ComboGenerator(WORKER_DEPTH, Combo.of());
        Combo prefix = generator.next();
        String lastProcessed = "";
        try {
            while (prefix != null) {
                while (prefix != null && jobCount.longValue() - numProcessed.longValue() < 10000) {
                    int batchCount = 0;
                    while (prefix != null && batchCount < 20000) {
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
                        Thread.sleep(1000);
                        System.out.println(jobCount.longValue() + " " + numProcessed.longValue());
                        System.out.println(jobCount.longValue() - numProcessed.longValue() + " excess jobs, maybe submitting more");
                    } else {
                        Thread.sleep(1000);
                    }
                }
            }
            doneSubmitting.set(true);
            System.out.println("======================generator finished");
        } catch (Exception e) {
            e.printStackTrace();
        }


        System.out.println(stats);
        System.out.println("Ended: " + LocalDateTime.now());
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
