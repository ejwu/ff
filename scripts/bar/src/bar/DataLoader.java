package bar;

import com.google.common.base.Joiner;
import com.google.common.base.Stopwatch;
import com.google.common.collect.ImmutableBiMap;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public class DataLoader {


    // TODO: contemplate an efficiency sort order, which is complicated at the individual drink level

    enum SortOrder implements Comparator<Drink> {
        OVERALL {
            public int compare(Drink l, Drink r) {
                if (l.getOverall() > r.getOverall()) {
                    return -1;
                } else if (l.getOverall() < r.getOverall()) {
                    return 1;
                }
                return 0;
            }
        },
        CHEAPEST {
            private static double getCostEstimate(Drink drink) {
                double cost = 0.0;
                for (FormulaMaterial material : drink.materials()) {
                    MaterialShop shop = MAT_SHOP.get(getMaterialById(material.id).name);
                    cost += (double) material.num / shop.num * shop.cost;
                }
                return cost;
            }

            public int compare(Drink l, Drink r) {
                if (getCostEstimate(l) > getCostEstimate(r)) {
                    return 1;
                } else if (getCostEstimate(l) < getCostEstimate(r)) {
                    return -1;
                }
                return 0;
            }
        };
    }

    // All sorts of things will go wrong if this isn't initialized first
    private static int BAR_LEVEL = BarOptimizer.BAR_LEVEL;
    private static SortOrder SORT_ORDER = BarOptimizer.sortOrder;
    private static final String BASE_PATH = "data/";
    public static ImmutableMap<String, MaterialShop> MAT_SHOP = loadMatShop();
    public static ImmutableMap<Integer, Integer> MAX_DRINKS_BY_BAR_LEVEL = loadMaxDrinksByBarLevel();
    public static ImmutableMap<Integer, Material> MATERIAL_COSTS = loadMaterialCosts();
    // materialId to count
    public static ImmutableMap<Integer, Integer> MATERIALS_AVAILABLE = loadMaterialsAvailable();
    public static final ImmutableMap<String, Drink> DRINK_DATA = loadDrinkData();
    public static final ImmutableMap<Integer, String> DRINK_ID_TO_NAME = loadDrinkIdToName();
    public static ImmutableBiMap<Integer, Drink> INDEX_DRINK;
    public static ImmutableList<Drink> DRINKS_BY_LEVEL;
    // Map of prefixes to all possible combos of a certain size that start with that prefix
    public static TreeCache TREE_CACHE;

    public static final double OVERALL_COEFF = 3.25;

    // Tests that muck around with different bar levels in BarOptimizer will need to call this instead of just init
    // This is a mess, too much static stuff
    public static void initForTests() {
        BAR_LEVEL = BarOptimizer.BAR_LEVEL;
        MAT_SHOP = loadMatShop();
        MAX_DRINKS_BY_BAR_LEVEL = loadMaxDrinksByBarLevel();
        MATERIAL_COSTS = loadMaterialCosts();
        MATERIALS_AVAILABLE = loadMaterialsAvailable();
        init();
    }

    // This needs to happen first to initialize BAR_LEVEL
    public static void init() {
        ImmutableBiMap.Builder<Integer, Drink> builder = ImmutableBiMap.builder();
        int index = 0;
        DRINKS_BY_LEVEL = ImmutableList.copyOf(getDrinksByLevel(BAR_LEVEL));
        for (Drink drink : DRINKS_BY_LEVEL) {
            System.out.printf("%2d %-20s: %2d fame, %3d tickets - (%s) %d%n",
                    index, drink.name(), drink.fame(), drink.tickets(), drink.getMaterialListString(), drink.id());
            builder.put(index, drink);
            index++;
        }
        INDEX_DRINK = builder.build();
    }

    // TODO: Extract this in a way that caching can be used to generate this cache as well
    public static void precalculateCache(boolean allowDuplicateDrinks, int lastDrinkIndex) {
        Stopwatch sw = Stopwatch.createStarted();
        ComboGenerator generator = new ComboGenerator(BarOptimizer.CACHE_DEPTH, getEmptyCombo(), allowDuplicateDrinks, ComboGenerator.RUN_FROM_START, lastDrinkIndex);
        Combo combo = generator.next();

        TreeCache treeCache = new TreeCache(BarOptimizer.CACHE_DEPTH);

        int currentKey = -1;
        Map<Integer, Integer> keyCount = new HashMap<>();
        while (combo != null) {
            if (combo.toIndices().get(0) > currentKey) {
                if (currentKey >= 0) {
                    System.out.printf("%2d: %8d - %s%n",
                            currentKey, keyCount.getOrDefault(currentKey, 0), LocalDateTime.now());
                }
                currentKey = combo.toIndices().get(0);
            }
            treeCache.addCombo(combo);
            keyCount.put(currentKey, keyCount.getOrDefault(currentKey, 0) + 1);
            combo = generator.next();
        }
        System.out.printf("%2d: %8d - %s%n",
                currentKey, keyCount.getOrDefault(currentKey, 0), LocalDateTime.now());

        System.out.println("Tree entries: " + treeCache.getSize());
        TREE_CACHE = treeCache;
        System.out.println(sw.elapsed(TimeUnit.SECONDS) + " seconds to create cache");
    }

    public record MaterialShop(int cost, int num, int level) {}
    public record Material(String name, int cost, int num, int type, int level) {}
    public record FormulaMaterial(int id, int num) {}
    public record Drink(int fame, int tickets, int level, String name, int id, List<FormulaMaterial> materials) {
        double getOverall() {
            return OVERALL_COEFF * fame + tickets;
        }

        @SuppressWarnings("ConstantConditions")
        String getMaterialListString() {
            List<String> materialNames = new ArrayList<>();
            for (FormulaMaterial material : materials) {
                materialNames.add(material.num + "x " + MATERIAL_COSTS.get(material.id).name);
            }
            return Joiner.on(", ").join(materialNames);
        }
    }

    private static int asInt(Object o) {
        if (o instanceof String) {
            return Integer.parseInt((String) o);
        } else if (o instanceof Long) {
            return ((Long) o).intValue();
        }
        throw new IllegalArgumentException();
    }

    private static ImmutableMap<String, MaterialShop> loadMatShop() {
        System.out.println(BAR_LEVEL);
        Map<String, MaterialShop> baseShop = new LinkedHashMap<>();
        // Base spirits
        baseShop.put("Rum", new MaterialShop(50, 10, 1));
        baseShop.put("Vodka", new MaterialShop(50, 10, 1));
        baseShop.put("Brandy", new MaterialShop(50, 10, 1));
        baseShop.put("Tequila", new MaterialShop(50, 10, 1));
        baseShop.put("Gin", new MaterialShop(50, 10, 1));
        baseShop.put("Whisky", new MaterialShop(50, 10, 1));
        // Flavor spirits
        baseShop.put("Coffee Liqueur", new MaterialShop(20, 4, 2));
        baseShop.put("Orange Curacao", new MaterialShop(20, 4, 6));
        baseShop.put("Vermouth", new MaterialShop(20, 4, 7));
        baseShop.put("Bitters", new MaterialShop(40, 4, 8));
        baseShop.put("Baileys", new MaterialShop(40, 4, 9));
        baseShop.put("Campari", new MaterialShop(40, 4, 10));
        baseShop.put("Chartreuse", new MaterialShop(40, 4, 12));
        baseShop.put("Aperol", new MaterialShop(40, 4, 13));
        baseShop.put("Wine", new MaterialShop(40, 4, 14));
        // This is dumb, but the market sells 4 for 60, and also 6 for 90.
        // Use 10 for 150 as a placeholder and fix the actual cost later
        // TODO: Only used 1x in Jammie Dodger (level 15) and 2x in Crystal Coral (17),
        // see if there's some optimization to be done.
        baseShop.put("Fruit Liqueur", new MaterialShop(150, 10, 15));
        // This is dumb, but the market sells 4 for 60, and also 6 for 90.
        // Use 10 for 150 as a placeholder and fix the actual cost later
        baseShop.put("Ginger Beer", new MaterialShop(150, 10, 16));
        baseShop.put("Benedictine", new MaterialShop(150, 10, 18));

        // Other
        baseShop.put("Cola", new MaterialShop(20, 4, 1));
        baseShop.put("Orange Juice", new MaterialShop(20, 4, 1));
        baseShop.put("Pineapple Juice", new MaterialShop(20, 4, 1));
        baseShop.put("Soda Water", new MaterialShop(20, 4, 1));
        baseShop.put("Cane Syrup", new MaterialShop(20, 4, 2));
        baseShop.put("Lemon Juice", new MaterialShop(20, 4, 2));
        baseShop.put("Mint Leaf", new MaterialShop(20, 4, 3));
        baseShop.put("Honey", new MaterialShop(20, 4, 4));
        baseShop.put("Sugar", new MaterialShop(20, 4, 4));
        baseShop.put("Cream", new MaterialShop(20, 4, 5));
        baseShop.put("Fruit Syrup", new MaterialShop(40, 4, 11));
        // This is dumb, but the market sells 4 for 60, and also 6 for 90.
        // Use 10 for 150 as a placeholder and fix the actual cost later
        baseShop.put("Soda", new MaterialShop(150, 10, 17));
        baseShop.put("Fruit Juice", new MaterialShop(150, 10, 19));
        baseShop.put("Hot Sauce", new MaterialShop(150, 10, 20));
        baseShop.put("Tomato Juice", new MaterialShop(150, 10, 20));

        // Clear out anything not available at the current level
        List<String> toRemove = new ArrayList<>();
        for (Map.Entry<String, MaterialShop> entry : baseShop.entrySet()) {
            if (entry.getValue().level > BAR_LEVEL) {
                toRemove.add(entry.getKey());
            }
        }
        for (String matToRemove : toRemove) {
            baseShop.remove(matToRemove);
        }

        if (BAR_LEVEL >= 11) {
            for (String spirit : List.of("Rum", "Vodka", "Brandy", "Gin", "Tequila", "Whisky")) {
                baseShop.put(spirit, new MaterialShop(75, 15, baseShop.get(spirit).level));
            }
            for (String flavor : List.of("Baileys", "Bitters")) {
                baseShop.put(flavor, new MaterialShop(60, 6, baseShop.get(flavor).level));
            }
            for (String flavor : List.of("Vermouth", "Orange Curacao", "Coffee Liqueur")) {
                baseShop.put(flavor, new MaterialShop(30, 6, baseShop.get(flavor).level));
            }
            for (String other : List.of("Cola", "Orange Juice", "Pineapple Juice", "Soda Water", "Cane Syrup", "Lemon Juice", "Mint Leaf", "Honey", "Sugar", "Cream")) {
                baseShop.put(other, new MaterialShop(30, 6, baseShop.get(other).level));
            }
        }

        if (BAR_LEVEL >= 16) {
            for (String spirit : List.of("Rum", "Vodka", "Brandy", "Gin", "Tequila", "Whisky")) {
                baseShop.put(spirit, new MaterialShop(100, 20, baseShop.get(spirit).level));
            }
            for (String flavor : List.of("Baileys", "Bitters")) {
                baseShop.put(flavor, new MaterialShop(80, 8, baseShop.get(flavor).level));
            }
            for (String flavor : List.of("Vermouth", "Orange Curacao", "Coffee Liqueur")) {
                baseShop.put(flavor, new MaterialShop(40, 8, baseShop.get(flavor).level));
            }
            for (String flavor : List.of("Wine", "Chartreuse", "Aperol", "Campari")) {
                baseShop.put(flavor, new MaterialShop(60, 6, baseShop.get(flavor).level));
            }
            for (String other : List.of("Cola", "Orange Juice", "Pineapple Juice", "Soda Water", "Cane Syrup", "Lemon Juice", "Mint Leaf", "Honey", "Sugar", "Cream")) {
                baseShop.put(other, new MaterialShop(40, 8, baseShop.get(other).level));
            }
            for (String other : List.of("Fruit Syrup")) {
                baseShop.put(other, new MaterialShop(60, 6, baseShop.get(other).level));
            }
        }

        return ImmutableMap.copyOf(baseShop);
    }

    private static ImmutableMap<Integer, Integer> loadMaxDrinksByBarLevel() {
        try (BufferedReader reader = new BufferedReader(new FileReader(BASE_PATH + "levelUp.json.pretty"))) {
            ImmutableMap.Builder<Integer, Integer> builder = ImmutableMap.builder();
            JSONParser parser = new JSONParser();
            JSONObject json = (JSONObject) parser.parse(reader);
            for (Object key : json.keySet()) {
                builder.put(asInt(key), asInt(((JSONObject) json.get(key)).get("stockNum")));
            }
            return builder.build();
        } catch (IOException | ParseException e) {
            e.printStackTrace();
            return null;
        }
    }

    @SuppressWarnings("ConstantConditions")
    private static ImmutableMap<Integer, Material> loadMaterialCosts() {
        try (BufferedReader reader = new BufferedReader(new FileReader(BASE_PATH + "material.json.pretty"))) {
            ImmutableMap.Builder<Integer, Material> builder = ImmutableMap.builder();
            JSONParser parser = new JSONParser();
            JSONObject json = (JSONObject) parser.parse(reader);
            for (Object key : json.keySet()) {
                int materialId = asInt(key);
                JSONObject value = (JSONObject) json.get(key);
                String name = (String) value.get("name");
                if (MAT_SHOP.containsKey(name)) {
                    Material material = new Material(name, MAT_SHOP.get(name).cost, MAT_SHOP.get(name).num, asInt(value.get("materialType")), asInt(value.get("openBarLevel")));
                    builder.put(materialId, material);
                }            }
            return builder.build();
        } catch (IOException | ParseException e) {
            e.printStackTrace();
            return null;
        }
    }

    @SuppressWarnings("ConstantConditions")
    private static ImmutableMap<Integer, Integer> loadMaterialsAvailable() {
        ImmutableMap.Builder<Integer, Integer> builder = ImmutableMap.builder();
        for (int materialId : MATERIAL_COSTS.keySet()) {
            builder.put(materialId, MATERIAL_COSTS.get(materialId).num);
        }
        return builder.build();
    }

    public static ImmutableMap<String, Drink> loadDrinkData() {
        try (BufferedReader formulaReader = new BufferedReader(new FileReader(BASE_PATH + "formula.json.pretty"));
             BufferedReader drinkReader = new BufferedReader(new FileReader(BASE_PATH + "drink.json.pretty"))) {
            ImmutableMap.Builder<String, Drink> builder = ImmutableMap.builder();
            JSONParser parser = new JSONParser();
            JSONObject formulasJson = (JSONObject) parser.parse(formulaReader);
            JSONObject drinksJson = (JSONObject) parser.parse(drinkReader);
            for (Object drinkObj : drinksJson.values()) {
                JSONObject drinkJson = (JSONObject) drinkObj;
                // Ignore 0-2* versions of drinks
                if (asInt(drinkJson.get("star")) == 3) {
                    JSONObject formulaJson = (JSONObject) formulasJson.get(String.valueOf(drinkJson.get("formulaId")));

                    JSONArray materials = (JSONArray) formulaJson.get("materials");
                    JSONArray matching = (JSONArray) formulaJson.get("matching");

                    List<FormulaMaterial> ingredients = new ArrayList<>();
                    for (int i = 0; i < materials.size(); ++i) {
                        ingredients.add(new FormulaMaterial(asInt(materials.get(i)), asInt(matching.get(i))));
                    }

                    String name = (String) drinkJson.get("name");
                    Drink drink = new Drink(asInt(drinkJson.get("barPopularity")), asInt(drinkJson.get("barPoint")), asInt(formulaJson.get("openBarLevel")), name, asInt(drinkJson.get("id")), ingredients);
                    builder.put(name, drink);
                }
            }
            return builder.build();
        } catch (IOException | ParseException e) {
            e.printStackTrace();
            return null;
        }
    }

    @SuppressWarnings("ConstantConditions")
    public static ImmutableMap<Integer, String> loadDrinkIdToName() {
        ImmutableMap.Builder<Integer, String> builder = ImmutableMap.builder();
        for (Drink drink : DRINK_DATA.values()) {
            builder.put(drink.id, drink.name);
        }
        return builder.build();
    }

    @SuppressWarnings("ConstantConditions")
    public static List<Drink> getDrinksByLevel(int barLevel) {
        List<Drink> sorted = DRINK_DATA.values().stream()
                .sorted(Comparator.comparingInt(o -> o.level))
                .filter(drink -> drink.level <= barLevel)
                .sorted(SORT_ORDER)
                .toList();
        return sorted;
    }

    public static Drink getDrinkByIndex(int i) {
        return INDEX_DRINK.get(i);
    }

    @SuppressWarnings("ConstantConditions")
    public static Material getMaterialById(int id) {
        return MATERIAL_COSTS.get(id);
    }

    public static Combo getEmptyCombo() {
        return new IndexListCombo();
    }
}
