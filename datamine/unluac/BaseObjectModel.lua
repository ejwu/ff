local BaseLogicModel = __Require("battle.object.logicModel.BaseLogicModel")
local BaseObjectModel = class("BaseObjectModel", BaseLogicModel)
function BaseObjectModel:ctor(...)
  BaseLogicModel.ctor(self, ...)
end
function BaseObjectModel:Init()
  BaseLogicModel.Init(self)
  self:InitViewModel()
  self:InitDrivers()
  self:InitInnerBuffImmune()
  self:InitWeatherImmune()
end
function BaseObjectModel:InitValue()
  BaseLogicModel.InitValue(self)
end
function BaseObjectModel:InitInnateProperty()
  BaseLogicModel.InitInnateProperty(self)
  self.state = {
    cur = OState.SLEEP,
    pre = OState.SLEEP,
    pause = false,
    towards = BattleObjTowards.FORWARD
  }
  self.extraStateInfo = __Require("battle.object.organ.BaseObjectState").new()
  self.buffs = {
    skillCounter = {},
    idx = {},
    id = {}
  }
  self.halos = {
    idx = {},
    id = {}
  }
  self.shield = {}
  self.qteBuffs = {
    idx = {},
    id = {}
  }
  self.castingSkillId = nil
  self.ciScene = nil
  self.isInHighlight = false
  self.wave = ValueConstants.V_NONE
  self.teamIndex = ValueConstants.V_NONE
  self.objDieEventHandler_ = nil
  self.objReviveEventHandler_ = nil
  self.objCastEventHandler_ = nil
  self.objLuckEventHandler_ = nil
  self.countdowns = {energy = 1}
  self:InitActionAnimationConfig()
end
function BaseObjectModel:InitUnitProperty()
  self.location = ObjectLocation.New(0, 0, 0, 0)
  self.zorderInBattle = 0
  self:InitEnergy()
  self.hate = 0
end
function BaseObjectModel:InitActionAnimationConfig()
  self.actionAnimationConfig = {}
end
function BaseObjectModel:InitViewModel()
end
function BaseObjectModel:InitDrivers()
  self.randomDriver = nil
  self.moveDriver = nil
  self.attackDriver = nil
  self.castDriver = nil
  self.phaseDriver = nil
  self.tintDriver = nil
  self.triggerDriver = nil
  self.artifactTalentDriver = nil
end
function BaseObjectModel:ActivateDrivers()
end
function BaseObjectModel:InitInnerBuffImmune()
end
function BaseObjectModel:InitWeatherImmune()
end
function BaseObjectModel:InitEnergy()
  self.energy = 0
  self.energyRecoverRate = 0
end
function BaseObjectModel:CanAct()
  return self:GetObjectExtraStateInfo():CanAct()
end
function BaseObjectModel:AwakeObject()
  self:SetState(OState.NORMAL)
end
function BaseObjectModel:SleepObject()
  self:SetState(OState.SLEEP)
end
function BaseObjectModel:SetObjectAbnormalState(abnormalState, b)
  self:GetObjectExtraStateInfo():SetAbnormalState(abnormalState, b)
end
function BaseObjectModel:InAbnormalState(abnormalState)
  return self:GetObjectExtraStateInfo():GetAbnormalState(abnormalState)
end
function BaseObjectModel:SetObjectAbnormalStateImmune(abnormalState, b)
  self:GetObjectExtraStateInfo():SetAbnormalImmune(abnormalState, b)
end
function BaseObjectModel:GetObjectAbnormalStateImmune(abnormalState)
  return self:GetObjectExtraStateInfo():GetAbnormalImmune(abnormalState)
end
function BaseObjectModel:ImmuneAbnormalStateByBuffType(buffType)
  return self:GetObjectExtraStateInfo():ImmuneAbnormalStateByBuffType(buffType)
end
function BaseObjectModel:SetAllImmune(immune)
  self:SetObjectDamageSwitch(immune)
  self:SetObjectAbnormalStateImmune(AbnormalState.SILENT, immune)
  self:SetObjectAbnormalStateImmune(AbnormalState.STUN, immune)
  self:SetObjectAbnormalStateImmune(AbnormalState.FREEZE, immune)
  self:SetObjectAbnormalStateImmune(AbnormalState.ENCHANTING, immune)
end
function BaseObjectModel:GetObjectWeatherImmune(weatherId)
  return self:GetObjectExtraStateInfo():GetWeatherImmuneByWeatherId(weatherId)
end
function BaseObjectModel:GetObjectInnerBuffImmune(buffType)
  return self:GetObjectExtraStateInfo():GetInnerBuffImmuneByBuffType(buffType)
end
function BaseObjectModel:GetObjectBuffImmune(buffType)
  return self:GetObjectExtraStateInfo():GetBuffImmuneByBuffType(buffType)
end
function BaseObjectModel:SetObjectBuffImmune(buffType, skillId, immune)
  self:GetObjectExtraStateInfo():SetBuffImmuneByBuffType(buffType, skillId, immune)
end
function BaseObjectModel:IsObjectImmuneBuff(buffType)
  return self:GetObjectInnerBuffImmune(buffType) or self:GetObjectBuffImmune(buffType)
end
function BaseObjectModel:DamageImmuneByDamageType(damageType)
  local result = self:GetObjectExtraStateInfo():GetDamageImmune(damageType) or self:GetObjectExtraStateInfo():GetDamageImmune(DamageType.PHYSICAL) or self:GetObjectExtraStateInfo():GetGlobalDamageImmune(damageType) or self:GetObjectExtraStateInfo():GetGlobalDamageImmune(DamageType.PHYSICAL) or self:GetObjectDamageSwitch()
  return result
end
function BaseObjectModel:SetDamageImmuneByDamageType(damageType, immune)
  self:GetObjectExtraStateInfo():SetDamageImmune(damageType, immune)
end
function BaseObjectModel:SetObjectDamageSwitch(b)
  self:GetObjectExtraStateInfo():SetDamageSwitch(b)
end
function BaseObjectModel:GetObjectDamageSwitch()
  return self:GetObjectExtraStateInfo():GetDamageSwitch()
end
function BaseObjectModel:IsPause()
  return self.state.pause
end
function BaseObjectModel:PauseLogic()
  self.state.pause = true
end
function BaseObjectModel:ResumeLogic()
  self.state.pause = false
end
function BaseObjectModel:IsAlive()
  return true
end
function BaseObjectModel:CanDie()
  return not self:InAbnormalState(AbnormalState.UNDEAD)
end
function BaseObjectModel:SetCanBeSearched(canBeSearched)
  self:SetObjectAbnormalState(AbnormalState.LUCK, not canBeSearched)
end
function BaseObjectModel:CanBeSearched()
  return not self:InAbnormalState(AbnormalState.LUCK)
end
function BaseObjectModel:Update(dt)
  if self:IsPause() then
    return
  end
end
function BaseObjectModel:SeekAttakTarget()
end
function BaseObjectModel:LostAttackTarget()
end
function BaseObjectModel:GetAttackRange()
  return 0
end
function BaseObjectModel:Attack(targetTag)
end
function BaseObjectModel:GetMoveSpeed()
  return 0
end
function BaseObjectModel:BeAttacked(damageData, noTrigger)
end
function BaseObjectModel:HpChange(damageData)
end
function BaseObjectModel:HpPercentChangeForce(percent)
end
function BaseObjectModel:BeHealed(healData, noTrigger)
end
function BaseObjectModel:GetHate()
  return self.hate
end
function BaseObjectModel:SetHate(hate)
  self.hate = hate
end
function BaseObjectModel:ForceUndeadOnce(minHp)
end
function BaseObjectModel:FixAnimationScaleByATKRate()
end
function BaseObjectModel:Cast(skillId)
end
function BaseObjectModel:BeCasted(buffInfo)
  return false
end
function BaseObjectModel:CastAllHalos()
end
function BaseObjectModel:CanCastConnectByAbnormalState()
  return false
end
function BaseObjectModel:CanTriggerBuff(skillId, buffType, triggerActionType)
  return true
end
function BaseObjectModel:CostTriggerBuffResources(skillId, buffType, triggerActionType, cd)
end
function BaseObjectModel:Move(dt, targetTag)
end
function BaseObjectModel:ForceMove(targetPos, moveActionName, moveOverCallback)
end
function BaseObjectModel:AddBuff(buff)
  local buffId = buff:GetBuffId()
  local skillId = buff:GetSkillId()
  local buffType = buff:GetBuffType()
  self.buffs.id[tostring(buffId)] = buff
  table.insert(self.buffs.idx, 1, buff)
  if nil == self.buffs.skillCounter[tostring(skillId)] then
    self.buffs.skillCounter[tostring(skillId)] = 0
  end
  self.buffs.skillCounter[tostring(skillId)] = self.buffs.skillCounter[tostring(skillId)] + 1
  if ConfigBuffType.SHIELD == buffType then
    table.insert(self.shield, 1, buff)
  end
  if BuffCauseEffectTime.ADD2OBJ == buff:GetCauseEffectTime() then
    buff:OnCauseEffectEnter()
  end
end
function BaseObjectModel:RemoveBuff(buff)
  local buffId = buff:GetBuffId()
  local skillId = buff:GetSkillId()
  local buffType = buff:GetBuffType()
  self.buffs.id[tostring(buffId)] = nil
  for i = #self.buffs.idx, 1, -1 do
    if buffId == self.buffs.idx[i]:GetBuffId() then
      table.remove(self.buffs.idx, i)
      break
    end
  end
  if nil ~= self.buffs.skillCounter[tostring(skillId)] then
    self.buffs.skillCounter[tostring(skillId)] = self.buffs.skillCounter[tostring(skillId)] - 1
    if 0 == self.buffs.skillCounter[tostring(skillId)] then
      self.buffs.skillCounter[tostring(skillId)] = nil
      self:RemoveInfecInfo(skillId)
    end
  else
    BattleUtils.PrintBattleWaringLog("here remove a buff and decrease skill counter but can not find skill counter -> " .. tostring(skillId) .. ", " .. tostring(buffType))
  end
  if ConfigBuffType.SHIELD == buffType then
    for i = #self.shield, 1, -1 do
      if buffId == self.shield[i]:GetBuffId() then
        table.remove(self.shield, i)
        break
      end
    end
  end
end
function BaseObjectModel:ClearBuff()
  for i = #self.buffs.idx, 1, -1 do
    local buff = self.buffs.idx[i]
    self.buffs.id[tostring(buff:GetBuffId())] = nil
    buff:OnRecoverEffectEnter()
  end
end
function BaseObjectModel:AddHalo(buff)
  local buffId = buff:GetBuffId()
  local skillId = buff:GetSkillId()
  local buffType = buff:GetBuffType()
  self.halos.id[tostring(buffId)] = buff
  table.insert(self.halos.idx, 1, buff)
  if ConfigBuffType.SHIELD == buffType then
    table.insert(self.shield, 1, buff)
  end
  if BuffCauseEffectTime.ADD2OBJ == buff:GetCauseEffectTime() then
    buff:OnCauseEffectEnter()
  end
end
function BaseObjectModel:RemoveHalo(buff)
  local buffId = buff:GetBuffId()
  local buffType = buff:GetBuffType()
  self.halos.id[tostring(buffId)] = nil
  for i = #self.halos.idx, 1, -1 do
    if buffId == self.halos.idx[i]:GetBuffId() then
      table.remove(self.halos.idx, i)
      break
    end
  end
  if ConfigBuffType.SHIELD == buffType then
    for i = #self.shield, 1, -1 do
      if self.shield[i]:GetBuffId() == bid then
        table.remove(self.shield, i)
        break
      end
    end
  end
end
function BaseObjectModel:GetBuffsByBuffId(buffId, onlyBuff)
  local result = {}
  local buff = self:GetBuffByBuffId(buffId)
  if nil ~= buff then
    table.insert(result, 1, buff)
  end
  if false == onlyBuff then
    buff = self:GetHaloByBuffId(buffId)
    if nil ~= buff then
      table.insert(result, 1, buff)
    end
  end
  return result
end
function BaseObjectModel:GetBuffByBuffId(buffId)
  return self.buffs.id[tostring(buffId)]
end
function BaseObjectModel:GetHaloByBuffId(buffId)
  return self.halos.id[tostring(buffId)]
end
function BaseObjectModel:GetBuffsByBuffType(buffType, onlyBuff)
  local result = {}
  for i = #self.buffs.idx, 1, -1 do
    if buffType == self.buffs.idx[i]:GetBuffType() then
      table.insert(result, 1, self.buffs.idx[i])
    end
  end
  if false == onlyBuff then
    for i = #self.halos.idx, 1, -1 do
      if buffType == self.halos.idx[i]:GetBuffType() then
        table.insert(result, 1, self.halos.idx[i])
      end
    end
  end
  return result
end
function BaseObjectModel:GetBuffBySkillId(skillId, buffType, onlyBuff)
  local buff
  for i = #self.buffs.idx, 1, -1 do
    buff = self.buffs.idx[i]
    if buffType == buff:GetBuffType() and skillId == buff:GetSkillId() then
      return buff
    end
  end
  if false == onlyBuff then
    for i = #self.halos.idx, 1, -1 do
      buff = self.halos.idx[i]
      if buffType == buff:GetBuffType() and skillId == buff:GetSkillId() then
        return buff
      end
    end
  end
  return nil
end
function BaseObjectModel:HasBuffByBuffType(buffType, onlyBuff)
  for i, v in ipairs(self.buffs.idx) do
    if buffType == v:GetBuffType() then
      return true
    end
  end
  if false == onlyBuff then
    for i, v in ipairs(self.halos.idx) do
      if buffType == v:GetBuffType() then
        return true
      end
    end
  end
  return false
end
function BaseObjectModel:HasBuffByBuffIconType(iconType, value)
  if true == BattleUtils.IsTable(value) then
    return
  end
  for i, v in ipairs(self.buffs.idx) do
    if iconType == v:GetBuffIconType() and v:GetBuffOriginValue() * value >= 0 then
      return true
    end
  end
  for i, v in ipairs(self.halos.idx) do
    if iconType == v:GetBuffIconType() and v:GetBuffOriginValue() * value >= 0 then
      return true
    end
  end
  return false
end
function BaseObjectModel:IsInfectBySkillId(skillId)
  return false
end
function BaseObjectModel:AddQTE(qteBuffsInfo)
end
function BaseObjectModel:RemoveQTE(skillId)
end
function BaseObjectModel:RemoveQTEBuff(skillId, buffType)
end
function BaseObjectModel:GetQTEBySkillId(skillId)
  return self.qteBuffs.id[tostring(skillId)]
end
function BaseObjectModel:HasQTE()
  return 0 < #self.qteBuffs.idx
end
function BaseObjectModel:AddInfectInfo(infectInfo)
end
function BaseObjectModel:RemoveInfecInfo(skillId)
end
function BaseObjectModel:GetHPPercent()
  return 0
end
function BaseObjectModel:GetRecordDeltaHp()
  return ConfigMonsterRecordDeltaHP.DONT
end
function BaseObjectModel:AddEnergy(delta)
  self.energy = math.max(0, math.min(self:GetMaxEnergy(), self:GetEnergy() + delta))
end
function BaseObjectModel:GetEnergy()
  return self.energy
end
function BaseObjectModel:GetMaxEnergy()
  return MAX_ENERGY
end
function BaseObjectModel:GetEnergyPercent()
  return self:GetEnergy() / self:GetMaxEnergy()
end
function BaseObjectModel:EnergyPercentChangeForce(percent)
  local energy = self:GetMaxEnergy() * percent
  self.energy = energy
end
function BaseObjectModel:GetEnergyRecoverRate()
  return self.energyRecoverRate
end
function BaseObjectModel:AddEnergyRecoverRate(delta)
  self.energyRecoverRate = self.energyRecoverRate + delta
end
function BaseObjectModel:GetEnergyRecoverRatePerS()
  return 0
end
function BaseObjectModel:CanEnterNextWave()
  return true
end
function BaseObjectModel:EnterNextWave(nextWave)
  self:SetObjectWave(nextWave)
end
function BaseObjectModel:Win()
end
function BaseObjectModel:StartEscape()
end
function BaseObjectModel:OverEscape()
end
function BaseObjectModel:AppearFromEscape()
end
function BaseObjectModel:CalcEscapeTargetPosition()
  return nil
end
function BaseObjectModel:GetAppearWaveAfterEscape()
  return nil
end
function BaseObjectModel:SetAppearWaveAfterEscape(wave)
end
function BaseObjectModel:BlewOff(distance)
end
function BaseObjectModel:DieBegin()
end
function BaseObjectModel:Die()
end
function BaseObjectModel:DieEnd()
end
function BaseObjectModel:KillSelf(nature)
end
function BaseObjectModel:Destroy()
end
function BaseObjectModel:KillByNature()
  self:KillSelf(true)
  self:DieEnd()
end
function BaseObjectModel:Revive(reviveHpPercent, reviveEnergyPercent, healData)
end
function BaseObjectModel:ViewTransform(oriSkinId, oriActionName, targetSkinId, targetActionName)
end
function BaseObjectModel:RefreshViewModel(spineDataStruct, avatarScale)
end
function BaseObjectModel:Stun(valid)
  self:SetObjectAbnormalState(AbnormalState.STUN, valid)
end
function BaseObjectModel:Freeze(valid)
  self:SetObjectAbnormalState(AbnormalState.FREEZE, valid)
end
function BaseObjectModel:Silent(valid)
  self:SetObjectAbnormalState(AbnormalState.SILENT, valid)
end
function BaseObjectModel:Enchanting(valid)
  self:SetObjectAbnormalState(AbnormalState.ENCHANTING, valid)
end
function BaseObjectModel:DoAnimation()
end
function BaseObjectModel:ClearAnimations()
end
function BaseObjectModel:SetAnimationTimeScale()
end
function BaseObjectModel:GetAnimationTimeScale()
end
function BaseObjectModel:GetCurrentAnimationName()
  return nil
end
function BaseObjectModel:ForceStun(valid)
end
function BaseObjectModel:ForceDisappear(actionName, targetPos, disappearCallback)
end
function BaseObjectModel:ChangePosition(p)
  self:UpdateLocation()
end
function BaseObjectModel:GetLocation()
  return self.location
end
function BaseObjectModel:UpdateLocation()
end
function BaseObjectModel:ResetLocation()
end
function BaseObjectModel:GetRotate()
end
function BaseObjectModel:SetRotate(angle)
end
function BaseObjectModel:SetOrientation(towards)
end
function BaseObjectModel:GetOrientation()
  return true
end
function BaseObjectModel:GetTowards()
  return self:GetOrientation() and BattleObjTowards.FORWARD or BattleObjTowards.NEGATIVE
end
function BaseObjectModel:GetStaticCollisionBox()
  return nil
end
function BaseObjectModel:GetStaticCollisionBoxInBattleRoot()
  return nil
end
function BaseObjectModel:GetStaticViewBox()
  return nil
end
function BaseObjectModel:IsHighlight()
  return self.isInHighlight
end
function BaseObjectModel:SetHighlight(highlight)
  self.isInHighlight = highlight
end
function BaseObjectModel:GetZOrder()
  return self.zorderInBattle
end
function BaseObjectModel:SetZOrder(zorder)
  self.zorderInBattle = zorder
end
function BaseObjectModel:GetDefaultZOrder()
  return self:GetObjInfo().defaultZOrder
end
function BaseObjectModel:RegisterObjectEventHandler()
end
function BaseObjectModel:UnregistObjectEventHandler()
end
function BaseObjectModel:RegistViewModelEventHandler()
end
function BaseObjectModel:UnregistViewModelEventHandler()
end
function BaseObjectModel:ObjectEventDieHandler(...)
end
function BaseObjectModel:ObjectEventReviveHandler(...)
end
function BaseObjectModel:ObjectEventCastHandler(...)
end
function BaseObjectModel:ObjectEventLuckHandler(...)
end
function BaseObjectModel:ObjectEventSlayHandler(...)
end
function BaseObjectModel:GetObjectName()
  return "Tag_" .. self:GetOTag()
end
function BaseObjectModel:GetObjectConfigId()
  return self:GetObjInfo().cardId
end
function BaseObjectModel:GetObjectConfig()
  return CardUtils.GetCardConfig(self:GetObjectConfigId())
end
function BaseObjectModel:GetObjectSkinId()
  return self:GetObjInfo().skinId
end
function BaseObjectModel:GetObjectFeature()
  return self:GetObjInfo().objectFeature
end
function BaseObjectModel:IsEnemy(o)
  return self:GetObjInfo().isEnemy
end
function BaseObjectModel:GetOCareer()
  return self:GetObjInfo().career
end
function BaseObjectModel:IsScarecrow()
  return false
end
function BaseObjectModel:GetTeamPosition()
  return self:GetObjInfo().teamPosition
end
function BaseObjectModel:GetObjectLevel()
  return 1
end
function BaseObjectModel:GetOFeature()
  return self:GetObjInfo().objectFeature
end
function BaseObjectModel:GetObjectMosnterType()
  return ConfigMonsterType.BASE
end
function BaseObjectModel:GetState(i)
  if -1 == i then
    return self.state.pre
  else
    return self.state.cur
  end
end
function BaseObjectModel:SetState(s, i)
  if -1 == i then
    self.state.pre = s
  else
    self.state.pre = self.state.cur
    self.state.cur = s
  end
end
function BaseObjectModel:GetObjectExtraStateInfo()
  return self.extraStateInfo
end
function BaseObjectModel:GetMainProperty()
  return nil
end
function BaseObjectModel:SetActionAnimationConfigBySkillId(skillId, animationConfig)
  self.actionAnimationConfig[tostring(skillId)] = animationConfig
end
function BaseObjectModel:GetActionAnimationConfigBySkillId(skillId)
  return self.actionAnimationConfig[tostring(skillId)]
end
function BaseObjectModel:HasAnimationByName(animationName)
  return self:GetViewModel():HasAnimationByName(animationName)
end
function BaseObjectModel:GetObjectWave()
  return self.wave
end
function BaseObjectModel:SetObjectWave(wave)
  self.wave = wave
end
function BaseObjectModel:GetObjectTeamIndex()
  return self.teamIndex
end
function BaseObjectModel:SetObjectTeamIndex(teamIndex)
  self.teamIndex = teamIndex
end
function BaseObjectModel:GetPropertyByObjP(propertyType, isOriginal)
  return 0
end
function BaseObjectModel:RefreshRenderViewPosition()
end
function BaseObjectModel:RefreshRenderViewTowards()
end
function BaseObjectModel:RefreshRenderAnimation()
end
function BaseObjectModel:ClearRenderAnimations()
end
function BaseObjectModel:RefreshRenderAnimationTimeScale(timeScale)
end
function BaseObjectModel:RefreshConnectButtonsByEnergy()
end
function BaseObjectModel:RefreshConnectButtonsByState()
end
function BaseObjectModel:EnableConnectSkillButton(skillId, enable)
end
function BaseObjectModel:UpdateHpBar()
end
function BaseObjectModel:ShowImmune()
end
function BaseObjectModel:AddBuffIcon(iconType, value)
end
function BaseObjectModel:RemoveBuffIcon(iconType, value)
end
function BaseObjectModel:ShowHurtEffect(effectData)
end
function BaseObjectModel:ShowAttachEffect(visible, buffId, effectData)
end
function BaseObjectModel:InitObjectRender()
end
function BaseObjectModel:Speak(dialogueFrameType, content)
end
function BaseObjectModel:ForceShowSelf(show)
end
function BaseObjectModel:ReviveRender()
end
function BaseObjectModel:ShowStageClearTargetMark(stageCompleteType, show)
end
function BaseObjectModel:HideAllStageClearTargetMark()
end
return BaseObjectModel
