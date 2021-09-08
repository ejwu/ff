local BaseObjectModel = __Require("battle.object.logicModel.objectModel.BaseObjectModel")
local EnemyPlayerObjectModel = class("EnemyPlayerObjectModel", BaseObjectModel)
function EnemyPlayerObjectModel:ctor(...)
  BaseObjectModel.ctor(self, ...)
end
function EnemyPlayerObjectModel:InitViewModel()
end
function EnemyPlayerObjectModel:UpdateCountdown(dt)
  for k, v in pairs(self.countdowns) do
    self.countdowns[k] = math.max(v - dt, 0)
  end
  if 0 >= self.countdowns.energy then
    self.countdowns.energy = 1
    self:AddEnergy(self:GetEnergyRecoverRatePerS())
  end
end
function EnemyPlayerObjectModel:AddEnergy(delta)
  BaseObjectModel.AddEnergy(self, delta)
end
function EnemyPlayerObjectModel:GetEnergyRecoverRatePerS()
  return PLAYER_ENERGY_PER_S + self:GetEnergyRecoverRate()
end
return EnemyPlayerObjectModel
