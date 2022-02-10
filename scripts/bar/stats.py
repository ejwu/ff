# 3.25 is close to the ratio of max_tickets to max_fame at bar level 9
OVERALL_COEFF = 3.25

class BestDrinkSet:
    def __init__(self, comp, drinks_data, drink_id_to_name, material_costs):
        # Comparator for drink sets
        self.comp = comp
        # Best drink set so far
        self.best = []

        # Data that's annoyingly duplicated to be able to put this in a separate file
        self.drinks_data = drinks_data
        self.drink_id_to_name = drink_id_to_name
        self.material_costs = material_costs
        
    def offer(self, drinks):
        """
        Compare the given set of drinks to the currently known best one according to the comparator and replace it if afppropriate.
        """
        if self.comp(self.get_drink_set_info(drinks), self.get_drink_set_info(self.best)) > 0:
            self.best = drinks

    def get_drink_set_info(self, drinks):
        cost = 0
        fame = 0
        tickets = 0
        materials_used = set()
        for drink in drinks:
            drink_data = self.drinks_data[self.drink_id_to_name[drink]]
            fame += drink_data["barFame"]
            tickets += drink_data["tickets"]
            for material in drink_data["materials"]:
                materials_used.add(material[0])

        for material in materials_used:
            cost += self.material_costs[material]["cost"]
        return [cost, fame, tickets]


class Stats:
    def __init__(self, drinks_data, drink_id_to_name, material_costs):
        self.bdc_cost = BestDrinkSet(sort_by_cost, drinks_data, drink_id_to_name, material_costs)
        self.bdc_fame = BestDrinkSet(sort_by_fame, drinks_data, drink_id_to_name, material_costs)
        self.bdc_fame_effic = BestDrinkSet(sort_by_fame_effic, drinks_data, drink_id_to_name, material_costs)
        self.bdc_tickets = BestDrinkSet(sort_by_tickets, drinks_data, drink_id_to_name, material_costs)
        self.bdc_tickets_effic = BestDrinkSet(sort_by_tickets_effic, drinks_data, drink_id_to_name, material_costs)
        self.bdc_overall = BestDrinkSet(sort_by_overall, drinks_data, drink_id_to_name, material_costs)
        self.bdc_overall_effic = BestDrinkSet(sort_by_overall_effic, drinks_data, drink_id_to_name, material_costs)
        self.num_processed = 0

    def offer_all(self, drinks):
        self.bdc_cost.offer(drinks)
        self.bdc_fame.offer(drinks)
        self.bdc_fame_effic.offer(drinks)
        self.bdc_tickets.offer(drinks)
        self.bdc_tickets_effic.offer(drinks)
        self.bdc_overall.offer(drinks)
        self.bdc_overall_effic.offer(drinks)
        self.num_processed += len(drinks)

    def add(self, stats):
        self.bdc_cost.offer(stats.bdc_cost.best)
        self.bdc_fame.offer(stats.bdc_fame.best)
        self.bdc_fame_effic.offer(stats.bdc_fame_effic.best)
        self.bdc_tickets.offer(stats.bdc_tickets.best)
        self.bdc_tickets_effic.offer(stats.bdc_tickets_effic.best)
        self.bdc_overall.offer(stats.bdc_overall.best)
        self.bdc_overall_effic.offer(stats.bdc_overall_effic.best)
        self.num_processed += stats.num_processed

# Drink info is [cost, fame, tickets]
def get_cost_diff_desc(l_info, r_info):
    return l_info[0] - r_info[0]

# In the usual case we want lowest cost
def get_cost_diff(l_info, r_info):
    return get_cost_diff_desc(l_info, r_info) * -1

def get_fame_diff(l_info, r_info):
    return l_info[1] - r_info[1]

def get_fame_effic_diff(l_info, r_info):
    # The starting empty drink set has no cost
    if r_info[0] == 0:
        return 1
    if l_info[0] == 0:
        return -1
    return (l_info[1] / l_info[0]) - (r_info[1] / r_info[0])

def get_overall_diff(l_info, r_info):
    return (l_info[1] * OVERALL_COEFF + l_info[2]) - (r_info[1] * OVERALL_COEFF + r_info[2])

def get_overall_effic_diff(l_info, r_info):
    # The starting empty drink set has no cost
    if r_info[0] == 0:
        return 1
    if l_info[0] == 0:
        return -1
    return ((l_info[1] * OVERALL_COEFF + l_info[2]) / l_info[0]) - ((r_info[1] * OVERALL_COEFF + r_info[2]) / r_info[0])
    
def get_tickets_diff(l_info, r_info):
    return l_info[2] - r_info[2]

def get_tickets_effic_diff(l_info, r_info):
    # The starting empty drink set has no cost
    if r_info[0] == 0:
        return 1
    if l_info[0] == 0:
        return -1
    return (l_info[2] / l_info[0]) - (r_info[2] / r_info[0])

def sort_by_cost(l_info, r_info):
    if get_cost_diff_desc(l_info, r_info) != 0:
        return get_cost_diff_desc(l_info, r_info)
    if get_fame_diff(l_info, r_info) != 0:
        return get_fame_diff(l_info, r_info)
    if get_tickets_diff(l_info, r_info) != 0:
        return get_tickets_diff(l_info, r_info)
    return 0

def sort_by_fame(l_info, r_info):
    if get_fame_diff(l_info, r_info) != 0:
        return get_fame_diff(l_info, r_info)
    if get_tickets_diff(l_info, r_info) != 0:
        return get_tickets_diff(l_info, r_info)
    if get_cost_diff(l_info, r_info) != 0:
        return get_cost_diff(l_info, r_info)
    return 0

def sort_by_fame_effic(l_info, r_info):
    if get_fame_effic_diff(l_info, r_info) != 0:
        return get_fame_effic_diff(l_info, r_info)
    if get_fame_diff(l_info, r_info) != 0:
        return get_fame_diff(l_info, r_info)
    if get_tickets_diff(l_info, r_info) != 0:
        return get_tickets_diff(l_info, r_info)
    # Fairly sure ticket_effic and cost don't matter here
    if get_cost_diff(l_info, r_info) != 0:
        return get_cost_diff(l_info, r_info)
    return 0

def sort_by_tickets(l_info, r_info):
    if get_tickets_diff(l_info, r_info) != 0:
        return get_tickets_diff(l_info, r_info)
    if get_fame_diff(l_info, r_info) != 0:
        return get_fame_diff(l_info, r_info)
    if get_cost_diff(l_info, r_info) != 0:
        return get_cost_diff(l_info, r_info)
    return 0

def sort_by_tickets_effic(l_info, r_info):
    if get_tickets_effic_diff(l_info, r_info) != 0:
        return get_tickets_effic_diff(l_info, r_info)
    if get_tickets_diff(l_info, r_info) != 0:
        return get_tickets_diff(l_info, r_info)
    if get_fame_diff(l_info, r_info) != 0:
        return get_fame_diff(l_info, r_info)
    # Fairly sure ticket_effic and cost don't matter here
    if get_cost_diff(l_info, r_info) != 0:
        return get_cost_diff(l_info, r_info)
    return 0

def sort_by_overall(l_info, r_info):
    if get_overall_diff(l_info, r_info) != 0:
        return get_overall_diff(l_info, r_info)
    if get_overall_effic_diff(l_info, r_info) != 0:
        return get_overall_effic_diff(l_info, r_info)
    if get_fame_diff(l_info, r_info) != 0:
        return get_fame_diff(l_info, r_info)
    return 0

def sort_by_overall_effic(l_info, r_info):
    if get_overall_effic_diff(l_info, r_info) != 0:
        return get_overall_effic_diff(l_info, r_info)
    if get_overall_diff(l_info, r_info) != 0:
        return get_overall_diff(l_info, r_info)
    return 0
