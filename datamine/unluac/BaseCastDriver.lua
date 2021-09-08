local BaseActionDriver = __Require("battle.objectDriver.BaseActionDriver")
local BaseCastDriver = class("BaseCastDriver", BaseActionDriver)
function BaseCastDriver:ctor(...)
  BaseActionDriver.ctor(self, ...)
  self:Init()
end
function BaseCastDriver:Init()
  self:InitInnateValue()
  self:InitUnitValue()
  self:InitSkills()
end
function BaseCastDriver:InitInnateValue()
  self.skillCastCounter = {}
  self.skillExtra = 1
  self.castingEcho = false
  self.castingSkillId = nil
  self.skillInsideCountdown = {}
  self.skillTriggerInfo = {}
end
function BaseCastDriver:InitUnitValue()
  self.curClickedWeakPointId = nil
  self.hasConnectSkill = false
  self.chantCountdown = nil
  self.castEchoSkillId = {}
end
function BaseCastDriver:CanDoAction(actionTriggerType, skillId)
  if nil ~= self:GetNextEchoSkill() then
    print(">>>>>>>>>>>>>>>>>>> here cast echo skillId : " .. skillId)
    self:SetCastingEcho(true)
    return self:GetNextEchoSkill()
  elseif ActionTriggerType.CD == actionTriggerType then
    return self:CanCastByCD()
  elseif ActionTriggerType.ATTACK == actionTriggerType then
    return self:CanCastByAttack()
  elseif ActionTriggerType.CONNECT == actionTriggerType and nil ~= skillId then
    return self:CanCastBySkillId(skillId)
  else
    return nil
  end
end
function BaseCastDriver:OnActionEnter(skillId)
  BattleUtils.BattleObjectActionLog(self:GetOwner(), "\229\135\134\229\164\135\233\135\138\230\148\190\230\138\128\232\131\189 ->", skillId)
  self:GetOwner():SetState(OState.CASTING)
  self:SetCastingSkillId(skillId)
  self:SetCurClickedWeakPointId(nil)
  self:CostActionResources(skillId)
  self:TriggerEvent(skillId)
end
function BaseCastDriver:OnActionExit()
  self:OnCastExit()
end
function BaseCastDriver:OnActionBreak()
  self:OnCastBreak()
end
function BaseCastDriver:OnActionUpdate(dt)
end
function BaseCastDriver:CanCastByCD()
  for i, skillId in ipairs(self.skills.cd) do
    if true == self:CanCastBySkillId(skillId) then
      return skillId
    end
  end
  return nil
end
function BaseCastDriver:CanCastByAttack()
  if G_BattleLogicMgr:AutoUseFriendConnectSkill() and not self:GetOwner():IsEnemy(true) then
    for i, skillId in ipairs(self.skills.connect) do
      if true == self:CanCastBySkillId(skillId) then
        return skillId
      end
    end
  end
  for i, skillId in ipairs(self.skills.attack) do
    if true == self:CanCastBySkillId(skillId) then
      return skillId
    end
  end
  return nil
end
function BaseCastDriver:CanCastBySkillId(skillId)
  local result = false
  if self:CanSpell() then
    local skillConfig = CommonUtils.GetSkillConf(skillId)
    if nil ~= skillConfig then
      local skillType = checkint(skillConfig.property)
      if ConfigSkillType.SKILL_CONNECT == skillType then
        if not self:CanUseConnectSkillByCardAlive(skillId) then
          return false
        end
        if self:CanCastSkillJudgeByTriggerType(skillId) then
          result = true
        end
      else
        if true == BattleUtils.IsSkillHaveBuffEffectByBuffType(skillId, ConfigBuffType.REVIVE) and false == self:CanCastRevive(skillId) then
          return false
        end
        if true == BattleUtils.IsSkillHaveBuffEffectByBuffType(skillId, ConfigBuffType.BECKON) and false == self:CanCastBeckon(skillId) then
          return false
        end
        if self:CanCastSkillJudgeByTriggerType(skillId) then
          result = true
        end
      end
    end
  end
  return result
end
function BaseCastDriver:CanSpell()
  return self:GetOwner():CanAct() and not self:GetOwner():InAbnormalState(AbnormalState.SILENT) and not self:GetOwner():InAbnormalState(AbnormalState.ENCHANTING) and 2 == self:IsInChanting()
end
function BaseCastDriver:CanCastRevive(skillId)
  local skillConfig = CommonUtils.GetSkillConf(skillId)
  local isEnemy = self:GetOwner():IsEnemy()
  local canReviveCards = BattleExpression.GetDeadFriendlyTargets(isEnemy, checkint(skillConfig.target[tostring(ConfigBuffType.REVIVE)].type), self:GetOwner(), true)
  return #canReviveCards > 0
end
function BaseCastDriver:CanCastBeckon(skillId)
  return G_BattleLogicMgr:CanCreateBeckonFromBuff()
end
function BaseCastDriver:CanCastSkillJudgeByTriggerType(skillId)
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
      local r1 = triggerValue <= self:GetActionTrigger(ActionTriggerType.HP)
      local r2 = true
      local countdown = self:GetActionTrigger(ActionTriggerType.CD, skillId)
      if nil == countdown or not (countdown <= 0) then
        r2 = false
      end
      return r1 and r2
    end,
    [ConfigSkillTriggerType.COST_HP] = function(triggerValue)
      return triggerValue < self:GetOwner():GetMainProperty():GetCurrentHp()
    end,
    [ConfigSkillTriggerType.COST_CHP] = function(triggerValue)
      return true
    end,
    [ConfigSkillTriggerType.COST_OHP] = function(triggerValue)
      return triggerValue < self:GetOwner():GetMainProperty():GetCurHpPercent()
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
function BaseCastDriver:TriggerEvent(skillId)
  local skillConfig = CommonUtils.GetSkillConf(skillId)
  local skillType = checkint(skillConfig.property)
  if ConfigSkillType.SKILL_HALO == skillType then
    self:OnCastEnter(skillId)
  elseif ConfigSkillType.SKILL_CUTIN == skillType then
    self:OnCastEnter(skillId)
  elseif ConfigSkillType.SKILL_CONNECT == skillType then
    self:TriggerConnectSkillEvent(skillId)
  elseif ConfigSkillType.SKILL_WEAK == skillType then
    self:TriggerWeakEvent(skillId)
  else
    self:OnCastEnter(skillId)
  end
end
function BaseCastDriver:TriggerConnectSkillEvent(skillId)
  local otherHeadSkinId = {}
  local connectCardIds = self:GetSkillBySkillId(skillId).connectCardId
  if nil ~= connectCardIds then
    local obj
    for _, cardId in ipairs(connectCardIds) do
      obj = G_BattleLogicMgr:IsObjAliveByCardId(cardId, self:GetOwner():IsEnemy(true))
      if nil ~= obj then
        local skinId = obj:GetObjectSkinId()
        table.insert(otherHeadSkinId, skinId)
      end
    end
  end
  local sceneTag = G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_CI_SCENE)
  local cardId = self:GetOwner():GetObjectConfigId()
  local skinId = self:GetOwner():GetObjectSkinId()
  G_BattleLogicMgr:SetBattleTouchEnable(false)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ShowConnectSkillCIScene", self:GetOwner():GetOTag(), sceneTag, cardId, skinId, otherHeadSkinId, skillId)
  if G_BattleLogicMgr:IsCalculator() then
    G_BattleLogicMgr:AddPlayerOperate2TimeLine("G_BattleLogicMgr", G_BattleLogicMgr:GetFixedAnimtionFrame(ANITIME_CUTIN_SCENE), "ConnectCISceneExit", self:GetOwner():GetOTag(), skillId, sceneTag)
  end
end
function BaseCastDriver:OnConnectSkillCastEnter(skillId)
  self:OnCastEnter(skillId)
  local skillModel = self:GetSkillModelBySkillId(skillId)
  local targets = skillModel:GetTargetPool(targets)
  self:ConnectSkillHighlightStart(skillId, targets)
end
function BaseCastDriver:ConnectSkillHighlightStart(skillId, targets)
  G_BattleLogicMgr:ConnectSkillHighlightEventEnter(skillId, self:GetOwner():GetOTag(), targets)
end
function BaseCastDriver:ConnectSkillHighlightOver(skillId)
  G_BattleLogicMgr:ConnectSkillHighlightEventExit(skillId, self:GetOwner():GetOTag())
end
function BaseCastDriver:TriggerWeakEvent(skillId)
  local skillConfig = CommonUtils.GetSkillConf(skillId)
  local time = checknumber(skillConfig.readingTime or 3)
  local weakPoints = clone(self:GetSkillBySkillId(skillId).weakPoints)
  self:OnChantEnter(skillId, time + 1)
  local sceneTag = G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_CI_SCENE)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ShowWeakSkillScene", self:GetOwner():GetOTag(), self:GetOwner():GetViewModelTag(), sceneTag, skillId, weakPoints, time)
end
function BaseCastDriver:OnCastEnter(skillId)
  local skillConfig = CommonUtils.GetSkillConf(skillId)
  local skillType = checkint(skillConfig.property)
  G_BattleLogicMgr:SendObjEvent(ObjectEvent.OBJECT_CAST_ENTER, {
    tag = self:GetOwner():GetOTag(),
    isEnemy = self:GetOwner():IsEnemy(true),
    skillId = skillId
  })
  self:GetOwner().triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.CAST)
  local castActionTriggerConfig = {
    [ConfigSkillType.SKILL_NORMAL] = ConfigObjectTriggerActionType.CAST_SKILL_NORMAL,
    [ConfigSkillType.SKILL_CUTIN] = ConfigObjectTriggerActionType.CAST_SKILL_CUTIN,
    [ConfigSkillType.SKILL_CONNECT] = ConfigObjectTriggerActionType.CAST_SKILL_CONNECT
  }
  if castActionTriggerConfig[skillType] then
    self:GetOwner().triggerDriver:OnActionEnter(castActionTriggerConfig[skillType])
  end
  local castAnimationConfig = self:GetOwner():GetActionAnimationConfigBySkillId(skillId)
  local castAnimationName = castAnimationConfig.actionName
  if not self:GetOwner():HasAnimationByName(castAnimationName) then
    castAnimationName = sp.AnimationName.skill1
  end
  local actionTimeScale = self:GetOwner():GetAvatarTimeScale(true)
  self:GetOwner():DoAnimation(true, actionTimeScale, castAnimationName, false, sp.AnimationName.idle, true)
  self:GetOwner():RefreshRenderAnimation(true, actionTimeScale, castAnimationName, false, sp.AnimationName.idle, true)
  G_BattleLogicMgr:RenderPlayBattleSoundEffect(castAnimationConfig.actionSE)
  G_BattleLogicMgr:RenderPlayBattleSoundEffect(castAnimationConfig.actionVoice)
  local params = ObjectCastParameterStruct.New(self:GetNextSkillExtra(skillId), 1, nil, cc.p(0, 0), false, self:GetOwner():IsHighlight())
  self:DoCastEnterLogic(skillId, params)
end
function BaseCastDriver:Cast(skillId, percent)
  local bulletOriPosition = self:GetOwner():GetLocation().po
  local boneData = self:GetOwner():FineBoneInBattleRootSpace(sp.CustomName.BULLET_BONE_NAME)
  if boneData then
    bulletOriPosition = cc.p(boneData.worldPosition.x, boneData.worldPosition.y)
  end
  local shouldShakeWorld = false
  if nil ~= self:GetCurClickedWeakPointId() and ConfigWeakPointId.NONE == self:GetCurClickedWeakPointId() then
    shouldShakeWorld = true
  end
  local skillModel = self:GetSkillModelBySkillId(skillId)
  if nil ~= skillModel then
    local params = ObjectCastParameterStruct.New(1, percent, nil, bulletOriPosition, shouldShakeWorld, self:GetOwner():IsHighlight())
    skillModel:Cast(params)
    BattleUtils.BattleObjectActionLog(self:GetOwner(), "here skill cause effect", self:GetCastingSkillId())
  end
  local animationData = self:GetOwner():GetActionAnimationConfigBySkillId(skillId)
  G_BattleLogicMgr:RenderPlayBattleSoundEffect(animationData.actionCauseSE)
end
function BaseCastDriver:OnCastExit()
  local castingSkillId = self:GetCastingSkillId()
  if nil ~= castingSkillId then
    local skillConfig = CommonUtils.GetSkillConf(castingSkillId)
    if G_BattleLogicMgr:IsCardVSCard() then
      if not self:GetOwner():IsEnemy(true) and ConfigSkillType.SKILL_CONNECT == checkint(skillConfig.property) then
        self:ConnectSkillHighlightOver(castingSkillId)
      end
    elseif ConfigSkillType.SKILL_CONNECT == checkint(skillConfig.property) then
      self:ConnectSkillHighlightOver(castingSkillId)
    end
  end
  self:ClearNextSkillExtra()
  self:SetCastingEcho(false)
  self:SetCastingSkillId(nil)
  self:GetOwner():SetState(self:GetOwner():GetState(-1))
  self:GetOwner():SetState(OState.NORMAL, -1)
end
function BaseCastDriver:OnCastBreak()
  self:OnCastExit()
  self:GetOwner():DoAnimation(true, self:GetOwner():GetAvatarTimeScale(), sp.AnimationName.idle, true)
  self:GetOwner():RefreshRenderAnimation(true, self:GetOwner():GetAvatarTimeScale(), sp.AnimationName.idle, true)
end
function BaseCastDriver:OnChantEnter(skillId, time)
  self:SetChantCountdown(time)
  self:SetChantAbnormalStateImmune(true)
  G_BattleLogicMgr:SendObjEvent(ObjectEvent.OBJECT_CHANT_ENTER, {
    tag = self:GetOwner():GetOTag(),
    isEnemy = self:GetOwner():IsEnemy(true),
    skillId = skillId
  })
  self:GetOwner():DoAnimation(true, nil, sp.AnimationName.chant, true)
  self:GetOwner():RefreshRenderAnimation(true, nil, sp.AnimationName.chant, true)
  self:GetOwner().tintDriver:OnActionEnter(BattleObjTintPattern.BOTP_DARK)
end
function BaseCastDriver:SetChantAbnormalStateImmune(immune)
  self:GetOwner():SetObjectAbnormalStateImmune(AbnormalState.SILENT, immune)
  self:GetOwner():SetObjectAbnormalStateImmune(AbnormalState.STUN, immune)
  self:GetOwner():SetObjectAbnormalStateImmune(AbnormalState.FREEZE, immune)
  self:GetOwner():SetObjectAbnormalStateImmune(AbnormalState.ENCHANTING, immune)
end
function BaseCastDriver:OnChantUpdate(dt)
end
function BaseCastDriver:OnChantExit(skillId)
  self:GetOwner().tintDriver:OnActionExit()
  self:SetChantCountdown(nil)
  self:SetChantAbnormalStateImmune(false)
  local monsterType = checkint(self:GetOwner():GetObjectConfig().type)
  if CardUtils.IsMonsterCard(self:GetOwner():GetObjectConfigId()) and ConfigMonsterType.BOSS == monsterType then
    local weakPointEffectId = self:GetCurClickedWeakPointId()
    if ConfigWeakPointId.HALF_EFFECT == weakPointEffectId then
      self:OnCastEnter(skillId)
    else
      local sceneTag = G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_CI_SCENE)
      local mainSkinId = self:GetOwner():GetObjectSkinId()
      G_BattleLogicMgr:SetBattleTouchEnable(false)
      G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ShowBossCIScene", self:GetOwner():GetOTag(), sceneTag, skillId, mainSkinId)
    end
  else
    self:OnCastEnter(skillId)
  end
end
function BaseCastDriver:OnChantBreak()
  self:SetChantCountdown(nil)
  self:SetChantAbnormalStateImmune(false)
  self:GetOwner():DoAnimation(true, nil, sp.AnimationName.attacked, false, sp.AnimationName.idle, true)
  self:GetOwner():RefreshRenderAnimation(true, nil, sp.AnimationName.attacked, false, sp.AnimationName.idle, true)
  self:GetOwner().tintDriver:OnActionExit()
  self:OnCastExit()
end
function BaseCastDriver:ChantClickHandler(skillId, data)
  if false == data.result then
    self:SetCurClickedWeakPointId(ConfigWeakPointId.NONE)
    self:OnChantExit(data.skillId)
  else
    local effectId, effectValue = self:GetOwner().randomDriver:RandomWeakEffect(checkint(data.skillId), self:GetWeakPointsConfigBySkillId(data.skillId), checkint(data.result))
    self:SetCurClickedWeakPointId(effectId)
    self:SetChantCountdown(data.leftTime)
    if ConfigWeakPointId.BREAK == effectId then
      self:OnChantBreak()
    elseif ConfigWeakPointId.HALF_EFFECT == effectId then
      self:SetSkillExtra(effectValue)
    elseif ConfigWeakPointId.NONE == effectId then
    end
    G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ShowObjectWeakHint", self:GetOwner():GetViewModelTag(), effectId)
  end
end
function BaseCastDriver:GetChantCountdown()
  return self.chantCountdown
end
function BaseCastDriver:SetChantCountdown(countdown)
  self.chantCountdown = countdown
end
function BaseCastDriver:IsInChanting()
  local chantCountdown = self:GetChantCountdown()
  if OState.CASTING == self:GetOwner():GetState() and nil ~= chantCountdown then
    if chantCountdown > 0 then
      return 1
    else
      return 0
    end
  else
    return 2
  end
end
function BaseCastDriver:CastAllHalos()
  local params = ObjectCastParameterStruct.New(1, 1, nil, cc.p(0, 0), false, false)
  for i, skillId in ipairs(self.skills.halo) do
    self:DoCastEnterLogic(skillId, params)
  end
end
function BaseCastDriver:DoCastEnterLogic(skillId, params)
  local skillModel = self:GetSkillModelBySkillId(skillId)
  if nil ~= skillModel then
    print([[

**************
]], "\tcast skill (BaseCastDriver:DoCastEnterLogic) -> ", skillId, [[

**************
]])
    skillModel:CastBegin(params)
  else
    BattleUtils.PrintBattleWaringLog("cast a not exist skill -> skillId : " .. skillId)
  end
end
function BaseCastDriver:UpdateActionTrigger(actionTriggerType, delta)
  if ActionTriggerType.CD == actionTriggerType then
    for k, v in pairs(self.actionTrigger[ActionTriggerType.CD]) do
      self.actionTrigger[ActionTriggerType.CD][k] = math.max(0, v - delta)
    end
    self:UpdateAllSkillsInsideCD(delta)
    if nil ~= self.chantCountdown then
      self.chantCountdown = math.max(0, self.chantCountdown - delta)
    end
  elseif ActionTriggerType.HP == actionTriggerType then
    self.actionTrigger[ActionTriggerType.HP] = 1 - delta
  end
end
function BaseCastDriver:CostActionResources(skillId)
  if self:GetCastingEcho() then
    self:RemoveNextEchoSkill()
  else
    local skillConfig = CommonUtils.GetSkillConf(skillId)
    self:SetSkillInsideCD(skillId, checknumber(skillConfig.insideCd))
    local skillTriggerInfo = self:GetSkillTriggerInfoBySkillId(skillId)
    if nil ~= skillTriggerInfo[ConfigSkillTriggerType.ENERGY] then
      self:GetOwner():AddEnergy(math.min(0, -1 * skillTriggerInfo[ConfigSkillTriggerType.ENERGY]))
    end
    if nil ~= skillTriggerInfo[ConfigSkillTriggerType.CD] then
      self:SetActionTrigger(ActionTriggerType.CD, skillId, skillTriggerInfo[ConfigSkillTriggerType.CD])
    end
    if nil ~= skillTriggerInfo[ConfigSkillTriggerType.COST_HP] then
      local selfTag = self:GetOwner():GetOTag()
      local damage = skillTriggerInfo[ConfigSkillTriggerType.COST_HP]
      local damageData = ObjectDamageStruct.New(selfTag, damage, DamageType.ATTACK_PHYSICAL, false, {attackerTag = selfTag})
      self:GetOwner():HpChange(damageData)
    end
    if nil ~= skillTriggerInfo[ConfigSkillTriggerType.COST_CHP] then
      local selfTag = self:GetOwner():GetOTag()
      local damage = skillTriggerInfo[ConfigSkillTriggerType.COST_CHP] * self:GetOwner():GetMainProperty():GetCurrentHp()
      local damageData = ObjectDamageStruct.New(selfTag, damage, DamageType.ATTACK_PHYSICAL, false, {attackerTag = selfTag})
      self:GetOwner():HpChange(damageData)
    end
    if nil ~= skillTriggerInfo[ConfigSkillTriggerType.COST_OHP] then
      local selfTag = self:GetOwner():GetOTag()
      local damage = skillTriggerInfo[ConfigSkillTriggerType.COST_OHP] * self:GetOwner():GetMainProperty():GetOriginalHp()
      local damageData = ObjectDamageStruct.New(selfTag, damage, DamageType.ATTACK_PHYSICAL, false, {attackerTag = selfTag})
      self:GetOwner():HpChange(damageData)
    end
  end
  self:AddSkillCastCounter(skillId)
end
function BaseCastDriver:ResetActionTrigger()
  self.chantCountdown = nil
end
function BaseCastDriver:GetActionTrigger(actionTriggerType, skillId)
  if nil ~= self.actionTrigger[actionTriggerType] and nil ~= skillId then
    return self.actionTrigger[actionTriggerType][tostring(skillId)]
  elseif nil ~= actionTriggerType then
    return self.actionTrigger[actionTriggerType]
  end
  return nil
end
function BaseCastDriver:SetActionTrigger(actionTriggerType, skillId, value)
  if nil ~= self.actionTrigger[actionTriggerType] and nil ~= skillId then
    self.actionTrigger[actionTriggerType][tostring(skillId)] = value
  end
  return nil
end
function BaseCastDriver:SetSkillInsideCD(skillId, cd)
  self.skillInsideCountdown[tostring(skillId)] = cd
end
function BaseCastDriver:GetSkillInsideCD(skillId)
  return self.skillInsideCountdown[tostring(skillId)]
end
function BaseCastDriver:UpdateAllSkillsInsideCD(delta)
  for k, v in pairs(self.skillInsideCountdown) do
    self.skillInsideCountdown[k] = math.max(0, v - delta)
  end
end
function BaseCastDriver:SpineAnimationEventHandler(event)
end
function BaseCastDriver:SpineCustomEventHandler(event)
end
function BaseCastDriver:HasConnectSkill()
  return self.hasConnectSkill
end
function BaseCastDriver:GetConnectSkills()
  return self.skills.equipedConnect
end
function BaseCastDriver:GetSkillBySkillId(skillId)
  return self.skills[tostring(skillId)]
end
function BaseCastDriver:SetSkillBySkillId(skillId, skill)
  self.skills[tostring(skillId)] = skill
end
function BaseCastDriver:GetSkillStructBySkillId(skillId)
  return self.skills[tostring(skillId)]
end
function BaseCastDriver:SetSkillStructBySkillId(skillId, skillStruct)
  self.skills[tostring(skillId)] = skillStruct
end
function BaseCastDriver:GetSkillModelBySkillId(skillId)
  if nil ~= self:GetSkillStructBySkillId(skillId) then
    return self:GetSkillStructBySkillId(skillId).skill
  else
    return nil
  end
end
function BaseCastDriver:InitSkills()
  local cardConfig = self:GetOwner():GetObjectConfig()
  self.actionTrigger = {
    [ActionTriggerType.CD] = {},
    [ActionTriggerType.HP] = 0
  }
  self.skills = {
    attack = {},
    cd = {},
    halo = {},
    connect = {},
    equipedConnect = {}
  }
  self.innerSkillChangeRule = {
    connect2ci = {}
  }
  self.skillChargeCounter = {}
  self.connectSkillChargeCounter = {}
  local skillId, skillConfig
  local effect = CardUtils.GetCardEffectConfigBySkinId(self:GetOwner():GetObjectConfigId(), self:GetOwner():GetObjectSkinId())
  for _, skillId_ in ipairs(cardConfig.skill) do
    skillId = checkint(skillId_)
    local skillLevel = 1
    if nil ~= self:GetOwner():GetObjInfo().skillData and nil ~= self:GetOwner():GetObjInfo().skillData[tostring(skillId)] then
      skillLevel = checkint(self:GetOwner():GetObjInfo().skillData[tostring(skillId)].level)
    end
    skillConfig = CommonUtils.GetSkillConf(skillId)
    if nil == skillConfig then
      BattleUtils.PrintConfigLogicError("cannot find skill config in BaseCastDriver -> InitSkills : " .. tostring(skillId))
    else
      self:AddASkill(skillId, skillLevel)
    end
  end
  if 0 < #self.skills.connect then
    local connectSkillId
    for i = #self.skills.connect, 1, -1 do
      connectSkillId = self.skills.connect[i]
      break
    end
    local ciSkillId
    for i = #self.skills.attack, 1, -1 do
      local skillId = self.skills.attack[i]
      if ConfigSkillType.SKILL_CUTIN == checkint(CommonUtils.GetSkillConf(skillId).property) then
        ciSkillId = skillId
        table.remove(self.skills.attack, i)
        break
      end
    end
    local connect2ciData = {connectSkillId = connectSkillId, ciSkillId = ciSkillId}
    self.innerSkillChangeRule.connect2ci = connect2ciData
  end
end
function BaseCastDriver:InnerChangeConnectSkill(enableConnectSkill)
  if enableConnectSkill then
    local connectSkillId = checkint(self.innerSkillChangeRule.connect2ci.connectSkillId)
    if 0 ~= connectSkillId then
      do
        local isSkillExist = false
        for i = #self.skills.connect, 1, -1 do
          if connectSkillId == self.skills.connect[i] then
            isSkillExist = true
            break
          end
        end
        if not isSkillExist then
          table.insert(self.skills.connect, connectSkillId)
        end
      end
    else
    end
    local ciSkillId = checkint(self.innerSkillChangeRule.connect2ci.ciSkillId)
    if 0 ~= ciSkillId then
      isSkillExist = false
      for i = #self.skills.attack, 1, -1 do
        if ciSkillId == self.skills.attack[i] then
          isSkillExist = true
          table.remove(self.skills.attack, i)
          break
        end
      end
      if not isSkillExist then
      end
    end
  else
    local connectSkillId = checkint(self.innerSkillChangeRule.connect2ci.connectSkillId)
    if 0 ~= connectSkillId then
      local isSkillExist = false
      for i = #self.skills.connect, 1, -1 do
        if connectSkillId == self.skills.connect[i] then
          isSkillExist = true
          table.remove(self.skills.connect, i)
          break
        end
      end
      if not isSkillExist then
      end
    end
    local ciSkillId = checkint(self.innerSkillChangeRule.connect2ci.ciSkillId)
    if 0 ~= ciSkillId then
      isSkillExist = false
      for i = #self.skills.attack, 1, -1 do
        if ciSkillId == self.skills.attack[i] then
          isSkillExist = true
          break
        end
      end
      if not isSkillExist then
        table.insert(self.skills.attack, ciSkillId)
      end
    else
    end
  end
end
function BaseCastDriver:AddSkillsBySkillData(skillData)
  print("here check fuck add outer skills", self:GetOwner():GetObjectName())
  dump(skillData)
  for _, v in ipairs(skillData) do
    self:AddASkill(checkint(v.skillId), checkint(v.level))
  end
end
function BaseCastDriver:AddASkill(skillId, level)
  local skillConfig = CommonUtils.GetSkillConf(skillId)
  if nil == skillConfig then
    BattleUtils.PrintConfigLogicError("cannot find skill config in BaseCastDriver -> InitSkills : " .. tostring(skillId))
    return
  end
  if not self:CanInitSkillBySkillId(checkint(skillId)) then
    return
  end
  local skillClassPath = "battle.skill.ObjSkill"
  local isSkillEnable = true
  local skillType = checkint(skillConfig.property)
  local extraInfo = {}
  local triggerInfo = {}
  for triggerType, triggerValue in pairs(skillConfig.triggerType) do
    triggerInfo[checkint(triggerType)] = checknumber(triggerValue)
  end
  self:SetSkillTriggerInfoBySkillId(skillId, triggerInfo)
  if nil ~= triggerInfo[ConfigSkillTriggerType.CD] then
    table.insert(self.skills.cd, skillId)
    self.actionTrigger[ActionTriggerType.CD][tostring(skillId)] = triggerInfo[ConfigSkillTriggerType.CD]
  end
  if ConfigSkillType.SKILL_NORMAL == skillType then
    table.insert(self.skills.attack, skillId)
  elseif ConfigSkillType.SKILL_HALO == skillType then
    table.insert(self.skills.halo, skillId)
    skillClassPath = "battle.skill.HaloSkill"
  elseif ConfigSkillType.SKILL_CUTIN == skillType then
    table.insert(self.skills.attack, skillId)
  elseif ConfigSkillType.SKILL_CONNECT == skillType and G_BattleLogicMgr:CanUseFriendConnectSkill() then
    local canCastConnect = true
    if G_BattleLogicMgr:IsCardVSCard() and self:GetOwner():IsEnemy(true) then
      canCastConnect = false
      isSkillEnable = false
    else
      local cardConfig = self:GetOwner():GetObjectConfig()
      if nil ~= cardConfig then
        for _, connectCardId in ipairs(cardConfig.concertSkill) do
          if false == G_BattleLogicMgr:IsCardInTeam(connectCardId, self:GetOwner():IsEnemy(true)) then
            isSkillEnable = false
            canCastConnect = false
            break
          else
            if nil == extraInfo.connectCardId then
              extraInfo.connectCardId = {}
            end
            table.insert(extraInfo.connectCardId, checkint(connectCardId))
          end
        end
        if canCastConnect then
          table.insert(self.skills.connect, skillId)
          table.insert(self.skills.equipedConnect, skillId)
          self.connectSkillChargeCounter[tostring(skillId)] = 0
        end
      end
    end
  elseif ConfigSkillType.SKILL_WEAK == skillType then
    table.insert(self.skills.attack, skillId)
    extraInfo.weakPoints = {}
    for i, v in ipairs(skillConfig.weaknessEffect) do
      local effectId = checkint(v[1])
      local effectValue = checknumber(v[2])
      local weakPoint = {
        id = i,
        effectId = effectId,
        effectValue = effectValue
      }
      table.insert(extraInfo.weakPoints, weakPoint)
    end
  end
  if isSkillEnable then
    self:SetSkillInsideCD(skillId, 0)
    local effect = CardUtils.GetCardEffectConfigBySkinId(self:GetOwner():GetObjectConfigId(), self:GetOwner():GetObjectSkinId())
    local spineActionData = BSCUtils.GetSkillSpineEffectStruct(skillId, effect, G_BattleLogicMgr:GetCurrentWave())
    self:GetOwner():SetActionAnimationConfigBySkillId(skillId, spineActionData)
    local skillBaseData = SkillConstructorStruct.New(skillId, level, BattleUtils.GetSkillInfoStructBySkillId(skillId, level), self:GetOwner():IsEnemy(true), self:GetOwner():GetOTag(), spineActionData)
    local skill = __Require(skillClassPath).new(skillBaseData)
    local skillInfo = ObjectSkillStruct.New(skillId, skill, extraInfo)
    self:SetSkillStructBySkillId(skillId, skillInfo)
  end
end
function BaseCastDriver:GetWeakPointsConfigBySkillId(skillId)
  return self:GetSkillStructBySkillId(skillId).weakPoints
end
function BaseCastDriver:CanUseConnectSkillByCardAlive(skillId)
  for i, v in ipairs(self:GetSkillStructBySkillId(skillId).connectCardId) do
    if nil == G_BattleLogicMgr:IsObjAliveByCardId(v, self:GetOwner():IsEnemy(true)) then
      return false
    end
  end
  return true
end
function BaseCastDriver:GetSkillTriggerInfoBySkillId(skillId)
  return self.skillTriggerInfo[tostring(skillId)]
end
function BaseCastDriver:SetSkillTriggerInfoBySkillId(skillId, triggerInfo)
  if nil == self:GetSkillTriggerInfoBySkillId(skillId) then
    self.skillTriggerInfo[tostring(skillId)] = triggerInfo
  end
end
function BaseCastDriver:AddSkillTriggerInfo(skillId, triggerInfoList)
  local skillTriggerInfo = self:GetSkillTriggerInfoBySkillId(skillId)
  if nil ~= skillTriggerInfo then
    for i, v in ipairs(triggerInfoList) do
      if nil == skillTriggerInfo[v.triggerType] then
        skillTriggerInfo[v.triggerType] = 0
      end
      skillTriggerInfo[v.triggerType] = skillTriggerInfo[v.triggerType] + v.triggerValue
    end
  end
end
function BaseCastDriver:RemoveSkillTriggerInfo(skillId, triggerInfoList)
  local skillTriggerInfo = self:GetSkillTriggerInfoBySkillId(skillId)
  if nil ~= skillTriggerInfo then
    for i, v in ipairs(triggerInfoList) do
      if nil ~= skillTriggerInfo[v.triggerType] then
        skillTriggerInfo[v.triggerType] = skillTriggerInfo[v.triggerType] - v.triggerValue
      end
    end
  end
end
function BaseCastDriver:GetSkillCastCounter(skillId)
  if nil == skillId then
    return self.skillCastCounter
  else
    return self.skillCastCounter[tostring(skillId)] or 0
  end
end
function BaseCastDriver:AddSkillCastCounter(skillId, delta)
  if nil == self.skillCastCounter[tostring(skillId)] then
    self.skillCastCounter[tostring(skillId)] = 0
  end
  self.skillCastCounter[tostring(skillId)] = self.skillCastCounter[tostring(skillId)] + (delta or 1)
end
function BaseCastDriver:GetNextSkillExtra(skillId)
  local skillConfig = CommonUtils.GetSkillConf(skillId)
  local skillType = checkint(skillConfig.property)
  local value = 0
  local buffTypes = {
    ConfigBuffType.ENHANCE_NEXT_SKILL
  }
  for i, buffType in ipairs(buffTypes) do
    local targetBuffs = self:GetOwner():GetBuffsByBuffType(buffType, false)
    for i = #targetBuffs, 1, -1 do
      value = value + targetBuffs[i]:OnCauseEffectEnter(skillType)
    end
  end
  return math.max(0, self:GetSkillExtra() + value)
end
function BaseCastDriver:ClearNextSkillExtra()
  self:SetSkillExtra(1)
end
function BaseCastDriver:GetSkillExtra()
  return self.skillExtra
end
function BaseCastDriver:SetSkillExtra(value)
  self.skillExtra = value
end
function BaseCastDriver:AddAEchoSkill(skillId)
  table.insert(self.castEchoSkillId, 1, skillId)
end
function BaseCastDriver:GetNextEchoSkill()
  return self.castEchoSkillId[#self.castEchoSkillId]
end
function BaseCastDriver:RemoveNextEchoSkill()
  if next(self.castEchoSkillId) then
    table.remove(self.castEchoSkillId, #self.castEchoSkillId)
  end
end
function BaseCastDriver:GetRandomSkillIdBySkillType(skillType)
  local skillConfig
  local cardConf = self:GetOwner():getObjectConfig()
  for _, skillId in ipairs(cardConf.skill) do
    skillConfig = CommonUtils.GetSkillConf(checkint(skillId))
    if nil ~= skillConfig and skillType == checkint(skillConfig.property) and nil ~= self:GetSkillStructBySkillId(skillId) then
      return checkint(skillId)
    end
  end
  return nil
end
function BaseCastDriver:GetCastingEcho()
  return self.castingEcho
end
function BaseCastDriver:SetCastingEcho(b)
  self.castingEcho = b
end
function BaseCastDriver:SetCastingSkillId(skillId)
  self.castingSkillId = skillId
end
function BaseCastDriver:GetCastingSkillId()
  return self.castingSkillId
end
function BaseCastDriver:SetCurClickedWeakPointId(id)
  self.curClickedWeakPointId = id
end
function BaseCastDriver:GetCurClickedWeakPointId()
  return self.curClickedWeakPointId
end
function BaseCastDriver:HasSkillBySkillId(skillId)
  return nil ~= self:GetSkillStructBySkillId(skillId)
end
function BaseCastDriver:CanInitSkillBySkillId(skillId)
  local result = false
  local skillConfig = CommonUtils.GetSkillConf(skillId)
  if nil ~= skillConfig and nil ~= skillConfig.battleType then
    for _, battleType in ipairs(skillConfig.battleType) do
      if QuestBattleType.ALL == checkint(battleType) then
        result = true
        break
      elseif G_BattleLogicMgr:GetQuestBattleType() == checkint(battleType) then
        result = true
        break
      end
    end
  else
    return true
  end
  return result
end
return BaseCastDriver
