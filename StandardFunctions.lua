--[[ ------------------------------------------------------------------------
	Title: 			StandardFunctions.lua
	Author: 		mrbryo
	Create Date : 	08/08/2025
	Description: 	Standard functions for WoW addon use.
-----------------------------------------------------------------------------]]

-- Instantiate Library as a Module
local StdFuncs = ABSync:NewModule("StandardFunctions")

-- set a boolean value by checking if wow version 10 or higher
function StdFuncs:IsWoW10()
    local WoW10 = select(4, GetBuildInfo()) >= 100000
    return WoW10
end

-- shallow table copy
function StdFuncs:shallowCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = v
    end
    return copy
end

-- deep table copy
function StdFuncs:deepCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            copy[k] = self:deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end