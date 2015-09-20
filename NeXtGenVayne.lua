if myHero.charName ~= "Vayne" then return end

require 'VPrediction'

--local variables
local enemies = {}
local minions = {}
local jungleMinions = {}
local tickCount = 0
local Wstacks = {}
local SAC = false
local SX = false
local windUpTime = 0
local startAttackTime = 0
local spells = 
{
	Q = { ready = false, range = 300 },
	E = { ready = false, range = 670, delay = 0.27, speed = 3500},
	R = { ready = false, range = 3000}
}

--hooks

function OnLoad()
	loadOrbwalker()
	variables()
	menu()
end

function OnTick()
	checks()
	local dashPosition = extend(mousePos, myHero.pos, spells.Q.range)
	beforeAttack()
	if SAC and isAfterAttack() then
		afterAttack()
	end
	if spells.E.ready then
		for _, target in ipairs(enemies) do
			if ValidTarget(target, spells.E.range) and config.econfig["useE"..target.charName] then
				if CondemnCheck(myHero.pos, target) then
					CastSpell(_E, target)
				elseif spells.Q.ready and DashCheck(dashPosition) and config.qconfig.QE and CondemnCheck(D3DXVECTOR3(dashPosition.x, dashPosition.y, dashPosition.z), target) then
					CastSpell(_Q, dashPosition.x, dashPosition.z)
				end
			end
		end
	end
	if checkTick(0) then
		if isCombo() and getBotrkSlot() ~= nil and myHero:CanUseSpell(getBotrkSlot()) == READY then
			local target = targetSelector(550, DAMAGE_PHYSICAL)
			if ValidTarget(target) then
				if myHero.health < myHero.maxHealth * 0.5 then
					CastSpell(getBotrkSlot(), target)
				elseif target.health < myHero:CalcDamage(target, 0.10 * target.maxHealth) then
					CastSpell(getBotrkSlot(), target)
				end
			end
		end
	end
	if checkTick(1) and spells.Q.ready then
		if config.rconfig.autoQR and TargetHaveBuff("vayneinquisition", myHero) then
			CastSpell(_Q, dashPosition.x, dashPosition.z)
		end
		if isCombo() and DashCheck(dashPosition) and not config.qconfig.QafteraA then
			local target = targetSelector(900, DAMAGE_PHYSICAL)
			if ValidTarget(target) and not isInAutoAttackRange(target) and GetDistance(target, mousePos) < GetDistance(target) and CountEnemyHeroInRange(800, dashPosition) < 3 and not isFacing(target) then
				CastSpell(_Q, dashPosition.x, dashPosition.z)
			end
		end
	end
	if checkTick(2) then
		local bestTarget = nil
		for _, target in ipairs(enemies) do
			if ValidTarget(target, spells.E.range) then
				if ValidTarget(target, 270) and target.range <= 200 then
					if spells.Q.ready and DashCheck(dashPosition) then
						CastSpell(_Q, dashPosition.x, dashPosition.z)
					elseif spells.E.ready and myHero.health < myHero.maxHealth * 0.5 then
						CastSpell(_E, target)
					end
				end
				if bestTarget == nil then
					bestTarget = target
				elseif GetDistance(target) < GetDistance(bestTarget) then
					bestTarget = target
				end
			end
		end
		if config.econfig.manualE and bestTarget ~= nil then
			CastSpell(_E, bestTarget)
		end
	end
	if checkTick(3) and spells.R.ready then
		if CountEnemyHeroInRange(700) > 2 then
			CastSpell(_R)
		elseif isCombo() and CountEnemyHeroInRange(600) > 1 then
			CastSpell(_R)
		elseif myHero.health < myHero.maxHealth * 0.5 and CountEnemyHeroInRange(500) > 0 then
			CastSpell(_R)
		end
	end
	if checkTick(4) then
		for _, target in ipairs(enemies) do
			if ValidTarget(target) and config.gapclosers["gap"..target.charName] then
				local TargetDashing, CanHit, TargetDashPosition = VP:IsDashing(target, spells.E.delay, 1, spells.E.speed, myHero)
				if TargetDashing and GetDistance(TargetDashPosition) < 200 then
					if spells.E.ready and config.gapclosers.gapE then
						CastSpell(_E, target)
					elseif (not spells.E.ready or not config.gapclosers.gapE) and spells.Q.ready and config.gapclosers.gapQ then
						CastSpell(_Q, dashPosition.x, dashPosition.z)
					end
				end
			end
		end
	end
end

function OnProcessAttack(unit, spell)
	if unit.isMe then
		startAttackTime = GetInGameTimer()
		windUpTime = spell.windUpTime
	end
end

function disableAttacks()
	if SX then
		SxOrb:DisableAttacks()
	elseif SAC then
		_G.AutoCarry.MyHero:AttacksEnabled(false)
	end
end

function enableAttacks()
	if SX then
		SxOrb:EnableAttacks()
	elseif SAC then
		_G.AutoCarry.MyHero:AttacksEnabled(true)
	end
end

function getTarget()
	if SX then
		return SxOrb:GetTarget()
	elseif SAC then
		return _G.AutoCarry.Crosshair:GetTarget()
	end
end

function forceTarget(tar)
	if SX then
		SxOrb:ForceTarget(tar)
	elseif SAC then
		_G.AutoCarry.Crosshair.Attack_Crosshair.target = tar
	end
end

function beforeAttack()
	if config.rconfig.blockR and TargetHaveBuff("vaynetumblefade", myHero) and CountEnemyHeroInRange(800) > 1 then
		disableAttacks()
	else
		enableAttacks()
	end
	for _, target in ipairs(enemies) do
		if ValidTarget(target, 800) and getStacks(target) > 0 then
			if isInAutoAttackRange(target) and target.health > 3 * myHero:CalcDamage(target, myHero.totalDamage) then
				forceTarget(target)
			end
		end
	end
end

function afterAttack()
	local dashPosition = extend(mousePos, myHero.pos, spells.Q.range)
	if not DashCheck(dashPosition) then return false end
	local target = getTarget()
	if spells.Q.ready and ValidTarget(target) and getStacks(target) > 0 and GetDistance(target, mousePos) < GetDistance(target) and CountEnemyHeroInRange(800, dashPosition) < 3 then
		CastSpell(_Q, dashPosition.x, dashPosition.z)
	elseif spells.Q.ready and (isHarass() or isLaneClear()) and config.qconfig.farmQ then
		minions:update()
		if minions.iCount == 0 then return end
		local count = 0
		for _, minion in ipairs(minions.objects) do
			if minion.health < myHero:CalcDamage(minion, myHero.totalDamage) + getDmg("Q", minion, myHero) then
				count = count + 1
			end
		end
		if count > 1 then
			CastSpell(_Q, dashPosition.x, dashPosition.z)
		end
	end
end

--[[calculations]]--

function checks()
	spells.Q.ready, spells.E.ready, spells.R.ready = (myHero:CanUseSpell(_Q) == READY), (myHero:CanUseSpell(_E) == READY), (myHero:CanUseSpell(_R) == READY)
end

function isAfterAttack()
	if not isWindingUp() and windUpTime+0.05 > GetInGameTimer() - startAttackTime then
		return true
	end
	return false
end

function getBotrkSlot()
	local name	= "itemswordoffeastandfamine"

	for slot = ITEM_1, ITEM_7 do
		local item = myHero:GetSpellData(slot).name
		if ((#item > 0) and (item:lower() == name:lower())) then
			return slot
		end
	end
end

function isFacing(tar)
	local TargetCastPosition = VP:GetPredictedPos(tar, 1, 1750, myHero, false)
	if GetDistance(myHero, TargetCastPosition) > GetDistance(myHero, tar) then
		return false
	end
	return true
end

function OnUpdateBuff(unit, buff, stacks)
	if buff.name == 'vaynesilvereddebuff' and unit.isAI ~= true then
		Wstacks[unit.networkID] = stacks
	end
end

function OnRemoveBuff(unit,buff)
	if buff.name == 'vaynesilvereddebuff' and unit.isAI ~= true then
		Wstacks[unit.networkID] = 0
	end
end

function getStacks(tar)
	return Wstacks[tar.networkID]
end

function isInAutoAttackRange(tar)
	return (myHero.range + myHero.boundingRadius + tar.boundingRadius > GetDistance(tar))
end

function DashCheck(dashPos)
	for i=0, 300, 100 do
		local ext = extend(myHero.pos, dashPos, spells.Q.range-i)
		if IsWall(D3DXVECTOR3(ext.x, ext.y, ext.z)) then
			return false
		end
	end
	return true
end

function CondemnCheck(from, target)
	local CastPosition, HitChance, Position = VP:GetLineCastPosition(target, 0.30, 1, spells.E.range, math.huge, myHero, false)
	if HitChance < 2 or HitChance > 5 then
			return false
	end
	local pushDistance = 0
	if myHero.pos == from then
		pushDistance = 490
	else
		pushDistance = 400
	end
	
	local finalPos2 = extend(from, CastPosition, -250)
	if IsWall(D3DXVECTOR3(finalPos2.x, finalPos2.y, finalPos2.z)) then
		return true
	end
	local finalPos = extend(from, CastPosition, -pushDistance)
	local points = CirclePoint(10, 90, finalPos)
	
	local cast = true
	for _, point in ipairs(points) do
		if not IsWall(D3DXVECTOR3(point.x, point.y, point.z)) then
			cast = false
		end
	end
	return cast
end

function CirclePoint(pointsAround, radius, position)
	local points = {}
	for i=1, pointsAround, 1 do
		local angle = i * 2 * math.pi / pointsAround
		local point = Vector(position.x + radius * math.cos(angle), position.y, position.z + radius * math.sin(angle))
		table.insert(points, point)
	end
	return points
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

function targetSelector(range, dmgType)
	local tarsel = TargetSelector(ts.mode, range, dmgType)
	tarsel:update()
	return tarsel.target
end

function extend(from, to, distance)
	local extendPos = Vector(to) + Vector(Vector(to) - Vector(from)):normalized()*(-distance)
	return extendPos
end

function isCombo()
	if SX then
		return SxOrb.isFight
	elseif SAC then
		return _G.AutoCarry.Keys.AutoCarry
	end
end

function isHarass()
	if SX then
		return SxOrb.isHarass
	elseif SAC then
		return _G.AutoCarry.Keys.MixedMode
	end
end

function isLaneClear()
	if SX then
		return SxOrb.isLaneClear
	elseif SAC then
		return _G.AutoCarry.Keys.LaneClear
	end
end

function isLastHit()
	if SX then
		return SxOrb.isLastHit
	elseif SAC then
		return _G.AutoCarry.Keys.LastHit
	end
end

function debugMsg(msg)
	PrintChat(tostring(msg))
end

--[[variables/menus/drawings]]--

function loadOrbwalker()
	if _G.Reborn_Loaded ~= nil then
		SAC = true
	else
		SX = true
		require 'SxOrbWalk'
	end
	if not SAC and not SX then
		print ("This script requires SAC:R or SxOrb to work!")
	end
end

function loadItems()
	_G.ITEM_1				= 06
	_G.ITEM_2				= 07
	_G.ITEM_3				= 08
	_G.ITEM_4				= 09
	_G.ITEM_5				= 10
	_G.ITEM_6				= 11
	_G.ITEM_7				= 12

	___GetInventorySlotItem	= rawget(_G, "GetInventorySlotItem")
	_G.GetInventorySlotItem	= GetSlotItem
end

function variables()
	loadItems()
	ts = TargetSelector(TARGET_LOW_HP,1000)
	VP = VPrediction()
	enemies = GetEnemyHeroes()
	minions = minionManager(MINION_ENEMY, myHero.range, myHero, MINION_SORT_MAXHEALTH_ASC)
	jungleMinions = minionManager(MINION_JUNGLE, math.huge, myHero, MINION_SORT_MAXHEALTH_DES)
	for _, enemy in ipairs(enemies) do
		Wstacks[enemy.networkID] = 0
	end
	if SX then 
		--SxOrb:RegisterBeforeAttackCallback(beforeAttack)
		SxOrb:RegisterAfterAttackCallback(afterAttack)
	end
	if SX then
		PrintChat ("<font color='#0084FF'>NeXtGen V</font><font color='#FFFFFF'>ayne Loaded with SxOrbWalker!</font>")
	elseif SAC then
		PrintChat ("<font color='#0084FF'>NeXtGen V</font><font color='#FFFFFF'>ayne Loaded with SAC:Reborn!</font>")
	end
end

function menu()
	config = scriptConfig("NeXtGen Vayne", "Vayne")
	config:addSubMenu("Draw", "draw")
	config.draw:addParam("onlyRdy", "Draw spells range only if ready", SCRIPT_PARAM_ONOFF, true)
	config.draw:addParam("qRange", "Draw Q range circle", SCRIPT_PARAM_ONOFF, true)
	config.draw:addParam("ePush", "Draw E push position", SCRIPT_PARAM_ONOFF, true)
	config:addSubMenu("Config Q", "qconfig")
	config.qconfig:addParam("farmQ", "Farm with Q help", SCRIPT_PARAM_ONOFF, true)
	config.qconfig:addParam("QE", "Use Q+E combo", SCRIPT_PARAM_ONOFF, true)
	config.qconfig:addParam("QafterAA", "Use Q after AA", SCRIPT_PARAM_ONOFF, true)
	config:addSubMenu("Gapclosers", "gapclosers")
	config.gapclosers:addParam("gapQ", "Dodge gapclosers with Q", SCRIPT_PARAM_ONOFF, true)
	config.gapclosers:addParam("gapE", "Dodge gapclosers with E", SCRIPT_PARAM_ONOFF, true)
	for _, enemy in ipairs(enemies) do
		config.gapclosers:addParam("gap"..enemy.charName, "Use on "..enemy.charName, SCRIPT_PARAM_ONOFF, true)
	end
	config:addSubMenu("Config E", "econfig")
	for _, enemy in ipairs(enemies) do
		config.econfig:addParam("useE"..enemy.charName, "Use E on "..enemy.charName, SCRIPT_PARAM_ONOFF, true)
	end
	config.econfig:addParam("manualE", "Key to manually cast E", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
	config:addSubMenu("Config R", "rconfig")
	config.rconfig:addParam("autoR", "Auto R", SCRIPT_PARAM_ONOFF, true)
	config.rconfig:addParam("blockR", "Block AA with R", SCRIPT_PARAM_ONOFF, true)
	config.rconfig:addParam("autoQR", "Auto Q when R is active", SCRIPT_PARAM_ONOFF, true)
	config:addTS(ts)
	ts.name = "TargetSelector"
end

function OnDraw()
	if config.draw.qRange then
		if config.draw.onlyRdy then
			if spells.Q.ready then
				DrawCircle3D(myHero.x, myHero.y, myHero.z, spells.Q.range, 1, RGB(0,255,255))
			end
		else
			DrawCircle3D(myHero.x, myHero.y, myHero.z, spells.Q.range, 1, RGB(0,255,255))
		end
	end
	if spells.E.ready and config.draw.ePush then
		for _, target in ipairs(enemies) do
			if ValidTarget(target, 800) then
				local ext = extend(myHero.pos, target.pos, -460)
				if IsWall(D3DXVECTOR3(ext.x, ext.y, ext.z)) then
					DrawCircle3D(ext.x, ext.y, ext.z, 80, 1, RGB(255,0,0))
				else
					DrawCircle3D(ext.x, ext.y, ext.z, 80, 1, RGB(154, 205, 50))
				end
			end
		end
	end
end