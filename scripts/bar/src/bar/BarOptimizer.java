package bar;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;
import com.google.common.base.Stopwatch;

import java.time.LocalDateTime;
import java.util.concurrent.TimeUnit;


@Parameters(separators="=")
public class BarOptimizer {
    @Parameter(names={"--barLevel"})
    public int barLevel = 4;
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

    public void run() {
        Stopwatch sw = Stopwatch.createStarted();
        // This needs to happen before any reference to DataLoader is made
        BAR_LEVEL = barLevel;
        System.out.println("Started at: " + LocalDateTime.now());
        System.out.printf("Bar level: %d, %d max drinks, %d workers at depth %d, cacheDepth: %d%n", barLevel, DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel), numWorkers, workerDepth, cacheDepth);


        // Some contortions here to pretend that an argument is constant
        DataLoader.init();
        Combo.init(DataLoader.getDrinksByLevel(barLevel).size());

        ComboGenerator generator = new ComboGenerator(DataLoader.MAX_DRINKS_BY_BAR_LEVEL.get(barLevel), Combo.of());
        Combo combo = generator.next();
        int count = 0;
        Stats stats = new Stats();

        while (combo != null) {
            stats.offerAll(combo);
//            System.out.println("final " + combo);
//            if ("17, 16, 15, 14, 13, 13, 2".equals(combo.toIndexString())) {
//                System.out.println(combo.toNames());
//                System.out.println(combo.canBeMade());
//                combo.canBeMade();
//            }
            combo = generator.next();
            count++;
        }
        System.out.println(count + " combos");
        System.out.println(stats);
        System.out.println("Ended: " + LocalDateTime.now());
        System.out.println(sw.elapsed(TimeUnit.SECONDS) + " seconds taken");
    }
}
