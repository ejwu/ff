package bar;

import com.google.common.base.Joiner;
import com.google.common.collect.ImmutableBiMap;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.MapMaker;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.*;
import java.util.function.Predicate;

public class DataLoader {

    // All sorts of things will go wrong if this isn't initialized first
    private static int BAR_LEVEL = BarOptimizer.BAR_LEVEL;
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

    public record MaterialShop(int cost, int num, int level) {}
    public record Material(String name, int cost, int num, int type, int level) {}
    public record FormulaMaterial(int id, int num) {}
    public record Drink(int fame, int tickets, int level, String name, int id, List<FormulaMaterial> materials) {
        double getOverall() {
            return OVERALL_COEFF * fame + tickets;
        }

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
        Map<String, MaterialShop> baseShop = new HashMap<>();
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
        baseShop.put("Fruit Syrup", new MaterialShop(20, 4, 11));

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

        // TODO: Add level 11 changes
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

    public static ImmutableMap<Integer, String> loadDrinkIdToName() {
        ImmutableMap.Builder<Integer, String> builder = ImmutableMap.builder();
        for (Drink drink : DRINK_DATA.values()) {
            builder.put(drink.id, drink.name);
        }
        return builder.build();
    }

    // Highest overall return first
    private static Comparator<Drink> sortByOverall = new Comparator<Drink>() {
        @Override
        public int compare(Drink l, Drink r) {
            if (l.getOverall() > r.getOverall()) {
                return -1;
            } else if (l.getOverall() < r.getOverall()) {
                return 1;
            }
            return 0;
        }
    };

    public static List<Drink> getDrinksByLevel(int barLevel) {
        List<Drink> sorted = DRINK_DATA.values().stream()
                .sorted(new Comparator<Drink>() {
                    @Override
                    public int compare(Drink o1, Drink o2) {
                        return o1.level - o2.level;
                    }
                })
                .filter(new Predicate<Drink>() {
                    @Override
                    public boolean test(Drink drink) {
                        return drink.level <= barLevel;
                    }
                })
                .sorted(sortByOverall)
                .toList();
        if (barLevel == 3) {
            Map<String, Drink> map = new HashMap<>();
            for (Drink drink : sorted) {
                map.put(drink.name, drink);
            }
            List<Drink> toReturn = new ArrayList<>();
            for (String name : List.of("Vodka Sour", "Tequila Sour", "Mojito", "Black Russian", "Screwdriver", "Sour Pineapple Juice", "Coffee Martini", "Rattlesnake", "Rum", "Tequila", "Gin", "Vodka", "Whisky", "Brandy", "Cola", "Pineapple Juice", "Soda Water", "Orange Juice")) {
                toReturn.add(map.get(name));
            }
            return toReturn;
        }
        return sorted;
    }

    public static Drink getDrinkByIndex(int i) {
        return INDEX_DRINK.get(i);
    }

    public static Material getMaterialById(int id) {
        return MATERIAL_COSTS.get(id);
    }
}