package bar;

import com.google.common.base.Joiner;
import com.google.common.base.Stopwatch;
import com.google.common.collect.ImmutableBiMap;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.ImmutableSet;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
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
        TICKETS {
            public int compare(Drink l, Drink r) {
                if (l.tickets > r.tickets) {
                    return -1;
                } else if (l.tickets < r.tickets) {
                    return 1;
                }
                if (l.fame > r.fame) {
                    return -1;
                } else if (l.fame < r.fame) {
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
    private static final SortOrder SORT_ORDER = BarOptimizer.sortOrder;
    private static final String BASE_PATH = "data/";
    public static ImmutableMap<String, MaterialShop> MAT_SHOP = loadMatShop();
    public static ImmutableMap<Integer, Integer> MAX_DRINKS_BY_BAR_LEVEL = loadMaxDrinksByBarLevel();
    public static ImmutableMap<Integer, Material> MATERIAL_COSTS = loadMaterialCosts();
    // materialId to count
    public static ImmutableMap<Integer, Integer> MATERIALS_AVAILABLE = loadMaterialsAvailable();
    public static final ImmutableMap<String, Drink> DRINK_DATA = loadDrinkData(BarOptimizer.allowImperfectDrinks);
    public static final ImmutableMap<Integer, String> DRINK_ID_TO_NAME = loadDrinkIdToName();
    public static ImmutableBiMap<Integer, Drink> INDEX_DRINK;
    public static ImmutableMap<String, Integer> NAME_TO_INDEX;
    // Map of the indices of 2* drinks to their 3* version
    public static ImmutableMap<Integer, Integer> TWO_TO_THREE;
    public static ImmutableList<Drink> DRINKS_BY_LEVEL;
    private static Combo REQUIRED_DRINKS;
    private static Combo ADDITIONAL_DISALLOWED_DRINKS;
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

    public static void init() {
        init(new ArrayList<>(), new ArrayList<>());
    }

    // This needs to happen first to initialize BAR_LEVEL
    public static void init(List<String> requiredDrinks, List<String> additionalDisallowedDrinks) {
        ImmutableBiMap.Builder<Integer, Drink> indexBuilder = ImmutableBiMap.builder();
        ImmutableMap.Builder<String, Integer> nameBuilder = ImmutableMap.builder();
        int index = 0;
        DRINKS_BY_LEVEL = ImmutableList.copyOf(getDrinksByLevel(BAR_LEVEL));
        for (Drink drink : DRINKS_BY_LEVEL) {
            System.out.printf("%2d %-24s: %2d fame, %3d tickets - (%s) %d%n",
                    index, drink.name(), drink.fame(), drink.tickets(), drink.getMaterialListString(), drink.id());
            indexBuilder.put(index, drink);
            nameBuilder.put(drink.name(), index);
            index++;
        }
        INDEX_DRINK = indexBuilder.build();
        NAME_TO_INDEX = nameBuilder.build();

        // TODO: Don't need to do this unless imperfect drinks are allowed
        ImmutableMap.Builder<Integer, Integer> twoToThreeBuilder = ImmutableMap.builder();
        for (String drinkName : NAME_TO_INDEX.keySet()) {
            if (drinkName.endsWith("-2")) {
                twoToThreeBuilder.put(Objects.requireNonNull(NAME_TO_INDEX.get(drinkName)),
                        Objects.requireNonNull(NAME_TO_INDEX.get(drinkName.substring(0, drinkName.length() - 2))));
            }
        }
        TWO_TO_THREE = twoToThreeBuilder.build();

        if (!requiredDrinks.isEmpty()) {
            System.out.println("Requiring " + requiredDrinks);
            List<Integer> requiredDrinkIndices = new ArrayList<>();
            Map<Integer, Integer> requiredMaterials = new HashMap<>();
            for (String required : requiredDrinks) {
                Drink drink = DRINK_DATA.get(required);
                for (FormulaMaterial material : drink.materials()) {
                    requiredMaterials.putIfAbsent(material.id(), 0);
                    requiredMaterials.put(material.id(), requiredMaterials.get(material.id()) + material.num());
                }
                requiredDrinkIndices.add(NAME_TO_INDEX.get(required));
            }

            REQUIRED_DRINKS = new IndexListCombo(ImmutableList.sortedCopyOf(Comparator.<Integer>naturalOrder().reversed(), requiredDrinkIndices));

            Map<Integer, Integer> mutableMaterialsAvailable = new HashMap<>(MATERIALS_AVAILABLE);
            for (Integer requiredMaterialId : REQUIRED_DRINKS.getMaterialsUsed().keySet()) {
                int matsRequired = REQUIRED_DRINKS.getMaterialsUsed().get(requiredMaterialId);
                int matsAvailable = MATERIALS_AVAILABLE.get(requiredMaterialId);
                int updatedMatsAvailable = matsAvailable - matsRequired;
                if (updatedMatsAvailable < 0) {
                    throw new IllegalArgumentException("Can't require %d of material %s, only %d available".formatted(
                            matsRequired, getMaterialById(requiredMaterialId).name(), matsAvailable));
                }
                mutableMaterialsAvailable.put(requiredMaterialId, updatedMatsAvailable);
                System.out.printf("Removing %d %s from available materials%n",
                        requiredMaterials.get(requiredMaterialId), getMaterialById(requiredMaterialId).name());
            }

            if (!additionalDisallowedDrinks.isEmpty()) {
                List<Integer> disallowedDrinks = new ArrayList<>();
                for (String disallowed : additionalDisallowedDrinks) {
                    if (!NAME_TO_INDEX.containsKey(disallowed)) {
                        throw new IllegalArgumentException(disallowed + " not in drink list");
                    }
                    disallowedDrinks.add(NAME_TO_INDEX.get(disallowed));
                }
                ADDITIONAL_DISALLOWED_DRINKS = new IndexListCombo(ImmutableList.sortedCopyOf(Comparator.<Integer>naturalOrder().reversed(), disallowedDrinks));
            }

            // Mutating the available mats seems dodgy, but cost calculations use MATERIAL_COSTS, so maybe it's safe?
            MATERIALS_AVAILABLE = ImmutableMap.copyOf(mutableMaterialsAvailable);
        }
    }

    // TODO: Extract this in a way that caching can be used to generate this cache as well
    public static void precalculateCache(boolean allowDuplicateDrinks, int lastDrinkIndex) {
        Stopwatch sw = Stopwatch.createStarted();
        ComboGenerator generator = new ComboGenerator(BarOptimizer.CACHE_DEPTH, getEmptyCombo(), allowDuplicateDrinks, ComboGenerator.RUN_FROM_START, lastDrinkIndex, getDisallowedDrinks());
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
            // TODO: This only excludes combos missing the 3* version of the current key - modifying the generator to be
            // smarter could exclude further combos involving 2/3* drinks besides the current key
            if (TWO_TO_THREE.containsKey(currentKey) && !combo.toIndices().contains(TWO_TO_THREE.get(currentKey))) {
                // Suppress combos that include the 2* but not the 3* version of a drink
            } else {
                treeCache.addCombo(combo);
                keyCount.put(currentKey, keyCount.getOrDefault(currentKey, 0) + 1);
            }
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
        // NOTE: Goes up to 6+8 for 210 at level 23
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
        // NOTE: Goes up to 6+8 for 210 at level 23, except Hot Sauce
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

        if (BAR_LEVEL >= 21) {
            for (String spirit : List.of("Rum", "Vodka", "Brandy", "Gin", "Tequila", "Whisky")) {
                baseShop.put(spirit, new MaterialShop(125, 25, baseShop.get(spirit).level));
            }
            for (String flavor : List.of("Wine", "Chartreuse", "Aperol", "Campari")) {
                baseShop.put(flavor, new MaterialShop(80, 8, baseShop.get(flavor).level));
            }
            for (String flavor : List.of("Vermouth", "Orange Curacao", "Coffee Liqueur")) {
                baseShop.put(flavor, new MaterialShop(50, 10, baseShop.get(flavor).level));
            }
            for (String flavor : List.of("Baileys", "Bitters")) {
                baseShop.put(flavor, new MaterialShop(100, 10, baseShop.get(flavor).level));
            }
            for (String other : List.of("Cola", "Orange Juice", "Pineapple Juice", "Soda Water", "Cane Syrup", "Lemon Juice", "Mint Leaf", "Honey", "Sugar", "Cream")) {
                baseShop.put(other, new MaterialShop(50, 10, baseShop.get(other).level));
            }
            for (String other : List.of("Fruit Syrup")) {
                baseShop.put(other, new MaterialShop(80, 8, baseShop.get(other).level));
            }
        }

        if (BAR_LEVEL >= 23) {
            for (String other : List.of("Soda", "Tomato Juice", "Fruit Juice", "Benedictine", "Ginger Beer")) {
                baseShop.put(other, new MaterialShop(210, 14, baseShop.get(other).level));
            }
            for (String other : List.of("Fruit Syrup")) {
                baseShop.put(other, new MaterialShop(100, 10, baseShop.get(other).level));
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

    private static Drink createDrink(String name, JSONObject json, int openBarLevel, List<FormulaMaterial> ingredients) {
        return new Drink(asInt(json.get("barPopularity")), asInt(json.get("barPoint")), openBarLevel, name, asInt(json.get("id")), ingredients);
    }

    public static ImmutableMap<String, Drink> loadDrinkData(boolean allowImperfectDrinks) {
        try (BufferedReader formulaReader = new BufferedReader(new FileReader(BASE_PATH + "formula.json.pretty"));
             BufferedReader drinkReader = new BufferedReader(new FileReader(BASE_PATH + "drink.json.pretty"))) {
            ImmutableMap.Builder<String, Drink> builder = ImmutableMap.builder();
            JSONParser parser = new JSONParser();
            JSONObject formulasJson = (JSONObject) parser.parse(formulaReader);
            JSONObject drinksJson = (JSONObject) parser.parse(drinkReader);
            for (Object drinkObj : drinksJson.values()) {
                JSONObject drinkJson = (JSONObject) drinkObj;
                JSONObject formulaJson = (JSONObject) formulasJson.get(String.valueOf(drinkJson.get("formulaId")));
                JSONArray materials = (JSONArray) formulaJson.get("materials");
                JSONArray matching = (JSONArray) formulaJson.get("matching");
                int openBarLevel = asInt(formulaJson.get("openBarLevel"));
                String name = (String) drinkJson.get("name");

                List<FormulaMaterial> ingredients = new ArrayList<>();

                // Always load well made drinks
                if (asInt(drinkJson.get("star")) == 3) {
                    for (int i = 0; i < materials.size(); ++i) {
                        ingredients.add(new FormulaMaterial(asInt(materials.get(i)), asInt(matching.get(i))));
                    }

                    Drink drink = createDrink(name, drinkJson, openBarLevel, ingredients);
                    builder.put(name, drink);
                } else if (allowImperfectDrinks) {
                    if (asInt(drinkJson.get("star")) == 2) {
                        // Can't make 2 star versions of 1 ingredient drinks
                        if (materials.size() != 1) {
                            // 2 star drinks require the same ingredients as 3 star drinks, just mixed in the wrong order
                            for (int i = 0; i < materials.size(); ++i) {
                                ingredients.add(new FormulaMaterial(asInt(materials.get(i)), asInt(matching.get(i))));
                            }
                            name += "-2";
                            Drink drink = createDrink(name, drinkJson, openBarLevel, ingredients);
                            builder.put(name, drink);
                        }
                    } else if (asInt(drinkJson.get("star")) == 1) {
                        // 1 star drinks require the number of total ingredients to be right, and at least one of each ingredient
                        // TODO: nodupes needs to treat all 1 star variants as dupes
//                        generate1StarDrinks(name, drinkJson, materials, openBarLevel, matching, builder);
                    } else if (asInt(drinkJson.get("star")) == 0) {
                        // 0 star drinks just need to use the right ingredients.  1 of each is fine
                        for (Object material : materials) {
                            ingredients.add(new FormulaMaterial(asInt(material), 1));
                        }
                        name += "-0";
                        // TODO: temporarily hack out 0* drinks
//                        builder.put(name, createDrink(name, drinkJson, openBarLevel, ingredients));
                    }
                }
            }
            return builder.build();
        } catch (IOException | ParseException e) {
            e.printStackTrace();
            return null;
        }
    }

    private static List<List<Integer>> generateValidCounts(int totalIngredients, int length) {
        List<List<Integer>> toReturn = new ArrayList<>();

        if (length == 1) {
            toReturn.add(List.of(totalIngredients));
            return toReturn;
        }
        for (int i = 1; totalIngredients - i >= length - 1; ++i) {
            for (List<Integer> completion : generateValidCounts(totalIngredients - i, length - 1)) {
                List<Integer> candidate = new ArrayList<>();
                candidate.add(i);
                candidate.addAll(completion);
                toReturn.add(candidate);
            }
        }

        return toReturn;
    }

    private static boolean isRegularDrink(List<Integer> coeffs, JSONArray matching) {
        for (int i = 0; i < matching.size(); ++i) {
            if (coeffs.get(i) != asInt(matching.get(i))) {
                return false;
            }
        }
        return true;
    }

    private static void generate1StarDrinks(String name, JSONObject drinkJson, JSONArray materials, int openBarLevel, JSONArray matching, ImmutableMap.Builder<String, Drink> builder) {
        int totalIngredients = 0;
        for (Object match : matching) {
            totalIngredients += asInt(match);
        }

        List<List<Integer>> z = generateValidCounts(totalIngredients, materials.size());


        for (List<Integer> coeffs : generateValidCounts(totalIngredients, materials.size())) {
            if (!isRegularDrink(coeffs, matching)) {
                StringBuilder sb = new StringBuilder(name);
                sb.append("-1-");
                List<FormulaMaterial> ingredients = new ArrayList<>();
                for (int i = 0; i < materials.size(); ++i) {
                    sb.append(coeffs.get(i));
                    ingredients.add(new FormulaMaterial(asInt(materials.get(i)), coeffs.get(i)));
                }
                String modifiedDrinkName = sb.toString();
                Drink drink = createDrink(modifiedDrinkName, drinkJson, openBarLevel, ingredients);
                builder.put(modifiedDrinkName, drink);
            }
        }
    }

    @SuppressWarnings("ConstantConditions")
    public static ImmutableMap<Integer, String> loadDrinkIdToName() {
        ImmutableMap.Builder<Integer, String> builder = ImmutableMap.builder();
        for (Drink drink : DRINK_DATA.values()) {
            if (!drink.name.contains("-")) {
                builder.put(drink.id, drink.name);
            }
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

    public static Combo getRequiredDrinks() {
        return REQUIRED_DRINKS;
    }

    public static Set<Integer> getDisallowedDrinks() {
        if (REQUIRED_DRINKS == null) {
            return Collections.emptySet();
        }
        if (ADDITIONAL_DISALLOWED_DRINKS != null) {
            return ImmutableSet.copyOf(REQUIRED_DRINKS.mergeWith(ADDITIONAL_DISALLOWED_DRINKS).toIndices());
        }
        return ImmutableSet.copyOf(REQUIRED_DRINKS.toIndices());
    }

    public static Combo getEmptyCombo() {
        return new IndexListCombo();
    }
}
