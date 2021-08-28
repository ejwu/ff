#!/usr/bin/python3

from collections import defaultdict
import json
import sqlite3

# FS rarity
FS_RARITY = {"5": "SP", "4": "UR", "3": "SR", "2": "R", "1": "M"}

# FS type
FS_TYPE = {"1": "Defense", "2": "Strength", "3": "Magic", "4": "Healer"}

# ConfigBuffType
BUFF_TYPES = {
    "0": "BASE", "1": "ATTACK_B", "2": "ATTACK_A", "3": "DEFENCE_B", "4": "DEFENCE_A", "5": "OHP_B",
    "6": "OHP_A", "7": "CR_RATE_B", "8": "CR_RATE_A", "9": "ATK_RATE_B", "10": "ATK_RATE_A",
    "11": "CR_DAMAGE_B", "12": "CR_DAMAGE_A", "13": "CDAMAGE_A", "14": "GDAMAGE_A", "15": "ISD",
    "16": "ISD_LHP", "17": "ISD_CHP", "18": "ISD_OHP", "19": "DOT", "20": "DOT_CHP",
    "21": "DOT_OHP", "22": "HEAL", "23": "HEAL_LHP", "24": "HEAL_OHP", "25": "HOT",
    "26": "HOT_LHP", "27": "HOT_OHP", "28": "DISPEL_DEBUFF", "29": "DISPEL_BUFF", "30": "IMMUNE",
    "31": "STUN", "32": "SILENT", "33": "SHIELD", "34": "HEAL_BY_ATK", "35": "HEAL_BY_DFN",
    "36": "HEAL_BY_CHP", "37": "FREEZE", "38": "DISPEL_QTE", "39": "BECKON", "40": "DISPEL_BECKON",
    "41": "REVIVE", "42": "ENCHANTING", "43": "EXECUTE", "45": "ENERGY_ISTANT",
    "46": "ENERGY_CHARGE_RATE", "47": "ATK_CR_RATE_CHARGE", "48": "ATK_ATTACK_B_CHARGE",
    "49": "ATK_ISD_CHARGE", "50": "ATK_HEAL_CHARGE",
    "51": "ATK_ENERGY_CHARGE", "52": "IMMUNE_ATTACK_PHYSICAL", "53": "IMMUNE_SKILL_PHYSICAL",
    "54": "IMMUNE_ATTACK_HEAL", "55": "IMMUNE_SKILL_HEAL",
    "56": " IMMUNE_HEAL", "57": "GET_DAMAGE_ATTACK", "58": "GET_DAMAGE_SKILL", "59": "GET_DAMAGE_PHYSICAL",
    "60": "CAUSE_DAMAGE_ATTACK",
    "61": "CAUSE_DAMAGE_SKILL", "62": "CAUSE_DAMAGE_PHYSICAL",
    "111": "CHANGE_SKILL_TRIGGER", "112": "CHANGE_PP",
    "130": "IMMUNE_BUFF_TYPE", "131": "VIEW_TRANSFORM"}

#ConfigSkillTriggerType
TRIGGER_TYPES = {
    "1": "RESIDENT", "2": "RANDOM", "3": "ENERGY", "4": "CD", "5": "LOST_HP", "6": "COST_HP", "7": "COST_CHP", "8": "COST_OHP"}

#SeekSortRule
SEEK_SORT_RULES = {
    "1": "S_NONE", "2": "S_DISTANCE_MIN", "3": "S_DISTANCE_MAX", "4": "S_HP_PERCENT_MAX", "5": "S_HP_PERCENT_MIN",
    "6": "S_ATTACK_MAX", "7": "S_ATTACK_MIN", "8": "S_DEFENCE_MAX", "9": "S_DEFENCE_MIN"}

#ConfigSeekTargetRule
TARGET_TYPES = {
    "1": "T_OBJ_SELF", "2": "T_OBJ_ENEMY", "3": "T_OBJ_FRIEND", "4": "T_OBJ_ALL"}

def transform_fs(fs):
    fs["career"] = FS_TYPE[fs["career"]]
    fs["qualityId"] = FS_RARITY[fs["qualityId"]]
    return fs

def transform_skill(skill):
    # Replace buff types
    for field in ["innerPile", "target", "triggerActionTarget", "triggerCondition", "triggerConditionTarget", "triggerInsideCd", "type"]:
        if skill[field]:
            new_field = {}
            for key in skill[field].keys():
                if key in BUFF_TYPES.keys():
                    new_field[BUFF_TYPES[key]] = skill[field][key]
                elif key not in BUFF_TYPES.values():
                    print("haven't mapped target type", key)
            skill[field] = new_field
        else:
            print("no target for", field, skill["id"])

    # the type.effect field also uses buff type as a value, replace it as well
    if skill["type"]:
        for effect in skill["type"].values():
            effect["type"] = BUFF_TYPES[effect["type"]]

    # Replace trigger types
    if skill["triggerType"]:
        new_trigger_type = {}
        for key in skill["triggerType"]:
            if key in TRIGGER_TYPES.keys():
#                skill["triggerType"][TRIGGER_TYPES[key]] = skill["triggerType"].pop(key)
                new_trigger_type[TRIGGER_TYPES[key]] = skill["triggerType"][key]
        skill["triggerType"] = new_trigger_type
    else:
        print("no triggerType for", skill["id"])        

    # Replace target types
    if skill["target"]:
        for value in skill["target"].values():
            # General target types
            if value["type"] in TARGET_TYPES:
                     value["type"] = TARGET_TYPES[value["type"]]
            # Specific target types
            if value["sequence"] in SEEK_SORT_RULES:
                value["sequence"] = SEEK_SORT_RULES[value["sequence"]]

        
    return skill

def insert_denormalized_skill(fsid, skill):
#c.execute("CREATE TABLE dn_skills(fsid text, descr text, id text, effect text, target_num text, target text, target_type text)")
#    print(skill)
    for target in skill["target"]:
        row = [fsid, skill["descr"], skill["id"]]
#        print(target)
#        print(skill["target"][target])
#        print(skill["target"][target]["num"])
        row.append(target)
        row.append(skill["target"][target]["num"])
        row.append(skill["target"][target]["sequence"])
        row.append(skill["target"][target]["type"])
#        print(row)
#        print(str(row))
        c.execute("INSERT INTO dn_skills VALUES(?, ?, ?, ?, ?, ?, ?)", row)

conn = sqlite3.connect("fs.db")
c = conn.cursor()

c.execute("DROP TABLE IF EXISTS fs")
c.execute("CREATE TABLE fs (artifactCost text, artifactCostId text, artifactName text, artifactQuestId text, artifactStatus text, attack text, attackRange text, attackRate text, backgroundStory text, breakLevel text, cardCollectionBook text, career text, concertSkill text, contractLevel text, critDamage text, critRate text, cv text, cvCn text, defence text, descr text, exclusivePet text, favoriteFood text, fragmentId text, growType text, hp text, id text, maxLevel text, name text, qualityId text, skill text, skin text, specialCard text, star text, tasteId text, threat text, vigour)")

fs_data = json.load(open("card.json.pretty"))

columns = list(fs_data["200001"].keys())
fill = ("?," * len(columns))[:-1]

fs_to_skills = {}
skills_to_fs = {}
for id, fs in fs_data.items():
    fs = transform_fs(fs)
#    if id == "200001":
#        print(list((str(value) for value in fs.values())))
#        print(list((str(value) for value in transform_fs(fs).values())))

#    print(fill)
#    print(list(str(value) for value in fs.values()))
        
    c.execute(f"INSERT INTO fs VALUES({fill})", list((str(value) for value in fs.values())))
    if not fs["skill"]:
        print("No skills: ", fs)
        raise
    for skill_id in fs["skill"]:
        if skill_id in skills_to_fs:
            print("Skill already exists:", skill_id)
        skills_to_fs[skill_id] = id


    
c.execute("DROP TABLE IF EXISTS skills")
c.execute("CREATE TABLE skills(fsid text, battleType text, descr text, id text, immuneDispel text, infectTarget text, infectTime text, innerPile text, insideCd text, name text, property text, readingTime text, target text, triggerAction text, triggerActionTarget text, triggerCondition text, triggerConditionTarget text, triggerInsideCd text, triggerType text, type text, weaknessEffect text)")

c.execute("DROP TABLE IF EXISTS dn_skills")
c.execute("CREATE TABLE dn_skills(fsid text, descr text, id text, effect text, target_num text, target text, target_type text)") 
    
skill_data = json.load(open("skill.json.pretty"))
skill_columns = list(skill_data["10001"].keys())
fill = ("?," * (len(skill_columns) + 1))[:-1]
for skill_id, skill in skill_data.items():
    fsid = None
    if skill_id not in skills_to_fs:
        print("missing skill", skill_id, skill["descr"])
    else:
        fsid = skills_to_fs[skill_id]

    skill = transform_skill(skill)
    c.execute(f"INSERT INTO skills VALUES({fill})", [fsid] + list((json.dumps(value) for value in skill.values())))
    insert_denormalized_skill(fsid, skill)
    
    
conn.commit()
conn.close()
