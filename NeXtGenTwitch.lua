if myHero.charName ~= "Twitch" then return end

require 'VPrediction'

--local variables
local enemies = {}
local jungleMinions = {}
local tickCount = 0
local PassiveStacks = {}
local PassiveApply = {}
local SAC = false
local SX = false
local MMA = false
local windUpTime = 0
local startAttackTime = 0
local spells = 
{
	Q = { ready = false, range = 0 },
	W = { ready = false, range = 950 , delay = 0.25, width = 100, speed = 1410},
	E = { ready = false, range = 1200 },
	R = { ready = false, range = 975 }
}

--hooks

function OnLoad()
	loadOrbwalker()
	variables()
	menu()
end

function OnTick()
	if checkTick(0) then
		checks()
		if GetSlotItem(3153) ~= nil and myHero:CanUseSpell(GetSlotItem(3153)) == READY then
			local target = targetSelector(550, DAMAGE_PHYSICAL)
				if ValidTarget(target, 550) then
					if myHero.health < myHero.maxHealth * (config.botrkP/100) then
						CastSpell(GetSlotItem(3153), target)
					elseif target.health < myHero:CalcDamage(target, 0.10 * target.maxHealth) then
						CastSpell(GetSlotItem(3153), target)
					end
				end
		end
	end
	if checkTick(1) and spells.E.ready then
		ELogic()
	end
	if checkTick(2) and spells.Q.ready and not isWindingUp() then
		QLogic()
	end
	if checkTick(3) and spells.W.ready and config.wconfig.autoW and not isWindingUp() then
		WLogic()
	end
	if checkTick(4) and spells.R.ready and isCombo() then
		RLogic()
	end
end

function OnProcessAttack(unit, spell)
	if unit.isMe then
		startAttackTime = GetInGameTimer()
		windUpTime = spell.windUpTime
	end
end

function OnProcessSpell(unit, spell)
	if unit.isAI or (not spells.E.ready and unit.team == player.team and not ValidTarget(unit)) then
		return
	end
	local spelltype, casttype = getSpellType(unit, spell.name)
	if spell.target ~= nil and spell.target.networkID == myHero.networkID and unit.isMe ~= true then
		local dmg = getDmg(spelltype, spell.target, unit)
		if myHero.health - dmg < CountEnemyHeroInRange(600) * myHero.level * 10 then
			CastSpell(_E)
		end
	end
end

--[[spells logic]]--

function QLogic()
	if config.qconfig.autoQ and isCombo() and ValidTarget(getTarget()) and myHero.mana > (spells.R.mana + spells.Q.mana) then
		CastSpell(_Q)
	end
	if config.qconfig.countQ == 0 or myHero.mana < (spells.R.mana + spells.Q.mana) then
		return
	end
	local countEnemies = 0
	for _, enemy in ipairs(enemies) do
		if ValidTarget(enemy, 3000) then
			local TargetPosition = VP:GetPredictedPos(enemy, 1, 1750, myHero, false)
			if GetDistance(TargetPosition) < 600 then
				countEnemies = countEnemies + 1
			end
		end
	end
	if countEnemies >= config.qconfig.countQ then
		CastSpell(_Q)
	end
end
		
function WLogic()
	local target = targetSelector(spells.W.range, DAMAGE_PHYSICAL)
	if ValidTarget(target) then
		local CastPosition, HitChance, Position = VP:GetCircularCastPosition(target, spells.W.delay, spells.W.width, spells.W.range, spells.W.speed, myHero, false)
		if HitChance < 2 and HitChance > 5 then return end
		if isCombo() and myHero.mana > (spells.W.mana + spells.R.mana + spells.E.mana) and (myHero:CalcDamage(target, myHero.totalDamage) * 2 < target.health or not isInAutoAttackRange(target)) then
			CastSpell(_W, CastPosition.x, CastPosition.z)
		elseif isHarass() and config.wconfig.autoWinH and myHero.mana > (spells.W.mana + spells.R.mana + spells.E.mana) and CountEnemyHeroInRange(CastPosition) > 1 then
			CastSpell(_W, CastPosition.x, CastPosition.z)
		elseif (isCombo() or (isHarass() or isLaneClear())) and myHero.mana > (spells.W.mana + spells.R.mana + spells.E.mana) then
			for _, enemy in ipairs(enemies) do
				if ValidTarget(enemy, spells.W.range) and enemy.canMove ~= false then
					CastSpell(_W, CastPosition.x, CastPosition.z)
				end
			end
		end
	end
end

function ELogic()
	for _, enemy in ipairs(enemies) do
		if ValidTarget(enemy, spells.E.range) and TargetHaveBuff("twitchdeadlyvenom", enemy) then
			if config.econfig.ksE and calculateEDmg(enemy) > enemy.health then
				CastSpell(_E)
			end
			if myHero.mana > (spells.R.mana + spells.E.mana) then
				if config.econfig.maxE and PassiveStacks[enemy.networkID] == 6 then
					CastSpell(_E)
				end
				if not isInAutoAttackRange(enemy) and config.econfig.countE ~= 0 and config.econfig.countE <= PassiveStacks[enemy.networkID] then
					CastSpell(_E)
				end
			end
		end
	end
	if config.econfig.jungleE and myHero.mana > (spells.R.mana + spells.E.mana) then
		if jungleMinions.iCount > 0 then
			if jungleMinions.objects[1].health < calculateEDmg(jungleMinions.objects[1]) then
				CastSpell(_E)
			end
		end
	end
end

function RLogic()
	local target = targetSelector(spells.R.range, DAMAGE_PHYSICAL)
	if ValidTarget(target) then
		if not isInAutoAttackRange(target) and config.rconfig.ksR and myHero:CalcDamage(target, myHero.totalDamage) * 4 > target.health then
			CastSpell(_R)
		end
		if CountEnemyHeroInRange(450) >= config.rconfig.countR and config.rconfig.countR ~= 0 then
			CastSpell(_R)
		end
	end
end

--[[calculations]]--

function checks()
	spells.Q.ready, spells.W.ready, spells.E.ready, spells.R.ready = (myHero:CanUseSpell(_Q) == READY), (myHero:CanUseSpell(_W) == READY), (myHero:CanUseSpell(_E) == READY), (myHero:CanUseSpell(_R) == READY)
	
	spells.Q.mana, spells.W.mana, spells.E.mana = 40, 50, (40 + myHero:GetSpellData(_E).level * 10)
	
	jungleMinions:update()	
	
	if not spells.R.ready then
		spells.R.mana = spells.E.mana - myHero.mpRegen * myHero:GetSpellData(_E).currentCd
	else
		spells.R.mana = (75 + myHero:GetSpellData(_R).level * 25)
	end
	
	if myHero.health < myHero.maxHealth * 0.2 then
		spells.Q.mana, spells.W.mana, spells.E.mana, spells.R.ready = 0, 0, 0, 0
	end
end

function calculateEDmg(tar)
	local dmg = getDmg("E", tar, myHero)
	dmg = dmg + (10 + (myHero:GetSpellData(_E).level * 5))
	dmg = dmg + (myHero.addDamage * 0.25) + (myHero.ap * 0.2)
	if PassiveStacks[tar.networkID] ~= nil and PassiveStacks[tar.networkID] > 0  then
		dmg = dmg * PassiveStacks[tar.networkID]
	end
	if tar.isAI ~= true then
		dmg = dmg - tar.hpRegen
	else
		return dmg - 80
	end
	return myHero:CalcDamage(tar, dmg)
end

function isWindingUp()
	if windUpTime > GetInGameTimer() - startAttackTime then
		return true
	end
	return false
end

function calculatePassiveDmg(tar)
	if not TargetHaveBuff("twitchdeadlyvenom", tar) then return end
	local dmgPerSec = 6
	if myHero.level < 17 then dmgPerSec = 5 end
	if myHero.level < 13 then dmgPerSec = 4 end
	if myHero.level < 9 then dmgPerSec = 3 end
	if myHero.level < 5 then dmgPerSec = 2 end
	local passiveTime = getPassiveTime(tar, 'twitchdeadlyvenom')
	return (dmgPerSec * PassiveStacks[tar.networkID] * passiveTime) - tar.hpRegen * passiveTime
end

function getPassiveTime(tar, buffName)
	local timer = PassiveApply[tar.networkID] - GetGameTimer()
	if timer > 0 then
		return PassiveApply[tar.networkID] - GetGameTimer()
	else
		return 0
	end
end

function GetSlotItem(id, unit)
	unit = unit or myHero

	if (not ItemNames[id]) then
		return ___GetInventorySlotItem(id, unit)
	end

	local name  = ItemNames[id]
  
	for slot = ITEM_1, ITEM_7 do
		local item = unit:GetSpellData(slot).name
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
	if buff.name == 'twitchdeadlyvenom' then
		--PassiveStacks[unit.networkID] = stacks
		if PassiveStacks[unit.networkID] and PassiveStacks[unit.networkID] < 6 then
			PassiveStacks[unit.networkID] = PassiveStacks[unit.networkID] + 1
		end
		PassiveApply[unit.networkID] = GetGameTimer() + 6
	end
end

function OnRemoveBuff(unit,buff)
	if buff.name == 'twitchdeadlyvenom' then
		PassiveStacks[unit.networkID] = 0
		PassiveApply[unit.networkID] = 0
	end
end

function getStacks(tar)
	return PassiveStacks[tar.networkID]
end

function getTarget()
	if SX then
		return SxOrb:GetTarget()
	elseif SAC then
		return _G.AutoCarry.Crosshair:GetTarget()
	elseif MMA then
		return _G.MMA_Target()
	end
end

function isInAutoAttackRange(tar)
	return (myHero.range + myHero.boundingRadius + tar.boundingRadius > GetDistance(tar))
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

function debugMsg(msg)
	PrintChat(tostring(msg))
end

--[[variables/menus/drawings]]--

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

function loadItems()
		ItemNames = {
	[3153]        = "ItemSwordOfFeastAndFamine"}
	
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
	jungleMinions = minionManager(MINION_JUNGLE, spells.E.range, myHero, MINION_SORT_MAXHEALTH_DEC)
	for _, enemy in ipairs(enemies) do
		PassiveStacks[enemy.networkID] = 0
		PassiveApply[enemy.networkID] = 0
	end
	if SX then
		PrintChat ("<font color='#0084FF'>NeXtGen T</font><font color='#FFFFFF'>witch Loaded with SxOrbWalker!</font>")
	elseif SAC then
		PrintChat ("<font color='#0084FF'>NeXtGen T</font><font color='#FFFFFF'>witch Loaded with SAC:Reborn!</font>")
	elseif MMA then
		PrintChat ("<font color='#0084FF'>NeXtGen T</font><font color='#FFFFFF'>witch Loaded with MMA!</font>")
	end
end

function menu()
	config = scriptConfig("NeXtGen Twitch", "Twitch")
	config:addSubMenu("Draw", "draw")
	config.draw:addParam("notification", "Show notifications", SCRIPT_PARAM_ONOFF, true)
	config.draw:addParam("onlyRdy", "Draw spells range only if ready", SCRIPT_PARAM_ONOFF, true)
	config.draw:addParam("wRange", "Draw W range circle", SCRIPT_PARAM_ONOFF, false)
	config.draw:addParam("eRange", "Draw E range circle", SCRIPT_PARAM_ONOFF, false)
	config.draw:addParam("rRange", "Draw R range circle", SCRIPT_PARAM_ONOFF, false)
	config:addParam("botrkP", "Botrk hp %", SCRIPT_PARAM_SLICE, 60, 0, 100, 0)
	config:addSubMenu("Config Q", "qconfig")
	config.qconfig:addParam("autoQ", "Auto Q in combo", SCRIPT_PARAM_ONOFF, true)
	config.qconfig:addParam("countQ", "Auto Q when X enemies coming", SCRIPT_PARAM_SLICE, 3, 0, 5, 0)
	config:addSubMenu("Config W", "wconfig")
	config.wconfig:addParam("autoW", "Auto W", SCRIPT_PARAM_ONOFF, true)
	config.wconfig:addParam("autoWinH", "Auto W in harass", SCRIPT_PARAM_ONOFF, true)
	config:addSubMenu("Config E", "econfig")
	config.econfig:addParam("ksE", "Killsteal with E", SCRIPT_PARAM_ONOFF, true)
	config.econfig:addParam("countE", "Auto E when X stacks", SCRIPT_PARAM_SLICE, 6, 0, 6, 0)
	config.econfig:addParam("maxE", "Always use E on 6 stacks", SCRIPT_PARAM_ONOFF, true)
	config.econfig:addParam("jungleE", "Steal monsters in jungle with E", SCRIPT_PARAM_ONOFF, true)
	config:addSubMenu("Config R", "rconfig")
	config.rconfig:addParam("ksR", "Try to KS with R", SCRIPT_PARAM_ONOFF, true)
	config.rconfig:addParam("countR", "Use R when X enemies around", SCRIPT_PARAM_SLICE, 3, 0, 5, 0)
	if SX then
		config:addSubMenu("SxOrbWalker", "orbwalker")
		SxOrb:LoadToMenu(config.orbwalker)
	end
	config:addTS(ts)
	ts.name = "TargetSelector"
end

function OnDraw()
	if config.draw.wRange then
		if config.draw.onlyRdy then
			if spells.W.ready then
				DrawCircle3D(myHero.x, myHero.y, myHero.z, spells.W.range, 1, RGB(0, 255, 0))
			end
		else
			DrawCircle3D(myHero.x, myHero.y, myHero.z, spells.W.range, 1, RGB(0, 255, 0))
		end
	end
	if config.draw.eRange then
		if config.draw.onlyRdy then
			if spells.E.ready then
				DrawCircle3D(myHero.x, myHero.y, myHero.z, spells.E.range, 1, RGB(0,255,255))
			end
		else
			DrawCircle3D(myHero.x, myHero.y, myHero.z, spells.E.range, 1, RGB(0,255,255))
		end
	end
	if config.draw.rRange then
		if config.draw.onlyRdy then
			if spells.R.ready then
				DrawCircle3D(myHero.x, myHero.y, myHero.z, spells.R.range, 1, RGB(255,255,0))
			end
		else
			DrawCircle3D(myHero.x, myHero.y, myHero.z, spells.R.range, 1, RGB(255,255,0))
		end
	end
	for _, enemy in ipairs(enemies) do
		if ValidTarget(enemy, 2000) and TargetHaveBuff("twitchdeadlyvenom", enemy) then
			if calculatePassiveDmg(enemy) > enemy.health then
				DrawText3D("Dead from POISON", enemy.x-190, enemy.y-150, enemy.z, 32, RGB(0,255,0), center)
			end
		end
	end
	if config.draw.notification then
		if TargetHaveBuff("TwitchHideInShadows", myHero) then
			DrawText3D("Q STEALTH", myHero.x-130, myHero.y-150, myHero.z, 32, RGB(0,255,0), center)
		end
		if TargetHaveBuff("twitchhideinshadowsbuff", myHero) then
			DrawText3D("Q BUFF", myHero.x-110, myHero.y-250, myHero.z, 32, RGB(0,255,0), center)
		end
		if TargetHaveBuff("TwitchFullAutomatic", myHero) then
			DrawText3D("R ACTIVE", myHero.x-130, myHero.y-350, myHero.z, 32, RGB(255,0,0), center)
		end
	end
end