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
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public class DataLoader {

    // All sorts of things will go wrong if this isn't initialized first
    private static final int BAR_LEVEL = BarOptimizer.BAR_LEVEL;
    private static final String BASE_PATH = "data/";
    public static final ImmutableMap<String, MaterialShop> MAT_SHOP = loadMatShop();
    public static final ImmutableMap<Integer, Integer> MAX_DRINKS_BY_BAR_LEVEL = loadMaxDrinksByBarLevel();
    public static final ImmutableMap<Integer, Material> MATERIAL_COSTS = loadMaterialCosts();
    // materialId to count
    public static final ImmutableMap<Integer, Integer> MATERIALS_AVAILABLE = loadMaterialsAvailable();
    public static final ImmutableMap<String, Drink> DRINK_DATA = loadDrinkData();
    public static final ImmutableMap<Integer, String> DRINK_ID_TO_NAME = loadDrinkIdToName();
    public static ImmutableBiMap<Integer, Drink> INDEX_DRINK;
    public static ImmutableList<Drink> DRINKS_BY_LEVEL;
    // Map of prefixes to all possible combos of a certain size that start with that prefix
    public static TreeCache TREE_CACHE;

    public static final double OVERALL_COEFF = 3.25;

    // This needs to happen first to initialize BAR_LEVEL
    public static void init() {
        ImmutableBiMap.Builder<Integer, Drink> builder = ImmutableBiMap.builder();
        int index = 0;
        DRINKS_BY_LEVEL = ImmutableList.copyOf(getDrinksByLevel(BAR_LEVEL));
        for (Drink drink : DRINKS_BY_LEVEL) {
            System.out.println(index + " " + drink.name() + " (" + drink.getMaterialListString() + ") " + drink.id());
            builder.put(index, drink);
            index++;
        }
        INDEX_DRINK = builder.build();
    }

    // TODO: Extract this in a way that caching can be used to generate this cache as well
    public static void precalculateCache(boolean allowDuplicateDrinks) {
        Stopwatch sw = Stopwatch.createStarted();
        ComboGenerator generator = new ComboGenerator(BarOptimizer.CACHE_DEPTH, getEmptyCombo(), allowDuplicateDrinks);
        Combo combo = generator.next();

        TreeCache treeCache = new TreeCache(BarOptimizer.CACHE_DEPTH);

        while (combo != null) {
            treeCache.addCombo(combo);
            combo = generator.next();
        }
        System.out.println("Tree entries: " + treeCache.getSize());
        System.out.println(treeCache.getSlowSize());
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

        // Assumptions for the future
        // other
        baseShop.put("Benedictine", new MaterialShop(40, 4, 18));
        // other
        baseShop.put("Fruit Juice", new MaterialShop(40, 4, 19));
        // other
        baseShop.put("Hot Sauce", new MaterialShop(40, 4, 20));
        // other
        baseShop.put("Tomato Juice", new MaterialShop(40, 4, 20));

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

    // Highest overall return first
    private static final Comparator<Drink> sortByOverall = (l, r) -> {
        if (l.getOverall() > r.getOverall()) {
            return -1;
        } else if (l.getOverall() < r.getOverall()) {
            return 1;
        }
        return 0;
    };

    // TODO: contemplate an efficiency sort order, which is complicated at the individual drink level

    @SuppressWarnings("ConstantConditions")
    public static List<Drink> getDrinksByLevel(int barLevel) {
        List<Drink> sorted = DRINK_DATA.values().stream()
                .sorted(Comparator.comparingInt(o -> o.level))
                .filter(drink -> drink.level <= barLevel)
                .sorted(sortByOverall)
                .toList();
        boolean debug = false;
        if (debug && (barLevel == 3 || barLevel == 6)) {
            Map<String, Drink> map = new HashMap<>();
            for (Drink drink : sorted) {
                map.put(drink.name, drink);
            }
            List<Drink> toReturn = new ArrayList<>();
            if (barLevel == 3) {
                for (String name : List.of("Vodka Sour", "Tequila Sour", "Mojito", "Black Russian", "Screwdriver", "Sour Pineapple Juice", "Coffee Martini", "Rattlesnake", "Rum", "Tequila", "Gin", "Vodka", "Whisky", "Brandy", "Cola", "Pineapple Juice", "Soda Water", "Orange Juice")) {
                    toReturn.add(map.get(name));
                }
            } else if (barLevel == 6) {
                for (String name : List.of("Singapore Sling", "Daiquiri", "Matador", "Lynchburg Lemonade", "Fog Cutter", "Palm Beach", "Between the Sheets", "Zombie", "Gin Basil Smash", "Brandy Crusta", "Cantaritos", "Thorn", "Cuba Libre", "Fish House Punch", "Honey Soda", "Bernice", "Sweet Orange", "Vodka Sour", "Tequila Sour", "Dirty Banana", "French 75", "Sweet Lemon", "Brandy Alexander", "Mayan", "Long Island Iced Tea", "Mojito", "Black Russian", "Screwdriver", "Blue Blazer", "Sour Pineapple Juice", "Coffee Martini", "Rattlesnake", "Rum", "Tequila", "Gin", "Vodka", "Whisky", "Brandy", "Cola", "Pineapple Juice", "Soda Water", "Orange Juice")) {
                    toReturn.add(map.get(name));
                }
            }
            return toReturn;
        }
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
//        return ArrayCombo.of();
    }
}
