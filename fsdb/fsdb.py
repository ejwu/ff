#!/usr/bin/python3

import argparse
from collections import defaultdict
import json
import os
from pathlib import Path
import sqlite3
import sys

# Mostly from BattleConstants.lua

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

#ConfigSkillType - Basic/energy/link?
SKILL_TYPES = {
    "1": "Basic", "2": "Aura", "3": "Energy", "4": "Link"}

#SeekSortRule
SEEK_SORT_RULES = {
    "1": "S_NONE", "2": "S_DISTANCE_MIN", "3": "S_DISTANCE_MAX", "4": "S_HP_PERCENT_MAX", "5": "S_HP_PERCENT_MIN",
    "6": "S_ATTACK_MAX", "7": "S_ATTACK_MIN", "8": "S_DEFENCE_MAX", "9": "S_DEFENCE_MIN"}

#ConfigSeekTargetRule
TARGET_TYPES = {
    "1": "T_OBJ_SELF", "2": "T_OBJ_ENEMY", "3": "T_OBJ_FRIEND", "4": "T_OBJ_ALL"}

# Just by inspection
TOGI_TYPES = {
    1: "Antler", 2: "Striped", 3: "Bushy"}

# Column name for skill types, e.g., Basic/Energy/Link/T1_Antler_L6
TYPE_DESC = "type_desc"

def create_tables():
    c.execute("DROP TABLE IF EXISTS fs")
    c.execute("CREATE TABLE fs (artifactCost text, artifactCostId text, artifactName text, artifactQuestId text, artifactStatus text, attack integer, attackRange integer, attackRate integer, backgroundStory text, breakLevel text, cardCollectionBook text, career text, concertSkill text, contractLevel integer, critDamage integer, critRate integer, cv text, cvCn text, defence integer, descr text, exclusivePet text, favoriteFood text, fragmentId text, growType text, hp integer, id text, maxLevel integer, name text, qualityId text, skill text, skin text, specialCard text, star text, tasteId text, threat integer, vigour integer)")

    c.execute("DROP TABLE IF EXISTS monsters")
    c.execute("CREATE TABLE monsters (agreeDialogue text, attack integer, attackInterval integer, attackRange integer, attackRate integer, career text, critDamage integer, critRate integer, defaultLayer text, defence integer, descr text, drawId text, dropRate integer, feature text, foodsLike text, formType text, hp integer, id text, immunitySkillProperty text, meetDialogue text, name text, petCoin text, refuseDialogue text, scale text, showSkill text, skill text, skinId text, star text, type text, weatherProperty text)")

    c.execute("DROP TABLE IF EXISTS skills")
    c.execute("CREATE TABLE skills(fsid text, battleType text, descr text, id integer, immuneDispel text, infectTarget text, infectTime text, innerPile text, insideCd text, name text, property text, readingTime text, skillGroup text, skillKind text, target text, triggerAction text, triggerActionTarget text, triggerCondition text, triggerConditionTarget text, triggerInsideCd text, triggerType text, type text, type_desc text, weaknessEffect text)")

    # Querying by complicated json objects on skills with multiple effects is a pain.
    # Denormalize skills by splitting each effect and target into a separate row.
    c.execute("DROP TABLE IF EXISTS dn_skills")
    c.execute("CREATE TABLE dn_skills(fs_id text, monster_id text, descr text, id text, type text, type_desc text, effect text, effect_rate numeric, effect_time numeric, target_num integer, target text, target_type text)") 

def transform_fs(fs):
    fs["career"] = FS_TYPE[fs["career"]]
    fs["qualityId"] = FS_RARITY[fs["qualityId"]]
    return fs

def parse_monsters():
    # Return a multimap of skills to every monster that uses it
    skills_to_monsters = defaultdict(list)
    monsters = json.load(open(MONSTER_FILE))
    fill = ("?," * len(monsters["362122"]))[:-1]
    for monster_id, monster in monsters.items():
        c.execute(f"INSERT INTO monsters VALUES({fill})", list([str(monster[key]) for key in sorted(monster)]))
        for skill_id in monster["skill"]:
            skills_to_monsters[skill_id].append(monster["id"])

    return skills_to_monsters

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
            # TODO: what's going on here?
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
        # TODO: what's going on here?
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

    # Replace skill type
    if skill["property"]:
        prop_str = str(skill["property"])
        if prop_str in SKILL_TYPES:
            skill["property"] = SKILL_TYPES[prop_str]
    skill[TYPE_DESC] = skill["property"]

    # Artifact skills have these populated, put something in for normal skills 
    if not "skillKind" in skill:
        skill["skillKind"] = -1
    if not "skillGroup" in skill:
        skill["skillGroup"] = -1
            
    return skill

def insert_skill(c, fill, fsid, skill, skills_to_monsters):
    row = [fsid]
    for k in sorted(skill.keys()):
        row.append(json.dumps(skill[k]))

    c.execute(f"INSERT INTO skills VALUES({fill})", row)

    monster_list = []
    if str(skill["id"]) in skills_to_monsters.keys():
        monster_list = skills_to_monsters[str(skill["id"])]
    insert_denormalized_skill(fsid, skill, monster_list)


def insert_denormalized_skill(fsid, skill, monster_list):
    for target in skill["target"]:
        row = [fsid, "", skill["descr"], skill["id"], skill["property"], skill["type_desc"]]
        row.append(target)
        effect = skill["type"][target]
        row.append(effect["effectSuccessRate"])
        row.append(effect["effectTime"])
        row.append(skill["target"][target]["num"])
        row.append(skill["target"][target]["sequence"])
        row.append(skill["target"][target]["type"])

        c.execute("INSERT INTO dn_skills VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", row)

    for monster in monster_list:
        for target in skill["target"]:
            row = ["", monster, skill["descr"], skill["id"], skill["property"], skill["type_desc"]]
            row.append(target)
            effect = skill["type"][target]
            row.append(effect["effectSuccessRate"])
            row.append(effect["effectTime"])
            row.append(skill["target"][target]["num"])
            row.append(skill["target"][target]["sequence"])
            row.append(skill["target"][target]["type"])

            c.execute("INSERT INTO dn_skills VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", row)
            
def parse_artifacts():
    # Return a multimap of fsid to all their skills
    fs_to_skills = defaultdict(list)
    
    all_artifacts = json.load(open(ARTIFACT_MAPPING_FILE))
    skill_groups = json.load(open(ARTIFACT_SKILL_GROUP_FILE))
    for fsid in all_artifacts.keys():
        artifact_map = all_artifacts[fsid]

        # There seems to be an explicit mapping in cardArtifactGemstoneSkill.json as well.
        # Assuming here that they're not insane and these filenames make sense.
        artifact_file = ARTIFACT_PATH / f"gemstoneSkill{fsid}.json.pretty"

        if not artifact_file.exists():
            # This seems to happen for partially translated newer artifacts.  Presumably all of them
            # have artifactStatus != 1 in the fs table.
            print(f"Artifact file doesn't exist for fs {fsid} despite existing in talentPoint.json")
            continue

        artifact = json.load(open(artifact_file))
        togi_count = 0

        for key in sorted(artifact_map.keys(), key=int):
            node = artifact_map[key]
            # The basic and energy skill buffs are also treated as artifact skills.
            # Identify them by their 3 levels and ignore them (togi nodes are level 1 in this file)
            if node["getSkill"] and node["level"] != "3":
                togi_count += 1

                # Making an assumption here that skills are always in the same order
                skill_count = 0
                for skill in node["getSkill"]:
                    skill_count += 1
                    # Only use the L6 version of a skill to avoid spamming the main skill table
                    skill = transform_skill(artifact[str(skill_groups[skill]["6"])])
                    skill[TYPE_DESC] = f"T{togi_count}_{TOGI_TYPES[skill_count]}_L6"
                    
                    # Make artifact skills look like normal skills
                    del skill["gemstoneGrade"]
                    # Huh?  descr0 and descr show different ranges.  Might want to keep these
                    del skill["descr0"]
                    skill["infectTarget"] = "artifact"
                    skill["infectTime"] = "artifact"
                    skill["weaknessEffect"] = "artifact"
                    fs_to_skills[fsid].append(skill)

    return fs_to_skills

        
def parse_args():
    parser = argparse.ArgumentParser(description="Parse and dump FF files to a database")
    parser.add_argument("dir", help="Base directory for the datafiles (contains com.egg.foodandroid)")
    parser.add_argument("--db", help="File name for the database to be created", default="fs.db")
    return parser.parse_args()

def assert_files_exist():
    if not FS_FILE.exists():
        sys.exit(f"Can't find card.json.pretty at {FS_FILE}")

    if not SKILLS_FILE.exists():
        sys.exit(f"Can't find skill.json.pretty at {SKILLS_FILE}")

    if not MONSTER_FILE.exists():
        sys.exit(f"Can't find monster.json.pretty at {MONSTER_FILE}")
        
    if not ARTIFACT_MAPPING_FILE.exists():
        sys.exit(f"Can't find talentPoint.json.pretty at {ARTIFACT_MAPPING_FILE}")

    if not ARTIFACT_SKILL_GROUP_FILE.exists():
        sys.exit(f"Can't find gemstoneSkillGroup.json.pretty at {ARTIFACT_SKILL_GROUP_FILE}")
    
args = parse_args()
path = Path(args.dir) / "com.egg.foodandroid" / "files" / "publish" / "conf" / "en-us"
FS_FILE = path / "card" / "card.json.pretty"
SKILLS_FILE = path / "card" / "skill.json.pretty"
MONSTER_FILE = path / "monster" / "monster.json.pretty"

ARTIFACT_PATH = path / "artifact"
# This appears to be the togi map for every FS
ARTIFACT_MAPPING_FILE = ARTIFACT_PATH / "talentPoint.json.pretty"
# Togi map refers to a skill group, which maps to individual skills for all 10 togi levels
ARTIFACT_SKILL_GROUP_FILE = ARTIFACT_PATH / "gemstoneSkillGroup.json.pretty"

assert_files_exist()

conn = sqlite3.connect(args.db)
c = conn.cursor()

create_tables()

fs_data = json.load(open(FS_FILE))

columns = list(fs_data["200001"].keys())
fs_fill = ("?," * len(columns))[:-1]

fs_to_skills = {}
skills_to_fs = {}
for id, fs in fs_data.items():
    fs = transform_fs(fs)
    
    c.execute(f"INSERT INTO fs VALUES({fs_fill})", list((str(value) for value in fs.values())))
    if not fs["skill"]:
        print("No skills: ", fs)
        raise
    for skill_id in fs["skill"]:
        if skill_id in skills_to_fs:
            print("Skill already exists:", skill_id)
        skills_to_fs[skill_id] = id


skills_to_monsters = parse_monsters()
  
skill_data = json.load(open(SKILLS_FILE))
skill_columns = list(skill_data["10001"].keys())
skill_fill = ("?," * (len(skill_columns) + 4))[:-1]

# Normal skills for FS and monsters
for skill_id, skill in skill_data.items():
    fsid = None
    if skill_id not in skills_to_fs:
        pass
    # This includes skills for enemies as well, not just FS
    #   print("missing skill", skill_id, skill["descr"])
    else:
        fsid = skills_to_fs[skill_id]

    skill = transform_skill(skill)
    insert_skill(c, skill_fill, fsid, skill, skills_to_monsters)

# Artifact skills
f2s = parse_artifacts()
for fsid in f2s.keys():
    for arti_skill in f2s[fsid]:
        insert_skill(c, skill_fill, fsid, arti_skill, {})

conn.commit()
conn.close()

