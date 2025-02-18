#!/usr/bin/python3

import argparse
from bidict import bidict
from collections import defaultdict
import csv
import json
import os
from pathlib import Path
import sqlite3
import sys
import unicodedata

# Mostly from BattleConstants.lua

# FS rarity
FS_RARITY = {"5": "SP", "4": "UR", "3": "SR", "2": "R", "1": "M"}

# FS type
FS_TYPE = {"1": "Defense", "2": "Strength", "3": "Magic", "4": "Healer"}

# Monster type (ConfigCardCareer)
MONSTER_TYPE = {"1": "Tank", "2": "Melee", "3": "Range", "4": "Healer"}

# ConfigMonsterFormType
MONSTER_FORM_TYPE = {"1": "Normal", "2": "Commode"}

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
    "56": "IMMUNE_HEAL", "57": "GET_DAMAGE_ATTACK", "58": "GET_DAMAGE_SKILL", "59": "GET_DAMAGE_PHYSICAL",
    "60": "CAUSE_DAMAGE_ATTACK",
    "61": "CAUSE_DAMAGE_SKILL", "62": "CAUSE_DAMAGE_PHYSICAL",
    "111": "CHANGE_SKILL_TRIGGER", "112": "CHANGE_PP",
    "130": "IMMUNE_BUFF_TYPE", "131": "VIEW_TRANSFORM"}

BUFF_TYPES_BIMAP = bidict(BUFF_TYPES)

#ConfigSkillTriggerType
TRIGGER_TYPES = {
    "1": "RESIDENT", "2": "RANDOM", "3": "ENERGY", "4": "CD", "5": "LOST_HP", "6": "COST_HP", "7": "COST_CHP", "8": "COST_OHP"}

#ObjPP - what gets affected by CHANGE_PP skills
OBJ_PP = {
    "1": "ATTACK_A", "2": "ATTACK_B", "3": "DEFENCE_A", "4": "DEFENCE_B", "5": "CDAMAGE_UP", "6": "CDAMAGE_DOWN", "7": "GDAMAGE_UP", "8": "GDAMAGE_DOWN", "9": "SKILL_UP", "10": "SKILL_DOWN", "11": "OHP_A", "12": "OHP_B", "13": "CR_RATE_A", "14": "CR_RATE_B", "15": "CR_DAMAGE_A", "16": "CR_DAMAGE_B", "17": "ATK_RATE_A", "18": "ATK_RATE_B", "19": "GET_DAMAGE_ATTACK", "20": "GET_DAMAGE_SKILL", "21": "GET_DAMAGE_PHYSICAL", "22": "CAUSE_DAMAGE_ATTACK", "23": "CAUSE_DAMAGE_SKILL", "24": "CAUSE_DAMAGE_PHYSICAL", "25": "GET_HEAL_ATTACK", "26": "GET_HEAL_SKILL", "27": "GET_HEAL_ALL", "28": "CAUSE_HEAL_ATTACK", "29": "CAUSE_HEAL_SKILL", "30": "CAUSE_HEAL_ALL"
}

#ConfigSkillType - Basic/energy/link?
SKILL_TYPES = {
    "1": "Basic", "2": "Aura", "3": "Energy", "4": "Link"}

#SeekSortRule
SEEK_SORT_RULES = {
    "1": "S_NONE", "2": "S_DISTANCE_MIN", "3": "S_DISTANCE_MAX", "4": "S_HP_PERCENT_MAX", "5": "S_HP_PERCENT_MIN",
    "6": "S_ATTACK_MAX", "7": "S_ATTACK_MIN", "8": "S_DEFENCE_MAX", "9": "S_DEFENCE_MIN", "10": "S_CHP_MAX",
    "11": "S_CHP_MIN", "12": "S_OHP_MAX", "13": "S_OHP_MIN", "14": "S_BATTLE_POINT_MAX"}

#ConfigSeekTargetRule
TARGET_TYPES = {
    "1": "T_OBJ_SELF", "2": "T_OBJ_ENEMY", "3": "T_OBJ_FRIEND", "4": "T_OBJ_ALL", "5": "T_OBJ_FRIEND_TANK", "6": "T_OBJ_FRIEND_MELEE", "7": "T_OBJ_FRIEND_REMOTE", "8": "T_OBJ_FRIEND_HEALER", "9": "T_OBJ_ENEMY_TANK", "10": "T_OBJ_ENEMY_MELEE", "11": "T_OBJ_ENEMY_REMOTE", "12": "T_OBJ_ENEMY_HEALER", "13": "T_OBJ_FRIEND_PLAYER", "14": "T_OBJ_ENEMY_PLAYER", "15": "T_OBJ_ATTACKER", "16": "T_OBJ_ATTACK_TARGET", "17": "T_OBJ_TRIGGER_ATTACKER"}

#ConfigObjectTriggerActionType
TRIGGER_ACTION_TYPE = {
    "1": "ATTACK", "3": "ATTACK_CRITICAL", "4": "GOT_DAMAGE", "5": "GOT_DAMAGE_CRITICAL", "6": "GOT_HEAL", "8": "CAST", "10": "DEAD", "14": "CAST_SKILL_NORMAL", "15": "CAST_SKILL_CUTIN", "16": "CAST_SKILL_CONNECT", "20": "OBJECT_AWAKE"
}

#ConfigObjectTriggerConditionType
TRIGGER_CONDITION_TYPE = {
    "0": "BASE", "1": "HP_MORE_THAN", "2": "HP_LESS_THAN", "3": "HAS_BUFF"}

#ConfigMeetConditionType
MEET_CONDITION_TYPE = {
    "0": "BASE", "1": "ONE", "2": "ALL"}

# Just by inspection
TOGI_TYPES = {
    1: "Antler", 2: "Striped", 3: "Bushy"}

# Column name for skill types, e.g., Basic/Energy/Link/T1_Antler_L6
TYPE_DESC = "type_desc"

def create_tables():
    c.execute("DROP TABLE IF EXISTS fs")
    c.execute("CREATE TABLE fs (id text, name text, artifactCost text, artifactCostId text, artifactName text, artifactQuestId text, artifactStatus text, attack integer, attackRange integer, attackRate integer, backgroundStory text, breakLevel text, cardCollectionBook text, career text, concertSkill text, contractLevel integer, critDamage integer, critRate integer, cv text, cvCn text, defence integer, descr text, exclusivePet text, favoriteFood text, fragmentId text, growType text, hp integer, maxLevel integer, qualityId text, skill text, skin text, specialCard text, star text, tasteId text, threat integer, vigour integer)")

    c.execute("DROP TABLE IF EXISTS monsters")
    c.execute("CREATE TABLE monsters (agreeDialogue text, attack integer, attackInterval integer, attackRange integer, attackRate integer, career text, critDamage integer, critRate integer, defaultLayer text, defence integer, descr text, drawId text, dropRate integer, feature text, foodsLike text, formType text, hp integer, id text, immunitySkillProperty text, meetDialogue text, name text, petCoin text, refuseDialogue text, scale text, showSkill text, skill text, skinId text, star text, type text, weatherProperty text)")

    c.execute("DROP TABLE IF EXISTS skills")
    c.execute("CREATE TABLE skills(fsid text, battleType text, descr text, id integer, immuneDispel text, infectTarget text, infectTime text, innerPile text, insideCd text, name text, property text, readingTime text, skillGroup text, skillKind text, target text, triggerAction text, triggerActionTarget text, triggerCondition text, triggerConditionTarget text, triggerInsideCd text, triggerType text, type text, type_desc text, weaknessEffect text)")

    # Querying by complicated json objects on skills with multiple effects is a pain.
    # Denormalize skills by splitting each effect and target into a separate row.

    # TODO: triggerThreshold and triggerConditionTargetNum being text is a hack to make sqlite-web work
    c.execute("DROP TABLE IF EXISTS dn_skills")
    c.execute("CREATE TABLE dn_skills(fs_id text, monster_id text, name text, descr text, id text, type text, type_desc text, effect_type text, effect text, effect_rate numeric, effect_time numeric, cooldown numeric, target_num integer, target text, target_type text, trigger_type text, immuneDispel text, triggerActionType text, triggerActionTargetType text, triggerActionTargetNum integer, triggerActionTargetSequence text, triggerCondition text, triggerThreshold text, triggerMeetType text, triggerConditionTarget text, triggerConditionTargetType text, triggerConditionTargetNum text, triggerConditionFull text)")

    c.execute("DROP TABLE IF EXISTS skins")
    c.execute("CREATE TABLE skins(id text, name text, fs_id text, fs_name text, auto numeric, basic numeric, energy numeric, auto_trigger text, basic_trigger text, energy_trigger text)") 
    
    c.execute("DROP TABLE IF EXISTS triggers")
    c.execute("CREATE TABLE triggers(skill_id text, type text)")

FUTURE_FS = {"200407": "Amaldin", "200415": "Milk (SP)", "200419": "Walnut Porridge", "200420": "Agate Fish Ball", "200421": "Lotus Leaf Phoenix Preserved", "200422": "Golden Pan-fried Marrow", "200423": "Fusilli", "200424": "French Baked Apple"}
# No artis past 200424 at the moment

def insert_fs(fs_data, c):
    columns = list(fs_data["200001"].keys())
    fs_fill = ("?," * len(columns))[:-1]
    fs_to_skills = {}
    skills_to_fs = {}
    for fs_id, fs in fs_data.items():
        fs = transform_fs(fs)
        fs_fields = list([str(fs[key]) for key in sorted(fs)])
        # HACK: Pull id and name to the front
        fs_fields = [fs_fields[25]] + [fs_fields[27]] + fs_fields
        fs_fields.pop(29)
        fs_fields.pop(27)

        c.execute(f"INSERT INTO fs VALUES({fs_fill})", fs_fields)

        if not fs["skill"]:
            print("No skills: ", fs)
            raise
        for skill_id in fs["skill"]:
            if skill_id in skills_to_fs:
                print("Skill already exists:", skill_id)
            skills_to_fs[skill_id] = fs_id

        if fs_id in FUTURE_FS:
            print("removing from future, update FUTURE_FS", fs_id)
            del FUTURE_FS[fs_id]

    # Add known future FS that already have artifacts but don't exist in card.json
    for fs_id, name in FUTURE_FS.items():
        fake_name = name + " (future)"
        c.execute(f"INSERT INTO fs(id, name) VALUES(\'{fs_id}\', \'{fake_name}\')")
        
    return skills_to_fs

def transform_fs(fs):
    fs["career"] = FS_TYPE[fs["career"]]
    fs["qualityId"] = FS_RARITY[fs["qualityId"]]
    return fs

def transform_monster(monster):
    immunity_list = []
    for immunity in monster["immunitySkillProperty"]:
        if immunity not in BUFF_TYPES.keys():
            print(f"unknown immunity {immunity} in monster {monster['id']}")
        immunity_list.append(BUFF_TYPES[immunity])
    monster["immunitySkillProperty"] = immunity_list
    monster["career"] = MONSTER_TYPE[monster["career"]]
    monster["formType"] = MONSTER_FORM_TYPE[monster["formType"]]
    return monster

def parse_monsters():
    # Return a multimap of skills to every monster that uses it
    skills_to_monsters = defaultdict(list)
    monsters = json.load(open(MONSTER_FILE))

    monsters_to_levels = defaultdict()
    levels = json.load(open(ENEMY_LEVEL_FILE))
    for _, rounds in levels.items():
        for r in rounds.values():
            print(r)
            for npc in r["npc"]:
                if npc["npcId"] in monsters_to_levels:
                    if npc["level"] != monsters_to_levels[npc["npcId"]]:
                        print(monsters_to_levels)
                        print(monsters_to_levels[npc["npcId"]])
                        print(_, npc)
#                        exit()
                monsters_to_levels[npc["npcId"]] = npc["level"]
#    exit(0)
    
    fill = ("?," * len(monsters["362122"]))[:-1]
    for monster_id, monster in monsters.items():
        monster = transform_monster(monster)
        c.execute(f"INSERT INTO monsters VALUES({fill})", list([str(monster[key]) for key in sorted(monster)]))
        for skill_id in monster["skill"]:
            skills_to_monsters[skill_id].append(monster["id"])

    return skills_to_monsters

def transform_skill(skill):
    # Replace buff types
    for field in ["innerPile", "target", "triggerActionTarget", "triggerCondition", "triggerConditionTarget", "triggerInsideCd", "type", "triggerAction"]:
        if skill[field]:
            new_field = {}
            for key in skill[field].keys():
                if key in BUFF_TYPES.keys():
                    new_field[BUFF_TYPES[key]] = skill[field][key]
                elif key not in BUFF_TYPES.values():
                    print("haven't mapped target type", key)
            skill[field] = new_field
        else:
            # triggerAction doesn't have targets, probably would be redundant
            if field not in ["triggerAction"]:
                # TODO: what's going on here?
                print("no target for", field, skill["id"])

    # the type.effect field also uses buff type as a value, replace it as well
    if skill["type"]:
        for effect in skill["type"].values():
            effect["type"] = BUFF_TYPES[effect["type"]]
            
            effect_effect = effect["effect"]
            # skills with type CHANGE_PP have an additional change to make within the effect field
            if effect["type"] == "CHANGE_PP":
                if len(effect_effect) != 2:
                    print("Can't parse CHANGE_PP", effect)
                    exit()
                effect_effect[0] = OBJ_PP[effect_effect[0]]

            # skills with type IMMUNE_BUFF_TYPE have an additional change to make within the effect field
            if effect["type"] == "IMMUNE_BUFF_TYPE":
                if skill["id"] == 10265:
                    print(effect)
                    print(effect_effect)
                
                for i, immunity in enumerate(effect_effect):
                    if immunity not in BUFF_TYPES:
                        print("Illegal immunity", immunity, skill["id"], effect)
                    else:
                        effect_effect[i] = BUFF_TYPES[immunity]

    # immuneDispel also uses the DISPEL_DEBUFF and DISPEL_BUFF buff types to denote immunity to having buffs/debuffs dispelled
    if skill["immuneDispel"]:
        immunities = []
        for immunity in skill["immuneDispel"]:
            if immunity in BUFF_TYPES:
                immunities.append(BUFF_TYPES[immunity])
            else:
                # Some immunities are apparently bugged and say '28,29' instead of ['28', '29']
                immunities.append(immunity)
        skill["immuneDispel"] = immunities
            
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
    for field in ["target", "triggerConditionTarget"]:
        if skill[field]:
            for value in skill[field].values():
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

def insert_skill(c, fill, fsid, skill, skills_to_monsters, skill_scaling_data):
    row = [fsid]
    for k in sorted(skill.keys()):
        # Show Chinese instead of unicode string
        if k == "descr":
            row.append(skill[k])
        else:
            row.append(json.dumps(skill[k]))

    c.execute(f"INSERT INTO skills VALUES({fill})", row)

    monster_list = []
    if str(skill["id"]) in skills_to_monsters.keys():
        monster_list = skills_to_monsters[str(skill["id"])]
    insert_denormalized_skill(c, fsid, skill, monster_list, skill_scaling_data)

def append_trigger_conditions(row, skill, target):
    # Add triggerActionType, if available
    hasTriggerAction = False
    hasTriggerActionField = False
    if skill["triggerAction"]:
        hasTriggerActionField = True
        for k, v in skill["triggerAction"].items():
            if k == target:
                if v[0]["type"] == "1.4":
                    print("1.4?!?", skill["id"])
                    continue
                if len(v) == 1:
                    row.append(TRIGGER_ACTION_TYPE[v[0]["type"]])
                    hasTriggerAction = True
                elif len(v) > 1:
                    tatypes = []
                    for data in v:
                       tatypes.append(TRIGGER_ACTION_TYPE[data["type"]]) 
                    row.append(str(tatypes))
                    hasTriggerAction = True;
    if not hasTriggerAction:
        row.append("")

    hasTriggerActionTarget = False
    if skill["triggerActionTarget"]:
        for k, v in skill["triggerActionTarget"].items():
            if k == target:
                # Lots of skills have the triggerActionTarget field filled with nulls,
                # pretend they don't exist
#                print(skill["id"], v)
                # TODO: check for other malformed versions that are partially populated, e.g. 2018177
                if v["type"]:
                    hasTriggerActionTarget = True;
                    row.append(TARGET_TYPES[v["type"]])
                    row.append(v["num"])
                    if v["sequence"]:
                        row.append(SEEK_SORT_RULES[v["sequence"]])
                    else:
                        row.append("None?")

        if not hasTriggerActionField:
            print(skill["id"], "has tat but no ta")
    else:
        if hasTriggerActionField:
            print(skill["id"], "has ta but no tat")
            
    if not hasTriggerActionTarget:
        row.append("")
        row.append("")
        row.append("")

    if skill["triggerCondition"]:
        triggerCondition = skill["triggerCondition"]
        hasValue = False
        condition = triggerCondition[target]
        if condition:
            if condition["value"]:
                if hasValue:
                    print("more than one condition has a threshold", skill)
                    exit()

                hasValue = True
                if len(condition["value"]) > 1:
                    print("too many values in ", skill)
                    exit()
                row.append(TRIGGER_CONDITION_TYPE.get(condition["type"], "missing"))
                row.append(condition["value"][0])
                row.append(MEET_CONDITION_TYPE.get(condition["meetType"], "missing"))
                row.append(skill["triggerConditionTarget"][target]["type"])
                row.append(skill["triggerConditionTarget"][target]["sequence"])
                row.append(skill["triggerConditionTarget"][target]["num"])
        if not hasValue:
            # List of the blank fields to fill
            for _ in ["triggerCondition", "triggerConditionThreshold", "triggerMeetType", "triggerConditionTarget", "triggerConditionTargetType", "triggerConditionTargetNum"]:
                row.append("")

    else:
        print("no trigger", skill)
        exit()

    # Always append raw form just in case
    # triggerConditionFull
    row.append(str(skill["triggerCondition"]))

def populate_and_insert(c, fsid, monster_id, skill, scaling_data):
    for target in skill["target"]:
        row = [fsid, monster_id, skill["name"], skill["descr"], skill["id"], skill["property"], skill["type_desc"]]
        row.append(target)
        effect = skill["type"][target]

        scaled_effect_used = False
        if scaling_data and str(skill["id"]) in scaling_data.keys():
            scaled_effect = scaling_data[str(skill["id"])][BUFF_TYPES_BIMAP.inv[target]]["41"]
            # Immunities don't scale, but their effects have been transformed in the nonscaled version,
            # so make sure we don't replace them
            if effect["type"] not in ("IMMUNE_BUFF_TYPE") and effect["effect"] != scaled_effect[0]:
                if fsid:
                    row.append(str(scaled_effect[0]))
                    scaled_effect_used = True
                # Some monster skills are in the scaling file for reasons unknown
#                else:
#                    print(skill["id"], "has scaling data for monster", monster_id)

        if not scaled_effect_used:
            row.append(str(effect["effect"]))

        # Success rates in triggerAction appear to override those in the skill.
        # Probably has something to do with skills with multiple effects/cooldowns
        effectSuccessRate = effect["effectSuccessRate"]
        effectTime = effect["effectTime"]
        
        if skill["triggerAction"]:
#            if fsid:
#                print(fsid, skill["id"], skill["descr"])

            tatypes = set()
            for tat, value in skill["triggerAction"].items():
                if tat == target:
                    if effectSuccessRate != value[0]["successRate"]:
                        effectSuccessRate = value[0]["successRate"]
                    if effectTime != value[0]["time"]:
                        effectTime = value[0]["time"]
                    # TODO: use the type field in triggerAction as well?
                
#                for v in value:
#                    tatypes.add(v["type"])
#                    if value[0]["type"] == "16":
#                        print(value[0]["type"], fsid, skill["id"], skill["descr"])
#            if len(tatypes) > 2:
#                print(tatypes, fsid, skill["id"], skill["descr"])

                        
        row.append(effectSuccessRate)
        row.append(effectTime)

        cd_index = len(row)
        
        row.append(skill["target"][target]["num"])
        row.append(skill["target"][target]["sequence"])
        row.append(skill["target"][target]["type"])
        row.append(str(skill["triggerType"]))

        row.append(str(skill["immuneDispel"]))

        append_trigger_conditions(row, skill, target)
                                                    
        if skill["triggerType"] and "CD" in skill["triggerType"]:
            row.insert(cd_index, skill["triggerType"]["CD"])
        elif skill["triggerInsideCd"] and skill["triggerInsideCd"][target]:
            # Skills with multiple effects may put cooldowns here
            # TODO: Verify that this doesn't mess up simpler skills
            row.insert(cd_index, skill["triggerInsideCd"][target])
            #row.append(skill["triggerInsideCd"][target])
        else:
            row.insert(cd_index, "")
#            row.append("")
        c.execute("INSERT INTO dn_skills VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", row)
    
def insert_denormalized_skill(c, fsid, skill, monster_list, scaling_data):
    populate_and_insert(c, fsid, "", skill, scaling_data)
    for monster in monster_list:
        populate_and_insert(c, "", monster, skill, scaling_data)

# 20241111 patch has more skill_groups in the res_sub file than the publish file.  Take the union of the two,
# preferring publish for historical reasons, even though I have no idea which one should have priority
def get_skill_groups(path):
    skill_groups = None
    pub_file = PUB_PATH / path
    res_file = RES_PATH / path
    if pub_file.exists():
        skill_groups = json.load(open(pub_file))
    else:
        # At least one of the files is guaranteed to exist
        return json.load(open(res_file))

    for i, k in json.load(open(res_file)).items():
        if i not in skill_groups:
            skill_groups[i] = k
    
    return skill_groups

def is_cjk(s):
    for c in s:
        # Brutal good enough hack
        if c != '\n' and unicodedata.name(c).startswith('CJK'):
            return True
    return False
        
def parse_artifacts():
    # Return a multimap of fsid to all their skills
    fs_to_skills = defaultdict(list)
    
    all_artifacts = json.load(open(ARTIFACT_MAPPING_FILE))
    skill_groups = get_skill_groups(ARTIFACT_SKILL_GROUP_PATH)
    
    for fsid in all_artifacts.keys():
        if fsid == "200028":
            print("skipping Moon Cake because something's gone wrong in the mappings")
            continue

        artifact_map = all_artifacts[fsid]

        # There seems to be an explicit mapping in cardArtifactGemstoneSkill.json as well.
        # Assuming here that they're not insane and these filenames make sense.
        artifact_file = get_file(f"artifact/gemstoneSkill{fsid}.json")

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

                    # Only use the L7 version of a skill to avoid spamming the main skill table
                    skill = transform_skill(artifact[str(skill_groups[skill]["7"])])
                    skill[TYPE_DESC] = f"T{togi_count}_{TOGI_TYPES[skill_count]}_L7"

                    # Make artifact skills look like normal skills
                    del skill["gemstoneGrade"]

                    # As of 20241118, many skills were untranslated.  Use the translated description with
                    # incorrect scaling instead
                    if is_cjk(skill["descr"]) and not is_cjk(skill["descr0"]):
                        skill["descr"] = "WRONG:" + skill["descr0"]
                        
                    # "descr0" shows the skill scaling at level 1.  "descr" shows the actual scaling for leveled skills
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
        sys.exit(f"Can't find card.json at {FS_FILE}")

    if not SKILLS_FILE.exists():
        sys.exit(f"Can't find skill.json at {SKILLS_FILE}")

    if not MONSTER_FILE.exists():
        sys.exit(f"Can't find monster.json at {MONSTER_FILE}")
        
    if not ARTIFACT_MAPPING_FILE.exists():
        sys.exit(f"Can't find talentPoint.json at {ARTIFACT_MAPPING_FILE}")

    if not ARTIFACT_SKILL_GROUP_FILE.exists():
        sys.exit(f"Can't find gemstoneSkillGroup.json at {ARTIFACT_SKILL_GROUP_FILE}")

    if not ENEMY_LEVEL_FILE.exists():
        sys.exit(f"Can't find enemy.json at {ENEMY_LEVEL_FILE}")

# Get the file in /publish if it exists, otherwise fall back to /res_sub
def get_file(path):
    pub_file = PUB_PATH / path
    if pub_file.exists():
        return pub_file
    return RES_PATH / path
        
args = parse_args()
# Based on ankimo event, this is the path shown in game
# Assumption is that /publish takes priority over res_sub when it exists
# These files generally exist in /publish unless there's been a large refactoring back to res_sub with a store update
PUB_PATH = Path(args.dir) / "com.egg.foodandroid" / "files" / "publish" / "conf" / "en-us"
RES_PATH = Path(args.dir) / "com.egg.foodandroid" / "files" / "res_sub" / "conf" / "en-us"

FS_FILE = get_file("card/card.json")
SKILLS_FILE = get_file("card/skill.json")
SKILLS_SCALING_FILE = get_file(Path("card/skillEffect.json"))
MONSTER_FILE = get_file("monster/monster.json")
ENEMY_LEVEL_FILE = get_file("quest/enemy.json")

# This appears to be the togi map for every FS
ARTIFACT_MAPPING_FILE = get_file("artifact/talentPoint.json")

# Togi map refers to a skill group, which maps to individual skills for all 10 togi levels
ARTIFACT_SKILL_GROUP_FILE = get_file("artifact/gemstoneSkillGroup.json")
# Wacky new updates mean we might have to check both files
ARTIFACT_SKILL_GROUP_PATH = "artifact/gemstoneSkillGroup.json"

assert_files_exist()

conn = sqlite3.connect(args.db)
c = conn.cursor()

create_tables()

skills_to_fs = insert_fs(json.load(open(FS_FILE)), c)
              
skills_to_monsters = parse_monsters()
  
skill_data = json.load(open(SKILLS_FILE))
skill_scaling_data = json.load(open(SKILLS_SCALING_FILE))
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
    insert_skill(c, skill_fill, fsid, skill, skills_to_monsters, skill_scaling_data)
#    print(skill["id"], fsid, 
    
# Artifact skills
f2s = parse_artifacts()
for fsid, arti_skills in f2s.items():
    for arti_skill in arti_skills:
        insert_skill(c, skill_fill, fsid, arti_skill, {}, None)

with open(Path(args.dir) / ".." / ".." / "src/ff/scripts/skin_speeds/fsdb_data.psv", "r") as skins_file:
    skin_reader = csv.reader(skins_file, delimiter = "|")
    for row in skin_reader:
        print(row)
        c.execute("INSERT INTO skins VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", row)

        
conn.commit()
conn.close()

