local BaseBattleManager = __Require("battle.manager.BaseBattleManager")
local BattleLogicManager = class("BattleLogicManager", BaseBattleManager)
local QTEAttachModel = __Require("battle.object.logicModel.BaseAttachModel")
local LOGIC_FPS = 0.03333333333333333
local BUY_REVIVAL_LAYER_TAG = 2301
local FORCE_QUIT_LAYER_TAG = 2311
local LOGIC_FRAME_ADVANCE = -1
function BattleLogicManager:ctor(...)
  BaseBattleManager.ctor(self, ...)
end
function BattleLogicManager:Init()
  BaseBattleManager.Init(self)
  self:InitValue()
end
function BattleLogicManager:InitValue()
  self.bconf = nil
  self.bdata = nil
  self.objEvents = {}
  self.globalEvents = {}
  self.canTouch = false
end
function BattleLogicManager:EnterBattle()
  self:InitBattleDrivers()
  self:InitBattleData()
end
function BattleLogicManager:InitBattleDrivers()
  local shiftDriverClassName = "battle.battleDriver.BattleShiftDriver"
  local questBattleType = self:GetQuestBattleType()
  local isTagMatch = self:IsTagMatchBattle()
  if isTagMatch then
    shiftDriverClassName = "battle.battleDriver.TagMatchShiftDriver"
  end
  local shiftDriver = __Require(shiftDriverClassName).new({owner = self})
  self:SetBattleDriver(BattleDriverType.SHIFT_DRIVER, shiftDriver)
  local completeType
  for wave, stageCompleteInfo in ipairs(self:GetBattleConstructData().stageCompleteInfo) do
    completeType = stageCompleteInfo.completeType
    local endDriverClassName = "battle.battleDriver.BattleEndDriver"
    if ConfigStageCompleteType.SLAY_ENEMY == completeType then
      endDriverClassName = "battle.battleDriver.SlayEndDriver"
    elseif ConfigStageCompleteType.HEAL_FRIEND == completeType then
      endDriverClassName = "battle.battleDriver.HealEndDriver"
    elseif ConfigStageCompleteType.ALIVE == completeType then
      endDriverClassName = "battle.battleDriver.AliveEndDriver"
    elseif ConfigStageCompleteType.TAG_MATCH == completeType or isTagMatch then
      endDriverClassName = "battle.battleDriver.TagMatchEndDriver"
    end
    local endDriver = __Require(endDriverClassName).new({
      owner = self,
      wave = wave,
      stageCompleteInfo = stageCompleteInfo
    })
    self:SetEndDriver(wave, endDriver)
  end
  local skadaDriver = __Require("battle.battleDriver.BattleSkadaDriver").new({owner = self})
  self:SetBattleDriver(BattleDriverType.SKADA_DRIVER, skadaDriver)
end
function BattleLogicManager:InitBattleData()
  local bdata = __Require("battle.controller.BattleData").new({
    battleConstructor = self:GetBattleConstructor()
  })
  self:SetBData(bdata)
end
function BattleLogicManager:LoadResourcesOver()
  self:InitBattleLogic()
  if DEBUG_MEM then
    print("----------------------------------------")
    print("battle start and check lua men")
    print(string.format("LUA VM MEMORY USED: %0.2f KB", collectgarbage("count")))
    print("----------------------------------------")
  end
end
function BattleLogicManager:InitBattleLogic()
  self:Init2ServerConstructorData()
  self:InitOBOjbect()
  self:InitRandomManager()
  self:InitBattleConfig()
  self:InitGlobalEffect()
  self:CreateNextWave()
  self:InitWeather()
  self:InitPlayer()
  self:InitHalosEffect()
  self:InitEventController()
  self:InitTimeScale()
  self:InitFunctionModule()
  self:GetBData():RecordStartAliveFriendObjPStr()
  self:ForceAnalyzeRenderOperate()
end
function BattleLogicManager:InitRandomManager()
  local randomManager = __Require("battle.controller.RandomManagerNew").new()
  self:SetRandomManager(randomManager)
  self:GetRandomManager():SetRandomseed(self:GetRandomseed())
end
function BattleLogicManager:InitFunctionModule()
end
function BattleLogicManager:InitTimeScale()
  local timeScale = self:GetBattleConstructData().gameTimeScale
  self:SetTimeScale(timeScale)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "SetBattleTimeScale", timeScale)
end
function BattleLogicManager:InitOBOjbect()
  local isEnemy = false
  local location = ObjectLocation.New(0, 0, 0, 0)
  local objInfo = ObjectConstructorStruct.New(nil, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy, nil, nil, nil, nil, false, nil, nil, nil, nil, nil)
  local tag = self:GetBData():GetTagByTagType(BattleTags.BT_OBSERVER)
  local objData = ObjectLogicModelConstructorStruct.New(ObjectIdStruct.New(tag, BattleElementType.BET_OB), objInfo)
  local obj = __Require("battle.object.logicModel.objectModel.OBObjectModel").new(objData)
  self:GetBData():AddAOBLogicModel(obj)
  self:GetBData():SetOBObject(obj)
end
function BattleLogicManager:InitGlobalEffect()
  local isEnemy = false
  local location = ObjectLocation.New(0, 0, 0, 0)
  local objInfo = ObjectConstructorStruct.New(nil, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy, nil, nil, nil, nil, false, nil, nil, nil, nil, nil)
  local tag = self:GetBData():GetTagByTagType(BattleTags.BT_GLOBAL_EFFECT)
  local objData = ObjectLogicModelConstructorStruct.New(ObjectIdStruct.New(tag, BattleElementType.BET_OB), objInfo)
  local obj = __Require("battle.object.logicModel.objectModel.GlobalEffectObjectModel").new(objData)
  self:GetBData():SetGlobalEffectObj(obj)
  if QuestBattleType.TOWER == self:GetQuestBattleType() then
    obj:AddTowerEffects(self:GetGlobalEffects())
  else
    obj:AddSkills(self:GetGlobalEffects())
  end
  obj:AddUnionPetsEffect(nil)
  self:InitSceneSkillEffect()
end
function BattleLogicManager:InitWeather()
  local weatherInfo = self:GetBData():GetStageWeatherConfig()
  if nil ~= weatherInfo then
    local weatherConfig
    local isEnemy = false
    local location = ObjectLocation.New(0, 0, 0, 0)
    for _, weatherId_ in ipairs(weatherInfo) do
      local weatherId = checkint(weatherId_)
      weatherConfig = CommonUtils.GetConfig("quest", "weather", weatherId)
      if nil ~= weatherConfig then
        local objInfo = ObjectConstructorStruct.New(weatherId, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, isEnemy, nil, nil, nil, nil, false, nil, nil, nil, nil, nil)
        local tag = self:GetBData():GetTagByTagType(BattleTags.BT_WEATHER)
        local objData = ObjectLogicModelConstructorStruct.New(ObjectIdStruct.New(tag, BattleElementType.BET_WEATHER), objInfo)
        local obj = __Require("battle.object.logicModel.objectModel.WeatherObjectModel").new(objData)
        self:GetBData():AddAOtherLogicModel(obj)
      end
    end
  end
end
function BattleLogicManager:InitPlayer()
  local friendPlayerCampType = false
  local friendPlayerSkills = self:GetPlayerSkilInfo(friendPlayerCampType)
  local location = ObjectLocation.New(0, 0, 0, 0)
  local objInfo = ObjectConstructorStruct.New(ConfigSpecialCardId.PLAYER, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, friendPlayerCampType, nil, friendPlayerSkills, nil, nil, false, nil, nil, nil, nil, nil)
  local tag = self:GetBData():GetTagByTagType(BattleTags.BT_FRIEND_PLAYER)
  local objData = ObjectLogicModelConstructorStruct.New(ObjectIdStruct.New(tag, BattleElementType.BET_PLAYER), objInfo)
  local obj = __Require("battle.object.logicModel.objectModel.BasePlayerObjectModel").new(objData)
  self:GetBData():AddAOtherLogicModel(obj)
  local enemyCampType = true
  local enemyPlayerSkills = self:GetPlayerSkilInfo(enemyCampType)
  if nil ~= enemyPlayerSkills then
    local location = ObjectLocation.New(0, 0, 0, 0)
    local objInfo = ObjectConstructorStruct.New(ConfigSpecialCardId.PLAYER, location, 1, BattleObjectFeature.BASE, ConfigCardCareer.BASE, enemyCampType, nil, enemyPlayerSkills, nil, nil, false, nil, nil, nil, nil, nil)
    local tag = self:GetBData():GetTagByTagType(BattleTags.BT_ENEMY_PLAYER)
    local objData = ObjectLogicModelConstructorStruct.New(ObjectIdStruct.New(tag, BattleElementType.BET_PLAYER), objInfo)
    local obj = __Require("battle.object.logicModel.objectModel.EnemyPlayerObjectModel").new(objData)
    self:GetBData():AddAOtherLogicModel(obj)
  end
end
function BattleLogicManager:InitBattleConfig()
  local designScreenSize = cc.size(1334, 750)
  local designBgImgSize = cc.size(1334, 1002)
  local oriL, oriR, oriB, oriT = 0, 1334, 200, 530
  local oriW = oriR - oriL
  local oriH = oriT - oriB
  local x = designBgImgSize.width * 0.5 - oriW * 0.5
  local y = oriB + designScreenSize.height * 0.5 - designBgImgSize.height * 0.5
  local battleArea = cc.rect(x, y, oriW, oriH)
  local battleAreaMaxDis = battleArea.width * battleArea.width + battleArea.height * battleArea.height
  local totalRow = 5
  local totalCol = 30
  local cellSizeWidth = battleArea.width / totalCol
  local cellSizeHeight = battleArea.height / totalRow
  local cellSize = cc.size(cellSizeWidth, cellSizeHeight)
  local bconf = {
    BATTLE_AREA = battleArea,
    BATTLE_AREA_MAX_DIS = battleAreaMaxDis,
    ROW = totalRow,
    COL = totalCol,
    cellSizeWidth = cellSizeWidth,
    cellSizeHeight = cellSizeHeight,
    cellSize = cellSize,
    designScreenSize = designScreenSize
  }
  self:SetBConf(bconf)
  self:InitCellsCoordinate()
end
function BattleLogicManager:InitCellsCoordinate()
  local bconf = self:GetBConf()
  bconf.cellsCoordinate = {}
  for r = 1, bconf.ROW do
    if nil == bconf.cellsCoordinate[r] then
      bconf.cellsCoordinate[r] = {}
    end
    for c = 1, bconf.COL do
      bconf.cellsCoordinate[r][c] = {
        cx = bconf.BATTLE_AREA.x + bconf.cellSize.width * 0.5 + (c - 1) * bconf.cellSize.width,
        cy = bconf.BATTLE_AREA.y + bconf.cellSize.height * 0.5 + (r - 1) * bconf.cellSize.height,
        box = cc.rect(bconf.BATTLE_AREA.x + (c - 1) * bconf.cellSize.width, bconf.BATTLE_AREA.y + (r - 1) * bconf.cellSize.height, bconf.cellSize.width, bconf.cellSize.height)
      }
    end
  end
end
function BattleLogicManager:GetCellPosByRC(r, c)
  local bconf = self:GetBConf()
  if r >= 1 and r <= bconf.ROW and c >= 1 and c <= bconf.COL then
    return bconf.cellsCoordinate[r][c]
  else
    return {
      cx = bconf.BATTLE_AREA.x + bconf.cellSize.width * 0.5 + (c - 1) * bconf.cellSize.width,
      cy = bconf.BATTLE_AREA.y + bconf.cellSize.height * 0.5 + (r - 1) * bconf.cellSize.height,
      box = cc.rect(bconf.BATTLE_AREA.x + (c - 1) * bconf.cellSize.width, bconf.BATTLE_AREA.y + (r - 1) * bconf.cellSize.height, bconf.cellSize.width, bconf.cellSize.height)
    }
  end
end
function BattleLogicManager:GetRowColByPos(p)
  local bconf = self:GetBConf()
  local fixP = cc.p(p.x - bconf.BATTLE_AREA.x, p.y - bconf.BATTLE_AREA.y)
  return {
    r = math.ceil(fixP.y / bconf.cellSize.height),
    c = math.floor(fixP.x / bconf.cellSize.width) + 1
  }
end
function BattleLogicManager:GetDesignScreenSize()
  return self:GetBConf().designScreenSize
end
function BattleLogicManager:GetCellSize()
  return self:GetBConf().cellSize
end
function BattleLogicManager:IsGameOver()
  return self:GetEndDriver():CanDoLogic()
end
function BattleLogicManager:CreateNextWave()
  self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):OnCreateNextWaveEnter()
end
function BattleLogicManager:EnterNextWave(dt)
  self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):OnLogicEnter(dt)
end
function BattleLogicManager:CanEnterNextWave(dt)
  return self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):CanEnterNextWave(dt)
end
function BattleLogicManager:ReadyStartNextWave()
  local bdata = self:GetBData()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ShowEnterNextWave", bdata:GetCurrentWave(), bdata:NextWaveHasElite(), bdata:NextWaveHasBoss())
  if self:IsCalculator() then
    self:AddPlayerOperate2TimeLine("G_BattleLogicMgr", self:GetFixedAnimtionFrame(ANITIME_NEXT_WAVE_REMIND), "RenderStartNextWaveHandler")
  end
end
function BattleLogicManager:StartNextWave()
  local sk = sortByKey(self:GetBData().battleObjs)
  local obj
  for _, key in ipairs(sk) do
    obj = self:GetBData().battleObjs[key]
    obj:AwakeObject()
  end
  self:SetGState(GState.START)
  self:SetBattleTouchEnable(true)
end
function BattleLogicManager:MainUpdate(dt)
  self:GetBData():AddLogicFrameIndex()
  self:GetBData():InitNextRenderOperate()
  self:AnalyzePlayerOperate()
  self:GetBData():InitNextPlayerOperate(true)
  if GState.OVER == self:GetGState() then
    return
  end
  if self:IsMainLogicPause() then
    return
  end
  self:LogicMainUpdate(dt)
end
function BattleLogicManager:LogicMainUpdate(dt, onlyLogic)
  for i = #self:GetBData().sortOBObjs, 1, -1 do
    self:GetBData().sortOBObjs[i]:Update(dt)
  end
  self:UpdateViewModel(dt)
  if GState.START == self:GetGState() then
    local needReturnLogic = self:UpdatePhaseChange(dt)
    if true == needReturnLogic then
      return
    end
    local result = self:IsGameOver()
    needReturnLogic = self:GetEndDriver():OnLogicEnter(result)
    if true == needReturnLogic then
      return
    end
    if not self:IsTimerPause() then
      self:UpdateTimer(dt)
    end
    self:UpdateLogicModel(dt)
  elseif GState.TRANSITION == self:GetGState() then
    self:EnterNextWave(dt)
  elseif GState.SUCCESS == self:GetGState() then
    if true ~= onlyLogic then
      self:GameSuccess(dt)
    end
    return PassedBattle.SUCCESS
  elseif GState.FAIL == self:GetGState() then
    if true ~= onlyLogic then
      self:GameFail(dt)
    end
    return PassedBattle.FAIL
  elseif GState.BLOCK == self:GetGState() then
    self:GameRescue(dt)
  end
end
function BattleLogicManager:CanEnterNextLogicUpdate()
  if -1 == LOGIC_FRAME_ADVANCE then
    return true
  end
  return self:GetBData():GetLogicFrameIndex() - self:GetBData():GetRenderFrameIndex() <= LOGIC_FRAME_ADVANCE
end
function BattleLogicManager:UpdateViewModel(dt)
  local viewModel
  for i = #self:GetBData().sortObjViewModels, 1, -1 do
    viewModel = self:GetBData().sortObjViewModels[i]
    viewModel:Update(dt)
  end
end
function BattleLogicManager:UpdateLogicModel(dt)
  local objs, obj
  objs = self:GetOtherLogicObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    obj:Update(dt)
  end
  objs = self:GetBulletObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    obj:Update(dt)
  end
  objs = self:GetAliveBattleObjs(false)
  for i = #objs, 1, -1 do
    obj = objs[i]
    obj:Update(dt)
  end
  objs = self:GetAliveBattleObjs(true)
  for i = #objs, 1, -1 do
    obj = objs[i]
    obj:Update(dt)
  end
  objs = self:GetAliveBeckonObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    obj:Update(dt)
  end
end
function BattleLogicManager:UpdateTimer(dt)
  self:GetBData():SetLeftTime(math.max(0, self:GetBData():GetLeftTime() - dt))
  self:GetEndDriver():OnLogicUpdate(dt)
  self:AddRenderOperate("G_BattleRenderMgr", "RefreshTimeLabel", self:GetBData():GetLeftTime())
end
function BattleLogicManager:AnalyzePlayerOperate()
  local operates = self:GetBData():GetNextPlayerOperate()
  if nil ~= operates then
    for _, operate in ipairs(operates.operate) do
      local functionName = operate.functionName
      local params = operate.variableParams
      if nil ~= self[functionName] then
        self[functionName](self, unpack(params, 1, operate.maxParams))
      end
    end
  end
end
function BattleLogicManager:UpdatePhaseChange(dt)
  local needReturnLogic = false
  local triggerPhaseNpcTag, triggerPhaseNpc, phaseData
  local dt_ = dt
  local phaseChangeDatas = self:GetBData():GetNextPhaseChange(false)
  for i = #phaseChangeDatas, 1, -1 do
    phaseData = phaseChangeDatas[i]
    triggerPhaseNpcTag = phaseData.objTag
    triggerPhaseNpc = self:IsObjAliveByTag(triggerPhaseNpcTag)
    if 0 >= phaseData.delayTime then
      if nil ~= triggerPhaseNpc then
        triggerPhaseNpc.phaseDriver:OnActionEnter(phaseData.index)
        if true == phaseData.isDieTrigger then
          triggerPhaseNpc.phaseDriver:SetDiePhaseChangeCounter(triggerPhaseNpc.phaseDriver:GetDiePhaseChangeCounter() - 1)
          needReturnLogic = true
        end
        self:SendObjEvent(ObjectEvent.OBJECT_PHASE_CHANGE, {
          triggerPhaseNpcTag = triggerPhaseNpcTag,
          phaseId = phaseData.phaseId
        })
      end
      self:GetBData():RemoveAPhaseChange(false, i)
    else
      phaseData.delayTime = math.max(0, phaseData.delayTime - dt_)
    end
  end
  phaseChangeDatas = self:GetBData():GetNextPhaseChange(true)
  for i = #phaseChangeDatas, 1, -1 do
    phaseData = phaseChangeDatas[i]
    triggerPhaseNpcTag = phaseData.objTag
    triggerPhaseNpc = self:IsObjAliveByTag(triggerPhaseNpcTag)
    if 0 >= phaseData.delayTime then
      if nil ~= triggerPhaseNpc then
        triggerPhaseNpc.phaseDriver:OnActionEnter(phaseData.index)
        if true == phaseData.isDieTrigger then
          triggerPhaseNpc.phaseDriver:SetDiePhaseChangeCounter(triggerPhaseNpc.phaseDriver:GetDiePhaseChangeCounter() - 1)
          needReturnLogic = true
        end
        self:SendObjEvent(ObjectEvent.OBJECT_PHASE_CHANGE, {
          triggerPhaseNpcTag = triggerPhaseNpcTag,
          phaseId = phaseData.phaseId
        })
      end
      self:GetBData():RemoveAPhaseChange(true, i)
      return true
    else
      phaseData.delayTime = math.max(0, phaseData.delayTime - dt_)
    end
  end
  return needReturnLogic
end
function BattleLogicManager:PauseGame()
  self:SetBattleTouchEnable(false)
  self:PauseMainLogic()
  self:PauseTimer()
  self:PauseBattleObjects()
  self:AddRenderOperate("G_BattleRenderMgr", "PauseGame")
end
function BattleLogicManager:ResumeGame()
  self:ResumeMainLogic()
  self:ResumeTimer()
  self:ResumeBattleObjects()
  self:SetBattleTouchEnable(true)
  self:AddRenderOperate("G_BattleRenderMgr", "ResumeGame")
end
function BattleLogicManager:PauseMainLogic()
  self:GetBData().isPause = true
end
function BattleLogicManager:ResumeMainLogic()
  self:GetBData().isPause = false
end
function BattleLogicManager:IsMainLogicPause()
  return self:GetBData().isPause
end
function BattleLogicManager:PauseTimer()
  self:GetBData().isPauseTimer = true
end
function BattleLogicManager:ResumeTimer()
  self:GetBData().isPauseTimer = false
end
function BattleLogicManager:IsTimerPause()
  return self:GetBData().isPauseTimer
end
function BattleLogicManager:PauseBattleObjects(ex)
  ex = ex or {}
  local objs, obj
  objs = self:GetOtherLogicObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:PauseLogic()
    end
  end
  objs = self:GetAliveBattleObjs(false)
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:PauseLogic()
    end
  end
  objs = self:GetAliveBattleObjs(true)
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:PauseLogic()
    end
  end
  objs = self:GetAliveBeckonObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:PauseLogic()
    end
  end
  objs = self:GetRestObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:PauseLogic()
    end
  end
  objs = self:GetBulletObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:PauseLogic()
    end
  end
  objs = self:GetDeadBattleObjs(false)
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:PauseLogic()
    end
  end
  objs = self:GetDeadBattleObjs(true)
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:PauseLogic()
    end
  end
  objs = self:GetDeadBeckonObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:PauseLogic()
    end
  end
end
function BattleLogicManager:ResumeBattleObjects(ex)
  ex = ex or {}
  local objs, obj
  objs = self:GetOtherLogicObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:ResumeLogic()
    end
  end
  objs = self:GetAliveBattleObjs(false)
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:ResumeLogic()
    end
  end
  objs = self:GetAliveBattleObjs(true)
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:ResumeLogic()
    end
  end
  objs = self:GetAliveBeckonObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:ResumeLogic()
    end
  end
  objs = self:GetRestObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:ResumeLogic()
    end
  end
  objs = self:GetBulletObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:ResumeLogic()
    end
  end
  objs = self:GetDeadBattleObjs(false)
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:ResumeLogic()
    end
  end
  objs = self:GetDeadBattleObjs(true)
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:ResumeLogic()
    end
  end
  objs = self:GetDeadBeckonObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    if nil == ex[obj:GetOTag()] then
      obj:ResumeLogic()
    end
  end
end
function BattleLogicManager:CIScenePauseGame(sceneTag)
  self:PauseTimer()
  self:PauseBattleObjects()
  self:PauseNormalCIScene()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "PauseCISceneStart", sceneTag)
end
function BattleLogicManager:CISceneResumeGame(sceneTag)
  self:ResumeTimer()
  self:ResumeBattleObjects()
  self:ResumeNormalCIScene()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "PauseCISceneOver", sceneTag)
  self:SetBattleTouchEnable(true)
end
function BattleLogicManager:PauseNormalCIScene()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "PauseNormalScene")
end
function BattleLogicManager:ResumeNormalCIScene()
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "ResumeNormalScene")
end
function BattleLogicManager:AppEnterBackground()
  local returnGState = {
    [GState.READY] = true,
    [GState.OVER] = true,
    [GState.BLOCK] = true,
    [GState.SUCCESS] = true,
    [GState.FAIL] = true
  }
  if true == returnGState[self:GetGState()] then
    return
  end
  self:RenderPauseBattleHandler()
end
function BattleLogicManager:AppEnterForeground()
end
function BattleLogicManager:InitHalosEffect()
  local objs, obj
  objs = self:GetOtherLogicObjs()
  for i = #objs, 1, -1 do
    obj = objs[i]
    obj:CastAllHalos()
  end
  objs = self:GetAliveBattleObjs(false)
  for i = #objs, 1, -1 do
    obj = objs[i]
    obj:CastAllHalos()
  end
  objs = self:GetAliveBattleObjs(true)
  for i = #objs, 1, -1 do
    obj = objs[i]
    obj:CastAllHalos()
  end
  self:GetGlobalEffectObj():CastAllHalos()
end
function BattleLogicManager:InitSceneSkillEffect()
  self:GetGlobalEffectObj():CastAllSceneSkills()
end
function BattleLogicManager:IsObjAliveByTag(tag)
  return self:GetBData():IsObjAliveByTag(tag)
end
function BattleLogicManager:IsObjAliveByCardId(cardId, isEnemy)
  return self:GetBData():IsObjAliveByCardId(cardId, isEnemy)
end
function BattleLogicManager:GetObjByTagForce(tag)
  return self:GetBData():GetObjByTagForce(tag)
end
function BattleLogicManager:GetObjByCardIdForce(cardId, isEnemy)
  return self:GetBData():GetObjByCardIdForce(id, isEnemy)
end
function BattleLogicManager:GetABattleObj(tag, objInfo)
  local objClassName = "battle.object.logicModel.objectModel.CardObjectModel"
  local objData = ObjectLogicModelConstructorStruct.New(ObjectIdStruct.New(tag, BattleElementType.BET_CARD), objInfo)
  local obj = __Require(objClassName).new(objData)
  self:GetBData():AddABattleObjLogicModel(obj)
  return obj
end
function BattleLogicManager:GetABeckonObj(tag, objInfo)
  local objClassName = "battle.object.logicModel.objectModel.BeckonObjectModel"
  local objData = ObjectLogicModelConstructorStruct.New(ObjectIdStruct.New(tag, BattleElementType.BET_CARD), objInfo)
  local obj = __Require(objClassName).new(objData)
  self:GetBData():AddABeckonObjLogicModel(obj)
  return obj
end
function BattleLogicManager:GetDeadObjByTag(tag)
  if nil == tag then
    return nil
  end
  local result
  tag = checkint(tag)
  local tagType = self:GetBData():GetBattleTagType(tag)
  if BattleTags.BT_FRIEND == tagType or BattleTags.BT_CONFIG_ENEMY == tagType or BattleTags.BT_OTHER_ENEMY == tagType or BattleTags.BT_BECKON == tagType or BattleTags.BT_BULLET == tagType then
    result = self:GetBData().dustObjs[tostring(tag)]
  end
  return result
end
function BattleLogicManager:GetBattleElementTypeByTag(tag)
  return self:GetBData():GetBattleElementTypeByTag(tag)
end
function BattleLogicManager:GetAQTEAttachObject(qteBuffsInfo)
  local idInfo = ObjectIdStruct.New(G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_QTE_ATTACH), BattleElementType.BASE)
  local data = ObjectLogicModelConstructorStruct.New(idInfo, qteBuffsInfo)
  local qteAttachModel = QTEAttachModel.new(data)
  return qteAttachModel
end
function BattleLogicManager:CanCreateBeckonFromBuff()
  return self:GetBData():CanCreateBeckonFromBuff()
end
function BattleLogicManager:SetEndDriver(wave, battleDriver)
  if nil == self:GetBattleDriver(BattleDriverType.END_DRIVER) then
    self:SetBattleDriver(BattleDriverType.END_DRIVER, {})
  end
  self:GetBattleDriver(BattleDriverType.END_DRIVER)[wave] = battleDriver
end
function BattleLogicManager:GetEndDriver(wave)
  if nil == wave then
    wave = self:GetBData():GetCurrentWave()
  end
  local endDriver = self:GetBattleDriver(BattleDriverType.END_DRIVER)[wave]
  if nil == endDriver then
    endDriver = self:GetBattleDriver(BattleDriverType.END_DRIVER)[1]
  end
  return endDriver
end
function BattleLogicManager:SkadaWork(skadaType, objectTag, damageData, trueDamage)
  if nil ~= self:GetBattleDriver(BattleDriverType.SKADA_DRIVER) then
    self:GetBattleDriver(BattleDriverType.SKADA_DRIVER):OnLogicEnter(skadaType, objectTag, damageData, trueDamage)
  end
end
function BattleLogicManager:SkadaAddObjectTag(teamIndex, memberIndex, objectTag)
  if nil ~= self:GetBattleDriver(BattleDriverType.SKADA_DRIVER) then
    self:GetBattleDriver(BattleDriverType.SKADA_DRIVER):SkadaAddObjectTag(teamIndex, memberIndex, objectTag)
  end
end
function BattleLogicManager:AddObjEvent(ename, o, callback)
  if nil == self.objEvents[ename] then
    self.objEvents[ename] = {}
  end
  table.insert(self.objEvents[ename], {
    tag = o:GetOTag(),
    callback = callback
  })
end
function BattleLogicManager:RemoveObjEvent(ename, o)
  if nil == self.objEvents[ename] then
    funLog(Logger.INFO, "can not find obj event -> " .. ename)
  else
    local targetTag = o:GetOTag()
    local callbackInfo
    for i = #self.objEvents[ename], 1, -1 do
      callbackInfo = self.objEvents[ename][i]
      if targetTag == callbackInfo.tag then
        table.remove(self.objEvents[ename], i)
      end
    end
  end
end
function BattleLogicManager:SendObjEvent(ename, ...)
  if nil ~= self.objEvents[ename] then
    local args = unpack({
      ...
    })
    local callbackInfo
    for i = #self.objEvents[ename], 1, -1 do
      callbackInfo = self.objEvents[ename][i]
      callbackInfo.callback(args)
    end
  end
end
function BattleLogicManager:InitEventController()
  self.connectSkillHighlightEvent = __Require("battle.event.ConnectSkillHighlightEvent").new({owner = self})
end
function BattleLogicManager:SendBullet(bulletData)
  local bullet = self:GetABullet(bulletData)
  bullet:AwakeObject()
end
function BattleLogicManager:GetABullet(bulletData)
  local className = "battle.object.logicModel.bulletModel.BaseBulletModel"
  if ConfigEffectBulletType.BASE == bulletData.otype then
    className = "battle.object.logicModel.bulletModel.BaseBulletModel"
  elseif ConfigEffectBulletType.SPINE_EFFECT == bulletData.otype then
    className = "battle.object.logicModel.bulletModel.BaseSpineBulletModel"
  elseif ConfigEffectBulletType.SPINE_PERSISTANCE == bulletData.otype then
    className = "battle.object.logicModel.bulletModel.SpinePersistenceBulletModel"
  elseif ConfigEffectBulletType.SPINE_UFO_STRAIGHT == bulletData.otype then
    className = "battle.object.logicModel.bulletModel.SpineUFOBulletModel"
  elseif ConfigEffectBulletType.SPINE_UFO_CURVE == bulletData.otype then
    className = "battle.object.logicModel.bulletModel.SpineUFOCurveBulletModel"
  elseif ConfigEffectBulletType.SPINE_WINDSTICK == bulletData.otype then
    className = "battle.object.logicModel.bulletModel.SpineWindStickBulletModel"
  else
    if ConfigEffectBulletType.SPINE_LASER == bulletData.otype then
      className = "battle.object.logicModel.bulletModel.SpineLaserBulletModel"
    else
    end
  end
  local idInfo = ObjectIdStruct.New(self:GetBData():GetTagByTagType(BattleTags.BT_BULLET), BattleElementType.BET_BULLET)
  local objData = ObjectLogicModelConstructorStruct.New(idInfo, bulletData)
  local obj = __Require(className).new(objData)
  self:GetBData():AddABulletModel(obj)
  return obj
end
function BattleLogicManager:IsBulletAdd2ObjectView(bulletData)
  local bulletType = bulletData.otype
  local causeType = bulletData.causeType
  if ConfigEffectCauseType.POINT == causeType then
    local config = {
      [ConfigEffectBulletType.SPINE_EFFECT] = true,
      [ConfigEffectBulletType.SPINE_PERSISTANCE] = true
    }
    if true == config[bulletType] then
      return true
    end
  end
  return false
end
function BattleLogicManager:RefreshAllConnectButtons(isEnemy)
  local objs = self:GetAliveBattleObjs(isEnemy)
  local obj
  for i = #objs, 1, -1 do
    obj = objs[i]
    self:AddRenderOperate("G_BattleRenderMgr", "RefreshObjectConnectButtons", obj:GetOTag(), obj:GetEnergyPercent(), obj:CanAct(), obj:GetState(), not obj:CanCastConnectByAbnormalState())
  end
end
function BattleLogicManager:CanUseFriendConnectSkill()
  return self:GetBattleConstructData().enableConnect
end
function BattleLogicManager:AutoUseFriendConnectSkill()
  return self:GetBattleConstructData().autoConnect
end
function BattleLogicManager:ConnectCISceneEnter(tag, skillId, sceneTag)
  self:CIScenePauseGame(sceneTag)
end
function BattleLogicManager:ConnectCISceneExit(tag, skillId, sceneTag)
  self:CISceneResumeGame()
  local obj = self:IsObjAliveByTag(tag)
  if nil ~= obj then
    obj.castDriver:OnConnectSkillCastEnter(skillId)
  end
end
function BattleLogicManager:ConnectSkillHighlightEventEnter(skillId, casterTag, targets)
  self.connectSkillHighlightEvent:OnEventEnter(skillId, casterTag, targets)
end
function BattleLogicManager:ConnectSkillHighlightEventExit(skillId, casterTag)
  self.connectSkillHighlightEvent:OnEventExit(skillId, casterTag)
end
function BattleLogicManager:BossCISceneEnter(tag, skillId, sceneTag)
  self:CIScenePauseGame(sceneTag)
end
function BattleLogicManager:BossCISceneExit(tag, skillId, sceneTag)
  self:CISceneResumeGame(sceneTag)
  local obj = self:IsObjAliveByTag(tag)
  if nil ~= obj then
    obj.castDriver:OnCastEnter(skillId)
  end
end
function BattleLogicManager:GameOver(gameResult)
  self:GetEndDriver():GameOver(gameResult)
end
function BattleLogicManager:GameSuccess(dt)
  if not self:CanEnterNextWave(dt) then
    return
  end
  self:SetGState(GState.OVER)
  BattleUtils.PrintBattleWaringLog("here game success !!!")
  local bdata = self:GetBData()
  local objs, obj
  objs = self:GetAliveBattleObjs(false)
  for i = #objs, 1, -1 do
    obj = objs[i]
    obj:Win()
  end
  local isPassed = PassedBattle.SUCCESS
  local params = self:GetExitCommonParameters(isPassed)
  G_BattleMgr:GameOver(isPassed, params)
end
function BattleLogicManager:GameFail(dt)
  if not self:CanEnterNextWave(dt) then
    return
  end
  self:SetGState(GState.OVER)
  BattleUtils.PrintBattleWaringLog("here game failed !!!")
  local isPassed = PassedBattle.FAIL
  local params = self:GetExitCommonParameters(isPassed)
  G_BattleMgr:GameOver(isPassed, params)
end
function BattleLogicManager:GameRescue(dt)
  if not self:CanEnterNextWave(dt) then
    return
  end
  self:SetGState(GState.OVER)
  self:AddRenderOperate("G_BattleRenderMgr", "ShowBuyRevivalScene", self:GetBData():CanBuyRevivalFree())
end
function BattleLogicManager:CancelRescue()
  self:GameOver(BattleResult.BR_FAIL)
end
function BattleLogicManager:RescueAllFriend()
  self:GetBData():AddBuyRevivalTime(1)
  self:GetBData():CostBuyRevivalFree()
  local viewModelTags = {}
  local objs = self:GetDeadBattleObjs(false)
  local obj
  for i = #objs, 1, -1 do
    obj = objs[i]
    local viewModelTag = obj:GetViewModelTag()
    if nil ~= viewModelTag then
      table.insert(viewModelTags, viewModelTag)
    end
  end
  self:AddRenderOperate("G_BattleRenderMgr", "StartRescueAllFriend", viewModelTags)
end
function BattleLogicManager:RescueAllFriendComplete()
  local objs = self:GetDeadBattleObjs(false)
  local obj
  for i = #objs, 1, -1 do
    obj = objs[i]
    obj:Revive(1, 0)
    obj:ResetLocation()
    obj:DoAnimation(true, nil, sp.AnimationName.idle, true)
    obj:RefreshRenderViewPosition()
    obj:RefreshRenderViewTowards()
    obj:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
  end
  objs = self:GetAliveBattleObjs(true)
  for i = #objs, 1, -1 do
    obj = objs[i]
    obj:ResetLocation()
    obj:DoAnimation(true, nil, sp.AnimationName.idle, true)
    obj:RefreshRenderViewPosition()
    obj:RefreshRenderViewTowards()
    obj:RefreshRenderAnimation(true, nil, sp.AnimationName.idle, true)
  end
end
function BattleLogicManager:RescueAllFriendOver()
  self:SetGState(GState.START)
  self:SetBattleTouchEnable(true)
end
function BattleLogicManager:GetPhaseChangeDataByNpcId(npcId)
  if nil == self:GetBData():GetPhaseChangeData() then
    return nil
  else
    return self:GetBData():GetPhaseChangeData()[tostring(npcId)]
  end
end
function BattleLogicManager:AddAPhaseChange(pauseLogic, phaseData)
  self:GetBData():AddAPhaseChange(pauseLogic, phaseData)
end
function BattleLogicManager:RemoveAPhaseChange(pauseLogic, index)
  self:GetBData():RemoveAPhaseChange(pauseLogic, phaseData)
end
function BattleLogicManager:GetSpineAvatarScaleByCardId(cardId)
  local cardConf = CardUtils.GetCardConfig(cardId)
  local avatarId = cardId
  local scale = CARD_DEFAULT_SCALE
  local isMonster = false
  if ConfigSpecialCardId.PLAYER == cardId or ConfigSpecialCardId.WEATHER == cardId then
    scale = CARD_DEFAULT_SCALE
  elseif nil ~= cardConf and true == CardUtils.IsMonsterCard(cardId) then
    avatarId = checkint(cardConf.drawId)
    isMonster = true
    if ConfigMonsterType.ELITE == checkint(cardConf.type) then
      scale = ELITE_DEFAULT_SCALE
    elseif ConfigMonsterType.BOSS == checkint(cardConf.type) then
      scale = BOSS_DEFAULT_SCALE
    end
    if true ~= CardUtils.IsMonsterCard(avatarId) then
      scale = CARD_DEFAULT_SCALE
    end
  end
  return scale
end
function BattleLogicManager:GetSpineAvatarScale2CardByCardId(cardId)
  return self:GetSpineAvatarScaleByCardId(cardId) / CARD_DEFAULT_SCALE
end
function BattleLogicManager:IsCardInTeam(cardId, isEnemy)
  local objs = self:GetCurrentTeam(isEnemy)
  for i, v in ipairs(objs) do
    if nil ~= v.cardId and checkint(cardId) == checkint(v.cardId) then
      return true
    end
  end
  return false
end
function BattleLogicManager:GetCurrentTeam(isEnemy)
  local currentTeamIndex = self:GetCurrentTeamIndex(isEnemy)
  if isEnemy then
    return self:GetBData():GetEnemyMembers(currentTeamIndex)
  else
    return self:GetBData():GetFriendMembers(currentTeamIndex)
  end
end
function BattleLogicManager:GetCurrentTeamIndex(isEnemy)
  return self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):GetCurrentTeamIndex(isEnemy)
end
function BattleLogicManager:AddRenderOperate(managerName, functionName, ...)
  local renderOperateStruct = RenderOperateStruct.New(managerName, functionName, ...)
  self:GetBData():AddRenderOperate(renderOperateStruct)
end
function BattleLogicManager:GetCurrentWave()
  return self:GetBData():GetCurrentWave()
end
function BattleLogicManager:GetNextWave()
  return self:GetBData():GetNextWave()
end
function BattleLogicManager:GetBData()
  return self.bdata
end
function BattleLogicManager:SetBData(bdata)
  self.bdata = bdata
end
function BattleLogicManager:GetBConf()
  return self.bconf
end
function BattleLogicManager:SetBConf(bconf)
  self.bconf = bconf
end
function BattleLogicManager:GetRandomManager()
  return self.randomManager
end
function BattleLogicManager:SetRandomManager(randomManager)
  self.randomManager = randomManager
end
function BattleLogicManager:GetRandomseed()
  return self:GetBattleConstructor():GetBattleRandomConfig().randomseed
end
function BattleLogicManager:GetTimeScale()
  return self:GetBData():GetTimeScale()
end
function BattleLogicManager:SetTimeScale(timeScale)
  if 0 == i then
    return
  end
  self:GetBData():SetTimeScale(timeScale)
  print("=====<<<< here set battle time scale ->", timeScale)
end
function BattleLogicManager:GetCurrentTimeScale()
  return self:GetBData():GetCurrentTimeScale()
end
function BattleLogicManager:SetCurrentTimeScale(timeScale)
  if 0 == i then
    return
  end
  self:GetBData():SetCurrentTimeScale(timeScale)
  print("=====<<<< here set battle temp time scale ->", timeScale)
end
function BattleLogicManager:GetGState()
  return self:GetBData().gameState
end
function BattleLogicManager:SetGState(gstate)
  self:GetBData().gameState = gstate
end
function BattleLogicManager:GetLogicFrameInterval()
  return LOGIC_FPS * self:GetBData():GetCurrentTimeScale()
end
function BattleLogicManager:GetFixedAnimtionFrame(frame)
  local fixedFrame = frame / self:GetBData():GetCurrentTimeScale()
  return fixedFrame
end
function BattleLogicManager:GetAliveBattleObjs(isEnemy)
  if true == isEnemy then
    return self:GetBData().sortBattleObjs.enemy
  else
    return self:GetBData().sortBattleObjs.friend
  end
end
function BattleLogicManager:GetBulletObjs()
  return self:GetBData().sortBattleObjs.bullet
end
function BattleLogicManager:GetDeadBattleObjs(isEnemy)
  if true == isEnemy then
    return self:GetBData().sortDustObjs.enemy
  else
    return self:GetBData().sortDustObjs.friend
  end
end
function BattleLogicManager:GetAliveBeckonObjs()
  return self:GetBData().sortBattleObjs.beckonObj
end
function BattleLogicManager:GetDeadBeckonObjs()
  return self:GetBData().sortDustObjs.beckonObj
end
function BattleLogicManager:GetGlobalEffectObj()
  return self:GetBData():GetGlobalEffectObj()
end
function BattleLogicManager:GetOBObject()
  return self:GetBData():GetOBObject()
end
function BattleLogicManager:GetOtherLogicObjs()
  return self:GetBData().sortOtherObjs
end
function BattleLogicManager:GetRestObjs()
  return self:GetBData().sortRestObjs
end
function BattleLogicManager:HasNextTeam(isEnemy)
  return self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):HasNextTeam(isEnemy)
end
function BattleLogicManager:HasNextWave()
  return self:GetEndDriver():HasNextWave()
end
function BattleLogicManager:GetRecordFightDataStr()
  return self:GetBData():GetFightDataStr()
end
function BattleLogicManager:SetBattleTouchEnable(enable)
  self.canTouch = enable
end
function BattleLogicManager:IsBattleTouchEnable()
  return self.canTouch
end
function BattleLogicManager:RenderQuitGameHandler()
  self:SetBattleTouchEnable(false)
  G_BattleMgr:QuitBattle()
end
function BattleLogicManager:RenderPauseBattleHandler()
  if not self:IsBattleTouchEnable() then
    return
  end
  if not self:IsMainLogicPause() then
    self:PauseGame()
  end
end
function BattleLogicManager:RenderResumeBattleHandler()
  self:ResumeGame()
end
function BattleLogicManager:RenderAccelerateHandler()
  if not self:IsBattleTouchEnable() then
    return
  end
  local timeScaleConfig = 3
  local currentTimeScale = self:GetBData():GetTimeScale()
  local newTimeScale = timeScaleConfig - currentTimeScale
  self:SetTimeScale(newTimeScale)
  self:AddRenderOperate("G_BattleRenderMgr", "SetBattleTimeScale", newTimeScale)
end
function BattleLogicManager:RenderConnectSkillHandler(tag, skillId)
  if not self:IsBattleTouchEnable() then
    return
  end
  if self:AutoUseFriendConnectSkill() then
    print("\229\189\147\229\137\141\229\164\132\228\186\142\232\135\170\229\138\168\233\135\138\230\148\190\232\191\158\230\144\186\230\138\128\230\168\161\229\188\143")
    return
  end
  local obj = self:IsObjAliveByTag(tag)
  if nil ~= obj then
    obj:CastConnectSkill(skillId)
  else
    print("\231\155\174\230\160\135\232\191\158\230\144\186\230\138\128\231\137\169\228\189\147\230\173\187\228\186\161")
  end
end
function BattleLogicManager:RenderQTEAttachObjectHandler(ownerTag, tag, skillId)
  if not self:IsBattleTouchEnable() then
    return
  end
  local owner = self:IsObjAliveByTag(ownerTag)
  if nil ~= owner then
    local qteAttachModel = owner:GetQTEBySkillId(skillId)
    if nil ~= qteAttachModel then
      qteAttachModel:TouchedAttachObject()
    end
  end
end
function BattleLogicManager:RenderBeckonObjectHandler(tag)
  if not self:IsBattleTouchEnable() then
    return
  end
  local obj = self:IsObjAliveByTag(tag)
  if nil ~= obj then
    obj:TouchedHandler()
  end
end
function BattleLogicManager:RenderSetTempTimeScaleHandler(timeScale)
  self:SetCurrentTimeScale(timeScale)
  self:AddRenderOperate("G_BattleRenderMgr", "SetBattleTimeScale", timeScale)
end
function BattleLogicManager:RenderRecoverTempTimeScaleHandler()
  local oriTimeScale = self:GetTimeScale()
  self:SetCurrentTimeScale(oriTimeScale)
  self:AddRenderOperate("G_BattleRenderMgr", "SetBattleTimeScale", oriTimeScale)
end
function BattleLogicManager:RenderWeakPointClickHandler(sceneTag, touchedPointId)
  if not self:IsBattleTouchEnable() then
    return
  end
  self:AddRenderOperate("G_BattleRenderMgr", "WeakPointBomb", sceneTag, touchedPointId)
end
function BattleLogicManager:RenderWeakChantOverHandler(ownerTag, skillId, result)
  local obj = self:IsObjAliveByTag(ownerTag)
  if nil ~= obj then
    obj.castDriver:ChantClickHandler(skillId, result)
  end
end
function BattleLogicManager:RenderPlayerSkillClickHandler(tag, skillId)
  if not self:IsBattleTouchEnable() then
    return
  end
  local obj = self:IsObjAliveByTag(tag)
  if nil ~= obj then
    obj:CastPlayerSkill(skillId)
  end
end
function BattleLogicManager:RenderPhaseChangeSpeakAndDeformOverHandler(deformTargetTag)
  local obj = self:IsObjAliveByTag(deformTargetTag)
  if nil ~= obj then
    obj:AwakeObject()
    self:SendObjEvent(ObjectEvent.OBJECT_CREATED, {
      tag = obj:GetOTag()
    })
  end
  for i = #self:GetBData().sortBattleObjs.friend, 1, -1 do
    obj = self:GetBData().sortBattleObjs.friend[i]
    obj:ForceStun(false)
  end
  G_BattleLogicMgr:ResumeMainLogic()
end
function BattleLogicManager:RenderPhaseChangeSpeakOverStartEscapeHandler(tag)
  local obj = self:GetBData():GetALogicModelFromRest(tag)
  if nil ~= obj then
    obj:StartEscape()
  end
end
function BattleLogicManager:RenderPhaseChangeEscapeOverHandler(tag)
  local obj = self:GetBData():GetALogicModelFromRest(tag)
  if nil ~= obj then
    obj:OverEscape()
  end
end
function BattleLogicManager:RenderPhaseChangeDeformCustomizeOverHandler(deformSourceTag, deformTargetTag)
  local deformSource = self:IsObjAliveByTag(deformSourceTag)
  local deformTarget = self:IsObjAliveByTag(deformTargetTag)
  if nil ~= deformTarget then
    deformTarget:AwakeObject()
    self:SendObjEvent(ObjectEvent.OBJECT_CREATED, {
      tag = deformTarget:GetOTag()
    })
  end
  G_BattleLogicMgr:ResumeMainLogic()
end
function BattleLogicManager:RenderCameraActionShakeAndZoomOverHandler(tag, cameraActionTag)
  local obj = self:IsObjAliveByTag(tag)
  if nil ~= obj then
    obj:CameraActionOverHandler(cameraActionTag)
  end
end
function BattleLogicManager:RenderWaveTransitionStartHandler(wave)
  self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):OnShiftBegin()
end
function BattleLogicManager:RenderWaveTransitionOverHandler(wave)
  self:GetBattleDriver(BattleDriverType.SHIFT_DRIVER):OnShiftEnd()
end
function BattleLogicManager:RenderReadyStartNextWaveHandler(wave)
  self:ReadyStartNextWave()
end
function BattleLogicManager:RenderStartNextWaveHandler(wave)
  self:StartNextWave()
end
function BattleLogicManager:RenderCancelRescueHandler()
  self:CancelRescue()
end
function BattleLogicManager:RenderRestartGameHandler()
  if self:CanRestartGame() then
    self:RestartGame()
  end
end
function BattleLogicManager:RenderGuideOverHandler()
  self:GetOBObject():GuideOver()
end
function BattleLogicManager:ForceAnalyzeRenderOperate()
  G_BattleMgr:AnalyzeRenderOperate(self:GetBData():GetNextRenderOperate())
end
function BattleLogicManager:RenderCreateAObjectView(viewModelTag, objInfo)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "CreateAObjectView", viewModelTag, objInfo)
end
function BattleLogicManager:RenderCreateABeckonObjectView(viewModelTag, tag, objInfo)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "CreateABeckonObjectView", viewModelTag, tag, objInfo)
end
function BattleLogicManager:RenderPlayBattleSoundEffect(soundEffectId)
  G_BattleLogicMgr:AddRenderOperate("G_BattleRenderMgr", "PlayBattleSoundEffect", soundEffectId)
end
function BattleLogicManager:AddPlayerOperate2TimeLine(managerName, delayFrame, functionName, ...)
  local playerOperateStruct = LogicOperateStruct.New(managerName, functionName, ...)
  self:GetBData():AddPlayerOperate(playerOperateStruct, delayFrame)
end
function BattleLogicManager:GetExitCommonParameters(isPassed)
  local constructorStr = Table2StringNoMeta(self:GetBData():GetConstructorData())
  local loadResStr = Table2StringNoMeta(self:GetBData():GetLoadedResources())
  local playerOperate = self:GetBData():GetPlayerOperateRecord()
  local playerOperateStr = Table2StringNoMeta(playerOperate)
  local skadaData
  local skadaDamage, skadaHeal, skadaGotDamage = 0, 0, 0
  if nil ~= self:GetBattleDriver(BattleDriverType.SKADA_DRIVER) then
    skadaData = self:GetBattleDriver(BattleDriverType.SKADA_DRIVER):GetSkada2Server()
    skadaDamage = skadaData[SkadaType.DAMAGE]
    skadaHeal = skadaData[SkadaType.HEAl]
    skadaGotDamage = skadaData[SkadaType.GOT_DAMAGE]
  end
  local result = {
    teamId = self:GetTeamId(false),
    deadCards = self:GetBData():GetDeadCardsStr(),
    passTime = self:GetBData():GetPassedTime(),
    fightData = self:GetBData():GetFightDataStr(),
    fightRound = self:GetBData():GetCurrentWave(),
    isPassed = isPassed,
    constructorJson = constructorStr,
    loadedResourcesJson = loadResStr,
    playerOperateJson = playerOperateStr,
    skadaDamage = skadaDamage,
    skadaHeal = skadaHeal,
    skadaGotDamage = skadaGotDamage,
    fightResult = json.encode(self:GetBData():GetAliveFriendObjStatus()),
    enemyHp = json.encode(self:GetBData():GetAliveEnemyObjStatus())
  }
  result.totalDamage = self:GetTargetMonsterDeltaHP()
  return result
end
function BattleLogicManager:GetTargetMonsterDeltaHP()
  local deltaHp, useConfigLogic = self:GetTargetMonsterDeltaHPByConfig()
  if not useConfigLogic then
    if self:IsShareBoss() then
      deltaHp = self:GetTargetMonsterDeltaHPByShareBoss()
    else
      deltaHp = nil
    end
  end
  return deltaHp
end
function BattleLogicManager:GetTargetMonsterDeltaHPByConfig()
  local deltaHp = 0
  local useConfigLogic = false
  for otag, obj in pairs(self:GetBData().battleObjs) do
    if ConfigMonsterRecordDeltaHP.DO == obj:GetRecordDeltaHp() then
      deltaHp = deltaHp + obj:GetMainProperty():GetDeltaHp()
      useConfigLogic = useConfigLogic or true
    end
  end
  for otag, obj in pairs(self:GetBData().dustObjs) do
    if ConfigMonsterRecordDeltaHP.DO == obj:GetRecordDeltaHp() then
      deltaHp = deltaHp + obj:GetMainProperty():GetDeltaHp()
      useConfigLogic = useConfigLogic or true
    end
  end
  return deltaHp, useConfigLogic
end
function BattleLogicManager:GetTargetMonsterDeltaHPByShareBoss()
  local deltaHp = 0
  local stageId = self:GetCurStageId()
  if nil ~= stageId then
    local enemyConfig = CommonUtils.GetConfig("quest", "enemy", stageId)
    if nil ~= enemyConfig then
      local targetMonsterId
      for wave, waveConfig in pairs(enemyConfig) do
        local needBreak = false
        for _, npcConfig in ipairs(waveConfig.npc) do
          targetMonsterId = checkint(npcConfig.npcId)
          needBreak = true
          break
        end
        if needBreak then
          break
        end
      end
      if nil ~= targetMonsterId then
        for otag, obj in pairs(self:GetBData().battleObjs) do
          if targetMonsterId == obj:GetObjectConfigId() then
            deltaHp = obj:GetMainProperty():GetDeltaHp()
            return deltaHp
          end
        end
        for otag, obj in pairs(self:GetBData().dustObjs) do
          if targetMonsterId == obj:GetObjectConfigId() then
            deltaHp = obj:GetMainProperty():GetDeltaHp()
            return deltaHp
          end
        end
      end
    end
  end
  return deltaHp
end
function BattleLogicManager:QuitBattle()
  self:SetBattleTouchEnable(false)
  self:SetGState(GState.OVER)
  self:GetBData():Destroy()
  self:DestroyValue()
end
function BattleLogicManager:DestroyValue()
  self.bconf = nil
  self.objEvents = {}
  self.globalEvents = {}
end
function BattleLogicManager:RestartGame()
  G_BattleMgr:RestartGame()
end
function BattleLogicManager:RecordLoadedResources(wave, resmap)
  self:GetBData():RecordLoadedResources(wave, resmap)
end
function BattleLogicManager:Init2ServerConstructorData()
  local constructorData = self:GetBattleConstructor():CalcRecordConstructData(true)
  self:GetBData():RecordConstructorData(constructorData)
end
function BattleLogicManager:SetRecordPlayerOperate(playerOperate)
  self:GetBData():SetPlayerOperateRecord(playerOperate)
end
function BattleLogicManager:CheckerMainUpdate(dt)
  self:GetBData():AddLogicFrameIndex()
  self:GetBData():InitNextRenderOperate()
  self:AnalyzeRecordPlayerOperate()
  if GState.OVER == self:GetGState() then
    return
  end
  if self:IsMainLogicPause() then
    return
  end
  return self:CheckerLogicMainUpdate(dt)
end
function BattleLogicManager:AnalyzeRecordPlayerOperate()
  local currentLogicFrameIndex = self:GetBData():GetLogicFrameIndex()
  local playerOperates = self:GetBData():GetPlayerOperateRecord()[currentLogicFrameIndex]
  if nil ~= playerOperates then
    for _, operate in ipairs(playerOperates) do
      local functionName = operate.functionName
      local params = operate.variableParams
      if nil ~= self[functionName] then
        self[functionName](self, unpack(params, 1, operate.maxParams))
      end
    end
  end
end
function BattleLogicManager:CheckerLogicMainUpdate(dt)
  for i = #self:GetBData().sortOBObjs, 1, -1 do
    self:GetBData().sortOBObjs[i]:Update(dt)
  end
  self:UpdateViewModel(dt)
  if GState.START == self:GetGState() then
    local needReturnLogic = self:UpdatePhaseChange(dt)
    if true == needReturnLogic then
      return
    end
    local result = self:IsGameOver()
    needReturnLogic = self:GetEndDriver():OnLogicEnter(result)
    if true == needReturnLogic then
      return
    end
    if not self:IsTimerPause() then
      self:UpdateTimer(dt)
    end
    self:UpdateLogicModel(dt)
  elseif GState.TRANSITION == self:GetGState() then
    self:EnterNextWave(dt)
  elseif GState.SUCCESS == self:GetGState() then
    return PassedBattle.SUCCESS
  elseif GState.FAIL == self:GetGState() then
    return PassedBattle.FAIL
  elseif GState.BLOCK == self:GetGState() then
    self:CheckerGameRescue(dt)
  end
end
function BattleLogicManager:CheckerGameRescue(dt)
  if not self:CanEnterNextWave(dt) then
    return
  end
  self:SetGState(GState.OVER)
end
function BattleLogicManager:CalculatorMainUpdate(dt)
  self:GetBData():AddLogicFrameIndex()
  self:GetBData():InitNextRenderOperate()
  self:AnalyzePlayerOperate()
  self:GetBData():InitNextPlayerOperate(true)
  if GState.OVER == self:GetGState() then
    return
  end
  if self:IsMainLogicPause() then
    return
  end
  return self:LogicMainUpdate(dt, true)
end
function BattleLogicManager:ReplayMainUpdate(dt)
  self:GetBData():AddLogicFrameIndex()
  self:GetBData():InitNextRenderOperate()
  if 1 == self:GetBData():GetLogicFrameIndex() then
    self:ReplayAnalyzePlayerOperateByIndex(0)
  end
  self:AnalyzeRecordPlayerOperate()
  if GState.OVER == self:GetGState() then
    return
  end
  if self:IsMainLogicPause() then
    return
  end
  self:LogicMainUpdate(dt)
end
function BattleLogicManager:ReplayAnalyzePlayerOperateByIndex(index)
  local playerOperates = self:GetBData():GetPlayerOperateRecord()[index]
  if nil ~= playerOperates then
    for _, operate in ipairs(playerOperates) do
      local functionName = operate.functionName
      local params = operate.variableParams
      if nil ~= self[functionName] then
        self[functionName](self, unpack(params, 1, operate.maxParams))
      end
    end
  end
end
return BattleLogicManager
