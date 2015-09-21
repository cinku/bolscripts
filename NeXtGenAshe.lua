if myHero.charName ~= "Ashe" then return end

local version = "1.2"
local AUTOUPDATE = true
local UPDATE_HOST = "raw.githubusercontent.com"
local UPDATE_PATH = "/cinkulol/bolscripts/master/NeXtGenAshe.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = LIB_PATH.."NeXtGenAshe.lua"
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>SAC VI:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH)
	if ServerData then
		local ServerVersion = string.match(ServerData, "local version = \"%d+.%d+\"")
		ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
		if ServerVersion then
			ServerVersion = tonumber(ServerVersion)
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New version available"..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end)	 
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end

require 'SxOrbWalk'
require 'VPrediction'

--local variables
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