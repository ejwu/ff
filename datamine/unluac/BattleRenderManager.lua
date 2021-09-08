local BaseBattleManager = __Require("battle.manager.BaseBattleManager")
local BattleRenderManager = class("BattleRenderManager", BaseBattleManager)
local BUY_REVIVAL_LAYER_TAG = 2301
local FORCE_QUIT_LAYER_TAG = 2311
local PAUSE_SCENE_TAG = 1001
local WAVE_TRANSITION_SCENE_TAG = 1201
local GAME_RESULT_LAYER_TAG = 2321
local SKADA_LAYER_TAG = 2322
local BattleBgmDefault = {
  SHEET_NAME = AUDIOS.BGM.name,
  CUE_NAME = AUDIOS.BGM.Food_Battle.id
}
function BattleRenderManager:ctor(...)
  BaseBattleManager.ctor(self, ...)
end
function BattleRenderManager:Init()
  BaseBattleManager.Init(self)
  self:InitValue()
end
function BattleRenderManager:InitValue()
  self.objectViews = {}
  self.qteAttachViews = {}
  self.playerViews = {}
  self.battleTouchEnable = false
  self.connectButtons = {}
  self.connectButtonsIndex = {}
  self.ciScenes = {
    pause = {},
    normal = {}
  }
  self.pauseActions = {
    pauseScene = {},
    normalScene = {},
    battle = {}
  }
  self.friendDialougeNodes = {}
  self.enemyDialougeNodes = {}
  self.friendDialougeY = 0
  self.enemyDialougeY = 0
  self.dialougeTagCounter = 0
  self.quitLock = false
  self.restartLock = false
end
function BattleRenderManager:EnterBattle()
  self:InitBattleDrivers()
end
function BattleRenderManager:InitBattleDrivers()
  local resLoadDriverClassName = "battle.battleDriver.BattleResLoadDriver"
  if self:IsTagMatchBattle() then
    resLoadDriverClassName = "battle.battleDriver.TagMatchResLoadDriver"
  end
  local resLoadDriver = __Require(resLoadDriverClassName).new({owner = self})
  self:SetBattleDriver(BattleDriverType.RES_LOADER, resLoadDriver)
end
function BattleRenderManager:InitGuideDriver()
  local guideDriver = __Require("battle.battleDriver.RenderGuideDriver").new({owner = self})
  self:SetBattleDriver(BattleDriverType.GUIDE_DRIVER, guideDriver)
end
function BattleRenderManager:InitButtonClickHandler()
  local battleScene = self:GetBattleScene()
  if nil ~= battleScene.viewData and nil ~= battleScene.viewData.actionButtons then
    for _, button in ipairs(battleScene.viewData.actionButtons) do
      display.commonUIParams(button, {
        cb = handler(self, self.ButtonsClickHandler),
        animate = false
      })
    end
  end
  if BattleConfigUtils.IsScreenRecordEnable() then
    local screenRecordBtn = self:GetBattleScene().viewData.screenRecordBtn
    if nil ~= screenRecordBtn then
      display.commonUIParams(screenRecordBtn, {
        cb = handler(self, self.ScreenRecordClickHandler)
      })
    end
  end
end
function BattleRenderManager:StartLoadResources()
  self:LoadSoundResources()
  self:LoadRenderResources(1)
end
function BattleRenderManager:LoadSoundResources()
  self:GetBattleDriver(BattleDriverType.RES_LOADER):LoadSoundResources()
end
function BattleRenderManager:LoadRenderResources(wave)
  self:GetBattleDriver(BattleDriverType.RES_LOADER):OnLogicEnter(wave)
end
function BattleRenderManager:LoadResourcesOver()
  self:InitButtonClickHandler()
  self:RefreshTimeLabel(self:GetBattleConstructData().time)
end
function BattleRenderManager:LogicInitOver()
  self:InitGuideDriver()
  self:InitBattleModule()
end
function BattleRenderManager:MainUpdate(dt)
  for _, pauseCIScene in pairs(self.ciScenes.pause) do
    pauseCIScene:update(dt)
  end
  for _, normalCIScene in pairs(self.ciScenes.normal) do
    normalCIScene:update(dt)
  end
end
function BattleRenderManager:ShowEnterNextWave(wave, hasElite, hasBoss)
  self:ShowNextWaveRemind(wave, function()
    self:SetBattleTouchEnable(true)
    self:StartRenderCountdown()
    if not self:IsCalculator() then
      self:AddPlayerOperate("G_BattleLogicMgr", "RenderStartNextWaveHandler")
    end
  end)
  self:ShowBossAppear(hasElite, hasBoss)
end
function BattleRenderManager:ShowNextWaveRemind(wave, callback)
  local battleScene = self:GetBattleScene()
  local uiLayer = battleScene.viewData.uiLayer
  local roundBg = display.newImageView(_res("ui/battle/battle_bg_black.png"), -display.width * 0.5, display.height * 0.5, {
    scale9 = true,
    size = cc.size(display.width, 144)
  })
  uiLayer:addChild(roundBg, BATTLE_E_ZORDER.UI_EFFECT)
  local plate = display.newNSprite(_res("ui/battle/battle_bg_switch.png"), display.width * 0.5, display.height * 0.5)
  uiLayer:addChild(plate, BATTLE_E_ZORDER.UI_EFFECT)
  plate:setScale(0)
  local knifeDeltaP = cc.p(50, -50)
  local knife = display.newNSprite(_res("ui/battle/battle_ico_switch_1.png"), display.width * 0.5 - knifeDeltaP.x, display.height * 0.5 - knifeDeltaP.y)
  uiLayer:addChild(knife, BATTLE_E_ZORDER.UI_EFFECT)
  knife:setOpacity(0)
  local forkDeltaP = cc.p(-50, -50)
  local fork = display.newNSprite(_res("ui/battle/battle_ico_switch_2.png"), display.width * 0.5 - forkDeltaP.x, display.height * 0.5 - forkDeltaP.y)
  uiLayer:addChild(fork, BATTLE_E_ZORDER.UI_EFFECT)
  fork:setOpacity(0)
  local labelBg = display.newNSprite(_res("ui/battle/battle_bg_switch_word.png"), 0, 0)
  display.commonUIParams(labelBg, {
    ap = cc.p(0, 0.5),
    po = cc.p(display.width * 0.5 - labelBg:getContentSize().width * 0.5, display.height * 0.5)
  })
  uiLayer:addChild(labelBg, BATTLE_E_ZORDER.UI_EFFECT)
  labelBg:setScaleX(0)
  local waveStr = ""
  if 1 == wave then
    waveStr = __("\230\136\152\230\150\151\229\188\128\229\167\139")
  else
    waveStr = string.format(__("\231\172\172%s\229\155\158\229\144\136"), CommonUtils.GetChineseNumber(checkint(wave)))
  end
  local waveLabel = display.newLabel(display.width * 0.5, display.height * 0.5, {
    text = waveStr,
    fontSize = 32,
    color = "#ffffff",
    ttf = true,
    font = TTF_GAME_FONT,
    outline = "#2e1e14"
  })
  uiLayer:addChild(waveLabel, BATTLE_E_ZORDER.UI_EFFECT)
  waveLabel:setOpacity(0)
  local bgActionSeq = cc.Sequence:create(cc.MoveBy:create(0.15, cc.p(display.width, 0)), cc.DelayTime:create(1.15), cc.FadeTo:create(0.2, 0), cc.RemoveSelf:create())
  roundBg:runAction(bgActionSeq)
  local plateActionSeq = cc.Sequence:create(cc.DelayTime:create(0.15), cc.ScaleTo:create(0.1, 1), cc.DelayTime:create(1.05), cc.FadeTo:create(0.2, 0), cc.RemoveSelf:create())
  plate:runAction(plateActionSeq)
  local knifeActionSeq = cc.Sequence:create(cc.DelayTime:create(0.2), cc.Spawn:create(cc.MoveBy:create(0.1, knifeDeltaP), cc.FadeTo:create(0.1, 255)), cc.DelayTime:create(1), cc.FadeTo:create(0.2, 0), cc.RemoveSelf:create())
  knife:runAction(knifeActionSeq)
  local forkActionSeq = cc.Sequence:create(cc.DelayTime:create(0.25), cc.Spawn:create(cc.MoveBy:create(0.1, forkDeltaP), cc.FadeTo:create(0.1, 255)), cc.DelayTime:create(0.95), cc.FadeTo:create(0.2, 0), cc.RemoveSelf:create())
  fork:runAction(forkActionSeq)
  local labelBgActionSeq = cc.Sequence:create(cc.DelayTime:create(0.35), cc.EaseSineOut:create(cc.ScaleTo:create(0.15, 1, 1)), cc.DelayTime:create(0.8), cc.FadeTo:create(0.2, 0), cc.RemoveSelf:create())
  labelBg:runAction(labelBgActionSeq)
  local labelActionSeq = cc.Sequence:create(cc.DelayTime:create(0.35), cc.FadeTo:create(0.2, 255), cc.DelayTime:create(0.75), cc.FadeTo:create(0.2, 0), cc.CallFunc:create(function()
    if callback then
      callback()
    end
  end), cc.RemoveSelf:create())
  waveLabel:runAction(labelActionSeq)
end
function BattleRenderManager:ShowBossAppear(hasElite, hasBoss)
  if not hasBoss then
    return
  end
  local battleScene = self:GetBattleScene()
  local waringBg = display.newNSprite(_res("ui/battle/battle_bg_warning.png"), display.width * 0.5, display.height * 0.5)
  local waringBgSize = waringBg:getContentSize()
  waringBg:setScaleX(display.width / waringBgSize.width)
  waringBg:setScaleY(display.height / waringBgSize.height)
  battleScene.viewData.uiLayer:addChild(waringBg)
  waringBg:setOpacity(0)
  local waringActionSeq = cc.Sequence:create(cc.Repeat:create(cc.Sequence:create(cc.FadeTo:create(0.5, 255), cc.DelayTime:create(0.25), cc.FadeTo:create(0.5, 0)), 3), cc.RemoveSelf:create())
  waringBg:runAction(waringActionSeq)
end
function BattleRenderManager:ShowBattleEffectLayer(show)
  self:GetBattleScene().viewData.effectLayer:setVisible(show)
end
function BattleRenderManager:StartRenderCountdown()
  self:GetBattleScene():StartAliveCountdown()
end
function BattleRenderManager:RefreshBattleBgm(teamMembers)
  local defaultBgmData = self:GetDefaultBattleBGMInfo()
  local bgmData = {
    name = defaultBgmData.SHEET_NAME,
    id = defaultBgmData.CUE_NAME
  }
  for memberIndex, memberObj in ipairs(teamMembers or {}) do
    local cardId = memberObj:GetObjectConfigId()
    local skinId = memberObj:GetObjectSkinId()
    local skinConf = CardUtils.GetCardSkinConfig(skinId)
    if string.len(checkstr(skinConf.bgm)) > 0 then
      local datas = string.split2(skinConf.bgm, ",")
      bgmData.name = datas[1]
      bgmData.id = datas[2]
      break
    end
  end
  self:GetBattleScene():PlayBattleBgm(bgmData.name, bgmData.id)
end
function BattleRenderManager:GetDefaultBattleBGMInfo()
  return BattleBgmDefault
end
function BattleRenderManager:CreateAObjectView(viewModelTag, objInfo, visible)
  local cardId = objInfo.cardId
  local cardConfig = CardUtils.GetCardConfig(cardId)
  local viewClassName = "battle.objectView.cardObject.BaseObjectView"
  if CardUtils.IsMonsterCard(cardId) then
    local monsterType = checkint(cardConfig.type)
    if ConfigMonsterType.BOSS == monsterType then
      viewClassName = "battle.objectView.cardObject.BossView"
    else
      viewClassName = "battle.objectView.cardObject.MonsterView"
    end
  else
    viewClassName = "battle.objectView.cardObject.CardObjectView"
  end
  local viewInfo = ObjectViewConstructStruct.New(cardId, objInfo.skinId, objInfo.avatarScale, self:GetSpineAvatarScale2CardByCardId(cardId), objInfo.isEnemy)
  local view = __Require(viewClassName).new({tag = viewModelTag, viewInfo = viewInfo})
  self:AddAObjectView(viewModelTag, view)
  self:GetBattleRoot():addChild(view)
  if nil ~= visible then
    view:SetObjectVisible(visible)
  end
end
function BattleRenderManager:SetObjectViewVisible(viewModelTag, visible)
  local view = self:GetAObjectView(viewModelTag)
  if nil ~= view then
    view:SetObjectVisible(visible)
  end
end
function BattleRenderManager:CreateABeckonObjectView(viewModelTag, tag, objInfo)
  local cardId = objInfo.cardId
  local viewClassName = "battle.objectView.cardObject.BeckonView"
  local viewInfo = ObjectViewConstructStruct.New(cardId, objInfo.skinId, objInfo.avatarScale, self:GetSpineAvatarScale2CardByCardId(cardId), objInfo.isEnemy)
  local view = __Require(viewClassName).new({
    tag = viewModelTag,
    viewInfo = viewInfo,
    logicTag = tag
  })
  self:AddAObjectView(viewModelTag, view)
  self:GetBattleRoot():addChild(view)
end
function BattleRenderManager:RefreshObjectView(tag, renderTransformData, renderStateData)
  self:RefreshObjectViewTransform(tag, renderTransformData)
  self:RefreshObjectViewHPState(tag, renderStateData)
end
function BattleRenderManager:RefreshObjectViewTransform(tag, renderTransformData)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    self:SetObjectViewPositionByView(view, renderTransformData.x, renderTransformData.y)
    self:SetObjectViewTowardsByView(view, renderTransformData.towards)
    self:SetObjectViewZOrderByView(view, renderTransformData.zorder)
  end
end
function BattleRenderManager:SetObjectViewPosition(tag, x, y)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    self:SetObjectViewPositionByView(view, x, y)
  end
end
function BattleRenderManager:SetObjectViewPositionByView(view, x, y)
  view:setPositionX(x)
  view:setPositionY(y)
end
function BattleRenderManager:SetObjectViewTowards(tag, towards)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    self:SetObjectViewTowardsByView(view, towards)
  end
end
function BattleRenderManager:SetObjectViewTowardsByView(view, towards)
  local sign = 1
  if BattleObjTowards.FORWARD == towards then
    sign = 1
  elseif BattleObjTowards.NEGATIVE == towards then
    sign = -1
  end
  local avatar = view:GetAvatar()
  if nil ~= avatar then
    avatar:setScaleX(math.abs(avatar:getScaleX()) * sign)
  end
end
function BattleRenderManager:SetObjectViewZOrder(tag, zorder)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    self:SetObjectViewZOrderByView(view, zorder)
  end
end
function BattleRenderManager:SetObjectViewZOrderByView(view, zorder)
  view:setLocalZOrder(zorder)
end
function BattleRenderManager:SetObjectViewRotate(tag, rotate)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    view:GetAvatar():setRotation(rotate)
  end
end
function BattleRenderManager:RefreshObjectViewHPState(tag, renderStateData)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    self:SetObjectViewHpPercentByView(view, renderStateData.hpPercent)
    self:SetObjectViewEnergyPercentByView(view, renderStateData.energyPercent)
  end
end
function BattleRenderManager:SetObjectViewHpPercent(tag, hpPercent)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    self:SetObjectViewHpPercentByView(view, hpPercent)
  end
end
function BattleRenderManager:SetObjectViewHpPercentByView(view, hpPercent)
  view:UpdateHpBar(hpPercent)
end
function BattleRenderManager:SetObjectViewEnergyPercent(tag, energyPercent)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    self:SetObjectViewEnergyPercentByView(view, energyPercent)
  end
end
function BattleRenderManager:SetObjectViewEnergyPercentByView(view, energyPercent)
  if view and view.UpdateEnergyBar then
    view:UpdateEnergyBar(energyPercent)
  end
end
function BattleRenderManager:ObjectViewDoAnimation(tag, setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    self:SetObejectViewAnimation(view, setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
  end
end
function BattleRenderManager:SetObejectViewAnimation(view, setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
  local avatar = view.GetAvatar and view:GetAvatar() or nil
  if avatar and true == setToSetupPose then
    avatar:setToSetupPose()
  end
  if avatar and nil ~= setAnimationName then
    avatar:setAnimation(0, setAnimationName, setAnimationLoop)
  end
  if avatar and nil ~= addAnimationName then
    avatar:addAnimation(0, addAnimationName, addAnimationLoop)
  end
  if avatar and nil ~= timeScale then
    avatar:setTimeScale(timeScale)
  end
end
function BattleRenderManager:ClearObjectViewAnimations(viewModelTag)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    local avatar = view:GetAvatar()
    if nil ~= avatar then
      avatar:clearTracks()
    end
  end
end
function BattleRenderManager:ObjectViewSetAnimationTimeScale(tag, timeScale)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    local avatar = view:GetAvatar()
    if nil ~= avatar then
      avatar:setTimeScale(timeScale)
    end
  end
end
function BattleRenderManager:ShowObjectViewImmune(tag)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    view:ShowImmune()
  end
end
function BattleRenderManager:ShowObjectWeakHint(tag, weakEffectId)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    view:ShowChantBreakEffect(weakEffectId)
  end
end
function BattleRenderManager:SetObjectViewColor(tag, color)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    view:SetObjectViewColor(color)
  end
end
function BattleRenderManager:ObjectViewAddABuffIcon(tag, iconType, value)
  local view = self:GetAObjectView(tag)
  if nil ~= view and view.AddBuff then
    view:AddBuff(iconType, value)
  end
end
function BattleRenderManager:ObjectViewRemoveABuffIcon(tag, iconType, value)
  local view = self:GetAObjectView(tag)
  if nil ~= view and view.RemoveBuff then
    view:RemoveBuff(iconType, value)
  end
end
function BattleRenderManager:ObjectViewShowHurtEffect(tag, effectData)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    view:ShowHurtEffect(effectData)
    self:PlayBattleSoundEffect(effectData.effectSoundEffectId)
  end
end
function BattleRenderManager:ObjectViewShowAttachEffect(tag, visible, buffId, effectData)
  local view = self:GetAObjectView(tag)
  if nil ~= view and view.ShowAttachEffect then
    view:ShowAttachEffect(visible, buffId, effectData)
  end
end
function BattleRenderManager:ObjectViewDieBegin(tag)
  local view = self:GetAObjectView(tag)
  if nil ~= view and view.DieBegin then
    view:DieBegin()
  end
end
function BattleRenderManager:KillObjectView(tag)
  local view = self:GetAObjectView(tag)
  if nil ~= view and view.DieEnd then
    view:DieEnd()
  end
end
function BattleRenderManager:ForceRemoveAttachEffectByEffectId(effectId)
  for _, view in pairs(self.objectViews) do
    view:RemoveAttachEffectByEffectId(effectId)
  end
end
function BattleRenderManager:ObjectViewShowTargetMark(viewModelTag, stageCompleteType, show)
  local view = self:GetAObjectView(viewModelTag)
  if nil ~= view then
    view:ShowStageClearTargetMark(stageCompleteType, show)
  end
end
function BattleRenderManager:ObjectViewHideAllTargetMark(viewModelTag)
  local view = self:GetAObjectView(viewModelTag)
  if nil ~= view then
    view:HideAllStageClearTargetMark()
  end
end
function BattleRenderManager:ObjectViewRevive(viewModelTag)
  local view = self:GetAObjectView(viewModelTag)
  if nil ~= view then
    view:Revive()
  end
end
function BattleRenderManager:CreateABulletObjectView(tag, bulletInfo)
  if ConfigEffectBulletType.BASE ~= bulletInfo.otype then
    local className = self:GetBulletObjectViewClassName(bulletInfo.otype)
    local parentNode, zorder, fixedLocation = self:GetfixedBulletParentAndZOrder(bulletInfo)
    local viewInfo = BulletViewConstructorStruct.New(bulletInfo.otype, bulletInfo.causeType, bulletInfo.spineId, bulletInfo.bulletScale, bulletInfo.towards)
    local view = __Require(className).new({tag = tag, viewInfo = viewInfo})
    self:AddAObjectView(tag, view)
    if nil ~= zorder then
      parentNode:addChild(view, zorder)
    else
      parentNode:addChild(view)
    end
    if nil ~= fixedLocation then
      view:setPosition(fixedLocation)
    end
  else
  end
end
function BattleRenderManager:GetBulletObjectViewClassName(bulletType)
  local config = {
    [ConfigEffectBulletType.SPINE_EFFECT] = "battle.objectView.bulletObject.BaseSpineBulletView",
    [ConfigEffectBulletType.SPINE_PERSISTANCE] = "battle.objectView.bulletObject.SpinePersistenceBulletView",
    [ConfigEffectBulletType.SPINE_UFO_STRAIGHT] = "battle.objectView.bulletObject.SpineUFOBulletView",
    [ConfigEffectBulletType.SPINE_UFO_CURVE] = "battle.objectView.bulletObject.SpineUFOBulletView",
    [ConfigEffectBulletType.SPINE_LASER] = "battle.objectView.bulletObject.SpineLaserBulletView",
    [ConfigEffectBulletType.SPINE_WINDSTICK] = "battle.objectView.bulletObject.SpineWindStickBulletView"
  }
  return config[bulletType]
end
function BattleRenderManager:GetfixedBulletParentAndZOrder(bulletInfo)
  local parentNode, zorder, fixedLocation
  if G_BattleLogicMgr:IsBulletAdd2ObjectView(bulletInfo) then
    local targetView = self:GetAObjectView(bulletInfo.targetViewModelTag)
    if nil ~= targetView then
      parentNode = targetView
      zorder = bulletInfo.bulletZOrder < 0 and -1 or BATTLE_E_ZORDER.BULLET
      local fixedPosInView = targetView.ConvertUnitPosToRealPos and targetView:ConvertUnitPosToRealPos(bulletInfo.fixedPos) or cc.p(0, 0)
      fixedLocation = fixedPosInView
    end
  elseif ConfigEffectCauseType.SCREEN == bulletInfo.causeType then
    parentNode = self:GetBattleRoot()
  else
    parentNode = self:GetBattleRoot()
  end
  return parentNode, zorder, fixedLocation
end
function BattleRenderManager:AwakeABulletObjectView(tag)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    view:Awake()
  end
end
function BattleRenderManager:DestroyABulletObjectView(tag)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    if view.Die then
      view:Die()
    end
    self:RemoveAObjectView(tag)
  end
end
function BattleRenderManager:SetLaserPart(tag, part)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    view:SetLaserPart(part)
  end
end
function BattleRenderManager:FixLaserBodyLength(tag, length)
  local view = self:GetAObjectView(tag)
  if nil ~= view and nil ~= view.FixLaserBodyLength then
    view:FixLaserBodyLength(length)
  end
end
function BattleRenderManager:CreateAAttachObjectView(ownerTag, ownerViewModelTag, tag, skillId, qteAttachObjectType)
  local viewClassName = "battle.objectView.cardObject.BaseAttachObjectView"
  local view = __Require(viewClassName).new({
    ownerTag = ownerTag,
    tag = tag,
    skillId = skillId,
    qteAttachObjectType = qteAttachObjectType
  })
  self:AddAAttachObjectView(tag, view)
  local ownerView = self:GetAObjectView(ownerViewModelTag)
  if nil ~= ownerView then
    ownerView:AddAAttachView(view)
  end
end
function BattleRenderManager:RefreshAAttachObjectViewState(tag, touchPace)
  local view = self:GetAAttachObjectView(tag)
  if nil ~= view then
    view:RefreshQTEViewByTouchPace(touchPace)
  end
end
function BattleRenderManager:DestroyAAttachObjectView(tag)
  local view = self:GetAAttachObjectView(tag)
  if nil ~= view then
    view:Destroy()
  end
  self:RemoveAAttachObjectView(tag)
end
function BattleRenderManager:InitConnectButton(teamMembers)
  local obj
  local x = 1
  local scale = 1
  local t = {}
  for otag_, btns in pairs(self.connectButtons) do
    local otag = checkint(otag_)
    for skillId, btn in pairs(btns) do
      obj = G_BattleLogicMgr:IsObjAliveByTag(otag)
      if nil == obj then
        btn:RemoveSelf()
        if nil ~= self.connectButtons[tostring(otag)] then
          self.connectButtons[tostring(otag)][tostring(skillId)] = nil
        end
      else
        table.insert(t, btn)
      end
    end
  end
  table.sort(t, function(a, b)
    return a:getPositionX() > b:getPositionX()
  end)
  for i, v in ipairs(t) do
    local btnSize = cc.size(v:getContentSize().width * scale, v:getContentSize().height * scale)
    v:setPositionX(display.SAFE_R - 20 - btnSize.width * 0.5 - (btnSize.width + 25) * (x - 1))
    local index = #self.connectButtonsIndex + 1
    self.connectButtonsIndex[index] = connectButton
    x = x + 1
  end
  for i = #teamMembers, 1, -1 do
    obj = teamMembers[i]
    tag = obj:GetOTag()
    local skinId = obj:GetObjectSkinId()
    local connectSkills = obj.castDriver:GetConnectSkills()
    if nil ~= connectSkills then
      for skillIndex, skillId in ipairs(connectSkills) do
        if nil == self:GetConnectButton(tag, skillId) then
          local connectButton = __Require("battle.view.ConnectButton").new({
            objTag = tag,
            cardHeadPath = CardUtils.GetCardHeadPathBySkinId(skinId),
            debugTxt = obj:GetObjectName(),
            skillId = checkint(skillId),
            callback = handler(self, self.ConnectSkillButtonClickHandler)
          })
          connectButton:setTag(skillIndex)
          local btnSize = cc.size(connectButton:getContentSize().width * scale, connectButton:getContentSize().height * scale)
          display.commonUIParams(connectButton, {
            po = cc.p(display.SAFE_R - 20 - btnSize.width * 0.5 - (btnSize.width + 25) * (x - 1), 20 + btnSize.height * 0.5)
          })
          self:GetBattleScene().viewData.uiLayer:addChild(connectButton)
          if nil == self.connectButtons[tostring(tag)] then
            self.connectButtons[tostring(tag)] = {}
          end
          self.connectButtons[tostring(tag)][tostring(skillId)] = connectButton
          local index = #self.connectButtonsIndex + 1
          self.connectButtonsIndex[index] = connectButton
          x = x + 1
        end
      end
    end
  end
end
function BattleRenderManager:GetConnectButtonsByTag(tag)
  return self.connectButtons[tostring(tag)]
end
function BattleRenderManager:GetConnectButton(tag, skillId)
  if nil ~= self.connectButtons[tostring(tag)] then
    return self.connectButtons[tostring(tag)][tostring(skillId)]
  end
  return nil
end
function BattleRenderManager:GetConnectButtonByIndex(index)
  return self.connectButtonsIndex[index]
end
function BattleRenderManager:RefreshObjectConnectButtons(tag, energyPercent, canAct, state, inAbnormalState)
  local btns = self:GetConnectButtonsByTag(tag)
  if nil ~= btns then
    for skillId_, btn in pairs(btns) do
      btn:RefreshButton(energyPercent, canAct, state, inAbnormalState)
    end
  end
end
function BattleRenderManager:RefreshObjectConnectButtonsByEnergy(tag, energyPercent)
  local btns = self:GetConnectButtonsByTag(tag)
  if nil ~= btns then
    for skillId_, btn in pairs(btns) do
      btn:RefreshButtonByEnergy(energyPercent)
    end
  end
end
function BattleRenderManager:RefreshObjectConnectButtonsByState(tag, canAct, state, inAbnormalState)
  local btns = self:GetConnectButtonsByTag(tag)
  if nil ~= btns then
    for skillId_, btn in pairs(btns) do
      btn:RefreshButtonByState(canAct, state, inAbnormalState)
    end
  end
end
function BattleRenderManager:EnableConnectSkillButton(tag, skillId, enable)
  local connectButton = self:GetConnectButton(tag, skillId)
  if nil ~= connectButton then
    connectButton:SetCanUse(enable)
    if false == enable then
      connectButton:DisableConnectButton()
    end
  end
end
function BattleRenderManager:ShowDamageNumber(damageData, battleRootPos, towards, inHighlight)
  local colorPath = "white"
  local fontSize = 50
  local actionSeq
  local fps = 30
  local parentNode = self:GetBattleRoot()
  local pos = battleRootPos
  local sign = towards and -1 or 1
  local zorder = BATTLE_E_ZORDER.DAMAGE_NUMBER
  if true == inHighlight then
    zorder = zorder + G_BattleLogicMgr:GetFixedHighlightZOrder()
  end
  if nil ~= damageData.healerTag then
    if true == damageData.isCritical then
      fontSize = 80
    end
    colorPath = "green"
    pos.x = pos.x + math.random(-35, 35)
    local deltaP1 = cc.p(0, 50 + math.random(40))
    local actionP1 = cc.pAdd(pos, deltaP1)
    local actionP2 = cc.pAdd(actionP1, cc.p(0, deltaP1.y * 0.5))
    actionSeq = cc.Sequence:create(cc.EaseSineIn:create(cc.Spawn:create(cc.ScaleTo:create(9 / fps, 1), cc.MoveTo:create(9 / fps, actionP1))), cc.Spawn:create(cc.Sequence:create(cc.MoveTo:create(19 / fps, actionP2), cc.MoveTo:create(11 / fps, pos)), cc.Sequence:create(cc.DelayTime:create(13 / fps), cc.ScaleTo:create(17 / fps, 0)), cc.Sequence:create(cc.DelayTime:create(19 / fps), cc.FadeTo:create(11 / fps, 0))), cc.RemoveSelf:create())
  elseif true == damageData.isCritical then
    colorPath = "orange"
    fontSize = 70
    local deltaP1 = cc.p(60 + math.random(40), 60 + math.random(40))
    local actionP1 = cc.p(pos.x + sign * deltaP1.x, pos.y + deltaP1.y)
    local actionP2 = cc.p(pos.x + sign * deltaP1.x * 2, pos.y + deltaP1.y * 0.25)
    local bezierConf2 = {
      actionP1,
      cc.p(actionP1.x + sign * deltaP1.x * 0.5, actionP1.y + deltaP1.y * 0.25),
      actionP2
    }
    actionSeq = cc.Sequence:create(cc.EaseSineOut:create(cc.Spawn:create(cc.ScaleTo:create(6 / fps, 1), cc.MoveTo:create(6 / fps, actionP1))), cc.Spawn:create(cc.BezierTo:create(33 / fps, bezierConf2), cc.Sequence:create(cc.DelayTime:create(22 / fps), cc.Spawn:create(cc.ScaleTo:create(11 / fps, 0), cc.FadeTo:create(11 / fps, 0)))), cc.RemoveSelf:create())
  else
    local deltaP1 = cc.p(15 + math.random(30), 15 + math.random(30))
    local actionP1 = cc.p(pos.x + sign * deltaP1.x, pos.y + deltaP1.y)
    local actionP2 = cc.p(pos.x + sign * deltaP1.x * 2, pos.y)
    local bezierConf2 = {
      actionP1,
      cc.p(actionP1.x + sign * deltaP1.x, actionP1.y + deltaP1.y),
      actionP2
    }
    actionSeq = cc.Sequence:create(cc.Spawn:create(cc.ScaleTo:create(5 / fps, 1), cc.MoveTo:create(5 / fps, actionP1)), cc.Spawn:create(cc.BezierTo:create(34 / fps, bezierConf2), cc.Sequence:create(cc.DelayTime:create(22 / fps), cc.Spawn:create(cc.ScaleTo:create(12 / fps, 0), cc.FadeTo:create(12 / fps, 0)))), cc.RemoveSelf:create())
  end
  local damageLabel = CLabelBMFont:create(string.format("%d", math.ceil(damageData:GetDamageValue())), string.format("font/battle_font_%s.fnt", colorPath))
  damageLabel:setBMFontSize(fontSize)
  damageLabel:setAnchorPoint(cc.p(0.5, 0.5))
  damageLabel:setPosition(pos)
  parentNode:addChild(damageLabel, zorder)
  damageLabel:setScale(0)
  if actionSeq then
    damageLabel:runAction(actionSeq)
  end
end
function BattleRenderManager:AddASpecialSkillIcon(skillId)
  self:GetBattleScene():AddAGlobalEffect(skillId)
end
function BattleRenderManager:RefreshTimeLabel(leftTime, a, b)
  local m = math.floor(leftTime / 60)
  local s = math.floor(leftTime - m * 60)
  if self:GetBattleScene().viewData and self:GetBattleScene().viewData.battleTimeLabel then
    self:GetBattleScene().viewData.battleTimeLabel:setString(string.format("%d:%02d", m, s))
  end
end
function BattleRenderManager:RefreshWaveInfo(currentWave, totalWave)
  local waveLabel = self:GetBattleScene().viewData.waveLabel
  local waveIcon = self:GetBattleScene().viewData.waveIcon
  waveLabel:setString(string.format("%d/%d", currentWave, totalWave))
  display.commonUIParams(waveIcon, {
    po = cc.p(waveLabel:getPositionX() - waveLabel:getContentSize().width, waveLabel:getPositionY() + 4)
  })
end
function BattleRenderManager:RefreshWaveClearInfo(stageCompleteInfo)
  local waveClearDescr = self:GetStageCompleteDescrByInfo(stageCompleteInfo)
  self:GetBattleScene():RefreshBattleClearTargetDescr(waveClearDescr)
  if ConfigStageCompleteType.ALIVE == stageCompleteInfo.completeType then
    self:GetBattleScene():InitAliveStageClear(stageCompleteInfo.aliveTime)
  else
  end
  self:GetBattleScene():HideStageClearByStageCompleteType(stageCompleteInfo.completeType)
end
function BattleRenderManager:GetStageCompleteDescrByInfo(stageCompleteInfo)
  local passType = stageCompleteInfo.completeType
  local passConfig = CommonUtils.GetConfig("quest", "passType", tostring(passType))
  if nil ~= passConfig then
    return tostring(passConfig.descr)
  else
    return "\230\156\170\232\131\189\230\137\190\229\136\176\232\191\135\229\133\179\230\157\161\228\187\182\230\143\143\232\191\176\233\133\141\231\189\174"
  end
end
function BattleRenderManager:RefreshTagMatchTeamStatus(friendTeamIndex, enemyTeamIndex)
  if self:IsTagMatchBattle() then
    self:GetBattleScene():RefreshTagMatchTeamStatus(friendTeamIndex, enemyTeamIndex)
  end
end
function BattleRenderManager:RefreshAliveCountdown(countdown)
  self:GetBattleScene():RefreshAliveCountdown(countdown)
end
function BattleRenderManager:ShowWaveTransition(needReloadResources, nextWave, friendTeamIndex, enemyTeamIndex, isFriendWin, aliveTargetsInfo, deadTargetsInfo)
  self:SetBattleTouchEnable(false)
  local function changeBegin()
    if true == needReloadResources then
      self:GetBattleDriver(BattleDriverType.RES_LOADER):OnLogicEnter(nextWave, friendTeamIndex, enemyTeamIndex, isFriendWin, aliveTargetsInfo, deadTargetsInfo)
    end
    self:AddPlayerOperate("G_BattleLogicMgr", "RenderWaveTransitionStartHandler")
  end
  local function changeEnd()
    self:AddPlayerOperate("G_BattleLogicMgr", "RenderWaveTransitionOverHandler")
  end
  local scene = __Require("battle.miniGame.WaveTransitionScene").new({
    callbacks = {changeBegin = changeBegin, changeEnd = changeEnd}
  })
  scene:setTag(WAVE_TRANSITION_SCENE_TAG)
  self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.CI)
  return scene
end
function BattleRenderManager:ContinueWaveTransition()
  local scene = self:GetBattleScene():getChildByTag(WAVE_TRANSITION_SCENE_TAG)
  if nil ~= scene then
    scene:ContinueWaveTransition()
  end
end
function BattleRenderManager:ShowConnectSkillCIScene(tag, sceneTag, cardId, skinId, otherHeadSkinId, skillId)
  self:SetBattleTouchEnable(false)
  local params = {
    ownerTag = tag,
    tag = sceneTag,
    mainSkinId = skinId,
    otherHeadSkinId = otherHeadSkinId,
    startCB = function()
      self:PlayCardSound(cardId, SoundType.TYPE_SKILL2)
    end,
    overCB = function()
      if not self:IsCalculator() then
        self:AddPlayerOperate("G_BattleLogicMgr", "ConnectCISceneExit", tag, skillId, sceneTag)
      end
      self:SetBattleTouchEnable(true)
      print("over connect skill ci", G_BattleLogicMgr:GetBData():GetLogicFrameIndex())
      print([[
=======================================>>>>>>>>

]])
    end,
    dieCB = function()
      self:SetCISceneBySceneTag(sceneTag, true, nil)
    end
  }
  local scene = __Require("battle.miniGame.CutinScene").new(params)
  self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.CI)
  self:SetCISceneBySceneTag(sceneTag, true, scene)
  self:AddPlayerOperate("G_BattleLogicMgr", "ConnectCISceneEnter", tag, skillId, sceneTag)
  print([[


=======================================>>>>>>>>]])
  print("start connect skill ci", G_BattleLogicMgr:GetBData():GetLogicFrameIndex())
end
function BattleRenderManager:ShowWeakSkillScene(tag, viewModelTag, sceneTag, skillId, weakPoints, time)
  local params = {
    ownerTag = tag,
    ownerViewModelTag = viewModelTag,
    tag = sceneTag,
    skillId = skillId,
    weakPoints = weakPoints,
    time = time,
    touchWeakPointCB = handler(self, self.WeakSkillPointClickHandler),
    overCB = function(result)
      self:AddPlayerOperate("G_BattleLogicMgr", "RenderWeakChantOverHandler", tag, skillId, result)
    end,
    dieCB = function(result)
      self:SetCISceneBySceneTag(sceneTag, false, nil)
    end
  }
  local scene = __Require("battle.miniGame.BossWeakScene").new(params)
  self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.CI)
  self:SetCISceneBySceneTag(sceneTag, false, scene)
end
function BattleRenderManager:WeakPointBomb(sceneTag, touchedPointId)
  local scene = self:GetCISceneBySceneTag(sceneTag, false)
  if nil ~= scene then
    scene:WeakPointBomb(touchedPointId)
  end
end
function BattleRenderManager:ShowBossCIScene(tag, sceneTag, skillId, mainSkinId)
  self:SetBattleTouchEnable(false)
  local params = {
    ownerTag = tag,
    tag = sceneTag,
    mainSkinId = mainSkinId,
    startCB = function()
    end,
    overCB = function()
      self:AddPlayerOperate("G_BattleLogicMgr", "BossCISceneExit", tag, skillId, sceneTag)
      self:SetBattleTouchEnable(true)
    end,
    dieCB = function()
      self:SetCISceneBySceneTag(sceneTag, true, nil)
    end
  }
  local scene = __Require("battle.miniGame.BossCutinScene").new(params)
  self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.CI)
  self:SetCISceneBySceneTag(sceneTag, true, scene)
  self:AddPlayerOperate("G_BattleLogicMgr", "BossCISceneEnter", tag, skillId, sceneTag)
end
function BattleRenderManager:KillObjectCISceneByTag(tag)
  for sceneTag_, scene in pairs(self.ciScenes.normal) do
    if tag == scene:GetOwnerTag() then
      scene:die()
    end
  end
  for sceneTag_, scene in pairs(self.ciScenes.pause) do
    if tag == scene:GetOwnerTag() then
      scene:die()
    end
  end
end
function BattleRenderManager:PauseGame()
  self:SetBattleTouchEnable(false)
  self:PauseRenderElements()
  local scene = __Require("battle.miniGame.PauseScene").new()
  self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.PAUSE)
  scene:setTag(PAUSE_SCENE_TAG)
  if nil ~= scene.viewData and nil ~= scene.viewData.actionButtons then
    for _, button in ipairs(scene.viewData.actionButtons) do
      display.commonUIParams(button, {
        cb = handler(self, self.ButtonsClickHandler)
      })
    end
  end
end
function BattleRenderManager:ResumeGame()
  self:SetBattleTouchEnable(true)
  self:ResumeRenderElements()
  local scene = self:GetBattleScene():getChildByTag(PAUSE_SCENE_TAG)
  if nil ~= scene then
    scene:setVisible(false)
    scene:die()
  end
end
function BattleRenderManager:PauseRenderElements()
  self:PauseBattleScene()
  self:PauseCIScene()
  self:PauseNormalScene()
  self:PauseOther()
end
function BattleRenderManager:ResumeRenderElements()
  self:ResumeBattleScene()
  self:ResumeCIScene()
  self:ResumeNormalScene()
  self:ResumeOther()
end
function BattleRenderManager:PauseBattleScene()
  self:GetBattleScene():PauseScene()
end
function BattleRenderManager:ResumeBattleScene()
  self:GetBattleScene():ResumeScene()
end
function BattleRenderManager:PauseCIScene()
  for _, node in pairs(self.ciScenes.pause) do
    node:pauseObj()
    cc.Director:getInstance():getActionManager():pauseTarget(node)
    table.insert(self.pauseActions.pauseScene, node)
  end
end
function BattleRenderManager:ResumeCIScene()
  for _, node in pairs(self.ciScenes.pause) do
    node:resumeObj()
    cc.Director:getInstance():getActionManager():resumeTarget(node)
  end
  self.pauseActions.pauseScene = {}
end
function BattleRenderManager:PauseNormalScene()
  for _, node in pairs(self.ciScenes.normal) do
    node:pauseObj()
    cc.Director:getInstance():getActionManager():pauseTarget(node)
    table.insert(self.pauseActions.normalScene, node)
  end
end
function BattleRenderManager:ResumeNormalScene()
  for _, node in pairs(self.ciScenes.normal) do
    node:resumeObj()
    cc.Director:getInstance():getActionManager():pauseTarget(node)
  end
  self.pauseActions.normalScene = {}
end
function BattleRenderManager:PauseOther()
  table.insert(self.pauseActions.battle, cc.Director:getInstance():getActionManager():pauseAllRunningActions())
  cc.Director:getInstance():getActionManager():resumeTarget(cc.CSceneManager:getInstance():getRunningScene())
end
function BattleRenderManager:ResumeOther()
  for i, v in ipairs(self.pauseActions.battle) do
    cc.Director:getInstance():getActionManager():resumeTargets(v)
  end
  self.pauseActions.battle = {}
end
function BattleRenderManager:PauseAObjectView(tag, timeScale)
  self:ObjectViewSetAnimationTimeScale(tag, timeScale)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    view:PauseView()
  end
end
function BattleRenderManager:ResumeAObjectView(tag, timeScale)
  self:ObjectViewSetAnimationTimeScale(tag, timeScale)
  local view = self:GetAObjectView(tag)
  if nil ~= view then
    view:ResumeView()
  end
end
function BattleRenderManager:PauseCISceneStart(sceneTag)
  self:PauseOther()
  if nil ~= sceneTag then
    local scene = self:GetCISceneBySceneTag(sceneTag, true)
    if nil ~= scene then
      scene:start()
    end
  end
end
function BattleRenderManager:PauseCISceneOver(sceneTag)
  self:ResumeOther()
end
function BattleRenderManager:InitBattleModule()
  self:InitBattleUIInfo()
  self:InitFunctionModule()
end
function BattleRenderManager:InitBattleUIInfo()
  if self:IsTagMatchBattle() then
    self:GetBattleScene():InitTagMatchView(self:GetBattleMembers(false), self:GetBattleMembers(true))
  end
end
function BattleRenderManager:InitFunctionModule()
  local initByGuide = self:InitFunctionModuleByGuide()
  if initByGuide then
    return
  end
  local questBattleType = self:GetQuestBattleType()
  if self:IsCardVSCard() then
    self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.PLAYER_SKILL, false)
    self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.WAVE, false)
  elseif QuestBattleType.PERFORMANCE == questBattleType then
    self:GetBattleScene():HideAllBattleFunctionModule()
  elseif QuestBattleType.RAID == questBattleType then
    self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.WAVE, false)
    self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.PLAYER_SKILL, false)
    self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.ACCELERATE_GAME, false)
    self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.PAUSE_GAME, false)
  elseif self:IsShareBoss() then
    self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.PLAYER_SKILL, false)
    self:GetBattleScene():ShowBattleFunctionModule(ConfigBattleFunctionModuleType.STAGE_CLEAR_TARGET, false)
  end
  local hideBattleFunctionModule = self:GetBattleConstructData().hideBattleFunctionModule
  if nil ~= hideBattleFunctionModule then
    for _, moduleType in ipairs(hideBattleFunctionModule) do
      self:GetBattleScene():ShowBattleFunctionModule(checkint(moduleType), false)
    end
  end
end
function BattleRenderManager:InitFunctionModuleByGuide()
  local guideConfig = self:GetBattleGuideConfigByStageId()
  if nil == guideConfig then
    return false
  end
  for _, moduleType in ipairs(guideConfig.hiddenFunction) do
    self:GetBattleScene():ShowBattleFunctionModule(checkint(moduleType), false)
  end
  return true
end
function BattleRenderManager:CreateAPlayerObjectView(viewModelTag, activeSkill, tag)
  local viewInfo = {tag = viewModelTag, logicTag = tag}
  local friendPlayerObjectView = __Require("battle.objectView.cardObject.PlayerObjectView").new(viewInfo)
  self:AddAPlayerObjectView(viewModelTag, friendPlayerObjectView)
  self:InitPlayerObjectSkills(viewModelTag, activeSkill)
end
function BattleRenderManager:InitPlayerObjectSkills(viewModelTag, activeSkill)
  local playerView = self:GetAPlayerObjectView(viewModelTag)
  if nil ~= playerView then
    local skillId
    for skillIndex, skillInfo in ipairs(activeSkill) do
      skillId = checkint(skillInfo.skillId)
      playerView:AddAPlayerSkillIcon(skillIndex, skillId, handler(self, self.PlayerSkillHandler))
    end
  end
end
function BattleRenderManager:AddAPlayerObjectView(viewModelTag, view)
  self.playerViews[tostring(viewModelTag)] = view
end
function BattleRenderManager:RemoveAPlayerObjectView(viewModelTag)
  self.playerViews[tostring(viewModelTag)] = nil
end
function BattleRenderManager:GetAPlayerObjectView(viewModelTag)
  return self.playerViews[tostring(viewModelTag)]
end
function BattleRenderManager:ShowPlayerObjectView(show)
  for _, view in pairs(self.playerViews) do
    view:SetVisible(show)
  end
end
function BattleRenderManager:RefreshPlayerSkillCDPercent(viewModelTag, skillId, cdPercent)
  local view = self:GetAPlayerObjectView(viewModelTag)
  if nil ~= view then
    view:RefreshPlayerSkillByCDPercent(skillId, cdPercent)
  end
end
function BattleRenderManager:RefreshPlayerSkillState(viewModelTag, skillId, canCast)
  local view = self:GetAPlayerObjectView(viewModelTag)
  if nil ~= view then
    view:RefreshPlayerSkillByState(skillId, canCast)
  end
end
function BattleRenderManager:SetPlayerObjectViewEnergyPercent(viewModelTag, energyPercent)
  local view = self:GetAPlayerObjectView(viewModelTag)
  if nil ~= view then
    view:UpdateEnergyBar(energyPercent)
  end
end
function BattleRenderManager:ShowCastPlayerSkillCover()
  local waringBg = display.newNSprite(_res("ui/battle/battle_bg_warning.png"), display.width * 0.5, display.height * 0.5)
  waringBg:setColor(cc.c3b(0, 0, 0))
  local waringBgSize = waringBg:getContentSize()
  waringBg:setScaleX(display.width / waringBgSize.width)
  waringBg:setScaleY(display.height / waringBgSize.height)
  self:GetBattleScene().viewData.uiLayer:addChild(waringBg)
  waringBg:setOpacity(0)
  local waringActionSeq = cc.Sequence:create(cc.FadeTo:create(0.5, 255), cc.DelayTime:create(2.5), cc.FadeTo:create(0.5, 0), cc.RemoveSelf:create())
  waringBg:runAction(waringActionSeq)
end
function BattleRenderManager:ShakeWorld(callback)
  self:GetBattleScene():ShakeWorld(callback)
end
function BattleRenderManager:PhaseChangeSpeakAndDeform(deformSourceViewModelTag, deformSourceTag, deformTargetViewModelTag, deformTargetTag, dialogueFrameType, content)
  self:ShakeWorld(function()
    local view = self:GetAObjectView(deformSourceViewModelTag)
    if nil ~= view then
      view:StartSpeakAndDeform(dialogueFrameType, content, deformTargetViewModelTag, function()
        self:AddPlayerOperate("G_BattleLogicMgr", "RenderPhaseChangeSpeakAndDeformOverHandler", deformTargetTag)
      end)
    end
  end)
end
function BattleRenderManager:PhaseChangeSpeakAndEscape(viewModelTag, tag, dialogueFrameType, content)
  local view = self:GetAObjectView(viewModelTag)
  if nil ~= view then
    view:StartSpeakBeforeEscape(dialogueFrameType, content, function()
      self:AddPlayerOperate("G_BattleLogicMgr", "RenderPhaseChangeSpeakOverStartEscapeHandler", tag)
    end)
  end
end
function BattleRenderManager:PhaseChangeEscape(viewModelTag, tag, targetPos, walkSpeed)
  local view = self:GetAObjectView(viewModelTag)
  if nil ~= view then
    view:StartEscape(targetPos, walkSpeed, function()
      self:AddPlayerOperate("G_BattleLogicMgr", "RenderPhaseChangeEscapeOverHandler", tag)
    end)
  end
end
function BattleRenderManager:PhaseChangeEscapeOverAndDisappear(viewModelTag)
  local view = self:GetAObjectView(viewModelTag)
  if nil ~= view then
    view:OverEscape()
  end
end
function BattleRenderManager:PhaseChangeEscapeBack(viewModelTag)
  local view = self:GetAObjectView(viewModelTag)
  if nil ~= view then
    view:EscapeBack()
  end
end
function BattleRenderManager:PhaseChangeDeformCustomize(deformSourceViewModelTag, deformSourceTag, deformSourceActionName, delayTime, deformTargetViewModelTag, deformTargetTag, deformTargetActionName)
  local deformSourceView = self:GetAObjectView(deformSourceViewModelTag)
  if nil ~= deformSourceView then
    deformSourceView:DeformCustomizeDisappear(deformSourceActionName, delayTime, nil)
    local deformSourceActionData = deformSourceView:GetSpineAnimationDataByAnimationName(deformSourceActionName)
    if nil ~= deformSourceActionData then
      delayTime = delayTime + deformSourceActionData.duration
    end
  end
  local deformTargetView = self:GetAObjectView(deformTargetViewModelTag)
  if nil ~= deformTargetView then
    deformTargetView:DeformCustomizeAppear(deformSourceActionName, delayTime, function()
      self:AddPlayerOperate("G_BattleLogicMgr", "RenderPhaseChangeDeformCustomizeOverHandler", deformSourceTag, deformTargetTag)
    end)
  end
end
function BattleRenderManager:PhaseChangeShowPlotStage(plotId, path, guide)
  local currentRenderTimeScale = G_BattleMgr:GetRenderTimeScale()
  G_BattleMgr:SetRenderTimeScale(1)
  local plotStage = require("Frame.Opera.OperaStage").new({
    id = plotId,
    path = path,
    guide = guide,
    cb = function()
      self:ResumeBattleButtonClickHandler(nil)
      G_BattleMgr:SetRenderTimeScale(currentRenderTimeScale)
    end
  })
  plotStage:setPosition(display.center)
  sceneWorld:addChild(plotStage, GameSceneTag.Dialog_GameSceneTag)
end
function BattleRenderManager:ObjectViewSpeak(viewModelTag, dialogueFrameType, content, callback)
  local view = self:GetAObjectView(viewModelTag)
  if nil ~= view then
    view:ShowDialogue(dialogueFrameType, content, nil, callback)
  end
end
function BattleRenderManager:CameraActionShakeAndZoom(tag, cameraActionTag, scale)
  local staticShakeTime = 1
  local scaleTime = 1.75
  local battleScene = self:GetBattleScene()
  local scaledSize = cc.size(battleScene:getContentSize().width * battleScene:getScaleX() * scale, battleScene:getContentSize().height * battleScene:getScaleY() * scale)
  local convertScaleX, convertScaleY = display.width / scaledSize.width, display.height / scaledSize.height
  local targetNode = battleScene.viewData.effectLayer
  local fixedSize = cc.size(targetNode:getContentSize().width * convertScaleX, targetNode:getContentSize().height * convertScaleY)
  targetNode:setContentSize(fixedSize)
  local fgShakeAction = cc.Sequence:create(ShakeAction:create(staticShakeTime + scaleTime, 20, 10))
  battleScene.viewData.fgLayer:runAction(fgShakeAction)
  local bgShakeAction = cc.Sequence:create(ShakeAction:create(staticShakeTime + scaleTime, 10, 5))
  battleScene.viewData.bgLayer:runAction(bgShakeAction)
  local battleLayerShakeAction = cc.Sequence:create(ShakeAction:create(staticShakeTime + scaleTime, 15, 7))
  battleScene.viewData.battleLayer:runAction(battleLayerShakeAction)
  local sceneActionSeq = cc.Sequence:create(cc.DelayTime:create(staticShakeTime), cc.EaseIn:create(cc.ScaleTo:create(scaleTime, scale), 3), cc.CallFunc:create(function()
    self:AddPlayerOperate("G_BattleLogicMgr", "RenderCameraActionShakeAndZoomOverHandler", tag, cameraActionTag)
  end))
  battleScene.viewData.fieldLayer:runAction(sceneActionSeq)
end
function BattleRenderManager:ForceShowAllObjectView(show)
  for _, view in pairs(self.objectViews) do
    view:SetObjectVisible(show)
  end
end
function BattleRenderManager:ShowActAfterGameOver(callback, r, responseData)
  if QuestBattleType.UNION_BEAST == self:GetQuestBattleType() then
    local beastId = self:GetUnionBeastId()
    local babyEnergyLevel = checkint(responseData.energyLevel)
    local deltaEnergy = checkint(responseData.energy)
    if babyEnergyLevel > 0 and 0 ~= beastId then
      local scene = __Require("battle.miniGame.UnionBeastBabyEatScene").new({
        beastId = beastId,
        energyLevel = babyEnergyLevel,
        deltaEnergy = deltaEnergy,
        callback = callback
      })
      self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.CI)
    else
      callback()
    end
  end
end
function BattleRenderManager:PlayeVoice(voiceData)
  local voicesConfig = CardUtils.GetVoiceLinesConfigByCardId(voiceData.cardId)
  local voiceConfig
  if nil ~= voicesConfig then
    for i, v in ipairs(voicesConfig) do
      if voiceData.voiceId == checkint(v.groupId) then
        voiceConfig = v
        break
      end
    end
  end
  if nil ~= voiceConfig then
    local cueSheet = tostring(voiceConfig.roleId)
    local cueName = voiceConfig.voiceId
    local acbFile = string.format("sounds/%s.acb", cueSheet)
    if utils.isExistent(acbFile) then
      app.audioMgr:AddCueSheet(cueSheet, acbFile)
      app.audioMgr:PlayAudioClip(cueSheet, cueName)
    end
  end
  self:ShowVoiceDialouge(voiceData.cardId, voiceData.text, voiceData.isEnemy, voiceData.time)
end
function BattleRenderManager:ShowVoiceDialouge(cardId, text, isEnemy, time)
  local layerSize = cc.size(325, 85)
  local layer = display.newLayer(0, 0, {
    size = layerSize,
    ap = cc.p(0.5, 0.5)
  })
  self:GetBattleScene():addChild(layer, 99999)
  self.dialougeTagCounter = self.dialougeTagCounter + 1
  layer:setTag(self.dialougeTagCounter)
  local bg = display.newImageView(_res("ui/common/common_bg_tips_common.png"), layerSize.width * 0.5, layerSize.height * 0.5, {scale9 = true, size = layerSize})
  layer:addChild(bg)
  local cardHeadBg = display.newImageView(_res("ui/cards/head/kapai_frame_bg.png"), 0, 0)
  local cardHeadScale = (layerSize.height - 10) / cardHeadBg:getContentSize().height
  cardHeadBg:setScale(cardHeadScale)
  layer:addChild(cardHeadBg)
  local cardHeadCover = display.newImageView(_res("ui/cards/head/kapai_frame_orange.png"), 0, 0)
  cardHeadCover:setScale(cardHeadScale)
  layer:addChild(cardHeadCover, 10)
  local headIcon = display.newImageView(_res(CardUtils.GetCardHeadPathBySkinId(CardUtils.GetCardSkinId(cardId))), 0, 0)
  headIcon:setScale(cardHeadScale)
  layer:addChild(headIcon, 5)
  local descrLabel = display.newLabel(0, 0, fontWithColor("6", {text = text}))
  layer:addChild(descrLabel)
  local x = 0
  local y = 0
  local textW = 0
  local textH = 0
  local textAlign = display.TAC
  local textPos = cc.p(0, 0)
  local textAp = cc.p(0, 0)
  local dislougeMoveX = 0
  local cardHeadPos = cc.p(0, 0)
  local cacheNodes
  if isEnemy then
    dislougeMoveX = -layerSize.width
    x = display.width - layerSize.width * 0.5 - dislougeMoveX
    y = display.height - layerSize.height * 0.5 - layerSize.height * self.enemyDialougeY
    cardHeadPos.x = layerSize.width - 5 - cardHeadBg:getContentSize().width * 0.5 * cardHeadScale
    cardHeadPos.y = layerSize.height * 0.5
    local headIconLeftBorderX = cardHeadPos.x - cardHeadBg:getContentSize().width * 0.5 * cardHeadScale
    textAp = cc.p(0, 1)
    textAlign = display.TAL
    textW = headIconLeftBorderX - 20
    textH = layerSize.height - 20
    textPos.x = headIconLeftBorderX * 0.5 - textW * 0.5
    textPos.y = layerSize.height * 0.5 + textH * 0.5
    self.enemyDialougeY = self.enemyDialougeY + 1
    cacheNodes = self.enemyDialougeNodes
  else
    dislougeMoveX = layerSize.width
    x = layerSize.width * 0.5 - dislougeMoveX
    y = display.height - layerSize.height * 0.5 - layerSize.height * self.friendDialougeY
    cardHeadPos.x = cardHeadBg:getContentSize().width * 0.5 * cardHeadScale + 5
    cardHeadPos.y = layerSize.height * 0.5
    local headIconRightBorderX = cardHeadPos.x + cardHeadBg:getContentSize().width * 0.5 * cardHeadScale
    textAp = cc.p(0, 1)
    textAlign = display.TAL
    textW = layerSize.width - headIconRightBorderX - 20
    textH = layerSize.height - 20
    textPos.x = (layerSize.width - headIconRightBorderX) * 0.5 + headIconRightBorderX - textW * 0.5
    textPos.y = layerSize.height * 0.5 + textH * 0.5
    self.friendDialougeY = self.friendDialougeY + 1
    cacheNodes = self.friendDialougeNodes
  end
  display.commonUIParams(layer, {
    po = cc.p(x, y)
  })
  display.commonUIParams(cardHeadBg, {po = cardHeadPos})
  display.commonUIParams(cardHeadCover, {po = cardHeadPos})
  display.commonUIParams(headIcon, {po = cardHeadPos})
  display.commonLabelParams(descrLabel, {
    w = textW,
    h = textH,
    hAlign = textAlign
  })
  display.commonUIParams(descrLabel, {ap = textAp, po = textPos})
  table.insert(cacheNodes, 1, layer)
  local actionSeq = cc.Sequence:create(cc.EaseOut:create(cc.MoveBy:create(0.2, cc.p(dislougeMoveX, 0)), 5), cc.DelayTime:create(2), cc.FadeTo:create(0.5, 0), cc.Hide:create(), cc.CallFunc:create(function()
    for i = #cacheNodes, 1, -1 do
      if layer:getTag() == cacheNodes[i]:getTag() then
        table.remove(cacheNodes, i)
        if isEnemy then
          self.enemyDialougeY = self.enemyDialougeY - 1
          break
        end
        self.friendDialougeY = self.friendDialougeY - 1
        break
      end
    end
    for i, v in ipairs(cacheNodes) do
      local y = display.height - layerSize.height * 0.5 - layerSize.height * (#cacheNodes - i)
      local moveActionSeq = cc.Sequence:create(cc.EaseIn:create(cc.MoveTo:create(0.2, cc.p(v:getPositionX(), y)), 5))
      v:runAction(moveActionSeq)
    end
  end), cc.RemoveSelf:create())
  layer:runAction(actionSeq)
end
function BattleRenderManager:StartObjectViewTransform(viewModelTag, oriSkinId, oriActionName, targetSkinId, targetActionName)
  local view = self:GetAObjectView(viewModelTag)
  if nil ~= view then
    view:StartViewTransform(oriSkinId, oriActionName, targetSkinId, targetActionName)
  end
end
function BattleRenderManager:DoObjectViewTransform(viewModelTag, oriSkinId, oriActionName, targetSkinId, targetActionName)
  local view = self:GetAObjectView(viewModelTag)
  if nil ~= view then
    view:DoViewTransform(oriSkinId, oriActionName, targetSkinId, targetActionName)
  end
end
function BattleRenderManager:CreateGuideView(guideStepData)
  self:GetBattleDriver(BattleDriverType.GUIDE_DRIVER):OnLogicEnter(guideStepData)
end
function BattleRenderManager:HideAllGuideCover()
  self:GetBattleDriver(BattleDriverType.GUIDE_DRIVER):HideAllGuideCover()
end
function BattleRenderManager:ShowGameSuccess(responseData)
  if self:NeedShowActAfterGameOver() then
    local function callback()
      self:CreateBattleSuccessView(responseData)
    end
    self:ShowActAfterGameOver(callback, BattleResult.BR_SUCCESS, responseData)
  else
    self:CreateBattleSuccessView(responseData)
  end
end
function BattleRenderManager:CreateBattleSuccessView(responseData)
  local className = "battle.view.BattleSuccessView"
  local p_ = {}
  local viewType = self:GetBattleResultViewType()
  local questBattleType = self:GetQuestBattleType()
  if self:IsShareBoss() then
    className = "battle.view.ShareBossSuccessView"
    p_ = {
      totalTime = responseData.requestData.passTime,
      totalDamage = responseData.requestData.totalDamage
    }
  elseif ConfigBattleResultType.POINT_HAS_RESULT == viewType or ConfigBattleResultType.POINT_NO_RESULT == viewType then
    className = "battle.view.PointSettleView"
    p_ = {
      battleResult = BattleResult.BR_SUCCESS
    }
  elseif ConfigBattleResultType.NO_RESULT_DAMAGE_COUNT == viewType then
    className = "battle.view.ShareBossSuccessView"
    p_ = {
      totalTime = responseData.requestData.passTime,
      totalDamage = checknumber(responseData.totalDamage)
    }
  elseif ConfigBattleResultType.ONLY_RESULT_AND_REWARDS == viewType then
    className = "battle.view.CommonBattleResultView"
    p_ = {
      battleResult = BattleResult.BR_SUCCESS
    }
  end
  local cleanCondition
  if self:CanRechallenge() then
    cleanCondition = self:GetBattleConstructData().cleanCondition
  end
  local showMessage = QuestBattleType.ROBBERY == questBattleType
  local viewParams = {
    viewType = viewType,
    cleanCondition = cleanCondition,
    showMessage = showMessage,
    canRepeatChallenge = false,
    teamData = self:GetBattleMembers(false, 1),
    trophyData = responseData
  }
  for k, v in pairs(p_) do
    viewParams[k] = v
  end
  local layer = __Require(className).new(viewParams)
  display.commonUIParams(layer, {
    ap = cc.p(0, 0),
    po = cc.p(0, 0)
  })
  self:GetBattleScene():AddUILayer(layer)
  layer:setTag(GAME_RESULT_LAYER_TAG)
end
function BattleRenderManager:ShowGameFail(responseData)
  if self:NeedShowActAfterGameOver() then
    local function callback()
      self:CreateBattleSuccessView(responseData)
    end
    self:ShowActAfterGameOver(callback, BattleResult.BR_FAIL, responseData)
  else
    self:CreateBattleFailView(responseData)
  end
end
function BattleRenderManager:CreateBattleFailView(responseData)
  local className = "battle.view.BattleFailView"
  local p_ = {}
  local viewType = ConfigBattleResultType.NO_EXP
  local questBattleType = self:GetQuestBattleType()
  local configResultType = self:GetBattleResultViewType()
  if QuestBattleType.SEASON_EVENT == questBattleType or QuestBattleType.SAIMOE == questBattleType or QuestBattleType.UNION_PVC == questBattleType then
    viewType = configResultType
  end
  if ConfigBattleResultType.POINT_NO_RESULT == configResultType or ConfigBattleResultType.NO_RESULT_DAMAGE_COUNT == configResultType then
    viewType = configResultType
  end
  if self:IsShareBoss() then
    className = "battle.view.ShareBossSuccessView"
    p_ = {
      totalTime = responseData.requestData.passTime,
      totalDamage = responseData.requestData.totalDamage
    }
  elseif ConfigBattleResultType.POINT_HAS_RESULT == viewType or ConfigBattleResultType.POINT_NO_RESULT == viewType then
    className = "battle.view.PointSettleView"
    p_ = {
      battleResult = BattleResult.BR_FAIL
    }
  elseif ConfigBattleResultType.NO_RESULT_DAMAGE_COUNT == viewType then
    className = "battle.view.ShareBossSuccessView"
    p_ = {
      totalTime = responseData.requestData.passTime,
      totalDamage = checknumber(responseData.totalDamage)
    }
  elseif ConfigBattleResultType.ONLY_RESULT_AND_REWARDS == viewType then
    className = "battle.view.CommonBattleResultView"
    p_ = {
      battleResult = BattleResult.BR_FAIL
    }
  end
  local viewParams = {
    viewType = viewType,
    cleanCondition = nil,
    showMessage = false,
    canRepeatChallenge = false,
    teamData = self:GetBattleMembers(false, 1),
    trophyData = responseData
  }
  for k, v in pairs(p_) do
    viewParams[k] = v
  end
  local layer = __Require(className).new(viewParams)
  display.commonUIParams(layer, {
    ap = cc.p(0, 0),
    po = cc.p(0, 0)
  })
  self:GetBattleScene():AddUILayer(layer)
  layer:setTag(GAME_RESULT_LAYER_TAG)
end
function BattleRenderManager:QuitBattle()
  self:SetBattleTouchEnable(false)
  self:DestroyAllView()
  self:DestroyScene()
  self:DestroyValue()
  self:DestroyBattleDrivers()
  BattleUtils.StopScreenRecord()
end
function BattleRenderManager:DestroyAllView()
  for _, view in pairs(self.objectViews) do
    if view.Destroy then
      view:Destroy()
    end
  end
  self.objectViews = {}
  for _, view in pairs(self.qteAttachViews) do
    if view.Destroy then
      view:Destroy()
    end
  end
  self.qteAttachViews = {}
end
function BattleRenderManager:DestroyScene()
end
function BattleRenderManager:DestroyValue()
  self.objectViews = {}
  self.qteAttachViews = {}
  self.playerViews = {}
  self.ciScenes = {
    pause = {},
    normal = {}
  }
  self.pauseActions = {
    pauseScene = {},
    normalScene = {},
    battle = {}
  }
  self.connectButtons = {}
  self.connectButtonsIndex = {}
  self.friendDialougeNodes = {}
  self.enemyDialougeNodes = {}
  self.friendDialougeY = 0
  self.enemyDialougeY = 0
  self.dialougeTagCounter = 0
end
function BattleRenderManager:DestroyBattleDrivers()
  self:DestroyGuideDriver()
end
function BattleRenderManager:DestroyGuideDriver()
  if nil ~= self:GetBattleDriver(BattleDriverType.GUIDE_DRIVER) then
    self:GetBattleDriver(BattleDriverType.GUIDE_DRIVER):OnDestroy()
  end
end
function BattleRenderManager:NeedShowActAfterGameOver(r)
  if QuestBattleType.UNION_BEAST == self:GetQuestBattleType() then
    return true
  end
  return false
end
function BattleRenderManager:ShowBuyRevivalScene(canBuyReviveFree)
  local scene = __Require("battle.view.BattleBuyRevivalView").new({
    stageId = self:GetCurStageId(),
    questBattleType = self:GetQuestBattleType(),
    buyRevivalTime = self:GetBuyRevivalTime(),
    buyRevivalTimeMax = self:GetMaxBuyRevivalTime(),
    canBuyReviveFree = canBuyReviveFree
  })
  scene:setTag(BUY_REVIVAL_LAYER_TAG)
  display.commonUIParams(scene, {
    ap = cc.p(0, 0),
    po = cc.p(0, 0)
  })
  self:GetBattleScene():AddUILayer(scene)
  for _, btn in pairs(scene.actionButtons) do
    display.commonUIParams(btn, {
      cb = handler(self, self.ButtonsClickHandler)
    })
  end
end
function BattleRenderManager:CancelRescue()
  self:GetBattleScene():RemoveUILayerByTag(BUY_REVIVAL_LAYER_TAG)
  self:AddPlayerOperate("G_BattleLogicMgr", "RenderCancelRescueHandler")
end
function BattleRenderManager:RescueAllFriend()
  local stageId = self:GetCurStageId()
  local questBattleType = self:GetQuestBattleType()
  local nextBuyRevivalTime = self:GetNextBuyRevivalTime()
  local costConsumeConfig = CommonUtils.GetBattleBuyReviveCostConfig(stageId, questBattleType, nextBuyRevivalTime)
  local costGoodsId = checkint(costConsumeConfig.consume)
  local costGoodsAmount = checkint(costConsumeConfig.consumeNum)
  local buyRevivalScene = self:GetBattleScene():GetUIByTag(BUY_REVIVAL_LAYER_TAG)
  local buyRevivalFree = false
  if nil ~= buyRevivalScene then
    buyRevivalFree = buyRevivalScene:CanBuyReviveFree()
  end
  if true == buyRevivalFree then
    costGoodsAmount = 0
  else
    local goodsAmount = app.gameMgr:GetAmountByIdForce(costGoodsId)
    if 0 ~= costGoodsAmount and costGoodsAmount > goodsAmount then
      if GAME_MODULE_OPEN.NEW_STORE and checkint(costGoodsId) == DIAMOND_ID then
        app.uiMgr:showDiamonTips(nil, true)
      else
        local goodsConfig = CommonUtils.GetConfig("goods", "goods", costGoodsId)
        app.uiMgr:ShowInformationTips(string.format(__("%s\228\184\141\232\182\179"), goodsConfig.name))
      end
      return
    end
  end
  local function callback(responseData)
    CommonUtils.DrawRewards({
      {
        goodsId = costGoodsId,
        num = -costGoodsAmount
      }
    })
    self:AddPlayerOperate("G_BattleLogicMgr", "RescueAllFriend")
  end
  local serverCommand = self:GetServerCommand()
  AppFacade.GetInstance():DispatchObservers("BATTLE_BUY_REVIVE_REQUEST", {
    requestCommand = serverCommand.buyCheatRequestCommand,
    responseSignal = serverCommand.buyCheatResponseSignal,
    requestData = serverCommand.buyCheatRequestData,
    callback = callback
  })
end
function BattleRenderManager:StartRescueAllFriend(viewModelTags)
  self:GetBattleScene():RemoveUILayerByTag(BUY_REVIVAL_LAYER_TAG)
  local renderTimeScale = G_BattleMgr:GetRenderTimeScale()
  local function reviveBegin()
    G_BattleMgr:SetRenderTimeScale(1)
    for _, viewModelTag in ipairs(viewModelTags) do
      do
        local view = self:GetAObjectView(viewModelTag)
        if nil ~= view then
          do
            local reviveSpine = SpineCache(SpineCacheName.BATTLE):createWithName("hurt_18")
            reviveSpine:setPosition(cc.p(view:getPositionX(), view:getPositionY()))
            self:GetBattleRoot():addChild(reviveSpine, view:getLocalZOrder())
            reviveSpine:setAnimation(0, "idle", false)
            reviveSpine:registerSpineEventHandler(function(event)
              if sp.CustomEvent.cause_effect == event.eventData.name then
                view:ReviveFromBuyRevive()
              end
            end, sp.EventType.ANIMATION_EVENT)
            reviveSpine:registerSpineEventHandler(function(event)
              reviveSpine:runAction(cc.RemoveSelf:create())
            end, sp.EventType.ANIMATION_COMPLETE)
          end
        end
      end
    end
  end
  local function reviveMiddle()
    self:AddPlayerOperate("G_BattleLogicMgr", "RescueAllFriendComplete")
  end
  local function reviveEnd()
    G_BattleMgr:SetRenderTimeScale(renderTimeScale)
    self:SetBattleTouchEnable(true)
    self:AddPlayerOperate("G_BattleLogicMgr", "RescueAllFriendOver")
  end
  local scene = __Require("battle.miniGame.RescueAllFriendScene").new({
    callbacks = {
      reviveBegin = reviveBegin,
      reviveMiddle = reviveMiddle,
      reviveEnd = reviveEnd
    }
  })
  self:GetBattleScene():addChild(scene, BATTLE_E_ZORDER.CI)
end
function BattleRenderManager:ShowSkada()
  local skadaLayer = self:GetBattleScene():GetUIByTag(SKADA_LAYER_TAG)
  if nil ~= skadaLayer then
    skadaLayer:setVisible(true)
  else
    skadaLayer = __Require("battle.view.SkadaView").new({
      teamsData = self:GetBattleMembers(false),
      skadaData = G_BattleLogicMgr:GetBattleDriver(BattleDriverType.SKADA_DRIVER):GetExtraSkadaData(),
      tagInfo = G_BattleLogicMgr:GetBattleDriver(BattleDriverType.SKADA_DRIVER):GetTagInfo()
    })
    display.commonUIParams(skadaLayer, {
      ap = cc.p(0.5, 0.5),
      po = display.center
    })
    self:GetBattleScene():AddUILayer(skadaLayer)
    skadaLayer:setTag(SKADA_LAYER_TAG)
  end
end
function BattleRenderManager:SpineInCache(spineId, spineType, wave)
  return self:GetBattleDriver(BattleDriverType.RES_LOADER):HasLoadSpineByCacheName(BattleUtils.GetCacheAniNameById(spineId, spineType))
end
function BattleRenderManager:GetSpineAvatarScale2CardByCardId(cardId)
  return self:GetSpineAvatarScaleByCardId(cardId) / CARD_DEFAULT_SCALE
end
function BattleRenderManager:GetSpineAvatarScaleByCardId(cardId)
  local cardConfig = CardUtils.GetCardConfig(cardId)
  local spineId = cardId
  local scale = CARD_DEFAULT_SCALE
  if CardUtils.IsMonsterCard(cardId) then
    local monsterType = checkint(cardConfig.type)
    if ConfigMonsterType.ELITE == monsterType then
      scale = ELITE_DEFAULT_SCALE
    elseif ConfigMonsterType.BOSS == monsterType then
      scale = BOSS_DEFAULT_SCALE
    end
  end
  return scale
end
function BattleRenderManager:PlayBattleSoundEffect(id)
  PlayBattleEffects(id)
end
function BattleRenderManager:PlayCardSound(cardId, soundType)
  CommonUtils.PlayCardSoundByCardId(cardId, soundType)
end
function BattleRenderManager:SetBattleTouchEnable(enable)
  self.battleTouchEnable = enable
  if self:GetBattleScene() and self:GetBattleScene().viewData then
    self:GetBattleScene().viewData.eaterLayer:setVisible(not enable)
  end
end
function BattleRenderManager:IsBattleTouchEnable()
  return self.battleTouchEnable
end
function BattleRenderManager:ButtonsClickHandler(sender)
  PlayUIEffects(AUDIOS.UI.ui_click_normal.id)
  local tag = sender:getTag()
  if 1001 == tag then
    self:PauseBattleButtonClickHandler(sender)
  elseif 1002 == tag then
    self:AccelerateButtonClickHandler(sender)
  elseif 1003 == tag then
    self:QuitGameButtonClickHandler(sender)
  elseif 1004 == tag then
    self:RestartGameButtonClickHandler(sender)
  elseif 1005 == tag then
    self:ResumeBattleButtonClickHandler(sender)
  elseif 1008 == tag then
    self:CancelRescue()
  elseif 1009 == tag then
    self:RescueAllFriend()
  end
end
function BattleRenderManager:AccelerateButtonClickHandler(sender)
  if not self:IsBattleTouchEnable() then
    return
  end
  self:AddPlayerOperate("G_BattleLogicMgr", "RenderAccelerateHandler")
  local gameTimeScale = 3 - G_BattleMgr:GetRenderTimeScale()
  app.gameMgr:UpdatePlayer({localBattleAccelerate = gameTimeScale})
end
function BattleRenderManager:PauseBattleButtonClickHandler(sender)
  if not self:IsBattleTouchEnable() then
    return
  end
  self:AddPlayerOperate("G_BattleLogicMgr", "RenderPauseBattleHandler")
end
function BattleRenderManager:ResumeBattleButtonClickHandler(sender)
  self:AddPlayerOperate("G_BattleLogicMgr", "RenderResumeBattleHandler")
end
function BattleRenderManager:ConnectSkillButtonClickHandler(tag, skillId)
  if not self:IsBattleTouchEnable() then
    return
  end
  PlayUIEffects(AUDIOS.UI.ui_click_normal.id)
  self:AddPlayerOperate("G_BattleLogicMgr", "RenderConnectSkillHandler", tag, skillId)
end
function BattleRenderManager:WeakSkillPointClickHandler(sceneTag, touchedPointId)
  self:AddPlayerOperate("G_BattleLogicMgr", "RenderWeakPointClickHandler", sceneTag, touchedPointId)
end
function BattleRenderManager:ForceSetTimeScaleHandler(timeScale)
  self:AddPlayerOperate("G_BattleLogicMgr", "RenderSetTempTimeScaleHandler", timeScale)
end
function BattleRenderManager:ForceRecoverTimeScaleHandler()
  self:AddPlayerOperate("G_BattleLogicMgr", "RenderRecoverTempTimeScaleHandler")
end
function BattleRenderManager:PlayerSkillHandler(tag, skillId)
  self:AddPlayerOperate("G_BattleLogicMgr", "RenderPlayerSkillClickHandler", tag, skillId)
end
function BattleRenderManager:QuitGameButtonClickHandler(sender)
  if self:GetQuitLock() then
    return
  end
  if QuestBattleType.PVC == self:GetQuestBattleType() then
    local layer = require("common.CommonTip").new({
      text = __("\231\161\174\229\174\154\232\166\129\233\128\128\229\135\186\229\144\151?"),
      descr = __("\233\128\128\229\135\186\230\156\172\229\156\186\230\136\152\230\150\151\228\188\154\232\162\171\232\174\164\229\174\154\228\184\186\229\164\177\232\180\165"),
      callback = function(sender)
        self:SetBattleTouchEnable(false)
        self:SetQuitLock(true)
        self:AddPlayerOperate("G_BattleLogicMgr", "RenderQuitGameHandler")
      end
    })
    layer:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(layer)
    return
  end
  self:SetBattleTouchEnable(false)
  self:SetQuitLock(true)
  self:AddPlayerOperate("G_BattleLogicMgr", "RenderQuitGameHandler")
end
function BattleRenderManager:RestartGameButtonClickHandler(sender)
  if not self:CanRestartGame() then
    app.uiMgr:ShowInformationTips(__("\230\151\160\230\179\149\233\135\141\230\150\176\229\188\128\229\167\139!!!"))
  else
    if self:GetRestartLock() then
      return
    end
    self:SetBattleTouchEnable(false)
    self:SetRestartLock(true)
    self:AddPlayerOperate("G_BattleLogicMgr", "RenderRestartGameHandler")
  end
end
function BattleRenderManager:ScreenRecordClickHandler(sender)
  local start = BattleUtils.StartScreenRecord()
  if start then
    PlayUIEffects(AUDIOS.UI.ui_click_normal.id)
    self:GetBattleScene().viewData.recordLabel:setTexture(_res("ui/battle/battle_btn_video_under.png"))
    self:GetBattleScene().viewData.recordMark:setTexture(_res("ui/battle/battle_ico_video_state.png"))
  end
end
function BattleRenderManager:AddPlayerOperate(managerName, functionName, ...)
  local playerOperateStruct = LogicOperateStruct.New(managerName, functionName, ...)
  G_BattleLogicMgr:GetBData():AddPlayerOperate(playerOperateStruct)
end
function BattleRenderManager:SetBattleTimeScale(timeScale)
  self:GetBattleScene().viewData.accelerateButton:getNormalImage():setTexture(_res(string.format("ui/battle/battle_btn_accelerate_%d.png", checkint(timeScale))))
  G_BattleMgr:SetRenderTimeScale(timeScale)
end
function BattleRenderManager:AppEnterBackground()
  if nil ~= self:GetBattleScene() or not self:IsBattleTouchEnable() then
    local ignoreLayerTags = {PAUSE_SCENE_TAG}
    for _, v in ipairs(ignoreLayerTags) do
      if nil ~= self:GetBattleScene():getChildByTag(v) then
        return
      end
    end
    self:AddPlayerOperate("G_BattleLogicMgr", "AppEnterBackground")
  end
end
function BattleRenderManager:AppEnterForeground()
end
function BattleRenderManager:ShowForceQuitLayer()
  local layer = app.uiMgr:GetCurrentScene():GetDialogByTag(FORCE_QUIT_LAYER_TAG)
  if nil ~= layer then
    layer:runAction(cc.RemoveSelf:create())
    return
  end
  local gameResultLayer = self:GetBattleScene():GetUIByTag(GAME_RESULT_LAYER_TAG)
  if nil ~= gameResultLayer then
    self:SetBattleTouchEnable(false)
    G_BattleMgr:BackToPrevious()
    return
  end
  layer = require("common.CommonTip").new({
    text = __("\231\161\174\229\174\154\232\166\129\233\128\128\229\135\186\229\144\151?"),
    descr = __("\233\128\128\229\135\186\230\156\172\229\156\186\230\136\152\230\150\151\228\188\154\232\162\171\232\174\164\229\174\154\228\184\186\229\164\177\232\180\165"),
    callback = function(sender)
      self:SetBattleTouchEnable(false)
      G_BattleMgr:BackToPrevious()
    end
  })
  layer:setTag(FORCE_QUIT_LAYER_TAG)
  layer:setPosition(display.center)
  app.uiMgr:GetCurrentScene():AddDialog(layer)
end
function BattleRenderManager:GetBattleScene()
  return G_BattleMgr:GetViewComponent()
end
function BattleRenderManager:GetBattleRoot()
  return self:GetBattleScene().viewData.battleLayer
end
function BattleRenderManager:AddAObjectView(tag, view)
  self.objectViews[tostring(tag)] = view
end
function BattleRenderManager:RemoveAObjectView(tag)
  self.objectViews[tostring(tag)] = nil
end
function BattleRenderManager:GetAObjectView(tag)
  return self.objectViews[tostring(tag)]
end
function BattleRenderManager:AddAAttachObjectView(tag, view)
  self.qteAttachViews[tostring(tag)] = view
end
function BattleRenderManager:RemoveAAttachObjectView(tag)
  self.qteAttachViews[tostring(tag)] = nil
end
function BattleRenderManager:GetAAttachObjectView(tag)
  return self.qteAttachViews[tostring(tag)]
end
function BattleRenderManager:GetCISceneBySceneTag(sceneTag, isPauseScene)
  if isPauseScene then
    return self.ciScenes.pause[tostring(sceneTag)]
  else
    return self.ciScenes.normal[tostring(sceneTag)]
  end
end
function BattleRenderManager:SetCISceneBySceneTag(sceneTag, isPauseScene, scene)
  if isPauseScene then
    self.ciScenes.pause[tostring(sceneTag)] = scene
  else
    self.ciScenes.normal[tostring(sceneTag)] = scene
  end
end
function BattleRenderManager:GetCISceneByOwnerTag(tag)
  for sceneTag_, scene in pairs(self.ciScenes.normal) do
    if tag == scene:GetOwnerTag() then
      return scene
    end
  end
  for sceneTag_, scene in pairs(self.ciScenes.pause) do
    if tag == scene:GetOwnerTag() then
      return scene
    end
  end
end
function BattleRenderManager:GetQuitLock()
  return self.quitLock
end
function BattleRenderManager:SetQuitLock(lock)
  self.quitLock = lock
end
function BattleRenderManager:GetRestartLock()
  return self.restartLock
end
function BattleRenderManager:SetRestartLock(lock)
  self.restartLock = lock
end
function BattleRenderManager:DebugCells()
  for r = 1, G_BattleLogicMgr:GetBConf().ROW do
    for c = 1, G_BattleLogicMgr:GetBConf().COL do
      local cellInfo = G_BattleLogicMgr:GetCellPosByRC(r, c)
      local t = display.newImageView(_res("ui/common/common_hint_circle_red_ico.png"), cellInfo.cx, cellInfo.cy)
      self:GetBattleRoot():addChild(t)
      local posLabel = display.newLabel(t:getContentSize().width * 0.5, t:getContentSize().height + 10, {
        text = string.format("(%d,%d)", r, c),
        fontSize = 14,
        color = "#6c6c6c"
      })
      t:addChild(posLabel)
    end
  end
end
return BattleRenderManager
