if myHero.charName ~= "Ashe" then return end

require 'SxOrbWalk'
require 'VPrediction'

--local variables
local version = 1.2
local SCRIPT_NAME = "NeXtGenAshe"
local AUTO_UPDATE = true
local enemies = {}
local minions = {}
local jungleMinions = {}
local spells = 
{
	Q = { ready = false, mana = 0, range = 0 },
	W = { ready = false, mana = 0, range = 1240, delay = 0.25, width = 50, speed = 1200},
	E = { ready = false, mana = 0, range = 2500, delay = 0.25, width = 299, speed = 1400},
	R = { ready = false, mana = 0, range = 3000, delay = 0.25, width = 130, speed = 1600}
}

if DOWNLOADING_SOURCELIB then print("Downloading required libraries, please wait...") return end

local RequireI = Require("SourceLib")
RequireI:Check()

if AUTO_UPDATE then
     SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/cinkulol/bolscripts/master"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/cinkulol/bolscripts/master"..SCRIPT_NAME..".version"):CheckUpdate()
end

--hooks

function OnLoad()
	variables()
	menu()
end

function OnTick()
	checks()
end

function variables()

end

function menu()

end

function checks()
	
end