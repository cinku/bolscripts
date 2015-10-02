require 'VPrediction'

local startAttackTime = 0
local windUpTime = 0

local items = {
	[3222] = { name = "ItemMorellosBane", range = 600 },
	[3140] = { name = "QuicksilverSash", range = 0 },
	[3139] = { name = "ItemMercurial", range = 0 },
	[3137] = { name = "ItemDervishBlade", range = 0 },
	[3153] = { name = "ItemSwordOfFeastAndFamine", range = 550 },
	[3144] = { name = "BilgewaterCutlass", range = 550 },
	[3142] = { name = "YoumusBlade", range = 650 },
	[3074] = { name = "ItemTiamatCleave", range = 440 },
	[3077] = { name = "ItemTiamatCleave", range = 440 },
	[3748] = { name = "", range = 150 },
	[3146] = { name = "HextechGunblade", range = 700 },
	[3092] = { name = "ItemGlacialSpikeCast", range = 850 },
	[3042] = { name = "Muramana", range = 0 },
	[3004] = { name = "Manamune", range = 0 },
	[3401] = { name = "HealthBomb", range = 600 },
	[3157] = { name = "ZhonyasHourglass", range = 0 },
	[3040] = { name = "ItemSeraphsEmbrace", range = 0 },
	[3190] = { name = "IronStylus", range = 600 },
	[3143] = { name = "RanduinsOmen", range = 500 },
	[2003] = { name = "RegenerationPotion", range = 0 },
	[2004] = { name = "FlaskOfCrystalWater", range = 0 },
	[2041] = { name = "ItemCrystalFlask", range = 0 },
	[2010] = { name = "ItemMiniRegenPotion", range = 0 }
}

local summonerSpells = {
	flash = nil,
	heal = nil,
	barrier = nil,
	ignite = nil,
	exhaust = nil,
}

function OnLoad()
	loadItemSlots()
	loadSummonerSpells()
	ts = TargetSelector(TARGET_LOW_HP, 1000)
	enemies = GetEnemyHeroes()
	allies = GetAllyHeroes()
	table.insert(allies, myHero)
	VP = VPrediction()
	menu()
	PrintChat ("<font color='#0084FF'>NeXtGen A</font><font color='#FFFFFF'>ctivator Loaded!</font>")
end

function OnTick()
	if config.cleanse.cleanse then Cleanse() end
	--if isAfterAttack() then
	--	afterAttack()
	--else
	if not isWindingUp() then
		beforeAttack()
	end
	if config.pots then	Potions() end	
	if summonerSpells.ignite ~= nil then Ignite() end
	if summonerSpells.exhaust ~= nil then Exhaust() end
	UseOffensive()
	UseRanduin()
	UseZhonyas()
end

function isAfterAttack()
	if not isWindingUp() and windUpTime+0.05 > GetInGameTimer() - startAttackTime then
		return true
	end
	return false
end

function OnProcessAttack(unit, spell)
	if unit.isMe then
		startAttackTime = GetInGameTimer()
		windUpTime = spell.windUpTime
	end
	if unit.isAI == false then
		Use(unit, spell)
	end
end

function isWindingUp()
	if windUpTime > GetInGameTimer() - startAttackTime then
		return true
	end
	return false
end

function afterAttack()
	--[[if config.offensive.hydra.hydraTitanic and isCombo() and ItemReady(3748) and ValidTarget(targetSelector(myHero.range, DAMAGE_PHYSICAL)) then
		CastSpell(GetSlotItem(3748))
		startAttackTime = 0
		windUpTime = 0
	end]]
end

function beforeAttack()
	if config.offensive.muramana.muramana then
		local idMur = 0
		if GetSlotItem(3042) ~= nil then 
			idMur = 3042
		elseif GetSlotItem(3043) ~= nil then 
			idMur = 3043
		end
		if idMur ~= 0 and ValidTarget(targetSelector(myHero.range, DAMAGE_PHYSICAL)) and ItemReady(idMur) and myHero.mana > myHero.maxMana * 0.3 then
			if not TargetHaveBuff("Muramana") then
				CastSpell(GetSlotItem(idMur))
			end
		elseif TargetHaveBuff("Muramana") and idMur ~= 0 and ItemReady(idMur) then
			CastSpell(GetSlotItem(idMur))
		end
	end
end

function Use(unit, spell)
	if unit.team == myHero.team then return end
	if not ItemReady(3190) and not ItemReady(3401) and not ItemReady(3040) and not ItemReady(3157) and not CanUseSummoner(summonerSpells.barrier) and not CanUseSummoner(summonerSpells.heal) and not CanUseSummoner(summonerSpells.exhaust) then return end
	if GetDistance(unit) > 1600 then return end
	for _, ally in ipairs(allies) do
		if ally.dead == false and ally.valid ~= false and GetDistance(ally) < 700 and ally.health < (ally.maxHealth * 0.5) then
			local spelltype = getSpellType(unit, spell.name)
			incomingDmg = 0
			if spell.target ~= nil and spell.target.networkID == ally.networkID then
				if spelltype == "BAttack" then
				incomingDmg = incomingDmg + unit:CalcDamage(spell.target, unit.totalDamage)
				elseif spelltype == "CAttack" then
				incomingDmg = incomingDmg + (unit:CalcDamage(spell.target, unit.totalDamage) * 2)
				else
				incomingDmg = incomingDmg + getDmg(spelltype, spell.target, unit)
				end
			else
				local area = GetDistance(spell.endPos, ally) * Vector(spell.endPos - ally.pos):normalized() + ally.pos
				if GetDistance(ally, area) < (ally.boundingRadius / 2) then
					incomingDmg = incomingDmg + getDmg(spelltype, spell.target, unit)
				else
					incomingDmg = 0
				end
			end
			if incomingDmg > 0 then
				if CanUseSummoner(summonerSpells.exhaust) and config.summoners.exhaust.exhaust then
					if (ally.health - incomingDmg) < (CountEnemyHeroInRange(700, ally) * ally.level * 40) then
						CastSpell(summonerSpells.exhaust, unit)
					end
				end
				if CanUseSummoner(summonerSpells.heal) and config.summoners.heal.heal then
					if config.summoners.heal.healAlly then
						if (ally.health - incomingDmg) < (CountEnemyHeroInRange(700, ally) * ally.level * 40) then
							CastSpell(summonerSpells.heal, ally)
						elseif (ally.health - incomingDmg) < (ally.level * 10) then
							CastSpell(summonerSpells.heal, ally)
						end
					end
				end
				if config.defensive.solari and ItemReady(3190) and GetDistance(ally) < items[3190].range then
					if (ally.health - incomingDmg) < (CountEnemyHeroInRange(700, ally) * ally.level * 40) then
						CastSpell(GetSlotItem(3190))
					elseif (ally.health - incomingDmg) < (ally.level * 10) then
						CastSpell(GetSlotItem(3190))
					end
				end
				if config.defensive.fotm and ItemReady(3401) and GetDistance(ally) < items[3401].range then
					if (ally.health - incomingDmg) < (CountEnemyHeroInRange(700, ally) * ally.level * 10) then
						CastSpell(GetSlotItem(3401), ally)
					elseif (ally.health - incomingDmg) < (ally.level * 10) then
						CastSpell(GetSlotItem(3401), ally)
					end
				end
				if ally.isMe then
					if CanUseSummoner(summonerSpells.barrier) and config.summoners.barrier.barrier then
						local barrierAmount = 95 + myHero.level * 20
						if incomingDmg > barrierAmount and myHero.health < myHero.maxHealth * 0.5 then
							CastSpell(summonerSpells.barrier)
						end
						if (myHero.health - incomingDmg) < (CountEnemyHeroInRange(700, ally) * ally.level * 15) then
							CastSpell(summonerSpells.barrier)
						end
					end
					if config.defensive.seraphs then
						if ItemReady(3040) then
							local seraphAmount = myHero.level * 20
							if incomingDmg > seraphAmount and myHero.health < myHero.maxHealth * 0.5 then
								CastSpell(GetSlotItem(3040))
							elseif (myHero.health - incomingDmg) < (CountEnemyHeroInRange(700, ally) * ally.level * 10) then
								CastSpell(GetSlotItem(3040))
							elseif myHero.health - incomingDmg < myHero.level * 10 then
								CastSpell(GetSlotItem(3040))
							end
						end
					end
					if config.defensive.zhonyas then
						if ItemReady(3157) then
							local zhonyaAmount = 95 + myHero.level * 20
							if incomingDmg > zhonyaAmount and myHero.health < myHero.maxHealth * 0.5 then
								CastSpell(GetSlotItem(3157))
							elseif (myHero.health - incomingDmg) < (CountEnemyHeroInRange(700, ally) * ally.level * 10) then
								CastSpell(GetSlotItem(3157))
							elseif myHero.health - incomingDmg < myHero.level * 10 then
								CastSpell(GetSlotItem(3157))
							end
						end
					end
				end
			end
		end
	end
end

function OnProcessSpell(unit, spell)
	if unit.isMe then
		if ItemReady(3142) and config.offensive.youmus.youmusR then
			local spelltype = getSpellType(unit, spell.name)
			if spelltype == "R" and (myHero.charName == "Twitch" or myHero.charName == "Lucian") then
				CastSpell(GetSlotItem(3142))
			end
			if spelltype == "Q" and myHero.charName == "Ashe" then
				CastSpell(GetSlotItem(3142))
			end
		end
	end
	if unit.isAI == false then
		Use(unit, spell)
	end
end

function getPassiveTime(tar, buffName)
	local unit = tar
	local endT = 0
	for i=1, unit.buffCount do
		if unit:getBuff(i).name == buffName then
			endT = unit:getBuff(i).endT
			break
		end
	end
	local timer = GetGameTimer() - endT
	if timer > 0 then
		return timer
	else
		return 0
	end
end

function UseZhonyas()
	if config.defensive.zhonyas and ItemReady(3157) then
		local timer = 2
		if TargetHaveBuff("zedulttargetmark") then
			timer = getPassiveTimer(myHero, "zedulttargetmark")
		end
		if TargetHaveBuff("FizzMarinerDoom") then
			timer = getPassiveTimer(myHero, "FizzMarinerDoom")
		end
		if TargetHaveBuff("MordekaiserChildrenOfTheGrave") then
			timer = getPassiveTimer(myHero, "MordekaiserChildrenOfTheGrave")
		end
		if TargetHaveBuff("VladimirHemoplague") then
			timer = getPassiveTimer(myHero, "VladimirHemoplague")
		end
		if timer < 1 and timer > 0 then
			CastSpell(GetSlotItem(3157))
		end
	end
end

function Potions()
	if InFountain() or TargetHaveBuff("Recall", myHero) then return end
	if GetSlotItem(2004) ~= nil and ItemReady(2004) and not TargetHaveBuff("FlaskOfCrystalWater") then
		if CountEnemyHeroInRange(1200) > 0 and myHero.mana < 200 then
			CastSpell(GetSlotItem(2004))
		end
	end
	if TargetHaveBuff(items[2003].name) or TargetHaveBuff(items[2010].name) or TargetHaveBuff(items[2041].name) then return end
	if GetSlotItem(2041) ~= nil and ItemReady(2041) then
		if CountEnemyHeroInRange(700) > 0 and (myHero.health + 200) < myHero.maxHealth then
			CastSpell(GetSlotItem(2041))
		elseif myHero.health < (myHero.maxHealth * 0.6) then
			CastSpell(GetSlotItem(2041))
		elseif CountEnemyHeroInRange(1200) > 0 and myHero.mana < 200 and not TargetHaveBuff(items[2004].name) then
			CastSpell(GetSlotItem(2041))
		end
		return
	end
	if GetSlotItem(2003) ~= nil and ItemReady(2003) then
		if CountEnemyHeroInRange(700) > 0 and (myHero.health + 200) < myHero.maxHealth then
			CastSpell(GetSlotItem(2003))
		elseif myHero.health < (myHero.maxHealth * 0.6) then
			CastSpell(GetSlotItem(2003))
		end
		return
	end
	if GetSlotItem(2010) ~= nil and ItemReady(2010) then
		if CountEnemyHeroInRange(700) > 0 and (myHero.health + 200) < myHero.maxHealth then
			CastSpell(GetSlotItem(2010))
		elseif myHero.health < (myHero.maxHealth * 0.6) then
			CastSpell(GetSlotItem(2010))
		end
		return
	end
end

function UseRanduin()
	if config.defensive.randuin and ItemReady(3143) then
		if CountEnemyHeroInRange(items[3143].range) > 0 then
			CastSpell(GetSlotItem(3143))
		end
	end
end

function UseOffensive()
	if ItemReady(3153) and config.offensive.botrk.botrk then
		local target = targetSelector(items[3153].range, DAMAGE_PHYSICAL)
		if ValidTarget(target) then
			if config.offensive.botrk.botrkKS and target.health < myHero:CalcDamage(target, 0.10 * target.maxHealth) then
				CastSpell(GetSlotItem(3153), target)
			end
			if config.offensive.botrk.botrkLS and myHero.health < (myHero.maxHealth * 0.5) then
				CastSpell(GetSlotItem(3153), target)
			end
			if config.offensive.botrk.botrkCombo and isCombo() then
				CastSpell(GetSlotItem(3153), target)
			end
		end
	end
	if ItemReady(3146) and config.offensive.hextech.hextech then
		local target = targetSelector(items[3146].range, DAMAGE_MAGICAL)
		if ValidTarget(target) then
			if config.offensive.hextech.hextechKS and target.health < myHero:CalcDamage(target, 150 + (myHero.ap * 0.4)) then
				CastSpell(GetSlotItem(3146), target)
			end
			if config.offensive.hextech.hextechCombo and isCombo() then
				CastSpell(GetSlotItem(3146), target)
			end
		end
	end
	if isCombo() and ItemReady(3092) and config.offensive.frostqueen.frostqueen then
		local target = targetSelector(items[3092].range, DAMAGE_MAGICAL)
		if ValidTarget(target) then
			local CastPosition, HitChance = VP:GetCircularCastPosition(target, 0.25, 200, items[3092].range, 1200, myHero, false)
			if HitChance >= 2 and HitChance <= 5 then
				CastSpell(GetSlotItem(3092), CastPosition.x, CastPosition.z)
			end
		end
	end
	if ItemReady(3144) and config.offensive.cutlass.cutlass then 
		local target = targetSelector(items[3144].range, DAMAGE_MAGICAL)
		if ValidTarget(target) then
			if config.offensive.cutlass.cutlassKS and target.health < myHero:CalcDamage(target, 100) then
				CastSpell(GetSlotItem(3144), target)
			end
			if config.offensive.cutlass.cutlassCombo and isCombo() then
				CastSpell(GetSlotItem(3144), target)
			end
		end
	end
	if ItemReady(3142) and config.offensive.youmus.youmus then
		local target = targetSelector(myHero.range, DAMAGE_PHYSICAL)
		if ValidTarget(target) and target.isAI == false then
			if config.offensive.youmus.youmusKS and target.health < (myHero.health * 0.6) and isCombo() then
				CastSpell(GetSlotItem(3142))
			end
			if config.offensive.youmus.youmusCombo and isCombo() then
				CastSpell(GetSlotItem(3142))
			end
		end
	end
	if config.offensive.hydra.hydra then
		if ItemReady(3074) and CountEnemyHeroInRange(items[3074].range) > 0 then
			CastSpell(GetSlotItem(3074))
		elseif ItemReady(3748) and CountEnemyHeroInRange(items[3748].range) > 0 then
			CastSpell(GetSlotItem(3748))
		end
	end
end

function Exhaust()
	if CanUseSummoner(summonerSpells.exhaust) and config.summoners.exhaust.exhaust then
		if config.summoners.exhaust.exhaustCombo and isCombo() then
			local target = targetSelector(650, DAMAGE_PHYSICAL)
			if ValidTarget(target) then
				CastSpell(summonerSpells.exhaust, target)
			end
		end
	end
end

function Ignite()
	if CanUseSummoner(summonerSpells.ignite) and config.summoners.ignite.ignite then
		local target = targetSelector(600, DAMAGE_TRUE)
		if ValidTarget(target) then
			local igniteDmg = getDmg("IGNITE", target, myHero)
			if target.health <= igniteDmg and GetDistance(target) > 500 and CountEnemyHeroInRange(target, 500) < 2 then
				CastSpell(summonerSpell.ignite, target)
			end
			if target.health <= (2 * igniteDmg) then
				if target.lifeSteal > 10 then
					CastSpell(summonerSpell.ignite, target)
				end
				if TargetHaveBuff("RegenerationPotion", target) or TargetHaveBuff("ItemMiniRegenPotion", target) or TargetHaveBuff("ItemCrystalFlask", target) then
					CastSpell(summonerSpell.ignite, target)
				end
				if target.health > myHero.health then
					CastSpell(summonerSpell.ignite, target)
				end
			end
		end
	end
end

--velkoz, yasuo, quinn, volibear, nocturne, shaco, cait, jinx, karma, maokai, nautilus,
local suppression = { "suppression", "Suppression", "SkarnerImpale", "AlZaharNetherGrasp", "UrgotSwap2", "InfiniteDuress"}
local stun = {  "stun", "Stun", "SonaCrescendo", "CurseoftheSadMummy", "EnchantedCrystalArrow", "CassiopeiaPetrifyingGaze", "JaxCounterStrike", "KennenShurikenStorm", "LeonaSolarFlare", "NamiQ", "OrianaDetonateCommand", 
"Pantheon_LeapBash", "SejuaniGlacialPrisonStart", "ThreshQ", "VeigarEventHorizon", "Imbue", "GnarR"}
local snare = { "snare", "Snare", "LuxLightBindingMis", "DarkBindingMissile", "LeblancSoulShackle", "SwainShadowGrasp", "VarusR", "ZyraGraspingRoots" }
local blind = { "blind", "Blind", "Wither", "BlindingDart", "LuluWTwo" }
local fear = { "fear", "Fear", "Terrify", "HecarimUlt"}
local charm = { "charm", "Charm", "AhriSeduce" }
local taunt = { "taunt", "Taunt", "PuncturingTaunt", "GalioIdolOfDurand"}
				
function Cleanse()
	if not ItemReady(3140) and not ItemReady(3222) and not ItemReady(3139) and not ItemReady(3137) then return end
	if ((myHero.health / myHero.maxHealth) * 100) >= config.cleanse.cleanseHP then return end
	if TargetHaveBuff("zedulttargetmark") or TargetHaveBuff("FizzMarinerDoom") or TargetHaveBuff("MordekaiserChildrenOfTheGrave") or TargetHaveBuff("PoppyDiplomaticImmunity") or TargetHaveBuff("VladimirHemoplague") then
		UseCleanse()
	end
	if config.cleanse.debuffs.suppression then
		for _, db in ipairs(suppression) do
			if TargetHaveBuff(db) then
				UseCleanse()
			end
		end
	end
	if config.cleanse.debuffs.stun then
		for _, db in ipairs(stun) do
			if TargetHaveBuff(db) then
				UseCleanse()
			end
		end
	end
	if config.cleanse.debuffs.blind then
		for _, db in ipairs(blind) do
			if TargetHaveBuff(db) then
				UseCleanse()
			end
		end
	end
	if config.cleanse.debuffs.snare then
		for _, db in ipairs(snare) do
			if TargetHaveBuff(db) then
				UseCleanse()
			end
		end
	end
	if myHero.isCharmed and config.cleanse.debuffs.charm then
		UseCleanse()
	end
	if myHero.isFeared and config.cleanse.debuffs.fear then
		UseCleanse()
	end
	if myHero.isTaunted and config.cleanse.debuffs.taunt then
		UseCleanse()
	end
end

function UseCleanse()
	if ItemReady(3140) then
		CastSpell(GetSlotItem(3140))
	elseif ItemReady(3222) then
		CastSpell(GetSlotItem(3222), myHero)
	elseif ItemReady(3139) then
		CastSpell(GetSlotItem(3139))
	elseif ItemReady(3137) then
		CastSpell(GetSlotItem(3137))
	end
end

function isCombo()
	return config.comboKey
end

function ItemReady(id)
	if GetSlotItem(id) ~= nil and myHero:CanUseSpell(GetSlotItem(id)) == READY then
		return true
	else
		return false
	end
end

function CanUseSummoner(ss)
	if ss ~= nil and myHero:CanUseSpell(ss) == READY then
		return true
	else
		return false
	end
end

function targetSelector(range, dmgType)
	local tarsel = TargetSelector(ts.mode, range, dmgType)
	tarsel:update()
	return tarsel.target
end

function loadSummonerSpells()
	for slot = SUMMONER_1, SUMMONER_2 do
		if myHero:GetSpellData(slot).name == "summonerheal" then
			summonerSpells.heal = slot
		elseif myHero:GetSpellData(slot).name == "summonerbarrier" then
			summonerSpells.barrier = slot
		elseif myHero:GetSpellData(slot).name == "summonerdot" then
			summonerSpells.ignite = slot
		elseif myHero:GetSpellData(slot).name == "summonerexhaust" then
			summonerSpells.exhaust = slot
		elseif myHero:GetSpellData(slot).name == "summonerflash" then
			summonerSpells.flash = slot
		end
	end
end

function loadItemSlots()
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

function GetSlotItem(id, unit)
	unit = unit or myHero

	if (not items[id]) then
		return ___GetInventorySlotItem(id, unit)
	end

	local name  = items[id].name
  
	for slot = ITEM_1, ITEM_7 do
		local item = unit:GetSpellData(slot).name
		if ((#item > 0) and (item:lower() == name:lower())) then
			return slot
		end
	end
end

function menu()
	config = scriptConfig("NeXtGen Activator", "Activator")
	config:addParam("comboKey", "Combo key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	config:addParam("pots", "Use health and mana potions", SCRIPT_PARAM_ONOFF, true)
	
	config:addSubMenu("Summoners", "summoners")
	if summonerSpells.exhaust ~= nil then
		config.summoners:addSubMenu("Exhaust", "exhaust")
		config.summoners.exhaust("exhaust", "Use Exhaust", SCRIPT_PARAM_ONOFF, true)
		config.summoners.exhaust("exhaustCombo", "Always use Exhaust in combo", SCRIPT_PARAM_ONOFF, true)
	end
	if summonerSpells.heal ~= nil then
		config.summoners:addSubMenu("Heal", "heal")
		config.summoners.heal:addParam("heal", "Use Heal", SCRIPT_PARAM_ONOFF, true)
		config.summoners.heal:addParam("healAlly", "Use Heal on Ally", SCRIPT_PARAM_ONOFF, true)
	end
	if summonerSpells.barrier ~= nil then
		config.summoners:addSubMenu("Barrier", "barrier")
		config.summoners.barrier:addParam("barrier", "Use Barrier", SCRIPT_PARAM_ONOFF, true)
	end
	if summonerSpells.ignite ~= nil then
		config.summoners:addSubMenu("Ignite", "ignite")
		config.summoners.ignite:addParam("ignite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
	end
	config:addSubMenu("Offensive", "offensive")
	config.offensive:addSubMenu("Botrk", "botrk")
	config.offensive.botrk:addParam("botrk", "Use Botrk", SCRIPT_PARAM_ONOFF, true)
	config.offensive.botrk:addParam("botrkKS", "Use Botrk to KS", SCRIPT_PARAM_ONOFF, true)
	config.offensive.botrk:addParam("botrkLS", "Use Botrk to save life", SCRIPT_PARAM_ONOFF, true)
	config.offensive.botrk:addParam("botrkCombo", "Always use Botrk in combo", SCRIPT_PARAM_ONOFF, false)
	config.offensive:addSubMenu("Cutlass", "cutlass")
	config.offensive.cutlass:addParam("cutlass", "Use Cutlass", SCRIPT_PARAM_ONOFF, true)
	config.offensive.cutlass:addParam("cutlassKS", "Use Cutlass to KS", SCRIPT_PARAM_ONOFF, true)
	config.offensive.cutlass:addParam("cutlassCombo", "Always use Cutlass in combo", SCRIPT_PARAM_ONOFF, true)
	config.offensive:addSubMenu("Hextech", "hextech")
	config.offensive.hextech:addParam("hextech", "Use Hextech", SCRIPT_PARAM_ONOFF, true)
	config.offensive.hextech:addParam("hextechKS", "Use Hextech to KS", SCRIPT_PARAM_ONOFF, true)
	config.offensive.hextech:addParam("hextechCombo", "Always use Hextech in combo", SCRIPT_PARAM_ONOFF, true)
	config.offensive:addSubMenu("Youmus", "youmus")
	config.offensive.youmus:addParam("youmus", "Use Youmuus", SCRIPT_PARAM_ONOFF, true)
	config.offensive.youmus:addParam("youmusR", "Use Youmuus with certain spells", SCRIPT_PARAM_ONOFF, true)
	config.offensive.youmus:addParam("youmusKS", "Use Youmuus to KS", SCRIPT_PARAM_ONOFF, true)
	config.offensive.youmus:addParam("youmusCombo", "Always use Youmuus in combo", SCRIPT_PARAM_ONOFF, false)
	config.offensive:addSubMenu("Hydra", "hydra")
	config.offensive.hydra:addParam("hydra", "Use Hydra", SCRIPT_PARAM_ONOFF, true)
	config.offensive.hydra:addParam("hydraTitanic", "Use Hydra Titanic", SCRIPT_PARAM_ONOFF, true)
	config.offensive:addSubMenu("Muramana", "muramana")
	config.offensive.muramana:addParam("muramana", "Use Muramana", SCRIPT_PARAM_ONOFF, true)
	config.offensive:addSubMenu("Frost Queen", "frostqueen")
	config.offensive.frostqueen:addParam("frostqueen", "Use Frost Queen", SCRIPT_PARAM_ONOFF, true)
	
	config:addSubMenu("Defensive", "defensive")
	config.defensive:addParam("randuin", "Use Randuin's Omen", SCRIPT_PARAM_ONOFF, true)
	config.defensive:addParam("fotm", "Use Face Of The Mountain", SCRIPT_PARAM_ONOFF, true)
	config.defensive:addParam("zhonyas", "Use Zhonya's", SCRIPT_PARAM_ONOFF, true)
	config.defensive:addParam("seraphs", "Use Seraph's Embrace", SCRIPT_PARAM_ONOFF, true)
	config.defensive:addParam("solari", "Use Locket of Iron Solari", SCRIPT_PARAM_ONOFF, true)

	config:addSubMenu("Cleanse", "cleanse")
	config.cleanse:addParam("cleanse", "Use QSS, Mikael's, Mercurial, Dervish", SCRIPT_PARAM_ONOFF, true)
	config.cleanse:addParam("cleanseHP", "Use cleanse under % hp", SCRIPT_PARAM_SLICE, 80, 0, 100, 0)
	config.cleanse:addSubMenu("Cleanse debuff types", "debuffs")
	config.cleanse.debuffs:addParam("stun", "Stun", SCRIPT_PARAM_ONOFF, true)
	config.cleanse.debuffs:addParam("snare", "Snare/Root", SCRIPT_PARAM_ONOFF, true)
	config.cleanse.debuffs:addParam("charm", "Charm", SCRIPT_PARAM_ONOFF, true)
	config.cleanse.debuffs:addParam("fear", "Fear", SCRIPT_PARAM_ONOFF, true)
	config.cleanse.debuffs:addParam("suppression", "Suppression", SCRIPT_PARAM_ONOFF, true)
	config.cleanse.debuffs:addParam("taunt", "Taunt", SCRIPT_PARAM_ONOFF, true)
	config.cleanse.debuffs:addParam("blind", "Blind / Polymorph", SCRIPT_PARAM_ONOFF, true)
end

--[[  ItemNames       = {
    [3303]        = "ArchAngelsDummySpell",
    [3007]        = "ArchAngelsDummySpell",
    [3188]        = "ItemBlackfireTorch",
    [3405]        = "TrinketSweeperLvl1",
    [3411]        = "TrinketOrbLvl1",
    [3166]        = "TrinketTotemLvl1",
    [3450]        = "OdinTrinketRevive",
    [2054]        = "ItemKingPoroSnack",
    [2138]        = "ElixirOfIron",
    [2137]        = "ElixirOfRuin",
    [2139]        = "ElixirOfSorcery",
    [2140]        = "ElixirOfWrath",
    [3184]        = "OdinEntropicClaymore",
    [2050]        = "ItemMiniWard",
    [3363]        = "TrinketOrbLvl3",
    [3460]        = "AscWarp",
    [3361]        = "TrinketTotemLvl3",
    [3362]        = "TrinketTotemLvl4",
    [3159]        = "HextechSweeper",
    [2051]        = "ItemHorn",
    [3187]        = "HextechSweeper",
    [3043]        = "Muramana",
    [3180]        = "OdynsVeil",
    [3056]        = "ItemFaithShaker",
    [2047]        = "OracleExtractSight",
    [3364]        = "TrinketSweeperLvl3",
    [2052]        = "ItemPoroSnack",
    [3800]        = "ItemRighteousGlory",
    [2045]        = "ItemGhostWard",
    [3342]        = "TrinketOrbLvl1",
    [3048]        = "ItemSeraphsEmbrace",
    [2049]        = "ItemGhostWard",
    [3345]        = "OdinTrinketRevive",
    [2044]        = "SightWard",
    [3341]        = "TrinketSweeperLvl1",
    [3069]        = "shurelyascrest",
    [3599]        = "KalistaPSpellCast",
    [3185]        = "HextechSweeper",
    [2009]        = "ItemMiniRegenPotion",
    [3023]        = "ItemWraithCollar",
    [3290]        = "ItemWraithCollar",
    [2043]        = "VisionWard",
    [3340]        = "TrinketTotemLvl1",
    [3090]        = "ZhonyasHourglass",
    [3154]        = "wrigglelantern",
    [3512]        = "ItemVoidGate",
    [3131]        = "ItemSoTD",
    [3352]        = "RelicSpotter",
	[3350]        = "TrinketTotemLvl2",
  }]]