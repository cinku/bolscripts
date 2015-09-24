if myHero.charName ~= "Jinx" then return end

require 'VPrediction'

--local variables
local enemies = {}
local minions = {}
local jungleMinions = {}
local DrakeBaronDmg = 0
local DrakeBaronTime = 0
local Wcast = 0
local teleporttime = 0
local tickCount = 0
local windUpTime = 0
local startAttackTime = 0
local SAC = false
local SX = false
local MMA = false
local interrupts = 
{
	Katarina = { spell = "KatarinaR" }, Tresh = { spell = "ThreshQ" }, Velkoz = { spell = "VelkozR" }, Warwick = { spell = "InfiniteDuress" }, Galio = { spell = "GalioIdolOfDurand" }, 
	Malzahar = { spell = "AlZaharNetherGrasp" }, Lux = { spell = "LuxMaliceCannon" }, Blitzcrank = { spell = "RocketGrabMissile" }, Caitlyn = { spell = "CaitlynPiltoverPeacemaker" },
	MissFortune = { spell = "MissFortuneBulletTime" }, Ezreal = { spell = "EzrealTrueshotBarrage" }
}
local Spells =
{
	Q = { ready = false, mana = 0, range = 0 },
	W = { ready = false, mana = 0, range = 1500, delay = 0.6, width=60, speed = 3300},
	E = { ready = false, mana = 0, range = 900, delay = 1.2, width=1, speed=1750},
	R = { ready = false, mana = 0, range = 3000, delay = 0.7, width=140, speed = 1500}
}

--hooks

function OnLoad()
	loadOrbwalker()
	variables()
	menu()
end

function OnTick()
	check()
	if checkTick(0) then
		if config.rconfig.rconfigjungle.Rjungle and Spells.R.ready then JungleStealer() end
		if GetInGameTimer() - teleporttime < 4 and teleportpos ~= nil and config.econfig.telE then
			CastSpell(_E, teleportpos.x, teleportpos.z)
		end
	end
	if checkTick(1) then
		if Spells.E.ready then
			ELogic()
		end
	end
	if checkTick(2) then
		if Spells.Q.ready then
			QLogic()
		end
	end
	if checkTick(3) then
		if Spells.W.ready and config.wconfig.autoW then
			WLogic()
		end
	end
	if checkTick(4) then
		if config.rconfig.manualR and Spells.R.ready then
			local target = targetSelector(Spells.R.range, DAMAGE_PHYSICAL)
			if ValidTarget(target) then
				local CastPosition = VP:GetLineCastPosition(target, Spells.R.delay, Spells.R.width, Spells.R.range, Spells.R.speed, myHero, false)
				CastSpell(_R, CastPosition.x, CastPosition.z)
			end
		end
		if Spells.R.ready then
			RLogic()
		end
	end
end

function isWindingUp()
	if windUpTime > GetInGameTimer() - startAttackTime then
		return true
	end
	return false
end

function OnCreateObj(obj)
	if obj.name == "global_ss_teleport_target_red.troy" then
		teleporttime = GetInGameTimer()
		teleportpos = obj.pos
	end
end

function OnProcessSpell(object, spell)
	if config.econfig.opsE and object.team ~= myHero.team and interruptWithE(object, spell.name) and ValidTarget(object, Spells.E.range) then
		CastSpell(_E, object.pos.x, object.pos.z)
	end
	if object.isMe and spell.name == "JinxW" then
		Wcast = GetInGameTimer()
	end
end

function OnProcessAttack(unit, spell)
	if unit.isMe then
		startAttackTime = GetInGameTimer()
		windUpTime = spell.windUpTime
	end
end

function QBefore()
	local target = targetSelector(bonusRange() + 60, DAMAGE_PHYSICAL)
	if Spells.Q.ready and fishBoneActive and ValidTarget(target) then
		if isCombo() and getRealDistance(target) < getRealPowPowRange(target) and (myHero.mana < (Spells.R.mana + Spells.W.mana + 20) or myHero:CalcDamage(target, myHero.totalDamage) * 3 < target.health) then
			CastSpell(_Q)
		elseif farm and (getRealDistance(target) > bonusRange() or getRealDistance(target) < getRealPowPowRange(target) or myHero.mana < (Spells.R.mana + Spells.E.mana + (Spells.W.mana*2))) then
			CastSpell(_Q)
		end
	end
	if Spells.Q.ready and isLaneClear() and not fishBoneActive and myHero.mana < (Spells.R.mana + Spells.E.mana + Spells.W.mana + 30) then
		minions:update()
		for _, minion in pairs(minions.objects) do
			if isInAutoAttackRange(minion) and minion.health < myHero:CalcDamage(minion, myHero.totalDamage) then
				for _, minion2 in pairs(minions.objects) do
					if minion2.health < myHero:CalcDamage(minion, myHero.totalDamage) and GetDistance(minion, minion2) < 150 and minion2.pos ~= minion.pos then
						CastSpell(_Q)
					end
				end
			end
		end
	end
end

--spells logic

function QLogic()
	if farm and config.farmQ and myHero.mana > (Spells.R.mana + Spells.E.mana + Spells.W.mana + 10) and not fishBoneActive then
		farmWithQ()
	end
	local target = targetSelector(bonusRange() + 60, DAMAGE_PHYSICAL)
	if ValidTarget(target) then
		local distance = getRealDistance(target)
		local powPowRange = getRealPowPowRange(target)
		if not fishBoneActive and not isInAutoAttackRange(target) then
			if isCombo() and (myHero.mana > (Spells.R.mana + Spells.W.mana + 20) or myHero:CalcDamage(target, myHero.totalDamage)*2 > target.health) then
				CastSpell(_Q)
			elseif isHarass() and myHero.mana > (Spells.R.mana + Spells.E.mana + Spells.W.mana + 20) and (distance < (bonusRange() + getHitBox(myHero) + getHitBox(target))) then
				CastSpell(_Q)
			elseif isLaneClear() and not UnderTurret(myHero) and myHero.mana > (Spells.R.mana + Spells.E.mana + (Spells.W.mana*2) + 20) and distance < bonusRange() then
				CastSpell(_Q)
			end
		end
	elseif not fishBoneActive and isCombo() and myHero.mana > (Spells.R.mana + Spells.W.mana + 20) and CountEnemyHeroInRange(2000) > 0 then
		CastSpell(_Q)
	elseif fishBoneActive and isCombo() and myHero.mana < (Spells.R.mana + Spells.W.mana + 20) then
			CastSpell(_Q)
	elseif fishBoneActive and isCombo() and CountEnemyHeroInRange(2000) == 0 then
			CastSpell(_Q)
	elseif fishBoneActive and farm then
			CastSpell(_Q)
	end
end

function WLogic()
	if isWindingUp() == true then return end
	local wait = false
	for _, enemy in ipairs(enemies) do
		if ValidTarget(enemy, Spells.W.range) then
			local predictedHealth = enemy.health + enemy.hpRegen * 2
			local Wdmg = getDmg("W", enemy, myHero)
			if Wdmg > predictedHealth or Wdmg > enemy.health then
				wait=true
				local CastPosition, HitChance, Position = VP:GetLineCastPosition(enemy, Spells.W.delay, Spells.W.width, Spells.W.range, Spells.W.speed, myHero, true)
				if CastPosition and HitChance >= 2 and not isInAutoAttackRange(enemy) and CountEnemyHeroInRange(400) == 0 and config.wconfig.ksW then
					CastSpell(_W, CastPosition.x, CastPosition.z)
				end
			end
		end
	end
	local target = targetSelector(Spells.W.range, DAMAGE_PHYSICAL)
	if ValidTarget(target) and not wait then
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(target, Spells.W.delay, Spells.W.width, Spells.W.range, Spells.W.speed, myHero, true)
		if CastPosition and HitChance >= 2 and isCombo() and myHero.mana > (Spells.R.mana + Spells.W.mana + 10) and CountEnemyHeroInRange(getRealPowPowRange(target)) == 0 and getRealDistance(target) > bonusRange() - 50 then
			CastSpell(_W, CastPosition.x, CastPosition.z)
		elseif CastPosition and HitChance >= 2 and (farm and myHero.mana > (Spells.R.mana + Spells.E.mana + (Spells.W.mana*2) + 40)) and config.wconfig["haras"..target.charName] and not UnderTurret(myHero) and CountEnemyHeroInRange(bonusRange()) == 0 then
			CastSpell(_W, CastPosition.x, CastPosition.z)
		elseif CastPosition and HitChance >= 2 and (farm or isCombo()) and myHero.mana > (Spells.R.mana + Spells.W.mana) and CountEnemyHeroInRange(getRealPowPowRange(target)) == 0 then
			for _, enemy in ipairs(enemies) do
				if enemy.canMove or TargetHaveBuff("Recall", target) then
					CastSpell(_W, CastPosition.x, CastPosition.z)
				end
			end
		end
	end
end

function ELogic()
	if myHero.mana > (Spells.R.mana + Spells.W.mana) and config.econfig.autoE then
		for _, target in ipairs(enemies) do
			if ValidTarget(target, Spells.E.range+100) then
				local TargetDashing, CanHit, DashPosition = VP:IsDashing(target, Spells.E.delay, Spells.E.width, Spells.E.speed, myHero)
				local CastPosition, HitChance, Position = VP:GetCircularCastPosition(target, 0.25, Spells.E.width, Spells.E.range, Spells.E.speed, myHero, false)
				local TargetCastPosition, TargetHitChance, TargetPosition = VP:GetCircularCastPosition(target, 1.2, Spells.E.width, Spells.E.range, 3000, myHero, false)
				if TargetDashing and GetDistance(DashPosition) < 300 and config.econfig.AGC then
					CastSpell(_E, DashPosition.x, DashPosition.z)
				elseif (target.canMove ~= false or (HitChance >= 3 and HitChance <= 5)) and myHero.mana > (Spells.R.mana + Spells.E.mana + Spells.W.mana) then
					CastSpell(_E, CastPosition.x, CastPosition.z)
				elseif config.econfig.comboE and isCombo() then
					local PlayerCastPosition, PlayerHitChance, PlayerPosition = VP:GetCircularCastPosition(myHero, Spells.E.delay, Spells.E.width, Spells.E.range, Spells.E.speed, myHero, false)
					if GetDistance(TargetCastPosition, target) > 350 and GetDistance(PlayerPosition, myHero) > 100 then
						if GetDistance(myHero, TargetCastPosition) > GetDistance(myHero, target) then
							if GetDistance(target, PlayerCastPosition) < GetDistance(target, myHero) then
								CastSpell(_E, TargetCastPosition.x, TargetCastPosition.z)
							end
						else
							if GetDistance(target, PlayerCastPosition) > GetDistance(target, myHero) then
								CastSpell(_E, TargetCastPosition.x, TargetCastPosition.z)
							end
						end
					end
				end
			end
		end
	end
end

function RLogic()
	if isWindingUp() == true and config.rconfig.autoR ~= true then return end
	for _, target in ipairs(enemies) do
		if ValidTarget(target, Spells.R.range) and validUltTarget(target) and (GetInGameTimer() - Wcast > 1) then
			local predictedHealth = target.health + target.hpRegen * 2
			local Rdmg = getDmg("R", target, myHero)
			if Rdmg > predictedHealth then
				local CastPosition, HitChance, Position = VP:GetLineCastPosition(target, Spells.R.delay, Spells.R.width, Spells.R.range, Spells.R.speed, myHero, false)
				if CastPosition and HitChance >= 2 and getRealDistance(target) > (bonusRange() + 30 + getHitBox(target)) and countAllyInRangeOfUnit(600, target) == 0 and CountEnemyHeroInRange(400) == 0 and not checkCollisionWithHeroes(target, CastPosition) and not isFacing(target) then
					CastSpell(_R, CastPosition.x, CastPosition.z)
				elseif CastPosition and HitChance >= 2 and CountEnemyHeroInRange(200, target) > 2 and getRealDistance(target) > (bonusRange() + 200 + getHitBox(target)) then
					CastSpell(_R, CastPosition.x, CastPosition.z)
				end
			end
		end
	end
end

--calculations

function isFacing(tar)
	local TargetCastPosition = VP:GetPredictedPos(tar, 1, 1750, myHero, false)
	--local PlayerCastPosition, PlayerHitChance = VPrediction:GetPredictedPos(myHero, 1, 1750, myHero, false)
	if GetDistance(myHero, TargetCastPosition) >= GetDistance(myHero, tar) then
		return false
	end
	return true
end

function checkTick(tick)
	if tickCount == tick then
		tickCount = tickCount + 1
		if tickCount >= 5 then
			tickCount = 0
		end
		return true
	end
	return false
end

function JungleStealer()
	jungleMinions:update()
	for _, mob in ipairs(jungleMinions.objects) do
		if ((mob.charName == "SRU_Dragon" and config.rconfig.rconfigjungle.Rdragon) or (mob.charName == "SRU_Baron" and config.rconfig.rconfigjungle.Rbaron)) and countAllyInRangeOfUnit(1000, mob) == 0 and mob.health < mob.maxHealth and GetDistance(myHero, mob) > 1000 then
			if DrakeBaronDmg == 0 then
				DrakeBaronDmg = mob.health
			end
			if GetInGameTimer() - DrakeBaronTime > 4 then
				if DrakeBaronDmg - mob.health > 0 then
					DrakeBaronDmg = mob.health
				end
				DrakeBaronTime = GetInGameTimer()
			else
				local dmgPerSec = (DrakeBaronDmg - mob.health) * (math.abs(DrakeBaronTime - GetInGameTimer()) / 4)
				if DrakeBaronDmg - mob.health > 0 then
					local timeTravel = getUltTravelTime(myHero, Spells.R.speed, Spells.R.delay, mob.pos)
					local timeR = (mob.health - (250 + (100 * myHero:GetSpellData(_R).level) + myHero.totalDamage + 300)) / (dmgPerSec / 4 )
					if timeTravel > timeR then
						CastSpell(_R, mob.pos.x, mob.pos.z)
					end
				else
					DrakeBaronDmg = mob.health
				end
			end
		end
	end
end

function debugMsg(msg)
	PrintChat(tostring(msg))
end

function getUltTravelTime(source, speed, delay, pos)
	local distance = GetDistance(source, pos)
	local missileSpeed = speed
	if source.charName == "Jinx" and distance > 1350 then
		local accelRate = 0.3
		local accelDif = distance - 1350
		if accelDif > 150 then
			accelDif = 150
		end
		local dif = distance - 1500
		missileSpeed = (1350 * speed + accelDif * (speed + accelRate * accelDif) + dif * 2200) / distance
	end
	return (distance / missileSpeed + delay)
end

function countAllyInRangeOfUnit(range, unit)
	local count = 0
	for i = 1, heroManager.iCount do
        local hero = heroManager:GetHero(i)
        if hero.team == myHero.team and GetDistance(hero, unit) < range then
			count = count + 1
        end
    end
	return count
end

function checkCollisionWithHeroes(tar, castPos)
	for _, enemy in ipairs(enemies) do
		if enemy.networkID ~= tar.networkID then
			if VP:CheckCol(tar, enemy, castPos, Spells.R.delay, Spells.R.width, Spells.R.range, Spells.R.speed, myHero, false) then
				return true
			end
		end
	end
	return false
end

function interruptWithE(object, spellName)
	if interrupts[object.charName] ~= nil and interrupts[object.charName].spell == spellName then
		return true
	end
	return false
end

function check()
	Spells.Q.ready, Spells.W.ready, Spells.E.ready, Spells.R.ready = (myHero:CanUseSpell(_Q) == READY), (myHero:CanUseSpell(_W) == READY), (myHero:CanUseSpell(_E) == READY), (myHero:CanUseSpell(_R) == READY)
	
	Spells.Q.mana, Spells.W.mana, Spells.E.mana, Spells.R.mana = 20, (40 + (myHero:GetSpellData(_W).level * 10 )), 50, 100
	
	fishBoneActive = (myHero.range > 525.5)
	
	farm = (isLaneClear() or isHarass() or isLastHit())
	
	if not Spells.R.ready then
		Spells.R.mana = Spells.W.mana - myHero.mpRegen * myHero:GetSpellData(_W).currentCd
	else
		Spells.R.mana = 100
	end
	
	if myHero.health < myHero.maxHealth * 0.2 then
		Spells.Q.mana, Spells.W.mana, Spells.E.mana, Spells.R.ready = 0, 0, 0, 0
	end
end

function farmWithQ()
	minions:update()
	for _, minion in pairs(minions.objects) do
		if not isInAutoAttackRange(minion) and minion.health < myHero:CalcDamage(minion, myHero.totalDamage) and getRealPowPowRange(minion) < getRealDistance(minion) and bonusRange() < getRealDistance(minion) then
			CastSpell(_Q)
			return
		end
	end
end

function validUltTarget(tar)
	if tar.dead or TargetHaveBuff("sionpassivezombie", tar) then
		return false
	end
	return true
end

function getHitBox(unit)
	return unit.boundingRadius
end

function bonusRange()
	return 670 + getHitBox(myHero) + 25 * myHero:GetSpellData(_Q).level
end

function getRealDistance(tar)
	return GetDistance(tar) + getHitBox(myHero) + getHitBox(tar)
end

function getRealPowPowRange(tar)
	return 650 + getHitBox(myHero) + getHitBox(tar)
end

function isInAutoAttackRange(tar)
	return (myHero.range + getHitBox(myHero) + getHitBox(tar) > GetDistance(tar))
end

function targetSelector(range, dmgType)
	local tarsel = TargetSelector(ts.mode, range, dmgType)
	tarsel:update()
	return tarsel.target
end

function isCombo()
	if SX then
		return SxOrb.isFight
	elseif SAC then
		return _G.AutoCarry.Keys.AutoCarry
	elseif MMA then
		return _G.MMA_IsOrbwalking()
	end
end

function isHarass()
	if SX then
		return SxOrb.isHarass
	elseif SAC then
		return _G.AutoCarry.Keys.MixedMode
	elseif MMA then
		return _G.MMA_IsDualCarrying()
	end
end

function isLaneClear()
	if SX then
		return SxOrb.isLaneClear
	elseif SAC then
		return _G.AutoCarry.Keys.LaneClear
	elseif MMA then
		return _G.MMA_IsClearing()
	end
end

function isLastHit()
	if SX then
		return SxOrb.isLastHit
	elseif SAC then
		return _G.AutoCarry.Keys.LastHit
	elseif MMA then
		return _G.MMA_IsLasthitting()
	end
end

--variables/menu/drawings

function menu()
 -- menu
	config = scriptConfig("NeXtGen Jinx", "Jinx")
	config:addSubMenu("Draw", "draw")
	config.draw:addParam("notification", "Show text and lines", SCRIPT_PARAM_ONOFF, true)
	config.draw:addParam("onlyRdy", "Draw spells range only if ready", SCRIPT_PARAM_ONOFF, true)
	config.draw:addParam("qRange", "Draw Q range circle", SCRIPT_PARAM_ONOFF, false)
	config.draw:addParam("wRange", "Draw W range circle", SCRIPT_PARAM_ONOFF, false)
	config.draw:addParam("eRange", "Draw E range circle", SCRIPT_PARAM_ONOFF, false)
	config.draw:addParam("rRange", "Draw R range circle", SCRIPT_PARAM_ONOFF, false)
	config:addSubMenu("Config W", "wconfig")
	config.wconfig:addParam("autoW", "Auto W", SCRIPT_PARAM_ONOFF, true)
	config.wconfig:addParam("ksW", "Kill steal with W", SCRIPT_PARAM_ONOFF, true)
	for _, enemy in pairs(enemies) do
		config.wconfig:addParam("haras"..enemy.charName, "Harass"..enemy.charName, SCRIPT_PARAM_ONOFF, true)
	end
	config:addSubMenu("Config E", "econfig")
	config.econfig:addParam("autoE", "Auto E", SCRIPT_PARAM_ONOFF, true)
	config.econfig:addParam("comboE", "Auto E in Combo", SCRIPT_PARAM_ONOFF, true)
	config.econfig:addParam("AGC", "Use E on gapclosers", SCRIPT_PARAM_ONOFF, true)
	config.econfig:addParam("opsE", "Interrupt important spells with E", SCRIPT_PARAM_ONOFF, true)
	config.econfig:addParam("telE", "Auto E on teleport casts", SCRIPT_PARAM_ONOFF, true)
	config:addSubMenu("Config R", "rconfig")
	config.rconfig:addParam("autoR", "Auto R", SCRIPT_PARAM_ONOFF, true)
	config.rconfig:addParam("manualR", "Key to manually cast R", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
	config.rconfig:addSubMenu("R jungle stealer", "rconfigjungle")
	config.rconfig.rconfigjungle:addParam("Rjungle", "R jungle stealer", SCRIPT_PARAM_ONOFF, true)
	config.rconfig.rconfigjungle:addParam("Rdragon", "Try to steal Dragon", SCRIPT_PARAM_ONOFF, true)
	config.rconfig.rconfigjungle:addParam("Rbaron", "Try to steal Baron", SCRIPT_PARAM_ONOFF, true)
	config:addParam("farmQ", "Farm with Q", SCRIPT_PARAM_ONOFF, true)
	if SX then
		config:addSubMenu("SxOrbWalker", "orbwalker")
		SxOrb:LoadToMenu(config.orbwalker)
	end
	config:addTS(ts)
	ts.name = "TargetSelector"
end

function loadOrbwalker()
	if _G.Reborn_Initialised then
		SAC = true
	elseif _G.Reborn_Loaded and not _G.Reborn_Initialised then
		DelayAction(function() loadOrbwalker() end, 1)
	elseif _G.MMA_Loaded ~= nil and _G.MMA_Loaded then
		MMA = true
	else
		SX = true
		if FileExist(LIB_PATH .. "/SxOrbWalk.lua") then
			require 'SxOrbWalk'
		end
	end
	if not SAC and not SX and not MMA then
		print ("This script requires SAC:R or SxOrb or MMA to work!")
	end
end

function variables()
	--variables
	ts = TargetSelector(TARGET_LOW_HP,1000)
	VP = VPrediction()
	enemies = GetEnemyHeroes()
	minions = minionManager(MINION_ENEMY, bonusRange() + 30, myHero, MINION_SORT_MAXHEALTH_ASC)
	jungleMinions = minionManager(MINION_JUNGLE, math.huge, myHero, MINION_SORT_MAXHEALTH_DES)
	if SX then SxOrb:RegisterBeforeAttackCallback(QBefore) end
	if MMA then _G.MMA_RegisterCallback('BeforeAttackCallbacks', QBefore) end
	if SAC then _G.AutoCarry.Plugins:RegisterPreAttack(QBefore) end
	if SX then
		PrintChat ("<font color='#0084FF'>NeXtGen J</font><font color='#FFFFFF'>inx Loaded with SxOrbWalker!</font>")
	elseif SAC then
		PrintChat ("<font color='#0084FF'>NeXtGen J</font><font color='#FFFFFF'>inx Loaded with SAC:Reborn!</font>")
	elseif MMA then
		PrintChat ("<font color='#0084FF'>NeXtGen J</font><font color='#FFFFFF'>inx Loaded with MMA!</font>")
	end
end

function OnDraw()
	--draw
	if config.draw.qRange then
		if not fishBoneActive then
			DrawCircle3D(myHero.x, myHero.y, myHero.z, 590 + myHero.boundingRadius, 1, RGB(255,20,147))
		else
			DrawCircle3D(myHero.x, myHero.y, myHero.z, bonusRange() - 40, 1, RGB(255, 20, 147))
		end
	end
	if config.draw.wRange then
		if config.draw.onlyRdy then
			if Spells.W.ready then
				DrawCircle3D(myHero.x, myHero.y, myHero.z, Spells.W.range, 1, RGB(0,255,255))
			end
		else
			DrawCircle3D(myHero.x, myHero.y, myHero.z, Spells.W.range, 1, RGB(0,255,255))
		end
	end
	if config.draw.eRange then
		if config.draw.onlyRdy then
			if Spells.E.ready then
				DrawCircle3D(myHero.x, myHero.y, myHero.z, Spells.E.range, 1, RGB(0,255,255))
			end
		else
			DrawCircle3D(myHero.x, myHero.y, myHero.z, Spells.E.range, 1, RGB(0,255,255))
		end
	end
	if config.draw.RRange then
		if config.draw.onlyRdy then
			if Spells.R.ready then
				DrawCircle3D(myHero.x, myHero.y, myHero.z, Spells.R.range, 1, RGB(0,255,255))
			end
		else
			DrawCircle3D(myHero.x, myHero.y, myHero.z, Spells.R.range, 1, RGB(0,255,255))
		end
	end
	if config.draw.notification then
		local target = targetSelector(Spells.R.range, DAMAGE_PHYSICAL)
		if ValidTarget(target) and Spells.R.ready and getDmg("R", target, myHero) > (target.health + target.hpRegen) then
			DrawText3D("Can kill "..target.charName.." with R", myHero.x-190, myHero.y-150, myHero.z, 32, RGB(255,0,0), center)
			DrawLine3D(myHero.x, myHero.y, myHero.z, target.x, target.y, target.z, 3, RGB(255,0,0))
		elseif ValidTarget(target, 2000) and Spells.W.ready and getDmg("W", target, myHero) > (target.health + target.hpRegen) then
			DrawText3D("Can kill "..target.charName.." with W", myHero.x-190, myHero.y-150, myHero.z, 32, RGB(255,0,0), center)
			DrawLine3D(myHero.x, myHero.y, myHero.z, target.x, target.y, target.z, 3, RGB(255,0,0))
		end
	end
end