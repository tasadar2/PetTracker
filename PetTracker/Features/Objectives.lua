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

if IsAddOnLoaded('Carbonite.Quests') then
	return
end

local ADDON, Addon = ...
local Objectives = Addon:NewModule('Objectives', ObjectiveTracker_GetModuleInfoTable())


--[[ Startup ]]--

function Objectives:Startup()
	local tracker = Addon.Tracker()
	tracker.Anchor:SetScript('OnMouseDown', tracker.ToggleOptions)
	tracker:SetParent(self.BlocksFrame)
	tracker.module = Objectives
	tracker.animateReason = 0
	tracker.maxEntries = 10
	tracker.height = 0

	local header = CreateFrame('Button', nil, self.BlocksFrame, 'ObjectiveTrackerHeaderTemplate')
	header:SetScript('OnClick', tracker.ToggleOptions)

	self:SetHeader(header, Addon.Locals.BattlePets)
	self.tracker, self.firstBlock = tracker, tracker
	self.blockOffsetX = -15

	self.updateReasonModule, self.updateReasonEvents = 0x80000000, OBJECTIVE_TRACKER_UPDATE_ALL
	self.usedBlocks, self.freeItemButtons = {}, {}

	tinsert(ObjectiveTrackerFrame.MODULES, self)
end


--[[ Events ]]--

function Objectives:TrackingChanged()
	if self.tracker then
		self.tracker:Update()
		self.tracker.height = self.tracker:Count() * 20
		ObjectiveTracker_Update(self.updateReasonModule)
	end
end

function Objectives:Update()
	if self.tracker then
		local display = not Addon.Sets.HideTracker
		self.firstBlock = display and self.tracker
		self.tracker:SetShown(display)

		if display then
			self:StaticReanchor()
		end
	end
end