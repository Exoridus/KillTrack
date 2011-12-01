--[[
	* Copyright (c) 2011 by Adam Hellberg.
	*
	* This file is part of KillTrack.
	*
	* KillTrack is free software: you can redistribute it and/or modify
	* it under the terms of the GNU General Public License as published by
	* the Free Software Foundation, either version 3 of the License, or
	* (at your option) any later version.
	*
	* KillTrack is distributed in the hope that it will be useful,
	* but WITHOUT ANY WARRANTY; without even the implied warranty of
	* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	* GNU General Public License for more details.
	*
	* You should have received a copy of the GNU General Public License
	* along with KillTrack. If not, see <http://www.gnu.org/licenses/>.
--]]

KillTrack.Command = {
	Slash = {
		"killtrack",
		"kt"
	},
	Commands = {}
}

local KT = KillTrack
local C = KT.Command
local KTT = KillTrack_Tools

--local CLib = ChocoboLib

-- Argument #1 (command) can be either string or a table.
function C:Register(command, func)
	if type(command) == "string" then
		command = {command}
	end
	for _,v in pairs(command) do
		if not self:HasCommand(v) then
			if v ~= "__DEFAULT__" then v = v:lower() end
			self.Commands[v] = func
		end
	end
end

function C:HasCommand(command)
	for k,_ in pairs(self.Commands) do
		if k == command then return true end
	end
	return false
end

function C:GetCommand(command)
	local cmd = self.Commands[command]
	if cmd then return cmd else return self.Commands["__DEFAULT__"] end
end

function C:HandleCommand(command, args)
	local cmd = self:GetCommand(command)
	if cmd then
		cmd(args)
	else
		KT:Msg(("%q is not a valid command."):format(command))
	end
end

C:Register("__DEFAULT__", function(args)
	KT:Msg("/kt target - Display number of kills on target mob.")
	KT:Msg("/kt lookup <name> - Display number of kills on <name>, <name> can also be NPC ID.")
	KT:Msg("/kt print - Toggle printing kill updates to chat.")
	KT:Msg("/kt list - Display a list of all mobs entries.")
	KT:Msg("/kt delete <id> - Delete entry with NPC id <id>.")
	KT:Msg("/kt purge [treshold] - Open dialog to purge entries, specifiying a treshold here is optional.")
	KT:Msg("/kt reset - Clear the mob database.")
	KT:Msg("/kt time - Track kills within specified time.")
	KT:Msg("/kt treshold <treshold> - Set treshold for kill record notices to show.")
	KT:Msg("/kt - Displays this help message.")
end)

C:Register({"target", "t", "tar"}, function(args)
	if not UnitExists("target") or UnitIsPlayer("target") then return end
	local id = KTT:GUIDToID(UnitGUID("target"))
	KT:PrintKills(id)
end)

C:Register({"print", "p"}, function(args)
	KT.Global.PRINTKILLS = not KT.Global.PRINTKILLS
	if KT.Global.PRINTKILLS then
		KT:Msg("Announcing kill updates.")
	else
		KT:Msg("No longer announcing kill updates.")
	end
end)

C:Register({"delete", "del", "remove", "rem"}, function(args)
	if #args <= 0 then
		KT:Msg("Missing argument: id")
		return
	end
	local id = tonumber(args[1])
	if not id then
		KT:Msg("Id must be a number")
		return
	end
	if not KT.Global.MOBS[id] then
		KT:Msg(("Id %d does not exist in the database."):format(id))
		return
	end
	local name = KT.Global.MOBS[id].Name
	KT:ShowDelete(id, name)
end)

C:Register({"purge"}, function(args)
	local treshold
	if #args >= 1 then treshold = tonumber(args[1]) end
	KT:ShowPurge(treshold)
end)

C:Register({"reset", "r"}, function(args)
	KT:ShowReset()
end)

C:Register({"lookup", "lo", "check"}, function(args)
	if #args <= 0 then
		KT:Msg("Missing argument: name")
		return
	end
	local name = table.concat(args, " ")
	KT:PrintKills(name)
end)

C:Register({"list", "moblist", "mobs"}, function(args)
	KT.MobList:ShowGUI()
end)

C:Register({"time", "timer"}, function(args)
	if #args <= 0 then
		KT:Msg("Usage: time <seconds> [minutes] [hours]")
		KT:Msg("Usage: time [<seconds>s][<minutes>m][<hours>h]")
		return
	end
	
	local s, m, h
	
	if #args == 1 then
		if not tonumber(args[1]) then
			args[1] = args[1]:lower()
			s = args[1]:match("(%d+)s")
			m = args[1]:match("(%d+)m")
			h = args[1]:match("(%d+)h")
			if not s and not m and not h then
				KT:Msg("Invalid number format.")
				return
			end
		else
			s = tonumber(args[1])
		end
	else
		s = tonumber(args[1])
		m = tonumber(args[2])
		h = tonumber(args[3])
	end
	KT.TimerFrame:Start(s, m, h)
end)

C:Register({"treshold"}, function(args)
	if #args <= 0 then
		KT:Msg("Usage: treshold <treshold>")
		KT:Msg("E.g: /kt treshold 100")
		KT:Msg("    Notice will be shown on every 100th kill.")
		return
	end
	local t = tonumber(args[1])
	if t then
		KT:SetTreshold(t)
	else
		KT:Msg("Argument must be a number.")
	end
end)

for i,v in ipairs(C.Slash) do
	_G["SLASH_" .. KT.Name:upper() .. i] = "/" .. v
end

SlashCmdList[KT.Name:upper()] = function(msg, editBox)
	msg = KTT:Trim(msg)
	local args = KTT:Split(msg)
	local cmd = args[1]
	local t = {}
	if #args > 1 then
		for i=2,#args do
			table.insert(t, args[i])
		end
	end
	C:HandleCommand(cmd, t)
end
