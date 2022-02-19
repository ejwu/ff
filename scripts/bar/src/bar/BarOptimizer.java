package bar;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;
import com.google.common.base.Stopwatch;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;


@Parameters(separators="=")
public class BarOptimizer {
    @Parameter(names={"--barLevel"})
    public int barLevel = 11;
    @Parameter(names={"--numWorkers"})
    int numWorkers = 7;
    @Parameter(names={"--cacheDepth"})
    int cacheDepth = 6;
    @Parameter(names={"--workerDepth"})
    int workerDepth = 6;

    public static void main(String... argv) {
        System.out.println("blah");
        BarOptimizer barOptimizer = new BarOptimizer();
        JCommander.newBuilder()
                .addObject(barOptimizer)
                .build()
                .parse(argv);
        barOptimizer.run();
    }


    public static int BAR_LEVEL;
    public static int CACHE_DEPTH;

    Stats getAllCompletions(Combo prefix) {
        Stats stats = new Stats();
        for (Integer cachePrefix : DataLoader.CACHE.keySet().stream().sorted(Collections.reverseOrder()).toList()) {
            if (prefix.getMin() >= cachePrefix) {
                for (Combo toAdd : DataLoader.CACHE.get(cachePrefix)) {
                    Combo combined = prefix.mergeWith(toAdd);
                    if (combined.canBeMade()) {
                        stats.offerAll(combined);
                    }
                }
            }
        }
        return stats;
    }

    @SuppressWarnings("ConstantConditions")
    public void run() {
        Stopwatch sw = Stopwatch.createStarted();
        // This needs to happen before any reference to DataLoader is made
        BAR_LEVEL = barLevel;
        CACHE_DEPTH = cacheDepth;

        System.out.println("Started at: " + LocalDateTime.now());
        System.out.printf("Bar level: %d, %d max drinks, %d workers at depth %d, cacheDepth: %d%n", barLevel, DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel), numWorkers, workerDepth, cacheDepth);

        // Some contortions here to pretend that an argument is constant
        DataLoader.init();
        Combo.init(DataLoader.getDrinksByLevel(barLevel).size());
        DataLoader.precalculateCache();

        final CompletionService<Stats> cs = new ExecutorCompletionService<>(Executors.newWorkStealingPool());


        final AtomicLong jobCount = new AtomicLong(0);
        final AtomicLong numProcessed = new AtomicLong(0);
        final AtomicBoolean doneSubmitting = new AtomicBoolean(false);
        final Stats stats = new Stats();
        Thread consumer = new Thread(new Runnable() {
            @Override
            public void run() {
                int empty = 0;
                while (!doneSubmitting.get() || cs.poll() != null) {
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

            }
        });

        consumer.start();

        ComboGenerator generator = new ComboGenerator(DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel) - CACHE_DEPTH, Combo.of());
        Combo prefix = generator.next();

        try {
            while (prefix != null) {
                while (jobCount.longValue() - numProcessed.longValue() < 500000) {
                    int batchCount = 0;
                    while (prefix != null && batchCount < 100000) {
                        Combo finalPrefix = prefix;
                        cs.submit(() -> getAllCompletions(finalPrefix));
                        jobCount.incrementAndGet();
                        prefix = generator.next();
                        batchCount++;
                    }

                }
                System.out.println(jobCount.longValue() + " " + numProcessed.longValue());
                System.out.println(jobCount.longValue() - numProcessed.longValue() + " excess jobs, done submitting " + prefix.toIndexString());
                Thread.sleep(30000);
                System.out.println(jobCount.longValue() + " " + numProcessed.longValue());
                System.out.println(jobCount.longValue() - numProcessed.longValue() + " excess jobs, maybe submitting more");
            }
            doneSubmitting.set(true);
        } catch (Exception e) {
            e.printStackTrace();
        }


        System.out.println(stats);
        System.out.println("Ended: " + LocalDateTime.now());
        System.out.println(sw.elapsed(TimeUnit.SECONDS) + " seconds taken");

        System.out.println("not actually done yet");
        while (cs.poll() != null) {
            try {
                System.out.println(stats);
                System.out.println(LocalDateTime.now());
                Thread.sleep(60000);
            } catch (Exception e) {
                e.printStackTrace();;
            }
        }
        try {
            System.out.println("completion service empty");
            Thread.sleep(10000);
        } catch (Exception e) {
            e.printStackTrace();
        }
        System.out.println(stats);
        System.out.println("Ended: " + LocalDateTime.now());
        System.out.println(sw.elapsed(TimeUnit.SECONDS) + " seconds taken");


    }
}
