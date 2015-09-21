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

function getVersion(version) 
	return tonumber(string.match(version or "", "%d+%.?%d*")) 
end
	
function CheckUpdate(scriptName, version, host, updatePath, filePath, versionPath)
	local server_version = nil
	local file_version = getVersion(version)
	local version_path = versionPath and versionPath .. "?rand="..math.random(1,10000)
	local update_path = updatePath .. "?rand="..math.random(1,10000)
	local update_url = "https://"..host..update_path
    local webResult = GetWebResult(host, version_path or update_path)
    if webResult then
        if version_path then
            server_version = webResult
        else
            server_version = string.match(webResult, "%s*local%s+version%s+=%s+.*%d+%.%d+")
        end
        if server_version then
            server_version = getVersion(server_version)
            if not server_version then
                print("SourceLib: Please contact the developer of the script \"" .. (GetCurrentEnv().FILE_NAME or "DerpScript") .. "\", since the auto updater returned an invalid version.")
                return
            end
            if file_version < server_version then
                self.printMessage("New version available: v" .. server_version)
                self.printMessage("Updating, please don't press F9")
                DelayAction(function () DownloadFile(update_url, filePath, function () print("Successfully updated, please reload!") end) end, 2)
            else
                print("You've got the latest version: v" .. server_version)
            end
        else
            print("Something went wrong! Please manually update the script!")
        end
    else
        print("Error downloading version info!")
    end

end

if AUTO_UPDATE then
     CheckUpdate(SCRIPT_NAME, version, "raw.githubusercontent.com", "/cinkulol/bolscripts/master/NeXtGenAshe.lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/cinkulol/bolscripts/master/"..SCRIPT_NAME..".version")
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