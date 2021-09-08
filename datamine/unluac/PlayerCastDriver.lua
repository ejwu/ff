local BaseCastDriver = __Require("battle.objectDriver.castDriver.BaseCastDriver")
local PlayerCastDriver = class("PlayerCastDriver", BaseCastDriver)
function PlayerCastDriver:ctor(...)
  local args = unpack({
    ...
  })
  self.skillIds = args.skillIds
  BaseCastDriver.ctor(self, ...)
end
function PlayerCastDriver:InitUnitValue()
end
function PlayerCastDriver:CanDoAction(skillId)
  return self:CanCastBySkillId(skillId)
end
function PlayerCastDriver:OnActionEnter(skillId)
  print([[

**************
]], " cast player skill(new logic) -> ", skillId, [[

**************
]])
  self:ClearNextSkillExtra()
  self:CostActionResources(skillId)
  self:OnCastEnter(skillId)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ShowCastPlayerSkillCover")
end
function PlayerCastDriver:OnActionExit()
  self:OnCastExit()
end
function PlayerCastDriver:OnActionBreak()
end
function PlayerCastDriver:OnActionUpdate(dt)
end
function PlayerCastDriver:OnCastEnter(skillId)
  G_BattleLogicMgr:SendObjEvent(ObjectEvent.OBJECT_CAST_ENTER, {
    tag = self:GetOwner():GetOTag(),
    isEnemy = self:GetOwner():IsEnemy(true),
    skillId = skillId
  })
  self:Cast(skillId)
  self:OnActionExit()
end
function PlayerCastDriver:Cast(skillId)
  local bulletOriPosition = self:GetOwner():GetLocation().po
  local params = ObjectCastParameterStruct.New(self:GetSkillExtra(), 1, nil, bulletOriPosition, false, false)
  local skillModel = self:GetSkillModelBySkillId(skillId)
  if nil ~= skillModel then
    skillModel:CastBegin(params)
  end
  local animationData = self:GetOwner():GetActionAnimationConfigBySkillId(skillId)
  if nil ~= animationData then
    G_BattleLogicMgr:RenderPlayBattleSoundEffect(animationData.actionSE)
    G_BattleLogicMgr:RenderPlayBattleSoundEffect(animationData.actionVoice)
    G_BattleLogicMgr:RenderPlayBattleSoundEffect(animationData.actionCauseSE)
  end
end
function PlayerCastDriver:OnCastExit()
  self:ClearNextSkillExtra()
  self:SetCastingEcho(false)
end
function PlayerCastDriver:CanCastBySkillId(skillId)
  local result = false
  local skillConfig = CommonUtils.GetSkillConf(skillId)
  if true == BattleUtils.IsSkillHaveBuffEffectByBuffType(skillId, ConfigBuffType.REVIVE) and false == self:CanCastRevive(skillId) then
    return false
  end
  if self:CanCastSkillJudgeByTriggerType(skillId) then
    result = true
  end
  return result
end
function PlayerCastDriver:CanCastSkillJudgeByTriggerType(skillId)
  local result = true
  local insideCD = self:GetSkillInsideCD(skillId)
  if nil ~= insideCD and insideCD > 0 then
    return false
  end
  local triggerType = 0
  local triggerValue = 0
  local judgeFunc = {
    [ConfigSkillTriggerType.RESIDENT] = function(triggerValue)
      return false
    end,
    [ConfigSkillTriggerType.RANDOM] = function(triggerValue)
      return triggerValue * 1000 >= G_BattleLogicMgr:GetRandomManager():GetRandomInt(1000)
    end,
    [ConfigSkillTriggerType.ENERGY] = function(triggerValue)
      return triggerValue <= self:GetOwner():GetEnergy()
    end,
    [ConfigSkillTriggerType.CD] = function(triggerValue)
      return 0 >= self:GetActionTrigger(ActionTriggerType.CD, skillId)
    end,
    [ConfigSkillTriggerType.LOST_HP] = function(triggerValue)
      return false
    end,
    [ConfigSkillTriggerType.COST_HP] = function(triggerValue)
      return false
    end,
    [ConfigSkillTriggerType.COST_CHP] = function(triggerValue)
      return false
    end,
    [ConfigSkillTriggerType.COST_OHP] = function(triggerValue)
      return false
    end
  }
  local skillTriggerInfo = self:GetSkillTriggerInfoBySkillId(skillId)
  local sk = sortByKey(skillTriggerInfo)
  for _, key in ipairs(sk) do
    triggerType = key
    triggerValue = skillTriggerInfo[triggerType]
    local result = judgeFunc[triggerType](triggerValue)
    if not result then
      return false
    end
  end
  return result
end
function PlayerCastDriver:CanCastRevive(skillId)
  local skillConfig = CommonUtils.GetSkillConf(skillId)
  local isEnemy = self:GetOwner():IsEnemy()
  local canReviveCards = BattleExpression.GetDeadFriendlyTargetsForPlayerSkill(isEnemy, checkint(skillConfig.target[tostring(ConfigBuffType.REVIVE)].type), self:GetOwner(), true)
  return #canReviveCards > 0
end
function PlayerCastDriver:GetCDPercentBySkillId(skillId)
  local currentCd = self:GetActionTrigger(ActionTriggerType.CD, skillId)
  if nil ~= currentCd then
    local skillConf = CommonUtils.GetSkillConf(skillId)
    return currentCd / checknumber(skillConf.triggerType[tostring(ConfigSkillTriggerType.CD)])
  else
    return nil
  end
end
function PlayerCastDriver:InitSkills()
  self.skills = {
    active = {},
    halo = {}
  }
  self.actionTrigger = {
    [ActionTriggerType.CD] = {}
  }
  local skillId, skillConfig
  for _, skillIdInfo in ipairs(self.skillIds.activeSkill) do
    skillId = checkint(skillIdInfo.skillId)
    skillConfig = CommonUtils.GetSkillConf(skillId)
    if nil ~= skillConfig then
      self:AddASkill(skillId, 1)
    end
  end
  for _, skillIdInfo in ipairs(self.skillIds.passiveSkill) do
    skillId = checkint(skillIdInfo.skillId)
    skillConfig = CommonUtils.GetSkillConf(skillId)
    if nil ~= skillConfig then
      self:AddASkill(skillId, 1)
    end
  end
end
function PlayerCastDriver:AddASkill(skillId, level)
  local skillConfig = CommonUtils.GetSkillConf(skillId)
  if nil == skillConfig then
    BattleUtils.PrintConfigLogicError("cannot find skill config in PlayerCastDriver -> AddASkill : " .. tostring(skillId))
    return
  end
  if not self:CanInitSkillBySkillId(checkint(skillId)) then
    return
  end
  local skillClassPath = "battle.skill.PlayerSkill"
  local skillType = checkint(skillConfig.property)
  local triggerInfo = {}
  for triggerType, triggerValue in pairs(skillConfig.triggerType) do
    triggerInfo[checkint(triggerType)] = checknumber(triggerValue)
  end
  self:SetSkillTriggerInfoBySkillId(skillId, triggerInfo)
  if nil ~= triggerInfo[ConfigSkillTriggerType.CD] then
    self.actionTrigger[ActionTriggerType.CD][tostring(skillId)] = triggerInfo[ConfigSkillTriggerType.CD]
  end
  self:SetSkillInsideCD(skillId, 0)
  local effect = CardUtils.GetCardEffectConfigBySkinId(ConfigSpecialCardId.PLAYER, ConfigSpecialCardId.PLAYER)
  local spineActionData = BSCUtils.GetSkillSpineEffectStruct(skillId, effect, G_BattleLogicMgr:GetCurrentWave())
  self:GetOwner():SetActionAnimationConfigBySkillId(skillId, spineActionData)
  local skillBaseData = SkillConstructorStruct.New(skillId, level, BattleUtils.GetSkillInfoStructBySkillId(skillId, level), self:GetOwner():IsEnemy(true), self:GetOwner():GetOTag(), spineActionData)
  local skill = __Require(skillClassPath).new(skillBaseData)
  local skillInfo = ObjectSkillStruct.New(skillId, skill)
  self:SetSkillStructBySkillId(skillId, skillInfo)
  if ConfigSkillType.SKILL_HALO == skillType then
    table.insert(self.skills.halo, skillId)
  elseif ConfigSkillType.SKILL_PLAYER == skillType then
    table.insert(self.skills.active, skillId)
  end
end
function PlayerCastDriver:GetRandomSkillIdBySkillType(skillType)
  return nil
end
return PlayerCastDriver
