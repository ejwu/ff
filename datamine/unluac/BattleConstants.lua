CARD_DEFAULT_SCALE = 0.5
ELITE_DEFAULT_SCALE = 0.75
BOSS_DEFAULT_SCALE = 0.9
RENDER_FPS = 0.016666666666666666
UI_FPS = 0.022222222222222223
BattleObjectFeature = {
  BASE = 0,
  MELEE = 1,
  REMOTE = 2,
  HEALER = 3
}
BattleObjectFSMState = {
  BASE = 0,
  SEEK_ATTACK_TARGET = 1,
  MOVE = 2,
  ATTACK = 3,
  CAST = 4,
  CAST_CONNECT_SKILL = 5,
  CHANT = 6,
  DIE = 7,
  WIN = 8
}
BattleObjTowards = {
  BASE = 0,
  FORWARD = 1,
  NEGATIVE = -1
}
BattleElementType = {
  BET_BASE = 0,
  BET_CARD = 1,
  BET_PLAYER = 2,
  BET_WEATHER = 3,
  BET_BULLET = 4,
  BET_OB = 99
}
BKIND = {
  BASE = 0,
  INSTANT = 1,
  OVERTIME = 2,
  SILENT = 3,
  STUN = 4,
  SHIELD = 5,
  IMMUNE = 6,
  DISPEL = 7,
  ABILITY = 8,
  FREEZE = 9,
  REVIVE = 10,
  ENCHANTING = 11,
  EXECUTE = 12,
  ATTACK_CHARGE = 13,
  TRIGGER = 14
}
BuffCauseEffectTime = {
  BASE = 0,
  ADD2OBJ = 1,
  DELAY = 2,
  INSTANT = 3
}
BuffIconType = {BASE = 0}
GState = {
  READY = 1,
  START = 2,
  OVER = 3,
  TRANSITION = 4,
  BLOCK = 5,
  SUCCESS = 6,
  FAIL = 7
}
ImmuneType = {IT_SKILL = 1, IT_WEATHER = 2}
ActionTriggerType = {
  HP = 1,
  CD = 2,
  DIE = 3,
  SKILL = 4,
  ATTACK = 98,
  CONNECT = 99
}
BattleResult = {
  BR_BASE = 0,
  BR_CONTINUE = 1,
  BR_NEXT_WAVE = 2,
  BR_SUCCESS = 3,
  BR_FAIL = 4,
  BR_RESCUE = 5
}
BattleObjTintType = {
  BOTT_BASE = 0,
  BOTT_INSTANT = 1,
  BOTT_BG = 2,
  BOTT_COVER = 3
}
BattleObjTintPattern = {
  BOTP_BASE = 0,
  BOTP_BLOOD = 1,
  BOTP_DARK = 2
}
BattleObjActionTag = {BOAT_BASE = 0, BOAT_TINT = 1001}
DamageType = {
  INVALID = 0,
  ATTACK_PHYSICAL = 1,
  ATTACK_HEAL = 2,
  SKILL_PHYSICAL = 3,
  SKILL_HEAL = 4,
  PHYSICAL = 90,
  HEAL = 91
}
ValueConstants = {
  V_INFINITE = -1,
  V_NONE = 0,
  V_NORMAL = 1
}
TimeAxisConstants = {
  TA_ENTER = 1,
  TA_ACTION = 2,
  TA_EXIT = 3
}
AttackModifierType = {
  AMT_BASE = 0,
  AMT_HIT_AND_HEAL = 1,
  AMT_HIT_GAIN_ENERGY = 2,
  AMT_CERTAIN_CRITICAL = 3,
  AMT_ATK_B = 4,
  AMT_ULTIMATE_DAMAGE = 5
}
BattleLoadingSceneType = {
  FIRST_PERFORMANCE = -2,
  BATTLE_REMIND = -1,
  NORMAL = 0
}
BattleDriverType = {
  BASE = 0,
  END_DRIVER = 1,
  RES_LOADER = 2,
  SHIFT_DRIVER = 3,
  GUIDE_DRIVER = 4,
  SKADA_DRIVER = 5
}
AbnormalState = {
  BASE = 0,
  SILENT = 1,
  STUN = 2,
  FREEZE = 3,
  ENCHANTING = 4,
  UNDEAD = 5,
  LUCK = 6
}
QTEAttachObjectType = {BASE = 0, ICE = 1}
SpineType = {
  BASE = 0,
  AVATAR = 1,
  EFFECT = 2,
  HURT = 3
}
PassedBattle = {
  NO_RESULT = -1,
  FAIL = 0,
  SUCCESS = 1
}
SkadaType = {
  DAMAGE = 1,
  HEAl = 2,
  GOT_DAMAGE = 3
}
ObjPP = {
  ATTACK_A = 1,
  ATTACK_B = 2,
  DEFENCE_A = 3,
  DEFENCE_B = 4,
  CDAMAGE_UP = 5,
  CDAMAGE_DOWN = 6,
  GDAMAGE_UP = 7,
  GDAMAGE_DOWN = 8,
  SKILL_UP = 9,
  SKILL_DOWN = 10,
  OHP_A = 11,
  OHP_B = 12,
  CR_RATE_A = 13,
  CR_RATE_B = 14,
  CR_DAMAGE_A = 15,
  CR_DAMAGE_B = 16,
  ATK_RATE_A = 17,
  ATK_RATE_B = 18,
  GET_DAMAGE_ATTACK = 19,
  GET_DAMAGE_SKILL = 20,
  GET_DAMAGE_PHYSICAL = 21,
  CAUSE_DAMAGE_ATTACK = 22,
  CAUSE_DAMAGE_SKILL = 23,
  CAUSE_DAMAGE_PHYSICAL = 24,
  GET_HEAL_ATTACK = 25,
  GET_HEAL_SKILL = 26,
  GET_HEAL_ALL = 27,
  CAUSE_HEAL_ATTACK = 28,
  CAUSE_HEAL_SKILL = 29,
  CAUSE_HEAL_ALL = 30,
  CDP_2_CARD = 100,
  CDP_2_MONSER = 101,
  CDP_2_ELITE = 102,
  CDP_2_BOSS = 103,
  CDP_2_CHEST = 107
}
ConfigWeakPointId = {
  BREAK = 101,
  HALF_EFFECT = 102,
  NONE = 103
}
ConfigSkillType = {
  SKILL_NORMAL = 1,
  SKILL_HALO = 2,
  SKILL_CUTIN = 3,
  SKILL_CONNECT = 4,
  SKILL_WEAK = 5,
  SKILL_PLAYER = 6,
  SKILL_SCENE = 7
}
ConfigSkillTriggerType = {
  RESIDENT = 1,
  RANDOM = 2,
  ENERGY = 3,
  CD = 4,
  LOST_HP = 5,
  COST_HP = 6,
  COST_CHP = 7,
  COST_OHP = 8
}
ConfigEffectBulletType = {
  BASE = 0,
  SPINE_EFFECT = 1,
  SPINE_PERSISTANCE = 2,
  SPINE_UFO_STRAIGHT = 3,
  SPINE_UFO_CURVE = 4,
  SPINE_WINDSTICK = 5,
  SPINE_LASER = 6
}
ConfigEffectCauseType = {
  BASE = 0,
  POINT = 1,
  SINGLE = 2,
  SCREEN = 3
}
ConfigMonsterType = {
  CARD = -1,
  BASE = 0,
  NORMAL = 1,
  ELITE = 2,
  BOSS = 3,
  SCARECROW_TANK = 4,
  SCARECROW_DPS = 5,
  SCARECROW_HEALER = 6,
  CHEST = 7
}
ConfigMonsterFormType = {
  BASE = 0,
  NORMAL = 1,
  COMMODE = 2
}
ConfigCardCareer = {
  BASE = 0,
  TANK = 1,
  MELEE = 2,
  RANGE = 3,
  HEALER = 4
}
ConfigWeatherTriggerType = {HALO = 1, RANDOM = 2}
ConfigWeatherType = {
  SUNSHINE = 1,
  HEAT = 2,
  COLD = 3,
  HUMID = 4,
  THUNDER = 5,
  HAZE = 6,
  HURRICANE = 7
}
ConfigSeekTargetRule = {
  BASE = 0,
  T_OBJ_SELF = 1,
  T_OBJ_ENEMY = 2,
  T_OBJ_FRIEND = 3,
  T_OBJ_ALL = 4,
  T_OBJ_FRIEND_TANK = 5,
  T_OBJ_FRIEND_MELEE = 6,
  T_OBJ_FRIEND_REMOTE = 7,
  T_OBJ_FRIEND_HEALER = 8,
  T_OBJ_ENEMY_TANK = 9,
  T_OBJ_ENEMY_MELEE = 10,
  T_OBJ_ENEMY_REMOTE = 11,
  T_OBJ_ENEMY_HEALER = 12,
  T_OBJ_FRIEND_PLAYER = 13,
  T_OBJ_ENEMY_PLAYER = 14,
  T_OBJ_ATTACKER = 15,
  T_OBJ_ATTACK_TARGET = 16,
  T_OBJ_TRIGGER_ATTACKER = 17
}
SeekSortRule = {
  S_NONE = 1,
  S_DISTANCE_MIN = 2,
  S_DISTANCE_MAX = 3,
  S_HP_PERCENT_MAX = 4,
  S_HP_PERCENT_MIN = 5,
  S_ATTACK_MAX = 6,
  S_ATTACK_MIN = 7,
  S_DEFENCE_MAX = 8,
  S_DEFENCE_MIN = 9,
  S_CHP_MAX = 10,
  S_CHP_MIN = 11,
  S_OHP_MAX = 12,
  S_OHP_MIN = 13,
  S_BATTLE_POINT_MAX = 14,
  S_BATTLE_POINT_MIN = 15,
  S_ATTACK_RATE_MAX = 16,
  S_ATTACK_RATE_MIN = 17,
  S_HATE_MAX = 18,
  S_HATE_MIN = 19,
  S_FOR_HEAL = 99
}
ConfigSpecialCardId = {PLAYER = 900001, WEATHER = 900002}
ConfigIsDebuff = {
  BUFF = 1,
  DEBUFF = 2,
  VALUE = 3
}
ConfigBuffType = {
  BASE = 0,
  ATTACK_B = 1,
  ATTACK_A = 2,
  DEFENCE_B = 3,
  DEFENCE_A = 4,
  OHP_B = 5,
  OHP_A = 6,
  CR_RATE_B = 7,
  CR_RATE_A = 8,
  ATK_RATE_B = 9,
  ATK_RATE_A = 10,
  CR_DAMAGE_B = 11,
  CR_DAMAGE_A = 12,
  CDAMAGE_A = 13,
  GDAMAGE_A = 14,
  ISD = 15,
  ISD_LHP = 16,
  ISD_CHP = 17,
  ISD_OHP = 18,
  DOT = 19,
  DOT_CHP = 20,
  DOT_OHP = 21,
  HEAL = 22,
  HEAL_LHP = 23,
  HEAL_OHP = 24,
  HOT = 25,
  HOT_LHP = 26,
  HOT_OHP = 27,
  DISPEL_DEBUFF = 28,
  DISPEL_BUFF = 29,
  IMMUNE = 30,
  STUN = 31,
  SILENT = 32,
  SHIELD = 33,
  HEAL_BY_ATK = 34,
  HEAL_BY_DFN = 35,
  HEAL_BY_CHP = 36,
  FREEZE = 37,
  DISPEL_QTE = 38,
  BECKON = 39,
  DISPEL_BECKON = 40,
  REVIVE = 41,
  ENCHANTING = 42,
  EXECUTE = 43,
  ENERGY_ISTANT = 45,
  ENERGY_CHARGE_RATE = 46,
  ATK_CR_RATE_CHARGE = 47,
  ATK_ATTACK_B_CHARGE = 48,
  ATK_ISD_CHARGE = 49,
  ATK_HEAL_CHARGE = 50,
  ATK_ENERGY_CHARGE = 51,
  IMMUNE_ATTACK_PHYSICAL = 52,
  IMMUNE_SKILL_PHYSICAL = 53,
  IMMUNE_ATTACK_HEAL = 54,
  IMMUNE_SKILL_HEAL = 55,
  IMMUNE_HEAL = 56,
  GET_DAMAGE_ATTACK = 57,
  GET_DAMAGE_SKILL = 58,
  GET_DAMAGE_PHYSICAL = 59,
  CAUSE_DAMAGE_ATTACK = 60,
  CAUSE_DAMAGE_SKILL = 61,
  CAUSE_DAMAGE_PHYSICAL = 62,
  STAGGER = 101,
  SACRIFICE = 102,
  SPIRIT_LINK = 103,
  UNDEAD = 104,
  DOT_FINISHER = 105,
  CRITICAL_COUNTER = 106,
  MULTISHOT = 108,
  ATTACK_SEEK_RULE = 109,
  HEAL_SEEK_RULE = 110,
  CHANGE_SKILL_TRIGGER = 111,
  CHANGE_PP = 112,
  DAMAGE_NO_TRIGGER = 113,
  HEAL_NO_TRIGGER = 114,
  HOT_EXTEND = 115,
  SLAY_DAMAGE_SPLASH = 116,
  SLAY_BUFF_INFECT = 117,
  ENHANCE_NEXT_SKILL = 118,
  OVERFLOW_HEAL_2_SHIELD = 119,
  OVERFLOW_HEAL_2_DAMAGE = 120,
  SLAY_CAST_ECHO = 121,
  MARKING = 122,
  CHANGE_PP_BY_PROPERTY = 123,
  ENHANCE_BUFF_TIME_CAUSE = 124,
  ENHANCE_BUFF_TIME_GET = 125,
  ENHANCE_BUFF_VALUE_CAUSE = 126,
  ENHANCE_BUFF_VALUE_GET = 127,
  CHANGE_BUFF_SUCCESS_RATE = 128,
  PROPERTY_CONVERT = 129,
  IMMUNE_BUFF_TYPE = 130,
  VIEW_TRANSFORM = 131,
  LIVE_CHEAT_FREE = 10001,
  BATTLE_TIME = 10002,
  TRIGGER_BUFF = 99999
}
ConfigBuffIconType = {
  BASE = 0,
  EFFECT_ATTACK = 1,
  EFFECT_DEFENCE = 2,
  EFFECT_MAX_HP = 3,
  EFFECT_CRIT_RATE = 4,
  EFFECT_ATTACK_RATE = 5,
  EFFECT_CRIT_DAMAGE = 6,
  EFFECT_DOT = 7,
  EFFECT_HOT = 8,
  EFFECT_CDAMAGE = 9,
  EFFECT_GDAMAGE = 10,
  IMMUNE = 11,
  STUN = 12,
  SILENT = 13,
  SHIELD = 14,
  INSTANT_DAMAGE = 15,
  INSTANT_HEAL = 16,
  DISPEL = 17
}
ConfigObjectTriggerActionType = {
  BASE = 0,
  ATTACK = 1,
  ATTACK_HIT = 2,
  ATTACK_CRITICAL = 3,
  GOT_DAMAGE = 4,
  GOT_DAMAGE_CRITICAL = 5,
  GOT_HEAL = 6,
  GOT_HEAL_CRITICAL = 7,
  CAST = 8,
  GOT_DEADLY_DAMAGE = 9,
  DEAD = 10,
  WAVE_SHIFT = 11,
  GOT_BUFF = 12,
  REFRESH_BUFF = 13,
  CAST_SKILL_NORMAL = 14,
  CAST_SKILL_CUTIN = 15,
  CAST_SKILL_CONNECT = 16,
  SLAY_OBJECT = 17,
  SHIELD_OVERPLUS = 18,
  WAVE_START = 19,
  OBJECT_AWAKE = 20
}
ConfigObjectTriggerConditionType = {
  BASE = 0,
  HP_MORE_THAN = 1,
  HP_LESS_THAN = 2,
  HAS_BUFF = 3
}
ConfigMeetConditionType = {
  BASE = 0,
  ONE = 1,
  ALL = 2
}
ConfigPhaseTriggerType = {
  BASE = 0,
  LOST_HP = 1,
  APPEAR_TIME = 2,
  OBJ_DIE = 3,
  OBJ_SKILL = 4
}
ConfigPhaseType = {
  TALK_DEFORM = 1,
  TALK_ESCAPE = 2,
  TALK_ONLY = 3,
  BECKON_ADDITION_FORCE = 4,
  BECKON_ADDITION = 5,
  BECKON_CUSTOMIZE = 6,
  EXEUNT_CUSTOMIZE = 7,
  DEFORM_CUSTOMIZE = 8,
  PLOT = 9
}
ConfigDeformType = {HOLD_HP = 1, RECOVER_HP = 2}
ConfigEscapeType = {ESCAPE = 1, RETREAT = 2}
ConfigBattleResultType = {
  NORMAL = 1,
  NONE_STAR = 2,
  NO_DROP = 3,
  RAID = 4,
  NO_EXP = 5,
  POINT_HAS_RESULT = 6,
  POINT_NO_RESULT = 7,
  ONLY_RESULT = 8,
  NO_RESULT_DAMAGE_COUNT = 9,
  ONLY_RESULT_AND_REWARDS = 10
}
ConfigBattleLevelRolling = {HIGHER_MAX = 30, LOWER_MIN = -60}
ConfigBattleFunctionModuleType = {
  DEFAULT = 0,
  ACCELERATE_GAME = 1,
  PLAYER_SKILL = 2,
  PAUSE_GAME = 3,
  WAVE = 4,
  STAGE_CLEAR_TARGET = 5
}
ConfigGlobalBuffType = {
  BASE = 0,
  BATTLE_TIME_A = 1,
  OHP_A = 2,
  ATTACK_A = 3,
  DEFENCE_A = 4,
  IMMUNE_ATTACK_PHYSICAL = 5,
  IMMUNE_SKILL_PHYSICAL = 6,
  CDAMAGE_A = 7
}
ConfigGlobalBuffSeekTargetRule = {
  BASE = 0,
  T_OBJ_FRIEND = 1,
  T_OBJ_ENEMY = 2,
  T_OBJ_ALL = 3,
  T_OBJ_OTHER = 4
}
ConfigGlobalEffectType = {
  BASE = 0,
  OUTSIDE = 1,
  INSIDE = 2
}
ConfigStageCompleteType = {
  BASE = 0,
  NORMAL = 1,
  SLAY_ENEMY = 2,
  HEAL_FRIEND = 3,
  ALIVE = 4,
  TAG_MATCH = 5
}
ConfigCampType = {
  BASE = 0,
  FRIEND = 1,
  ENEMY = 2,
  NEUTRAL = 3
}
ConfigCameraActionType = {
  BASE = 0,
  SHAKE = 1,
  SHAKE_ZOOM = 2
}
ConfigCameraTriggerType = {
  BASE = 0,
  PHASE_CHANGE = 1,
  OBJ_SKILL = 2
}
ConfigMonsterRecordDeltaHP = {DONT = 0, DO = 1}
BDDamageType = {
  N_ATTACK = 1,
  C_ATTACK = 2,
  N_SKILL = 3,
  O_SKILL = 4
}
OState = {
  SLEEP = 1,
  NORMAL = 2,
  BATTLE = 3,
  MOVING = 4,
  ATTACKING = 5,
  CASTING = 6,
  MOVE_BACK = 7,
  CHANTING = 8,
  MOVE_FORCE = 9,
  DIE = 10,
  VIEW_TRANSFORM = 11
}
BattleTags = {
  BT_BASE = 0,
  BT_FRIEND = 1,
  BT_CONFIG_ENEMY = 2,
  BT_OTHER_ENEMY = 3,
  BT_BECKON = 4,
  BT_WEATHER = 5,
  BT_FRIEND_PLAYER = 6,
  BT_ENEMY_PLAYER = 7,
  BT_OBSERVER = 8,
  BT_GLOBAL_EFFECT = 9,
  BT_BULLET = 10,
  BT_ATTACK_MODIFIER = 101,
  BT_TRIGGER = 102,
  BT_CI_SCENE = 103,
  BT_QTE_ATTACH = 104,
  BT_VIEW_MODEL = 201,
  BT_DEBUFF = 2000
}
BattleObjTagConfig = {
  [BattleTags.BT_FRIEND] = {
    lower = 0,
    upper = 1000,
    elementType = BattleElementType.BET_CARD
  },
  [BattleTags.BT_CONFIG_ENEMY] = {
    lower = 1000,
    upper = 2000,
    elementType = BattleElementType.BET_CARD
  },
  [BattleTags.BT_OTHER_ENEMY] = {
    lower = 2000,
    upper = 3000,
    elementType = BattleElementType.BET_CARD
  },
  [BattleTags.BT_BECKON] = {
    lower = 3000,
    upper = 4000,
    elementType = BattleElementType.BET_CARD
  },
  [BattleTags.BT_WEATHER] = {
    lower = 4000,
    upper = 5000,
    elementType = BattleElementType.BET_WEATHER
  },
  [BattleTags.BT_FRIEND_PLAYER] = {
    lower = 5000,
    upper = 6000,
    elementType = BattleElementType.BET_PLAYER
  },
  [BattleTags.BT_ENEMY_PLAYER] = {
    lower = 6000,
    upper = 7000,
    elementType = BattleElementType.BET_PLAYER
  },
  [BattleTags.BT_OBSERVER] = {
    lower = 7000,
    upper = 8000,
    elementType = BattleElementType.BET_OB
  },
  [BattleTags.BT_GLOBAL_EFFECT] = {
    lower = 8000,
    upper = 8100,
    elementType = BattleElementType.BET_OB
  },
  [BattleTags.BT_BULLET] = {
    lower = 10000,
    upper = nil,
    elementType = BattleElementType.BET_BULLET
  },
  [BattleTags.BT_ATTACK_MODIFIER] = {
    lower = 0,
    upper = nil,
    elementType = BattleElementType.BET_BASE,
    ignore = true
  },
  [BattleTags.BT_TRIGGER] = {
    lower = 0,
    upper = nil,
    elementType = BattleElementType.BET_BASE,
    ignore = true
  },
  [BattleTags.BT_CI_SCENE] = {
    lower = 0,
    upper = nil,
    elementType = BattleElementType.BET_BASE,
    ignore = true
  },
  [BattleTags.BT_QTE_ATTACH] = {
    lower = 0,
    upper = nil,
    elementType = BattleElementType.BET_BASE,
    ignore = true
  },
  [BattleTags.BT_VIEW_MODEL] = {
    lower = 100,
    upper = nil,
    elementType = BattleElementType.BET_BASE,
    ignore = true
  }
}
MAX_BECKON_AMOUNT_LIMIT = 5
MAX_ENERGY = 100
LEADER_ENERGY_ADD = 50
ENERGY_PER_S = 1
ENERGY_PER_KILL = 20
ENERGY_PER_HURT = 3
ENERGY_PER_ATTACK = 1.3333333333333333
PLAYER_ENERGY_PER_S = 1
PLAYER_ENERGY_BY_NORMAL_SKILL = 1
PLAYER_ENERGY_BY_CI_SKILL = 3
BattleFormation = {
  [1] = {r = 4, c = 12},
  [2] = {r = 2, c = 12},
  [3] = {r = 5, c = 7},
  [4] = {r = 1, c = 7},
  [5] = {r = 3, c = 4}
}
MELEE_STANCE_OFF_Y = 0.4
TIME_ACCURACY = 10000
RE_TIME_ACCURACY = 1.0E-4
HP_BAR_MAX_VALUE = 10000
ATTACK_2_SKILL_ID = -1
sp.AnimationName = {
  attack = "attack",
  attacked = "attacked",
  die = "die",
  idle = "idle",
  run = "run",
  skill = "skill",
  skill1 = "skill1",
  skill2 = "skill2",
  win = "win",
  chant = "chant",
  slaytarget = "red",
  healtarget = "green"
}
sp.CustomEvent = {
  cause_effect = "cause_effect"
}
sp.CustomName = {
  BULLET_BONE_NAME = "bullet",
  VIEW_BOX = "viewBox",
  COLLISION_BOX = "collisionBox"
}
sp.LaserAnimationName = {
  laserHead = "_laser_head",
  laserBody = "_laser_body",
  laserEnd = "_laser_end"
}
sp.AniCacheName = {
  CARD_CI_FG = "cutin_2",
  CARD_CI_HEAD_ACTIVE = "head_active",
  CARD_CI_CONNECT_HEAD_BG = "connect_head_1",
  CARD_CI_CONNECT_HEAD_FG = "connect_head_2",
  BOSS_WEAK_POINT = "boss_weak",
  BOSS_WEAK_CHANT = "boss_chant_progressBar",
  BOSS_CI_BG = "boss_cutin_1",
  BOSS_CI_FG = "boss_cutin_2",
  BOSS_CI_MASK = "boss_cutin_mask",
  BUY_REVIVAL = "hurt_18",
  WAVE_TARGET_MARK = "wavetarget",
  PHASE_DEFORM_EFFECT = "phase_deform_effect"
}
ObjectEvent = {
  OBJECT_DIE = "OBJECT_DIE",
  OBJECT_REVIVE = "OBJECT_REVIVE",
  OBJECT_CAST_ENTER = "OBJECT_CAST_ENTER",
  OBJECT_CHANT_ENTER = "OBJECT_CHANT_ENTER",
  OBJECT_CREATED = "OBJECT_CREATED",
  OBJECT_PHASE_CHANGE = "OBJECT_PHASE_CHANGE",
  OBJECT_LURK = "OBJECT_LURK"
}
BATTLE_E_ZORDER = {
  BATTLE_LAYER = 10,
  EFFECT = 40,
  UI = 50,
  CI = 120,
  TOP = 150,
  PAUSE = 9998,
  GUIDE = 9999,
  BULLET = 2000,
  DAMAGE_NUMBER = 3000,
  SPECIAL_EFFECT = 4000,
  DIALOGUE = 9000,
  UI_NORMAL = 0,
  UI_CLEAR_TARGET = 10,
  UI_TAGMATCH = 10,
  UI_EFFECT = 99
}
FIRST_PERFORMANCE_STAGE_ID = 8999
GUIDE_QUEST_SUCCESS_WORLD_MAP = 53
ANITIME_NEXT_WAVE_REMIND = 46
ANITIME_CUTIN_SCENE = 86
ConfigBattleGuideStepTriggerType = {
  BASE = 0,
  TIME_AXIS = 1,
  CAST_SKILL = 2,
  CONTINUE = 3,
  CHANT = 4,
  CAN_CAST_SKILL = 5
}
ConfigBattleGuideStepHighlightType = {
  NONE = 0,
  UI = 1,
  BATTLE_ROOT = 2,
  OBJECT_ALL = 3,
  OBJECT_HP_BAR = 4,
  OBJECT_WEAK_POINT = 5,
  OBJECT_EXPRESSION = 6
}
ConfigBattleGuideStepUIId = {
  BASE = 0,
  PAUSE_BTN = 1,
  PLAYER_SKILL_ALL = 2,
  PLAYER_SKILL_ENERGY = 3,
  PLAYER_SKILL_ICON = 4,
  ACCELERATE_BTN = 5,
  CONNECT_SKILL_ICON = 6,
  WAVE_ICON = 7,
  TIME_ICON = 8,
  WEATHER_ICON = 9
}
ConfigBattleGuideStepType = {
  BASE = 0,
  ONLY_TEXT = 1,
  NEED_TOUCH = 2
}
ConfigBattleGuideStepEndType = {
  BASE = 0,
  TOUCH_ANYWHERE = 1,
  TOUCH_APPOINTED = 2,
  CLEAR_QTE_ICE = 3,
  CLEAR_QTE_BECKON = 4,
  CLEAR_WEAK_POINT = 5
}
ConfigBattleGuideStepBattleRootId = {
  BASE = 0,
  FRIEND_ALL = 1,
  ENEMY_ALL = 2,
  QTE_ALL = 3
}
ConfigBattleGuideStepGodType = {
  BASE = 0,
  TEACHER = 1,
  FINGER = 2
}
ConfigBattleGuideStepHighlightShapeType = {
  BASE = 0,
  ICE = 1,
  CIRCLE = 2,
  SQUARE = 3
}
