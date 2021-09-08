local BaseObjectModel = __Require("battle.object.logicModel.objectModel.BaseObjectModel")
local CardObjectModel = class("CardObjectModel", BaseObjectModel)
function CardObjectModel:ctor(...)
  BaseObjectModel.ctor(self, ...)
end
function CardObjectModel:Init()
  BaseObjectModel.Init(self)
  self:RegisterObjectEventHandler()
end
function CardObjectModel:InitValue()
  BaseObjectModel.InitValue(self)
end
function CardObjectModel:InitInnateProperty()
  BaseObjectModel.InitInnateProperty(self)
end
function CardObjectModel:InitUnitProperty()
  self.location = ObjectLocation.New(self:GetObjInfo().oriLocation.po.x, self:GetObjInfo().oriLocation.po.y, self:GetObjInfo().oriLocation.po.r, self:GetObjInfo().oriLocation.po.c)
  self.zorderInBattle = 0
  self:InitEnergy()
  self:GetMainProperty():UpdateCurHpPercent()
  self.hate = checkint(self:GetObjectConfig().threat or 0)
end
function CardObjectModel:InitActionAnimationConfig()
  BaseObjectModel.InitActionAnimationConfig(self)
  local effect = self:GetObjectEffectConfig()
  local attackAnimationConfig = BSCUtils.GetSkillSpineEffectStruct(ATTACK_2_SKILL_ID, effect, G_BattleLogicMgr:GetCurrentWave())
  self:SetActionAnimationConfigBySkillId(ATTACK_2_SKILL_ID, attackAnimationConfig)
end
function CardObjectModel:InitViewModel()
  local skinId = self:GetObjectSkinId()
  local skinConfig = CardUtils.GetCardSkinConfig(skinId)
  local spineDataStruct = BattleUtils.GetAvatarSpineDataStructBySpineId(skinConfig.spineId, G_BattleLogicMgr:GetSpineAvatarScaleByCardId(self:GetObjectConfigId()))
  local viewModel = __Require("battle.viewModel.SpineViewModel").new(ObjectViewModelConstructorStruct.New(G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_VIEW_MODEL), self:GetOTag(), self:GetObjInfo().avatarScale, spineDataStruct))
  self:SetViewModel(viewModel)
  self:RegistViewModelEventHandler()
  viewModel:Awake()
  self:ChangePosition(self:GetObjInfo().oriLocation.po)
  if self:IsEnemy(true) then
    self:SetOrientation(BattleObjTowards.NEGTIVE)
  else
    self:SetOrientation(BattleObjTowards.FORWARD)
  end
end
function CardObjectModel:InitDrivers()
  self.randomDriver = __Require("battle.object.RandomDriver").new({
    ownerTag = self:GetOTag()
  })
  local attackDriverClassName = "BaseAttackDriver"
  local moveDriverClassName = "BaseMoveDriver"
  local objectFeature = self:GetObjectFeature()
  if BattleObjectFeature.REMOTE == objectFeature then
    attackDriverClassName = "RemoteAttackDriver"
    moveDriverClassName = "RemoteMoveDriver"
  elseif BattleObjectFeature.HEALER == objectFeature then
    attackDriverClassName = "HealAttackDriver"
    moveDriverClassName = "RemoteMoveDriver"
  end
  self.attackDriver = __Require(string.format("battle.objectDriver.attackDriver.%s", attackDriverClassName)).new({owner = self})
  self.moveDriver = __Require(string.format("battle.objectDriver.moveDriver.%s", moveDriverClassName)).new({owner = self})
  self.castDriver = __Require("battle.objectDriver.castDriver.BaseCastDriver").new({owner = self})
  self.infectDriver = __Require("battle.objectDriver.castDriver.BaseInfectDriver").new({owner = self})
  self.triggerDriver = __Require("battle.objectDriver.castDriver.BaseTriggerDriver").new({owner = self})
  self.phaseDriver = nil
  if nil ~= self:GetObjInfo().phaseChangeData then
    self.phaseDriver = __Require("battle.objectDriver.performanceDriver.BasePhaseDriver").new({
      owner = self,
      phaseChangeData = self:GetObjInfo().phaseChangeData
    })
  end
  self:GetObjInfo().phaseChangeData = nil
  self.tintDriver = __Require("battle.objectDriver.performanceDriver.BaseTintDriver").new({owner = self})
  self.artifactTalentDriver = __Require("battle.objectDriver.castDriver.BaseArtifactTalentDriver").new({
    owner = self,
    talentData = self:GetObjInfo().talentData
  })
  self.exAbilityDriver = __Require("battle.objectDriver.performanceDriver.BaseEXAbilityDriver").new({
    owner = self,
    exAbilityData = self:GetObjInfo().exAbilityData
  })
  self.buffDriver = __Require("battle.objectDriver.buffDriver.BaseBuffDriver").new({owner = self})
  self:ActivateDrivers()
end
function CardObjectModel:ActivateDrivers()
  self.artifactTalentDriver:OnActionEnter()
end
function CardObjectModel:InitInnerBuffImmune()
  local cardConfig = self:GetObjectConfig()
  if nil ~= cardConfig and nil ~= cardConfig.immunitySkillProperty then
    self:GetObjectExtraStateInfo():InitInnerBuffImmune(cardConfig.immunitySkillProperty)
  end
end
function CardObjectModel:InitWeatherImmune()
  local cardConfig = self:GetObjectConfig()
  if nil ~= cardConfig and nil ~= cardConfig.weatherProperty then
    self:GetObjectExtraStateInfo():InitWeatherImmune(cardConfig.weatherProperty)
  end
end
function CardObjectModel:InitEnergy()
  self.energy = self:GetMainProperty():CalcFixedInitEnergy(self:GetObjInfo().isLeader)
  self.energyRecoverRate = 0
end
function CardObjectModel:AwakeObject()
  self:SetState(OState.NORMAL)
  self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.OBJECT_AWAKE)
end
function CardObjectModel:PauseLogic()
  BaseObjectModel.PauseLogic(self)
  local timeScale = self:GetAvatarTimeScale()
  self:SetAnimationTimeScale(timeScale)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "PauseAObjectView", self:GetViewModelTag(), timeScale)
end
function CardObjectModel:ResumeLogic()
  BaseObjectModel.ResumeLogic(self)
  local timeScale = self:GetAvatarTimeScale()
  self:SetAnimationTimeScale(timeScale)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ResumeAObjectView", self:GetViewModelTag(), timeScale)
end
function CardObjectModel:IsAlive()
  return OState.DIE ~= self:GetState()
end
function CardObjectModel:SetObjectAbnormalState(abnormalState, b)
  BaseObjectModel.SetObjectAbnormalState(self, abnormalState, b)
  self:RefreshConnectButtonsByState()
end
function CardObjectModel:BreakCurrentAction()
  if OState.CASTING == self:GetState() then
    self.castDriver:OnActionBreak()
  elseif OState.ATTACKING == self:GetState() then
    self.attackDriver:OnActionBreak()
  elseif OState.VIEW_TRANSFORM == self:GetState() and nil ~= self.exAbilityDriver then
    self.exAbilityDriver:OnViewTransformBreak()
  end
end
function CardObjectModel:Update(dt)
  if self:IsPause() then
    return
  end
  local needReturnUpdate = self:DieJudge()
  if needReturnUpdate then
    return
  end
  self:UpdateCountdown(dt)
  self:UpdateDrivers(dt)
  self:UpdateBuffs(dt)
  self:AutoController(dt)
end
function CardObjectModel:DieJudge()
  local needReturnUpdate = false
  if self:CanDie() then
    if nil ~= self.phaseDriver then
      local diePhaseChangeCounter = self.phaseDriver:GetDiePhaseChangeCounter()
      if nil == diePhaseChangeCounter then
        self.phaseDriver:UpdateActionTrigger(ActionTriggerType.DIE, true)
        local canChangePhaseIndexs = self.phaseDriver:CanDoActionWhenDie()
        self.phaseDriver:SetDiePhaseChangeCounter(#canChangePhaseIndexs)
        local pcdata
        for i, canChangePhaseIndex in ipairs(canChangePhaseIndexs) do
          pcdata = self.phaseDriver:GetPCDataByIndex(canChangePhaseIndex)
          local phaseChangeInfo = ObjectPhaseSturct.New(self:GetOTag(), pcdata.phaseId, canChangePhaseIndex, true, pcdata.phaseTriggerDelayTime)
          local needPauselLogic = self.phaseDriver:NeedToPauseMainLogic(pcdata.phaseType)
          G_BattleLogicMgr:AddAPhaseChange(needPauselLogic, phaseChangeInfo)
          self.phaseDriver:CostActionResources(canChangePhaseIndex)
        end
        return true
      elseif diePhaseChangeCounter > 0 then
        return true
      end
    end
    self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.DEAD)
    self:DieBegin()
    needReturnUpdate = true
  end
  return needReturnUpdate
end
function CardObjectModel:UpdateCountdown(dt)
  for k, v in pairs(self.countdowns) do
    self.countdowns[k] = math.max(v - dt, 0)
  end
  if 0 >= self.countdowns.energy then
    self.countdowns.energy = 1
    self:AddEnergy(self:GetEnergyRecoverRatePerS())
  end
end
function CardObjectModel:UpdateDrivers(dt)
  self.tintDriver:OnActionUpdate(dt)
  self.infectDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)
  self.attackDriver:UpdateActionTrigger(dt)
  self.castDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)
  self.buffDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)
  if self.phaseDriver then
    self.phaseDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)
    local canChangePhaseIndex = self.phaseDriver:CanDoAction()
    if nil ~= canChangePhaseIndex then
      local pcdata = self.phaseDriver:GetPCDataByIndex(canChangePhaseIndex)
      local phaseChangeInfo = ObjectPhaseSturct.New(self:GetOTag(), pcdata.phaseId, canChangePhaseIndex, false, pcdata.phaseTriggerDelayTime)
      local needPauselLogic = self.phaseDriver:NeedToPauseMainLogic(pcdata.phaseType)
      G_BattleLogicMgr:AddAPhaseChange(needPauselLogic, phaseChangeInfo)
      self.phaseDriver:CostActionResources(canChangePhaseIndex)
    end
  end
end
function CardObjectModel:UpdateBuffs(dt)
  for i = #self.halos.idx, 1, -1 do
    self.halos.idx[i]:OnBuffUpdateEnter(dt)
  end
  for i = #self.buffs.idx, 1, -1 do
    self.buffs.idx[i]:OnBuffUpdateEnter(dt)
  end
end
function CardObjectModel:AutoController(dt)
  if not self:CanAct() then
    return
  end
  if OState.NORMAL == self:GetState() then
    BattleUtils.BattleObjectActionLog(self, "\230\173\163\229\184\184\231\138\182\230\128\129 \229\188\128\229\167\139\231\180\162\230\149\140")
    self:SeekAttakTarget()
  elseif OState.BATTLE == self:GetState() then
    BattleUtils.BattleObjectActionLog(self, "\230\136\152\230\150\151\231\138\182\230\128\129 \232\191\155\228\184\128\230\173\165\233\128\187\232\190\145")
    self:Battle(dt)
  elseif OState.MOVING == self:GetState() then
    if self.attackDriver:CanAttackByDistance(self.attackDriver:GetAttackTargetTag()) then
      BattleUtils.BattleObjectActionLog(self, "\231\167\187\229\138\168\229\136\176\228\189\141 \231\187\147\230\157\159\231\167\187\229\138\168\231\138\182\230\128\129")
      self.moveDriver:OnActionExit()
    else
      BattleUtils.BattleObjectActionLog(self, "\231\167\187\229\138\168\228\184\173.....")
      self:Move(dt, self.attackDriver:GetAttackTargetTag())
    end
  elseif OState.MOVE_BACK == self:GetState() then
    self.moveDriver:OnMoveBackUpdate(dt)
  elseif OState.MOVE_FORCE == self:GetState() then
    self.moveDriver:OnForceMoveUpdate(dt)
  elseif 0 == self.castDriver:IsInChanting() then
    self.castDriver:OnChantExit(self.castDriver:GetCastingSkillId())
  else
    BattleUtils.BattleObjectActionLog(self, "\229\133\182\228\187\150\231\138\182\230\128\129 \231\173\137\229\190\133\232\191\155\228\184\128\230\173\165\229\164\132\231\144\134", self:GetState())
  end
end
function CardObjectModel:Battle(dt)
  local canCastSkillId
  canCastSkillId = self.castDriver:CanDoAction(ActionTriggerType.CD)
  if nil ~= canCastSkillId then
    BattleUtils.BattleObjectActionLog(self, "\229\175\187\230\137\190\229\136\176\228\186\134cd\229\135\134\229\164\135\229\174\140\230\136\144\231\154\132\230\138\128\232\131\189 \229\135\134\229\164\135 [\233\135\138\230\148\190\230\138\128\232\131\189] ", canCastSkillId)
    self:Cast(canCastSkillId)
  else
    local attackTargetTag = self.attackDriver:GetAttackTargetTag()
    if nil == G_BattleLogicMgr:IsObjAliveByTag(attackTargetTag) then
      BattleUtils.BattleObjectActionLog(self, "\228\185\139\229\137\141\231\154\132\230\148\187\229\135\187\229\175\185\232\177\161\229\164\177\230\149\136 \229\176\157\232\175\149\233\135\141\230\150\176 [\229\175\187\230\137\190\230\148\187\229\135\187\229\175\185\232\177\161] ")
      self:SetState(OState.NORMAL)
      self:SeekAttakTarget()
    else
      local canAttack = self.attackDriver:CanAttackByDistance(attackTargetTag)
      if true == canAttack then
        canAttack = self.attackDriver:CanDoAction()
        if true == canAttack then
          canCastSkillId = self.castDriver:CanDoAction(ActionTriggerType.ATTACK)
          if nil ~= canCastSkillId then
            BattleUtils.BattleObjectActionLog(self, "\230\187\161\232\182\179\230\148\187\229\135\187\229\136\164\229\174\154 \228\189\134\230\152\175\232\167\166\229\143\145\228\186\134\230\148\187\229\135\187\230\138\128\232\131\189 \229\135\134\229\164\135 [\233\135\138\230\148\190\230\148\187\229\135\187\230\138\128\232\131\189] ")
            self:Cast(canCastSkillId)
          else
            BattleUtils.BattleObjectActionLog(self, "\230\187\161\232\182\179\230\148\187\229\135\187\229\136\164\229\174\154 \229\135\134\229\164\135\232\191\155\232\161\140 [\230\153\174\233\128\154\230\148\187\229\135\187] ", attackTargetTag)
            self:Attack(attackTargetTag)
          end
        end
      else
        BattleUtils.BattleObjectActionLog(self, "\230\148\187\229\135\187\231\155\174\230\160\135\232\191\152\230\156\170\232\191\155\229\133\165\230\148\187\229\135\187\229\176\132\231\168\139\229\134\133.......\229\135\134\229\164\135\229\188\128\229\167\139 [\231\167\187\229\138\168] ", attackTargetTag)
        self.moveDriver:OnActionEnter(attackTargetTag)
      end
    end
  end
end
function CardObjectModel:SeekAttakTarget()
  self.attackDriver:SeekAttackTarget()
end
function CardObjectModel:LostAttackTarget()
  self.attackDriver:LostAttackTarget()
end
function CardObjectModel:GetAttackRange()
  return self:GetMainProperty():GetCurrentAttackRange()
end
function CardObjectModel:Attack(targetTag)
  self.attackDriver:OnActionEnter(targetTag)
end
function CardObjectModel:GetMoveSpeed()
  return self:GetMainProperty():GetCurrentMoveSpeed()
end
function CardObjectModel:BeAttacked(damageData, noTrigger)
  if not self:IsAlive() or 0 >= self:GetMainProperty():GetCurrentHp() then
    return
  end
  BattleUtils.BattleObjectActionLog(self, "\228\187\142\232\191\153\228\184\170\228\186\186\233\130\163\232\142\183\229\190\151\228\186\134\228\188\164\229\174\179", damageData.attackerTag, "\228\188\164\229\174\179\229\128\188:", damageData.damage, "\230\138\128\232\131\189id:", damageData.skillInfo and damageData.skillInfo.skillId)
  self:AddEnergy(ENERGY_PER_HURT)
  local damage = damageData.damage
  local shieldEffect = 0
  if damage > 0 then
    if self:DamageImmuneByDamageType(damageData.damageType) then
      return
    end
    damage, shieldEffect = self:CalcFixedDamageByShield(damage)
  else
  end
  damage = self:CalcFixedDamageByObjPP(damage, damageData)
  if 0 == damage then
    return
  end
  damage = self:CalcFixedDamageByBuff(damage, damageData)
  if 0 == damage then
    return
  end
  damageData:SetDamageValue(damage)
  local trueDamage = self:CalcObjectGotTrueDamage(damageData:GetDamageValue())
  G_BattleLogicMgr:SkadaWork(SkadaType.GOT_DAMAGE, self:GetOTag(), damageData, trueDamage)
  G_BattleLogicMgr:SkadaWork(SkadaType.DAMAGE, damageData:GetSourceObjTag(), damageData, trueDamage + shieldEffect)
  self:HpChange(damageData)
  self.castDriver:UpdateActionTrigger(ActionTriggerType.HP, self:GetMainProperty():GetCurHpPercent())
  if self.phaseDriver then
    self.phaseDriver:UpdateActionTrigger(ActionTriggerType.HP, self:GetMainProperty():GetCurHpPercent())
  end
  if not noTrigger then
    local attackerTag
    if not damageData:CausedBySkill() then
      attackerTag = damageData.attackerTag
    end
    self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_DAMAGE, ObjectTriggerParameterStruct.New(attackerTag))
    if damageData.isCritical then
      self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_DAMAGE_CRITICAL)
    end
  end
  if sp.AnimationName.idle == self:GetCurrentAnimationName() and OState.VIEW_TRANSFORM ~= self:GetState() then
    self:DoAnimation(true, nil, sp.AnimationName.attacked, false, sp.AnimationName.idle, true)
    self:RefreshRenderAnimation(true, nil, sp.AnimationName.attacked, false, sp.AnimationName.idle, true)
  end
  self.tintDriver:OnActionEnter(BattleObjTintPattern.BOTP_BLOOD)
end
function CardObjectModel:HpChange(damageData)
  local delta = damageData.damage
  local causeDamageObjTag = damageData:GetSourceObjTag()
  local causeDamageObj = G_BattleLogicMgr:IsObjAliveByTag(causeDamageObjTag)
  local damageNumberStartPos = cc.p(0.5, 1)
  if damageData:IsHeal() then
  else
    delta = -1 * delta
    if self:GetMainProperty():IsDamageDeadly(delta) then
      if causeDamageObj then
        local slayData = SlayObjectStruct.New(self:GetOTag(), damageData, self:GetMainProperty():GetCurrentHp() + delta)
        causeDamageObj:ObjectEventSlayHandler(slayData)
      end
      self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_DEADLY_DAMAGE)
    end
    damageNumberStartPos = cc.p(0.5, 0.8)
  end
  self:GetMainProperty():Setp(ObjP.HP, self:GetMainProperty():GetCurrentHp() + delta)
  if self:GetMainProperty():GetOriginalHp() < self:GetMainProperty():GetCurrentHp() then
    self:GetMainProperty():Setp(ObjP.HP, self:GetMainProperty():GetOriginalHp())
  elseif self:GetMainProperty():GetCurrentHp() <= 0 then
    self:GetMainProperty():Setp(ObjP.HP, 0)
  end
  BattleUtils.BattleObjectActionLog(self, "\232\161\128\233\135\143\229\143\152\229\140\150\229\144\142\231\154\132\229\189\147\229\137\141\231\148\159\229\145\189\231\153\190\229\136\134\230\175\148:", self:GetMainProperty():GetCurHpPercent())
  self:UpdateHp()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ShowDamageNumber", damageData, self:GetPosInBattleRootByCollisionBoxPos(damageNumberStartPos), self:GetOrientation(), self:IsHighlight())
  local energy
  if causeDamageObj then
    energy = causeDamageObj:GetEnergy()
  end
  G_BattleLogicMgr:GetBData():AddADamageStr(damageData, damageData.damage, energy)
end
function CardObjectModel:HpPercentChangeForce(percent)
  self:GetMainProperty():SetCurHpPercent(percent)
  self:UpdateHp()
  if nil ~= self.phaseDriver then
    self.phaseDriver:UpdateActionTrigger(ActionTriggerType.HP, percent)
  end
end
function CardObjectModel:UpdateHp()
  self:GetMainProperty():UpdateCurHpPercent()
  self:UpdateHpBar()
end
function CardObjectModel:CalcFixedDamageByShield(damage)
  local damage_ = damage
  for i = #self.shield, 1, -1 do
    damage_ = damage_ - self.shield[i]:OnCauseEffectEnter(damage_)
  end
  return damage_, damage - damage_
end
function CardObjectModel:CalcFixedDamageByObjPP(damage, damageData)
  local damage_ = damage
  damage_ = self:GetMainProperty():FixFinalGetDamage(damage_, damageData.damageType)
  return damage_
end
function CardObjectModel:CalcFixedDamageByBuff(damage, damageData)
  local damage_ = damage
  local damageReduceConfig = {
    ConfigBuffType.SACRIFICE,
    ConfigBuffType.STAGGER
  }
  for _, reduceBuffType in ipairs(damageReduceConfig) do
    if nil == damageData.skillInfo or reduceBuffType ~= damageData.skillInfo.btype then
      local targetBuffs = self:GetBuffsByBuffType(reduceBuffType, false)
      for i = #targetBuffs, 1, -1 do
        damage_ = damage_ - targetBuffs[i]:OnCauseEffectEnter(damage_, damageData)
        if 0 == damage_ then
          return damage_
        end
      end
    end
  end
  return damage_
end
function CardObjectModel:BeHealed(healData, noTrigger)
  if not self:IsAlive() or healData.damage == 0 then
    return
  end
  if self:HealImmuneByHealType(healData.damageType) then
    return
  end
  local heal = healData.damage
  heal = self:CalcFixedHealByObjPP(heal, healData)
  healData:SetDamageValue(heal)
  local overflowHeal = self:GetMainProperty():GetCurrentHp() + healData.damage - self:GetMainProperty():GetOriginalHp()
  if overflowHeal > 0 then
    local overflowBuffs = {
      ConfigBuffType.OVERFLOW_HEAL_2_SHIELD,
      ConfigBuffType.OVERFLOW_HEAL_2_DAMAGE
    }
    for _, buffType in ipairs(overflowBuffs) do
      local targetBuffs = self:GetBuffsByBuffType(buffType, false)
      for i = #targetBuffs, 1, -1 do
        targetBuffs[i]:OnCauseEffectEnter(overflowHeal)
      end
    end
  end
  local trueHeal = self:CalcObjectGotTrueHeal(healData:GetDamageValue())
  G_BattleLogicMgr:SkadaWork(SkadaType.HEAl, healData:GetSourceObjTag(), healData, trueHeal)
  self:HpChange(healData)
  self.castDriver:UpdateActionTrigger(ActionTriggerType.HP, self:GetMainProperty():GetCurHpPercent())
  if self.phaseDriver then
    self.phaseDriver:UpdateActionTrigger(ActionTriggerType.HP, self:GetMainProperty():GetCurHpPercent())
  end
  if not noTrigger then
    self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_HEAL)
    if healData.isCritical then
      self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_HEAL_CRITICAL)
    end
  end
end
function CardObjectModel:HealImmuneByHealType(healType)
  local result = self:GetObjectExtraStateInfo():GetDamageImmune(healType) or self:GetObjectExtraStateInfo():GetDamageImmune(DamageType.HEAL) or self:GetObjectExtraStateInfo():GetGlobalDamageImmune(healType) or self:GetObjectExtraStateInfo():GetGlobalDamageImmune(DamageType.HEAL)
  return result
end
function CardObjectModel:CalcFixedHealByObjPP(damage, damageData)
  local damage_ = damage
  damage_ = self:GetMainProperty():FixFinalGetHeal(damage_, damageData.damageType)
  return damage_
end
function CardObjectModel:ForceUndeadOnce(minHp)
  self:GetMainProperty():Setp(ObjP.HP, math.max(minHp or 1, self:GetMainProperty():GetCurrentHp()))
end
function CardObjectModel:FixAnimationScaleByATKRate()
  local avatarTimeScale = self:GetAvatarTimeScale()
  self:SetAnimationTimeScale(avatarTimeScale)
  if OState.ATTACKING == self:GetState() then
    self:RefreshRenderAnimationTimeScale(avatarTimeScale)
  end
end
function CardObjectModel:CalcObjectGotTrueDamage(damage)
  if damage > self:GetMainProperty():GetCurrentHp() then
    return self:GetMainProperty():GetCurrentHp()
  else
    return damage
  end
end
function CardObjectModel:CalcObjectGotTrueHeal(heal)
  if self:GetMainProperty():GetCurrentHp() + heal > self:GetMainProperty():GetOriginalHp() then
    return self:GetMainProperty():GetOriginalHp() - self:GetMainProperty():GetCurrentHp()
  else
    return heal
  end
end
function CardObjectModel:Cast(skillId)
  self.castDriver:OnActionEnter(skillId)
end
function CardObjectModel:BeCasted(buffInfo)
  BattleUtils.BattleObjectActionLog(self, "get buff effect -> fromTag", buffInfo.casterTag, buffInfo.btype)
  if BattleElementType.BET_WEATHER == G_BattleLogicMgr:GetBattleElementTypeByTag(buffInfo.casterTag) and true == self:GetObjectWeatherImmune(buffInfo.weatherId) then
    self:ShowImmune()
    return false
  end
  if true == self:IsObjectImmuneBuff(buffInfo.btype) then
    self:ShowImmune()
    return false
  end
  if true == self:ImmuneAbnormalStateByBuffType(buffInfo.btype) then
    self:ShowImmune()
    return false
  end
  if BuffCauseEffectTime.INSTANT == buffInfo.causeEffectTime then
    local buff = __Require(buffInfo.className).new(buffInfo)
    buff:OnCauseEffectEnter()
  elseif buffInfo.isHalo then
    local buff = self:GetHaloByBuffId(buffInfo:GetStructBuffId())
    if nil == buff then
      buff = __Require(buffInfo.className).new(buffInfo)
      self:AddHalo(buff)
      self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_BUFF)
    else
      buff:OnRefreshBuffEnter(buffInfo)
      self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.REFRESH_BUFF)
    end
  else
    local buff = self:GetBuffByBuffId(buffInfo:GetStructBuffId())
    if nil == buff then
      buff = __Require(buffInfo.className).new(buffInfo)
      self:AddBuff(buff)
      self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.GOT_BUFF)
    else
      buff:OnRefreshBuffEnter(buffInfo)
      self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.REFRESH_BUFF)
    end
  end
  return true
end
function CardObjectModel:CastAllHalos()
  self.castDriver:CastAllHalos()
end
function CardObjectModel:CastConnectSkill(skillId)
  if true == self.castDriver:CanDoAction(ActionTriggerType.CONNECT, skillId) then
    self:BreakCurrentAction()
    self.castDriver:OnActionEnter(skillId)
  else
    print("\230\156\170\230\187\161\232\182\179\233\135\138\230\148\190\232\191\158\230\144\186\230\138\128\230\157\161\228\187\182")
  end
end
function CardObjectModel:CanCastConnectByAbnormalState()
  local result = self:InAbnormalState(AbnormalState.SILENT) or self:InAbnormalState(AbnormalState.ENCHANTING)
  return not result
end
function CardObjectModel:CanTriggerBuff(skillId, buffType, triggerActionType)
  return self.buffDriver:CanTriggerBuff(skillId, buffType, triggerActionType)
end
function CardObjectModel:CostTriggerBuffResources(skillId, buffType, triggerActionType, cd)
  self.buffDriver:CostTriggerBuffResources(skillId, buffType, triggerActionType, cd)
end
function CardObjectModel:AddBuff(buff)
  local buffIconType = buff:GetBuffIconType()
  if BuffIconType.BASE ~= buffIconType and not self:HasBuffByBuffIconType(buffIconType, buff:GetBuffOriginValue()) then
    self:AddBuffIcon(buffIconType, buff:GetBuffOriginValue())
  end
  BaseObjectModel.AddBuff(self, buff)
end
function CardObjectModel:RemoveBuff(buff)
  BaseObjectModel.RemoveBuff(self, buff)
  local buffIconType = buff:GetBuffIconType()
  if BuffIconType.BASE ~= buffIconType and not self:HasBuffByBuffIconType(buffIconType, buff:GetBuffOriginValue()) then
    self:RemoveBuffIcon(buffIconType, buff:GetBuffOriginValue())
  end
end
function CardObjectModel:AddHalo(buff)
  local buffIconType = buff:GetBuffIconType()
  if BuffIconType.BASE ~= buffIconType and not self:HasBuffByBuffIconType(buffIconType, buff:GetBuffOriginValue()) then
    self:AddBuffIcon(buffIconType, buff:GetBuffOriginValue())
  end
  BaseObjectModel.AddHalo(self, buff)
end
function CardObjectModel:RemoveHalo(buff)
  BaseObjectModel.RemoveHalo(self, buff)
  local buffIconType = buff:GetBuffIconType()
  if BuffIconType.BASE ~= buffIconType and not self:HasBuffByBuffIconType(buffIconType, buff:GetBuffOriginValue()) then
    self:RemoveBuffIcon(buffIconType, buff:GetBuffOriginValue())
  end
end
function CardObjectModel:AddQTE(qteBuffsInfo)
  local skillId = qteBuffsInfo.skillId
  local qteAttachModel = self:GetQTEBySkillId(skillId)
  if nil == qteAttachModel then
    qteAttachModel = G_BattleLogicMgr:GetAQTEAttachObject(qteBuffsInfo)
    self.qteBuffs.id[tostring(skillId)] = qteAttachModel
    table.insert(self.qteBuffs.idx, 1, qteAttachModel)
    G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "CreateAAttachObjectView", self:GetOTag(), self:GetViewModelTag(), qteAttachModel:GetOTag(), skillId, qteAttachModel:GetAttachType())
  else
    qteAttachModel:RefreshQTEBuffs(qteBuffsInfo)
  end
end
function CardObjectModel:RemoveQTE(skillId)
  local qteAttachModel
  for i = #self.qteBuffs.idx, 1, -1 do
    qteAttachModel = self.qteBuffs.idx[i]
    if checkint(skillId) == checkint(qteAttachModel:GetSkillId()) then
      qteAttachModel:Die()
      table.remove(self.qteBuffs.idx, i)
      break
    end
  end
  self.qteBuffs.id[tostring(skillId)] = nil
end
function CardObjectModel:RemoveQTEBuff(skillId, buffType)
  local qteAttachModel = self:GetQTEBySkillId(skillId)
  if nil ~= qteAttachModel then
    qteAttachModel:RemoveQTEBuff(buffType)
  end
end
function CardObjectModel:IsInfectBySkillId(skillId)
  return nil ~= self.infectDriver:GetInfectInfoBySkillId(skillId)
end
function CardObjectModel:AddInfectInfo(infectInfo)
  self.infectDriver:AddAInfectInfo(infectInfo)
end
function CardObjectModel:RemoveInfecInfo(skillId)
  self.infectDriver:RemoveAInfectInfoBySkillId(skillId)
end
function CardObjectModel:Move(dt, targetTag)
  self.moveDriver:OnActionUpdate(dt, targetTag)
end
function CardObjectModel:ForceMove(targetPos, moveActionName, moveOverCallback)
  self.moveDriver:OnForceMoveEnter(targetPos, moveActionName, moveOverCallback)
end
function CardObjectModel:GetHPPercent()
  return self:GetMainProperty():GetCurHpPercent()
end
function CardObjectModel:GetRecordDeltaHp()
  return self:GetObjInfo().recordDeltaHp
end
function CardObjectModel:AddEnergy(delta)
  BaseObjectModel.AddEnergy(self, delta)
  self:UpdateEnergyBar()
  self:RefreshConnectButtonsByEnergy()
end
function CardObjectModel:GetMaxEnergy()
  return self:GetMainProperty():GetMaxEnergy()
end
function CardObjectModel:GetEnergyRecoverRatePerS()
  return ENERGY_PER_S + self:GetEnergyRecoverRate()
end
function CardObjectModel:EnergyPercentChangeForce(percent)
  BaseObjectModel.EnergyPercentChangeForce(self, percent)
  self:UpdateEnergyBar()
  self:RefreshConnectButtonsByEnergy()
end
function CardObjectModel:CanEnterNextWave()
  local result = false
  if 1 == self.castDriver:IsInChanting() then
    self.castDriver:OnChantBreak()
  end
  local currentAnimationName = self:GetCurrentAnimationName()
  if true == self.moveDriver:IsEscaping() then
    return false
  elseif nil == currentAnimationName or sp.AnimationName.idle == currentAnimationName then
    return true
  elseif self:InAbnormalState(AbnormalState.STUN) or self:InAbnormalState(AbnormalState.FREEZE) then
    self:ClearBuff()
  elseif sp.AnimationName.run == currentAnimationName then
    self:DoAnimation(true, nil, sp.AnimationName.idle, true)
    self:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
  end
  return result
end
function CardObjectModel:EnterNextWave(nextWave)
  BaseObjectModel.EnterNextWave(self, nextWave)
  self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.WAVE_SHIFT)
  self:ClearBuff()
  self:SetState(OState.SLEEP)
  self:SetState(OState.SLEEP, -1)
  self:DoAnimation(true, nil, sp.AnimationName.idle, true)
  self:ResetLocation()
  self:RefreshRenderViewPosition()
  self:RefreshRenderViewTowards()
  self:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
  self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.WAVE_SHIFT)
  self.attackDriver:ResetActionTrigger()
  self.castDriver:ResetActionTrigger()
  self.countdowns.energy = 1
end
function CardObjectModel:Win()
  self:DoAnimation(true, 1, sp.AnimationName.win, true)
  self:RefreshRenderAnimation(true, 1, sp.AnimationName.win, true)
end
function CardObjectModel:StartEscape()
  local targetPos = self.moveDriver:GetEscapeTargetPosition()
  if nil ~= targetPos then
    self.moveDriver:StartEscape(targetPos)
  end
end
function CardObjectModel:OverEscape()
  self.moveDriver:OnEscapeExit()
end
function CardObjectModel:AppearFromEscape()
  self:SetAllImmune(false)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "PhaseChangeEscapeBack", self:GetViewModelTag())
end
function CardObjectModel:CalcEscapeTargetPosition()
  local designSize = G_BattleLogicMgr:GetDesignScreenSize()
  local targetPos
  if true == self:IsEnemy(true) then
    targetPos = cc.p(designSize.width + self:GetStaticViewBox().width * 1.25, self:GetLocation().po.y)
  else
    targetPos = cc.p(-1 * self:GetStaticViewBox().width * 1.25, self:GetLocation().po.y)
  end
  return targetPos
end
function CardObjectModel:GetAppearWaveAfterEscape()
  return self.moveDriver:GetAppearWaveAfterEscape()
end
function CardObjectModel:SetAppearWaveAfterEscape(wave)
  self.moveDriver:SetAppearWaveAfterEscape(wave)
end
function CardObjectModel:BlewOff(distance)
  self.moveDriver:OnBlewOffEnter(distance)
end
function CardObjectModel:CanDie()
  local result = not self:InAbnormalState(AbnormalState.UNDEAD) and 0 >= self:GetMainProperty():GetCurrentHp()
  return result
end
function CardObjectModel:DieBegin()
  BattleUtils.BattleObjectActionLog(self, " !!!!!!!!! \229\188\128\229\167\139 [\230\173\187\228\186\161] !!!!!!!!!")
  self:ClearAnimations()
  self:Die()
  self:DoAnimation(true, 1, sp.AnimationName.die, false)
  self:RefreshRenderAnimation(true, 1, sp.AnimationName.die, false)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ObjectViewDieBegin", self:GetViewModelTag())
  if not CardUtils.IsMonsterCard(self:GetObjectConfigId()) then
    G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "PlayCardSound", self:GetObjectConfigId(), SoundType.TYPE_BATTLE_DIE)
  end
end
function CardObjectModel:Die()
  self:KillSelf(false)
end
function CardObjectModel:DieEnd()
  if nil ~= self:GetViewModel() then
    self:ClearAnimations()
    self:GetViewModel():Kill()
  end
  self:SetHighlight(false)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "KillObjectView", self:GetViewModelTag())
end
function CardObjectModel:KillSelf(nature)
  self:BreakCurrentAction()
  self:SetState(OState.DIE)
  self:UnregistObjectEventHandler()
  G_BattleLogicMgr:SendObjEvent(ObjectEvent.OBJECT_DIE, {
    tag = self:GetOTag(),
    cardId = self:GetObjectConfigId(),
    isEnemy = self:IsEnemy(true)
  })
  for i = #self.qteBuffs.idx, 1, -1 do
    self.qteBuffs.idx[i]:Die()
  end
  self:ClearBuff()
  G_BattleLogicMgr:GetBData():AddALogicModelToDust(self, nature)
  G_BattleLogicMgr:GetBData():RemoveABattleObjLogicModel(self)
  self:AddEnergy(-self:GetEnergy())
  if nature and nil ~= self:GetViewModel() then
    self:ClearAnimations()
    self:GetViewModel():Kill()
  end
  self:EnableConnectSkillButton(skillId, false)
  self.tintDriver:OnActionBreak()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "KillObjectCISceneByTag", self:GetOTag())
end
function CardObjectModel:Destroy()
  if OState.DIE ~= self:GetState() then
    self:SetState(OState.DIE)
  end
  if nil ~= self:GetViewModel() then
    self:ClearAnimations()
    self:GetViewModel():Kill()
  end
  self.buffs = {
    idx = {},
    id = {}
  }
  self.halos = {
    idx = {},
    id = {}
  }
  self.shield = {}
end
function CardObjectModel:Revive(reviveHpPercent, reviveEnergyPercent, healData)
  self:RegisterObjectEventHandler()
  if nil ~= self:GetViewModel() then
    self:GetViewModel():Awake()
  end
  G_BattleLogicMgr:GetBData():AddABattleObjLogicModel(self)
  G_BattleLogicMgr:GetBData():RemoveALogicModelFromDust(self)
  self:HpPercentChangeForce(reviveHpPercent)
  self:EnergyPercentChangeForce(reviveEnergyPercent)
  local recoverHp = self:GetMainProperty():GetOriginalHp() * reviveHpPercent
  if nil ~= healData then
    local healer = G_BattleLogicMgr:IsObjAliveByTag(healData.healerTag)
    local attackerEnergy
    if nil ~= healer and healer.GetEnergy then
      attackerEnergy = healer:GetEnergy()
    end
    healData.damage = recoverHp
    G_BattleLogicMgr:GetBData():AddADamageStr(healData, healData.damage, attackerEnergy)
  end
  self:AwakeObject()
  self:ReviveRender()
  self:ClearAnimations()
  self:DoAnimation(true, nil, sp.AnimationName.idle, true)
  self:SetAnimationTimeScale(self:GetAnimationTimeScale())
  self:ClearRenderAnimations()
  self:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
  self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
  G_BattleLogicMgr:SendObjEvent(ObjectEvent.OBJECT_REVIVE, {
    tag = self:GetOTag(),
    cardId = self:GetObjectConfigId(),
    isEnemy = self:IsEnemy(true)
  })
  self:CheckConnectSkillState()
end
function CardObjectModel:ViewTransform(oriSkinId, oriActionName, targetSkinId, targetActionName)
  if nil ~= self.exAbilityDriver and true == self.exAbilityDriver:CanDoViewTransform(oriSkinId) then
    self:BreakCurrentAction()
    self.exAbilityDriver:OnViewTransformEnter(oriSkinId, oriActionName, targetSkinId, targetActionName)
  end
end
function CardObjectModel:RefreshViewModel(spineDataStruct, avatarScale)
  self:GetViewModel():InnerChangeViewModel(spineDataStruct, avatarScale)
end
function CardObjectModel:Stun(valid)
  BaseObjectModel.Stun(self, valid)
  if true == valid then
    self:BreakCurrentAction()
    if self:IsAlive() then
      self:DoAnimation(true, nil, sp.AnimationName.attacked, true)
      self:SetAnimationTimeScale(self:GetAnimationTimeScale())
      self:RefreshRenderAnimation(true, nil, sp.AnimationName.attacked, true)
      self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
    end
  elseif self:IsAlive() then
    self:DoAnimation(true, nil, sp.AnimationName.idle, true)
    self:SetAnimationTimeScale(self:GetAnimationTimeScale())
    self:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
    self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
  end
end
function CardObjectModel:Freeze(valid)
  BaseObjectModel.Freeze(self, valid)
  if true == valid then
    self:BreakCurrentAction()
    if self:IsAlive() then
      self:SetAnimationTimeScale(self:GetAvatarTimeScale())
      self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
    end
  elseif self:IsAlive() then
    self:DoAnimation(true, nil, sp.AnimationName.idle, true)
    self:SetAnimationTimeScale(self:GetAvatarTimeScale())
    self:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
    self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
  end
end
function CardObjectModel:Silent(valid)
  BaseObjectModel.Silent(self, valid)
  if true == valid and OState.CASTING == self:GetState() then
    self.castDriver:OnActionBreak()
  end
end
function CardObjectModel:Enchanting(valid)
  BaseObjectModel.Enchanting(self, valid)
  if true == valid then
    self:BreakCurrentAction()
  end
end
function CardObjectModel:DoAnimation(setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
  if true == setToSetupPose then
    self:GetViewModel():SetSpineToSetupPose()
  end
  if nil ~= setAnimationName then
    self:GetViewModel():SetSpineAnimation(setAnimationName, setAnimationLoop)
  end
  if nil ~= addAnimationName then
    self:GetViewModel():AddSpineAnimation(addAnimationName, addAnimationLoop)
  end
  if nil ~= timeScale then
    self:SetAnimationTimeScale(timeScale)
  end
end
function CardObjectModel:ClearAnimations()
  self:GetViewModel():ClearSpineTracks()
end
function CardObjectModel:SetAnimationTimeScale(timeScale)
  self:GetViewModel():SetAnimationTimeScale(timeScale)
end
function CardObjectModel:GetAnimationTimeScale()
  return self:GetViewModel():GetAnimationTimeScale()
end
function CardObjectModel:GetCurrentAnimationName()
  return self:GetViewModel():GetRunningSpineAniName()
end
function CardObjectModel:ForceStun(valid)
  BaseObjectModel.ForceStun(self, valid)
  if true == valid then
    self:BreakCurrentAction()
    self:DoAnimation(true, nil, sp.AnimationName.attacked, true)
    self:SetAnimationTimeScale(self:GetAnimationTimeScale())
    self:RefreshRenderAnimation(true, nil, sp.AnimationName.attacked, true)
    self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
  else
    self:DoAnimation(true, nil, sp.AnimationName.idle, true)
    self:SetAnimationTimeScale(self:GetAnimationTimeScale())
    self:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
    self:RefreshRenderAnimationTimeScale(self:GetAnimationTimeScale())
  end
end
function CardObjectModel:ForceDisappear(actionName, targetPos, disappearCallback)
  if nil ~= targetPos then
    self:ForceMove(actionName, targetPos, disappearCallback)
  else
  end
end
function CardObjectModel:ChangePosition(p)
  self:GetViewModel():SetPositionX(p.x)
  self:GetViewModel():SetPositionY(p.y)
  BaseObjectModel.ChangePosition(self, p)
end
function CardObjectModel:UpdateLocation()
  BaseObjectModel.UpdateLocation(self)
  self.location.po.x = self:GetViewModel():GetPositionX()
  self.location.po.y = self:GetViewModel():GetPositionY()
  local rc = G_BattleLogicMgr:GetRowColByPos(self:GetViewModel():GetPosition())
  self.location.rc.r = rc.r
  self.location.rc.c = rc.c
  if self:IsHighlight() or -1 ~= self:GetDefaultZOrder() then
    self:SetZOrder(G_BattleLogicMgr:GetObjZOrderInBattle(self:GetLocation().po, self:IsEnemy(true), self:IsHighlight()))
  else
    self:SetZOrder(self:GetDefaultZOrder())
  end
end
function CardObjectModel:ResetLocation()
  BaseObjectModel.ResetLocation(self)
  local oriPos = self:GetObjInfo().oriLocation.po
  self:ChangePosition(oriPos)
  if self:IsEnemy(true) then
    self:SetOrientation(BattleObjTowards.NEGTIVE)
  else
    self:SetOrientation(BattleObjTowards.FORWARD)
  end
end
function CardObjectModel:SetOrientation(towards)
  self:GetViewModel():SetTowards(towards)
end
function CardObjectModel:GetOrientation()
  return BattleObjTowards.FORWARD == self:GetViewModel():GetTowards()
end
function CardObjectModel:GetStaticCollisionBox()
  return self:GetViewModel():GetStaticCollisionBox()
end
function CardObjectModel:GetStaticCollisionBoxInBattleRoot()
  local collisionBox = self:GetStaticCollisionBox()
  if nil ~= collisionBox then
    local location = self:GetLocation().po
    local fixedBox = cc.rect(location.x + collisionBox.x, location.y + collisionBox.y, collisionBox.width, collisionBox.height)
    return fixedBox
  else
    return nil
  end
end
function CardObjectModel:GetStaticViewBox()
  return self:GetViewModel():GetStaticViewBox()
end
function CardObjectModel:GetPosInBattleRootByCollisionBoxPos(pos)
  local collisionBox = self:GetStaticCollisionBox()
  local pos_ = cc.p(0, 0)
  pos_.x = self:GetLocation().po.x + collisionBox.x + collisionBox.width * pos.x
  pos_.y = self:GetLocation().po.y + collisionBox.y + collisionBox.height * pos.y
  return pos_
end
function CardObjectModel:FindBone(boneName)
  return self:GetViewModel():GetBoneDataByBoneName(boneName)
end
function CardObjectModel:FineBoneInBattleRootSpace(boneName)
  local boneData = self:FindBone(boneName)
  if nil == boneData then
    return nil
  end
  return nil
end
function CardObjectModel:RegisterObjectEventHandler()
  local eventHandlerInfo = {
    {
      member = "objDieEventHandler_",
      eventType = ObjectEvent.OBJECT_DIE,
      handler = handler(self, self.ObjectEventDieHandler)
    },
    {
      member = "objReviveEventHandler_",
      eventType = ObjectEvent.OBJECT_REVIVE,
      handler = handler(self, self.ObjectEventReviveHandler)
    },
    {
      member = "objCastEventHandler_",
      eventType = ObjectEvent.OBJECT_CAST_ENTER,
      handler = handler(self, self.ObjectEventCastHandler)
    },
    {
      member = "objLuckEventHandler_",
      eventType = ObjectEvent.OBJECT_LURK,
      handler = handler(self, self.ObjectEventLuckHandler)
    }
  }
  for _, v in ipairs(eventHandlerInfo) do
    if nil == self[v.member] then
      self[v.member] = v.handler
    end
    G_BattleLogicMgr:AddObjEvent(v.eventType, self, self[v.member])
  end
end
function CardObjectModel:UnregistObjectEventHandler()
  local eventHandlerInfo = {
    {
      member = "objDieEventHandler_",
      eventType = ObjectEvent.OBJECT_DIE,
      handler = handler(self, self.ObjectEventDieHandler)
    },
    {
      member = "objReviveEventHandler_",
      eventType = ObjectEvent.OBJECT_REVIVE,
      handler = handler(self, self.ObjectEventReviveHandler)
    },
    {
      member = "objCastEventHandler_",
      eventType = ObjectEvent.OBJECT_CAST_ENTER,
      handler = handler(self, self.ObjectEventCastHandler)
    },
    {
      member = "objLuckEventHandler_",
      eventType = ObjectEvent.OBJECT_LURK,
      handler = handler(self, self.ObjectEventLuckHandler)
    }
  }
  for _, v in ipairs(eventHandlerInfo) do
    G_BattleLogicMgr:RemoveObjEvent(v.eventType, self)
  end
end
function CardObjectModel:RegistViewModelEventHandler()
  if nil ~= self:GetViewModel() then
    self:GetViewModel():RegistEventListener(sp.EventType.ANIMATION_COMPLETE, handler(self, self.SpineEventCompleteHandler))
    self:GetViewModel():RegistEventListener(sp.EventType.ANIMATION_EVENT, handler(self, self.SpineEventCustomHandler))
  end
end
function CardObjectModel:UnregistViewModelEventHandler()
end
function CardObjectModel:SpineEventCompleteHandler(eventType, event)
  if not event then
    return
  end
  local eventName = event.animation
  if sp.AnimationName.attack == eventName or nil ~= string.find(eventName, sp.AnimationName.skill) then
    if OState.ATTACKING == self:GetState() then
      BattleUtils.BattleObjectActionLog(self, "\230\148\187\229\135\187\231\138\182\230\128\129 \230\148\187\229\135\187\229\138\168\228\189\156\229\174\140\230\149\180\231\187\147\230\157\159", event.animation)
      self.attackDriver:OnActionExit()
    elseif OState.CASTING == self:GetState() then
      BattleUtils.BattleObjectActionLog(self, "\230\150\189\230\179\149\231\138\182\230\128\129 \230\150\189\230\179\149\229\138\168\228\189\156\229\174\140\230\149\180\231\187\147\230\157\159", event.animation)
      self.castDriver:OnActionExit()
    elseif OState.VIEW_TRANSFORM == self:GetState() then
      BattleUtils.BattleObjectActionLog(self, "\229\143\152\229\189\162\231\138\182\230\128\129 \229\143\152\229\189\162\229\138\168\228\189\156\229\174\140\230\149\180\231\187\147\230\157\159", event.animation)
      if nil ~= self.exAbilityDriver then
        self.exAbilityDriver:OnViewTransformExit()
      end
    end
  elseif OState.DIE == self:GetState() then
    BattleUtils.BattleObjectActionLog(self, "\230\173\187\228\186\161\229\138\168\228\189\156\229\174\140\230\149\180\231\187\147\230\157\159", event.animation)
    self:DieEnd()
  end
end
function CardObjectModel:SpineEventCustomHandler(eventType, event)
  if GState.START ~= G_BattleLogicMgr:GetGState() or OState.DIE == self:GetState() then
    return
  end
  if sp.CustomEvent.cause_effect == event.eventData.name then
    if OState.ATTACKING == self:GetState() then
      BattleUtils.BattleObjectActionLog(self, "\230\148\187\229\135\187\231\138\182\230\128\129 \232\142\183\229\190\151\228\186\134spine\228\186\139\228\187\182", event.animation, event.eventData.name)
      local percent = event.eventData.intValue * 0.01
      if percent == 0 then
        percent = 1
      end
      self.attackDriver:Attack(self.attackDriver:GetAttackTargetTag(), percent)
    elseif OState.CASTING == self:GetState() then
      BattleUtils.BattleObjectActionLog(self, "\230\150\189\230\179\149\231\138\182\230\128\129 \232\142\183\229\190\151\228\186\134spine\228\186\139\228\187\182", event.animation, event.eventData.name)
      local percent = event.eventData.intValue * 0.01
      if percent == 0 then
        percent = 1
      end
      self.castDriver:Cast(self.castDriver:GetCastingSkillId(), percent)
    elseif OState.VIEW_TRANSFORM == self:GetState() and nil ~= self.exAbilityDriver then
      self.exAbilityDriver:ViewTransform()
    end
  end
end
function CardObjectModel:ObjectEventDieHandler(...)
  local args = unpack({
    ...
  })
  local targetTag = args.tag
  local halo
  for i = #self.halos.idx, 1, -1 do
    halo = self.halos.idx[i]
    if halo:HasHaloOuterPileByCasterTag(targetTag) then
      halo:OnRecoverEffectEnter(targetTag)
    end
  end
  if nil ~= self.attackDriver:GetAttackTargetTag() and targetTag == checkint(self.attackDriver:GetAttackTargetTag()) then
    self:LostAttackTarget()
  end
  if args.cardId and args.isEnemy == self:IsEnemy(true) then
    self:ObjectDiedConnectSkillHandler(args.cardId)
  end
end
function CardObjectModel:ObjectEventReviveHandler(...)
  local args = unpack({
    ...
  })
  local targetTag = args.tag
  if targetTag == self:GetOTag() then
    return
  end
  if args.cardId and args.isEnemy == self:IsEnemy(true) then
    self:ObjectReviveConnectSkillHandler(args.cardId)
  end
end
function CardObjectModel:ObjectEventCastHandler(...)
  local args = unpack({
    ...
  })
  local targetTag = args.tag
  local obj = G_BattleLogicMgr:IsObjAliveByTag(targetTag)
  if nil ~= obj and nil ~= self.phaseDriver then
    local cardId = obj:GetObjectConfigId()
    local skillId = args.skillId
    local isEnemy = args.isEnemy
    if self.phaseDriver then
      self.phaseDriver:UpdateActionTrigger(ActionTriggerType.SKILL, {
        npcId = cardId,
        npcCampType = isEnemy and ConfigCampType.ENEMY or ConfigCampType.FRIEND,
        skillId = skillId
      })
    end
  end
end
function CardObjectModel:ObjectEventLuckHandler(...)
end
function CardObjectModel:ObjectEventSlayHandler(...)
  local slayData = (...)
  local damageBuffType = slayData.damageData:GetDamageBuffType()
  local ruleOutBuffType = {
    [ConfigBuffType.SPIRIT_LINK] = true
  }
  if true == ruleOutBuffType[damageBuffType] then
    return
  end
  self:AddEnergy(ENERGY_PER_KILL)
  self.triggerDriver:OnActionEnter(ConfigObjectTriggerActionType.SLAY_OBJECT, slayData)
end
function CardObjectModel:ObjectDiedConnectSkillHandler(cardId)
  self:ChangeConnectSkillStateByCardId(cardId, false)
end
function CardObjectModel:ObjectReviveConnectSkillHandler(cardId)
  self:ChangeConnectSkillStateByCardId(cardId, true)
end
function CardObjectModel:ChangeConnectSkillStateByCardId(cardId, enable)
  local connectSkills = self.castDriver:GetConnectSkills()
  if false == enable then
    for _, skillId in ipairs(connectSkills) do
      for _, connectCardId in ipairs(self.castDriver:GetSkillBySkillId(skillId).connectCardId) do
        if cardId == connectCardId then
          self.castDriver:InnerChangeConnectSkill(enable)
          self:EnableConnectSkillButton(skillId, enable)
          break
        end
      end
    end
  else
    for _, skillId in ipairs(connectSkills) do
      local inConnectTeam, canEnable = false, true
      for _, connectCardId in ipairs(self.castDriver:GetSkillBySkillId(skillId).connectCardId) do
        if cardId == connectCardId then
          inConnectTeam = true
        elseif not G_BattleLogicMgr:IsObjAliveByCardId(connectCardId, self:IsEnemy(true)) then
          canEnable = false
          break
        end
      end
      if inConnectTeam and canEnable then
        self.castDriver:InnerChangeConnectSkill(enable)
        self:EnableConnectSkillButton(skillId, enable)
      end
    end
  end
end
function CardObjectModel:CheckConnectSkillState()
  local connectSkills = self.castDriver:GetConnectSkills()
  for _, skillId in ipairs(connectSkills) do
    local result = self.castDriver:CanUseConnectSkillByCardAlive(skillId)
    if result then
      self.castDriver:InnerChangeConnectSkill(true)
      self:EnableConnectSkillButton(skillId, true)
    else
      self.castDriver:InnerChangeConnectSkill(false)
      self:EnableConnectSkillButton(skillId, false)
    end
  end
end
function CardObjectModel:GetObjectName()
  return "Tag_" .. self:GetOTag() .. "_ID_" .. self:GetObjectConfigId() .. "_Name_" .. self:GetObjectConfig().name
end
function CardObjectModel:IsEnemy(o)
  if true == o then
    return self:GetObjInfo().isEnemy
  end
  if self:InAbnormalState(AbnormalState.ENCHANTING) then
    return not self:GetObjInfo().isEnemy
  else
    return self:GetObjInfo().isEnemy
  end
end
function CardObjectModel:IsScarecrow()
  if CardUtils.IsMonsterCard(self:GetObjectConfigId()) then
    local monsterType = checkint(self:GetObjectConfig().type)
    local isScarecrow = ConfigMonsterType.SCARECROW_TANK == monsterType or ConfigMonsterType.SCARECROW_DPS == monsterType or ConfigMonsterType.SCARECROW_HEALER == monsterType
    return isScarecrow
  else
    return false
  end
end
function CardObjectModel:GetObjectLevel()
  return self:GetMainProperty().level
end
function CardObjectModel:GetObjectMosnterType()
  if not CardUtils.IsMonsterCard(self:GetObjectConfigId()) then
    return ConfigMonsterType.CARD
  else
    local cardConfig = self:GetObjectConfig()
    return checkint(cardConfig.type)
  end
end
function CardObjectModel:GetMainProperty()
  return self:GetObjInfo().property
end
function CardObjectModel:GetAvatarTimeScale(o)
  if self:IsPause() or self:InAbnormalState(AbnormalState.FREEZE) then
    return 0
  end
  local avatarTimeScale = 1
  if true == o then
    return avatarTimeScale
  end
  if OState.ATTACKING == self:GetState() then
    local attackAniName = sp.AnimationName.attack
    local attackAniData = self:GetActionAnimationConfigBySkillId(ATTACK_2_SKILL_ID)
    if nil ~= attackAniData then
      attackAniName = attackAniData.actionName
    end
    avatarTimeScale = self:GetViewModel():CalcAnimationFixedTimeScale(self:GetMainProperty():GetATKCounter(), attackAniName)
  end
  return avatarTimeScale
end
function CardObjectModel:GetObjectEffectConfig()
  return CardUtils.GetCardEffectConfigBySkinId(self:GetObjectConfigId(), self:GetObjectSkinId())
end
function CardObjectModel:GetViewModelTag()
  return self:GetViewModel():GetViewModelTag()
end
function CardObjectModel:GetPropertyByObjP(propertyType, isOriginal)
  if ObjP.ENERGY == propertyType then
    if isOriginal then
      return self:GetMaxEnergy()
    else
      return self:GetEnergy()
    end
  elseif isOriginal then
    return self:GetMainProperty():GetCurrentP(propertyType)
  else
    return self:GetMainProperty():GetOriginalP(propertyType)
  end
end
function CardObjectModel:RefreshRenderViewPosition()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "SetObjectViewPosition", self:GetViewModelTag(), self:GetLocation().po.x, self:GetLocation().po.y)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "SetObjectViewZOrder", self:GetViewModelTag(), self:GetZOrder())
end
function CardObjectModel:RefreshRenderViewTowards()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "SetObjectViewTowards", self:GetViewModelTag(), self:GetTowards())
end
function CardObjectModel:RefreshRenderAnimation(setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ObjectViewDoAnimation", self:GetViewModelTag(), setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
end
function CardObjectModel:ClearRenderAnimations()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ClearObjectViewAnimations", self:GetViewModelTag())
end
function CardObjectModel:RefreshRenderAnimationTimeScale(timeScale)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ObjectViewSetAnimationTimeScale", self:GetViewModelTag(), timeScale)
end
function CardObjectModel:RefreshConnectButtonsByEnergy()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "RefreshObjectConnectButtonsByEnergy", self:GetOTag(), self:GetEnergyPercent())
end
function CardObjectModel:RefreshConnectButtonsByState()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "RefreshObjectConnectButtonsByState", self:GetOTag(), self:CanAct(), self:GetState(), not self:CanCastConnectByAbnormalState())
end
function CardObjectModel:EnableConnectSkillButton(skillId, enable)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "EnableConnectSkillButton", self:GetOTag(), skillId, enable)
  self:RefreshConnectButtonsByState()
end
function CardObjectModel:UpdateHpBar()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "SetObjectViewHpPercent", self:GetViewModelTag(), self:GetHPPercent())
end
function CardObjectModel:UpdateEnergyBar()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "SetObjectViewEnergyPercent", self:GetViewModelTag(), self:GetEnergyPercent())
end
function CardObjectModel:ShowImmune()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ShowObjectViewImmune", self:GetViewModelTag())
end
function CardObjectModel:AddBuffIcon(iconType, value)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ObjectViewAddABuffIcon", self:GetViewModelTag(), iconType, value)
end
function CardObjectModel:RemoveBuffIcon(iconType, value)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ObjectViewRemoveABuffIcon", self:GetViewModelTag(), iconType, value)
end
function CardObjectModel:ShowHurtEffect(effectData)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ObjectViewShowHurtEffect", self:GetViewModelTag(), effectData)
end
function CardObjectModel:ShowAttachEffect(visible, buffId, effectData)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ObjectViewShowAttachEffect", self:GetViewModelTag(), visible, buffId, effectData)
end
function CardObjectModel:InitObjectRender()
  self:DoAnimation(false, nil, sp.AnimationName.idle, true)
  self:RefreshRenderAnimation(false, nil, sp.AnimationName.idle, true)
  self:RefreshRenderViewPosition()
  self:RefreshRenderViewTowards()
  self:UpdateHpBar()
  self:UpdateEnergyBar()
end
function CardObjectModel:Speak(dialogueFrameType, content)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ObjectViewSpeak", self:GetViewModelTag(), dialogueFrameType, content)
end
function CardObjectModel:ForceShowSelf(show)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "SetObjectViewVisible", self:GetViewModelTag(), show)
end
function CardObjectModel:ShowStageClearTargetMark(stageCompleteType, show)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ObjectViewShowTargetMark", self:GetViewModelTag(), stageCompleteType, show)
end
function CardObjectModel:HideAllStageClearTargetMark()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ObjectViewHideAllTargetMark", self:GetViewModelTag())
end
function CardObjectModel:ReviveRender()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ObjectViewRevive", self:GetViewModelTag())
end
return CardObjectModel
