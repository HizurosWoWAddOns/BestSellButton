
local addon,ns = ...;
local L = ns.L;
local media,hooked = "interface\\addons\\"..addon.."\\media\\",false;
local priceIconsEdgePos = {
	TOPLEFT     = {-8,8},
	TOPRIGHT    = {8,8},
	BOTTOMLEFT  = {-8,-8},
	BOTTOMRIGHT = {8,-8}
};
local priceIconsHigh = {
	"interface\\buttons\\ui-grouploot-coin-up",
	"interface\\minimap\\tracking\\auctioneer"
};
local priceIconsNone = {
	"interface\\common\\icon-noloot",
	"interface\\common\\voicechat-muted",
	"interface\\buttons\\ui-grouploot-pass-up"
};

-- [ misc functions ] --

function ns.print(...)
	local colors,t,c = {"0099ff","00ff00","ff6060","44ffff","ffff00","ff8800","ff44ff","ffffff"},{},1;
	for i,v in ipairs({...}) do
		v = tostring(v);
		if i==1 and v~="" then
			tinsert(t,"|cff0099ff"..addon.."|r:"); c=2;
		end
		if not v:match("||c") then
			v,c = "|cff"..colors[c]..v.."|r", c<#colors and c+1 or 1;
		end
		tinsert(t,v);
	end
	print(unpack(t));
end

if GetAddOnMetadata(addon,"Version")=="@".."project-version".."@" then
	function ns.debug(...)
		ns.print("debug",...);
	end
end

local function iconstr(path)
	return "|T"..path..":16:16|t";
end

-- [ Ace3 Options table ] --

local dbDefaults = {
	profile = {
		showAddOnLoaded = true,
		showPriceIcons = true,

		priceIconsEnabled = false,
		priceIconsEdge = "TOPRIGHT",
		priceIconsHigh = "interface\\minimap\\tracking\\auctioneer",
		priceIconsNone = "interface\\common\\icon-noloot",
	}
};

local options = {
	type = "group",
	name = addon,
	childGroups = "tab",
	get = function(info)
		return BestSellButton.db.profile[info[#info]];
	end,
	set = function(info,value)
		BestSellButton.db.profile[info[#info]] = value;
	end,
	args = {
		options = {
			type = "group", order = 1,
			name = L["Options"],
			args = {
				showAddOnLoaded = {
					type = "toggle", order = 1, width = "double",
					name = L["Show 'AddOn loaded...'"],
					desc = L["Display 'AddOn loaded...' message on startup in chat window"]
				},
				priceIcons = {
					type = "group", order = 2, inline = true,
					name = L["Price indicator icons"],
					args = {
						info = {
							type = "description", order = 0,
							name = L["Display icons for highest price and unsaleable items on an edge of the item icon"]
						},
						priceIconsEnabled = {
							type = "toggle", order = 1,
							name = L["Enabled"],
						},
						priceIconsEdge = {
							type = "select", order = 2,
							name = L["Edge"],
							values = {
								TOPLEFT     = L["Top left"],
								TOPRIGHT    = L["Top right"],
								BOTTOMLEFT  = L["Bottom left"],
								BOTTOMRIGHT = L["Bottom right"]
							}
						},
						priceIconsHigh = {
							type = "select", order = 3, width = "double",
							name = L["Icon for highest price"],
							values = {}
						},
						priceIconsNone = {
							type = "select", order = 4, width = "double",
							name = L["Icon for unsaleable items"],
							values = {}
						}
					}
				}
			}
		}
	}
};

-- [ BestSellButton functions ] --
BestSellButtonMixin = {};

local function HideOnHook()
	BestSellButton:HideButton();
end

function BestSellButtonMixin:OnLoad()
	_G[addon.."LeftDisabled"]:Hide();
	_G[addon.."MiddleDisabled"]:Hide();
	_G[addon.."RightDisabled"]:Hide();

	_G[addon.."Text"]:SetText(L["Best sell"]);
	PanelTemplates_TabResize(self,12,nil,64);

	if not hooked then
		QuestFrame:HookScript("OnHide", HideOnHook);
		QuestFrameCompleteQuestButton:HookScript("OnClick", HideOnHook);
		QuestFrameCompleteButton:HookScript("OnClick", HideOnHook);
		QuestFrameGoodbyeButton:HookScript("OnClick", HideOnHook);
		hooked = true;
	end

	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent("QUEST_COMPLETE");
	self:RegisterEvent("QUEST_FINISHED");

	BestSellButtonMixin=nil;
end

function BestSellButtonMixin:OnEvent(event,...)
	if event == "ADDON_LOADED" and addon==... then
		self:UnregisterEvent("ADDON_LOADED");

		self:InitPriceIcons();

		self.db = LibStub("AceDB-3.0"):New("BestSellButtonDB",dbDefaults,true);
		options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);

		LibStub("AceConfig-3.0"):RegisterOptionsTable(addon, options);
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addon);

		if self.db.profile.showAddOnLoaded then
			ns.print(L["AddOn loaded..."]);
		end
	elseif event == "QUEST_FINISHED" then
		self:HideButton();
	elseif (event == "QUEST_COMPLETE" or event=="QUEST_LOG_UPDATE") then
		self:ShowButton();
	end
end

function BestSellButtonMixin:OnClick()
	--[[
	local bestItem,bestPrice = 0,0;
	local num = GetNumQuestChoices() or 0;
	ns.debug("<numChoices>",num);
	for index=1, num do
		local QuestRewardItem = _G["QuestInfoRewardsFrameQuestInfoItem"..index];
		if QuestRewardItem and QuestRewardItem:IsShown() and QuestRewardItem.objectType=="item" then
			local link = GetQuestItemLink(QuestRewardItem.type,index);
			local name, _, _, _, _, _, _, _, _, _, price = GetItemInfo(link);
			ns.debug("<item>",index,name,price);
			if price > bestPrice then
				bestItem,bestPrice = index,price;
			end
		end
	end
	--]]
	for i=1, #self.choices do
		if self.choices[i]==self.bestPrice then
			QuestInfoFrame.itemChoice = i;
			QuestInfoItemHighlight:ClearAllPoints();
			QuestInfoItemHighlight:SetPoint("TOPLEFT",_G["QuestInfoRewardsFrameQuestInfoItem"..i],"TOPLEFT",-8,7);
			QuestInfoItemHighlight:Show();
			break;
		end
	end
end

function BestSellButtonMixin:HideButton()
	if self:IsShown() then
		self:CleanPriceIcons();
		self:Hide();
	end
end

function BestSellButtonMixin:ShowButton()
	if GetNumQuestChoices()>1 and (QuestInfoRewardsFrameQuestInfoItem2 and QuestInfoRewardsFrameQuestInfoItem2:IsVisible()) then
		self:CheckChoices();
		if self.bestPrice~=0 then
			self:ShowPriceIcons();
			self:Show();
		end
	elseif self:IsShown() then
		self:HideButton();
	end
end

function BestSellButtonMixin:CheckChoices()
	self.choices,self.bestPrice = {},0;
	local num = GetNumQuestChoices() or 0;
	for index=1, num do
		local QuestRewardItem = _G["QuestInfoRewardsFrameQuestInfoItem"..index];
		if QuestRewardItem and QuestRewardItem:IsShown() and QuestRewardItem.objectType=="item" then
			local link = GetQuestItemLink(QuestRewardItem.type,index);
			local name, _, _, _, _, _, _, _, _, _, price = GetItemInfo(link);
			self.choices[index] = price;
			if price > self.bestPrice then
				self.bestPrice = price;
			end
		end
	end
end

-- [ price indicator icons ] --

function BestSellButtonMixin:ShowPriceIcons()
	if self.db.profile.priceIconsEnabled then
		for i=1, #self.choices do
			if not self.choices[i] or self.choices[i]==0 then
				self:SetPriceIcon(i,false);
			elseif self.choices[i]==self.bestPrice then
				self:SetPriceIcon(i,true);
			end
		end
	end
end

function BestSellButtonMixin:SetPriceIcon(index,high)
	local icon;
	if #self.iconsUnused>0 then
		icon = self.iconsUnused[1];
		tinsert(self.icons,icon);
		tremove(self.iconsUnused,1);
	end
	if not icon then
		icon = CreateFrame("Frame",nil,self);
		icon:SetSize(24,24);
		icon.tex = icon:CreateTexture(nil,"OVERLAY");
		icon.tex:SetAllPoints();
		tinsert(self.icons,icon);
	end
	local point = BestSellButton.db.profile.priceIconsEdge;
	local parent = _G["QuestInfoRewardsFrameQuestInfoItem"..index];
	icon:ClearAllPoints();
	icon:SetPoint(point,parent.Icon,point,unpack(priceIconsEdgePos[point]));
	icon:SetFrameLevel(parent:GetFrameLevel()+1);
	icon.tex:SetTexture(BestSellButton.db.profile["priceIcons"..(high and "High" or "None")]);
	icon:Show();
end

function BestSellButtonMixin:CleanPriceIcons()
	for i,v in pairs(self.icons)do
		v:ClearAllPoints();
		v:Hide();
		tinsert(self.iconsUnused,v);
	end
	wipe(self.icons);
end

function BestSellButtonMixin:InitPriceIcons()
	local group = options.args.options.args.priceIcons.args;
	for i=1, #priceIconsHigh do
		group.priceIconsHigh.values[priceIconsHigh[i]] = iconstr(priceIconsHigh[i]).." "..priceIconsHigh[i];
	end
	for i=1, #priceIconsNone do
		group.priceIconsNone.values[priceIconsNone[i]] = iconstr(priceIconsNone[i]).." "..priceIconsNone[i];
	end
	self.icons = {};
	self.iconsUnused = {};
end
