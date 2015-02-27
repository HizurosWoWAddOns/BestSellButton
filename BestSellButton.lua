
local addon,ns = ...
local L = ns.L
local bestSellButton, bestItem = nil,{v=0,l=nil,i=0}
local _print = print
local media = "interface\\addons\\"..addon.."\\media\\"
local icons = {
--	gold   = "interface\\buttons\\ui-grouploot-coin-up",
--	silver = media.."coin-silver",
--	copper = media.."coin-copper",
	gold   = "interface\\minimap\\tracking\\auctioneer",
	silver = media.."coins-silver",
	copper = media.."coins-copper",
--	none   = "interface\\common\\icon-noloot",
--	none   = "interface\\common\\voicechat-muted",
	none   = "interface\\buttons\\ui-grouploot-pass-up",
}
if not ( ns.buttonWidth ) then
	ns.buttonWidth = 128
end


local function print(...)
	local args = {...}
	table.insert(args,1,"|cffff0000"..addon.."|r: ")
	table.insert(args,"|r")
	_print(unpack(args))
end

local function hookScriptHide(self,button)
	if bestSellButton~=nil and bestSellButton:IsShown() and QuestInfoFrame.itemChoice>0 then
		bestSellButton:ClearAllPoints()
		bestSellButton:Hide()
	end
end

local function appendIcon(target,icon)
	
end

local function chState(state)
	local num = state<2 and GetNumQuestChoices() or 0
	local n = addon.."_BestSellButton"
	local hideButton = false

	if state<2 and (not bestSellButton) then
		bestSellButton = CreateFrame("Button",n,QuestFrame,"CharacterFrameTabButtonTemplate")
	end

	if state==0 and num>1 then
		bestSellButton:Show()

		bestSellButton:ClearAllPoints()
		bestSellButton:SetPoint("TOPLEFT",QuestFrame,"BOTTOMLEFT",0,0)

		_G[n.."LeftDisabled"]:Hide() _G[n.."MiddleDisabled"]:Hide() _G[n.."RightDisabled"]:Hide()
		local w0,w1,wm0 = bestSellButton:GetWidth(),ns.buttonWidth,_G[n.."Middle"]:GetWidth()
		bestSellButton:SetWidth(w1)
		_G[n.."Middle"]:SetWidth((w1-w0)+wm0)
		_G[n.."Text"]:SetText(L["Best sell"])

		bestSellButton:SetScript("OnClick", function() chState(1) end)
		_G['QuestFrame']:HookScript("OnHide", hookScriptHide)
		_G['QuestFrameCompleteQuestButton']:HookScript("OnClick", hookScriptHide)
		_G['QuestFrameCompleteButton']:HookScript("OnClick", hookScriptHide)
		_G['QuestFrameGoodbyeButton']:HookScript("OnClick", hookScriptHide)
	elseif (state==1 or state==0) and num==0 and bestSellButton:IsShown() then
		hideButton = true
	elseif state==1 and num>1 and bestSellButton:IsShown() then
		local items = {}
		for i=1, num do -- or 10 instead of num
			-- sometimes GetNumQuestChoices() return higher value then really visible items.
			if (_G["QuestInfoItem"..i]~=nil and _G["QuestInfoItem"..i]:IsShown()) or (_G["QuestInfoRewardsFrameQuestInfoItem"..i]~=nil and _G["QuestInfoRewardsFrameQuestInfoItem"..i]:IsShown()) then
				local l = GetQuestItemLink("choice",i)
				local n, _, _, _, _, _, _, _, _, _, v = GetItemInfo(l);
				if v==0 then
					-- append icon to not sellable item
				end
				if items[v]~=nil then
					items[v-1] = i
				else
					items[v] = i
				end
				if v > bestItem.v then
					bestItem = {v=v,l=l,i=i}
				end
			end
		end
		if bestItem.i~=0 then
			QuestInfoFrame.itemChoice = bestItem.i
			if ( _G["QuestInfoRewardsFrameQuestInfoItem"..bestItem.i] ) then
				QuestInfoItemHighlight:SetPoint("TOPLEFT",_G["QuestInfoRewardsFrameQuestInfoItem"..bestItem.i],"TOPLEFT",-8,7)
			elseif ( _G["QuestInfoItem"..bestItem.i] ) then
				QuestInfoItemHighlight:SetPoint("TOPLEFT",_G["QuestInfoItem"..bestItem.i],"TOPLEFT",-8,7)
			end
			QuestInfoItemHighlight:Show()
		end
	elseif state==2 and bestSellButton~=nil and bestSellButton:GetObjectType()=="Button" then
		hideButton = true
	end
	if hideButton and bestSellButton~=nil and bestSellButton:IsShown() then
		bestSellButton:ClearAllPoints()
		bestSellButton:Hide()
	end
end

local f = CreateFrame("frame")
f:SetScript("OnEvent",function(self,event)
	if event == "ADDON_LOADED" then
		f:UnregisterEvent("ADDON_LOADED")
		print("|cff00ff00Addon loaded...")
	elseif event == "QUEST_COMPLETE" or event=="QUEST_LOG_UPDATE" then
		chState(0) -- show button
	elseif event == "QUEST_FINISHED" then
		chState(2) -- hide button
	end
end)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("QUEST_COMPLETE")
f:RegisterEvent("QUEST_FINISHED")
