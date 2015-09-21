if myHero.charName ~= "Ashe" then return end

local version = 1.2
local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/cinkulol/bolscripts/master/NeXtGenAshe.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = LIB_PATH.."NeXtGenAshe.lua"
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function Say(text)
  print("<font color=\"#FF0000\"><b>LonseViktor:</b></font> <font color=\"#FFFFFF\">" .. text .. "</font>")
end
if AUTOUPDATE then
  local ServerData = GetWebResult(UPDATE_HOST, "/cinkulol/bolscripts/master/NeXtGenAshe.version")
  if ServerData then
    ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
    if ServerVersion then
      if tonumber(version) < ServerVersion then
        Say("New version available "..ServerVersion)
        Say("Updating, please don't press F9")
        DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () Say("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
      else
        Say("You have got the latest version (v"..ServerVersion..") of LonseViktor by " .. author)
      end
    end
  else
    Say("Error downloading version info")
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