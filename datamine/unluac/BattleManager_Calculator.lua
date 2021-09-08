local BaseBattleManager = __Require("battle.manager.BattleManager")
local BattleManager = class("BattleManager", BaseBattleManager)
__Require("battle.defines.BattleImportDefine")
local NAME = "BattleMediator"
function BattleManager:ctor(...)
  BaseBattleManager.ctor(self, ...)
end
function BattleManager:Init()
  BaseBattleManager.Init(self)
end
function BattleManager:InitValue()
  self.recordLoadedSpineResources = nil
end
function BattleManager:InitLogicManager(battleConstructor)
  local logicManager = __Require("battle.manager.BattleLogicManager").new({battleConstructor = battleConstructor})
  G_BattleLogicMgr = logicManager
end
function BattleManager:InitRenderManager(battleConstructor)
  local renderManager = __Require("battle.manager.BattleRenderManager_Server").new({battleConstructor = battleConstructor})
  G_BattleRenderMgr = renderManager
end
function BattleManager:InitClientBasedData(resmap, playerOperate)
  G_BattleRenderMgr:SetLoadedResources(resmap)
end
function BattleManager:EnterBattle()
  G_BattleLogicMgr:EnterBattle()
end
function BattleManager:StartCheckRecord()
  G_BattleLogicMgr:LoadResourcesOver()
  G_BattleRenderMgr:AddPlayerOperate("G_BattleLogicMgr", "RenderReadyStartNextWaveHandler")
  local battleResult
  while nil == battleResult do
    battleResult = G_BattleLogicMgr:CalculatorMainUpdate(G_BattleLogicMgr:GetLogicFrameInterval())
  end
  print("here checker run over and get battle result !!!", battleResult)
  local fightData = G_BattleLogicMgr:GetRecordFightDataStr()
  local playerOperateData = G_BattleLogicMgr:GetBData():GetPlayerOperateRecord()
  local playerOperateStr = Table2StringNoMeta(playerOperateData)
  return battleResult, fightData, playerOperateStr
end
function BattleManager:AnalyzeRenderOperate(operates)
end
return BattleManager
