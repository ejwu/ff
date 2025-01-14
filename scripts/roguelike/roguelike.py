#!/usr/bin/python

import csv
import json

RARITY_MAP = {"1": "M", "2": "R", "3": "SR", "4": "UR"}
MAIN_ATTR_MAP = {"1": "Power", "2": "Agility", "3": "Intellect", "4": "Stamina"}
POSITION_MAP = {"1": "Captain", "2": "Scout", "3": "Vanguard", "4": "Middle", "5": "Rear"}
DAMAGE_TYPE = {"1": "Melee Physical", "2": "Ranged Physical", "4": "Ranged Magic", "5": ""}
ATTR_MAP = {"11": "Max HP", "13": "Max Soul Pts", "14": "Max Armor", "20": "Melee Phys", "21": "Ranged Phys", "23": "Ranged Magic", "24": "HP Recovery", "25": "Phys Resist", "26": "Magic Resist", "27": "Hit Rate", "28": "Dodge", "29": "Crit Rate", "30": "Crit Dmg", "19": "Seeking Range?!?", "22": "Melee Magic?!?"}

BASE_PATH = "/home/ejwu/ff/ff20240322/com.egg.foodandroid/files/publish/conf/en-us/minesweeper/"
RES_PATH = "/home/ejwu/ff/ff20240322/com.egg.foodandroid/files/res_sub/conf/en-us/minesweeper/"

fs_data = json.load(open(BASE_PATH + "card.json"))
skill_data = json.load(open(BASE_PATH + "passiveSkill.json"))

def generate_god_skills():
    with open("roguelike_heroes.csv", 'w') as csvfile:
        hero_data = json.load(open(BASE_PATH + "god.json"))
        writer = csv.writer(csvfile)
        writer.writerow(["hero", "blessing", "curse", "betray", "taco"])
        for _, hero in hero_data.items():
            row = []
            row.append(hero["name"])
            row.append(skill_data[str(hero["buffSkillId"])]["descr"])
            row.append(skill_data[str(hero["debuffSkillId"])]["descr"])
            row.append(skill_data[str(hero["betrayDebuffSkillId"])]["descr"])
            for i, taco in hero["tacoSkill"].items():
                if i != "1":
                    row = ["", "", "", ""]
                row.append(skill_data[str(taco["skillId"])]["descr"])
                writer.writerow(row)
            writer.writerow([])

def generate_events():
    with open("roguelike_events.csv", 'w') as csvfile:
        event_data = json.load(open(BASE_PATH + "mapEventCell.json"))
        writer = csv.writer(csvfile)
        for _, event in event_data.items():
            writer.writerow([event["descr"]])
            for i, choice in event["choice"].items():
                writer.writerow([choice["text"], choice["descr"]])
            writer.writerow([])

def generate_chests():
    with open("roguelike_chests.csv", 'w') as csvfile:
        writer = csv.writer(csvfile)
        chest_data = json.load(open(BASE_PATH + "chest.json"))
        for chest in chest_data.values():
            writer.writerow([chest["name"]])
            for card in chest["dropCards"]:
                writer.writerow([fs_data[card]["name"], RARITY_MAP[fs_data[card]["rare"]]])
            writer.writerow([])

def generate_skills():
    with open("roguelike_skills.csv", 'w') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["name", "requirements"])
        skill_req_data = json.load(open(RES_PATH + "mapMall.json"))
        skill_data = json.load(open(BASE_PATH + "skill.json"))
        for skill_req in skill_req_data.values():
            if skill_req["requireAttr"]:
                skill = skill_data[str(skill_req["goodsId"])]
                attrs = []
                for attr, req in skill_req["requireAttr"].items():
                    attrs.append(f"{MAIN_ATTR_MAP[attr]}: {req}")
                writer.writerow([skill["name"], " / ".join(attrs)])
                writer.writerow([skill["descr"]])
                writer.writerow([])

def generate_bosses():
    with open("roguelike_bosses.csv", 'w') as csvfile:
        writer = csv.writer(csvfile)
        monster_data = json.load(open(BASE_PATH + "monster.json"))
        for i in ["200401", "200402"]:
            monster = monster_data[i]
            writer.writerow([monster["name"]])
            writer.writerow([])
            attrs = []
            for attr_id, v in monster["attr"].items():
                if str(v) != "0":
                    attrs.append(f"{ATTR_MAP[attr_id]}: {v}")
            writer.writerow([" / ".join(attrs)])
            writer.writerow([])
            for skill in monster["skills"]:
                writer.writerow([skill_data[skill]["descr"]])
            writer.writerow([])
                
with open("roguelike_fs.csv", 'w') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["name", "position", "rarity", "damage type", "requirements", "fixed attributes", "# random attributes", "fixed skills", "# random skills"])
    current_pos = "1"
    for i, fs in fs_data.items():
        if current_pos != fs["locationId"]:
            writer.writerow([])
            current_pos = fs["locationId"]
            
        row = []
#        print()
#        print(fs["name"])
#        for random_skill in fs["randomSkillPool"]:
#            print(skill_data[random_skill]["descr"])
        row.append(fs["name"])
        row.append(POSITION_MAP[fs["locationId"]])
        row.append(RARITY_MAP[fs["rare"]])
        row.append(DAMAGE_TYPE[fs["attackType"]])

        reqs = []
        for stat, req in fs["requireMainAttr"].items():
            if req != "0":
                reqs.append(MAIN_ATTR_MAP[stat] + ": " + req)
        row.append(" / ".join(reqs))

        fixed_attrs = []
        for i, location_attr in fs["locationAttr"].items():
            fixed_attrs.append(ATTR_MAP[i] + ": " + location_attr)
        if fs["attr"]:
            for i, fixed_attr in fs["attr"].items():
                fixed_attrs.append(ATTR_MAP[i] + ": " + fixed_attr)
        row.append(" / ".join(fixed_attrs))

        if fs["randomAttrNum"][0] == fs["randomAttrNum"][1]:
            row.append(fs["randomAttrNum"][0])
        else:
            row.append(fs["randomAttrNum"][0] + "-" + fs["randomAttrNum"][1])

        random_attrs = []
#        print(fs["randomAttrPool"])
        if fs["randomAttrPool"]:
            for random_attr_id in fs["randomAttrPool"]:
                if random_attr_id in ATTR_MAP:
                    random_attrs.append(ATTR_MAP[random_attr_id])
                else:
                    random_attrs.append(random_attr_id)
#        row.append(" / ".join(random_attrs))

        fixed_skills = []
        if fs["skills"]:
            for skill in fs["skills"]:
                fixed_skills.append(skill_data[skill]["descr"])
        row.append(" / ".join(fixed_skills))
                       
        if fs["randomSkillNum"][0] == fs["randomSkillNum"][1]:
            row.append(fs["randomSkillNum"][0])
        else:
            row.append(fs["randomSkillNum"][0] + "-" + fs["randomSkillNum"][1])

        writer.writerow(row)

generate_god_skills()
generate_events()
generate_chests()
generate_skills()
generate_bosses()
