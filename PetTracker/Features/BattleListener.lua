--[[
Copyright 2012-2014 João Cardoso
PetTracker is distributed under the terms of the GNU General Public License (Version 3).
As a special exception, the copyright holders of this addon do not give permission to
redistribute and/or modify it.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the addon. If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.

This file is part of PetTracker.
--]]

local _, Addon = ...
local Battle = Addon.Battle
local Listener = Addon:NewModule('BattleListener', CreateFrame('Frame'))


--[[ Startup ]]--

function Listener:Startup()
	Addon.Sets.TamerHistory = Addon.Sets.TamerHistory or {}
	self:FixTamerHistory()
	if not Addon.State.Casts then
		self:Reset()
	end

	self:RegisterEvent('PET_BATTLE_FINAL_ROUND')
	self:RegisterEvent('CHAT_MSG_PET_BATTLE_COMBAT_LOG')
	self:SetScript('OnEvent', function(self, event, ...)
		self[event](self, ...)
	end)
end

function Listener:FixTamerHistory()
	for tamerId, tamerData in pairs(Addon.Sets.TamerHistory) do
		for recordId, recordData in pairs(tamerData) do
			local recordLen = recordData:len()
			if recordLen == 82 and recordData:sub(15,18) == '0000' then --Pre 6.0 Patch
				Addon.Sets.TamerHistory[tamerId][recordId] = recordData:sub(1,14) .. 'BattlePet-0-' .. recordData:sub(19,40) .. 'BattlePet-0-' .. recordData:sub(45,66) .. 'BattlePet-0-' .. recordData:sub(71,82)
			elseif recordLen == 100 and recordData:sub(15,18) == 'ttle' then --Post 6.0 Bug in PetTamer
				Addon.Sets.TamerHistory[tamerId][recordId] = recordData:sub(1,14) .. 'Ba' .. recordData:sub(15,46) .. 'Ba' .. recordData:sub(47,78) .. 'Ba' .. recordData:sub(79,100)
			end
		end
	end
end

function Listener:Reset()
	Addon.State.Casts = {{id = {}, turn = {}}, {id = {}, turn = {}}, {id = {}, turn = {}}}
	Addon.State.Turn = 0
end


--[[ Events ]]--

function Listener:CHAT_MSG_PET_BATTLE_COMBAT_LOG(message)
	local id = tonumber(message:match('^|T.-|t|cff......|HbattlePetAbil:(%d+)'))
	if id then
		local isHeal = message:find(ACTION_SPELL_HEAL)
		local isTargetEnemy = message:find(ENEMY)

		if (isHeal and isTargetEnemy) or not (isHeal or isTargetEnemy) then
			local pet = Battle:GetCurrent(LE_BATTLE_PET_ENEMY)
			local casts = Addon.State.Casts[pet.index]

			for i, ability in ipairs(pet:GetAbilities()) do
				if ability == id then
					local k = i % 3
					casts.turn[k] = Addon.State.Turn
					casts.id[k] = id
					return
				end 
			end
		end
	else
		local round = message:match(PET_BATTLE_COMBAT_LOG_NEW_ROUND:gsub('%%d', '(%%d+)'))
		if round then
			Addon.State.Turn = tonumber(round)
		end
	end
end

function Listener:PET_BATTLE_FINAL_ROUND(winner)
	local tamer = Battle:GetTamer()
	if tamer then
		local history = Addon.Sets.TamerHistory[tamer] or {}
		local entry = tostring(winner) .. format('%03x', Addon:GetDate())

		for i = 1,3 do
			local id, spell1, spell2, spell3 = C_PetJournal.GetPetLoadOutInfo(i)
			local health = C_PetBattles.GetHealth(LE_BATTLE_PET_ALLY, i) / C_PetBattles.GetMaxHealth(LE_BATTLE_PET_ALLY, i)

			entry = entry .. format('%01x', ceil(health * 15))
						  .. format('%03x', spell1) .. format('%03x', spell2) .. format('%03x', spell3)
						  .. id
		end

		tinsert(history, 1, entry)
		if #history > 9 then
			tremove(history)
		end

		Addon.Sets.TamerHistory[tamer] = history
	end

	self:Reset()
end