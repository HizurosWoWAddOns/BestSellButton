
local addon,ns = ...;
local L = ns.L;
ns.debugMode = "@project-version@"=="@".."project-version".."@";
LibStub("HizurosSharedTools").RegisterPrint(ns,addon,"BSB");

local media,hooked = "interface\\addons\\"..addon.."\\media\\",false;
local imgWidth,imgHeight = 256,64;
local choices,bestPrice = {},0;
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
local function iconstr(path)
	return "|T"..path..":16:16|t";
end

local function HideOnHook(parent)
	if BestSellButton:IsShown() then
		C_Timer.After(0.6,function()
			if not parent:IsShown() then
				BestSellButton:Hide();
			end
		end);
	end
end

local function ShowButton(button)
	BestSellButton.sellbutton_under:SetShown(button=="under");
	BestSellButton.sellbutton_beside:SetShown(button=="beside");
	BestSellButton.sellbutton_over:SetShown(button=="over");
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

		sellbutton = "under",
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
			name = OPTIONS,
			args = {
				showAddOnLoaded = {
					type = "toggle", order = 1, width = "double",
					name = L["AddOnLoaded"], desc = L["AddOnLoadedDesc"].."|n|n|cff44ff44"..L["AddOnLoadedDescAlt"].."|r"
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
				},
				sellbutton = {
					type = "group", order = 3, inline = true,
					name = L["Choose a button position"],
					get = function(info)
						return BestSellButton.db.profile[info[#info-1]]==info[#info];
					end,
					set = function(info,value)
						BestSellButton.db.profile.sellbutton=info[#info];
						if BestSellButton:IsShown() then
							ShowButton(BestSellButton.db.profile.sellbutton);
						end
					end,
					args = {
						over = {
							type = "toggle", order = 1, width = "double",
							name = L["Over the \"Complete quest\" button"]
						},
						beside = {
							type = "toggle", order = 3, width = "double",
							name = L["Beside the \"Complete quest\" button"]
						},
						under = {
							type = "toggle", order = 5, width = "double",
							name = L["Under the quest window"]
						},

						over_image = {
							type = "description", order = 2, width = "", name = "",
							image = media.."button_over", imageWidth = imgWidth, imageHeight = imgHeight
						},
						beside_image = {
							type = "description", order = 4, width = "", name = "",
							image = media.."button_beside", imageWidth = imgWidth, imageHeight = imgHeight
						},
						under_image = {
							type = "description", order = 6, width = "", name = "",
							image = media.."button_under", imageWidth = imgWidth, imageHeight = imgHeight
						},
					}
				}
			}
		},

		credits = {
			type = "group", order = 200,
			name = L["Credit"],
			args = {}
		},
	}
};

-- [ BestSellButton functions ] --
BestSellButtonMixin = {};

function BestSellButtonMixin:CheckChoices()
	-- it could be GetQuestItemLink returns nil while QuestRewardItem:IsShown() is true.
	-- maybe network timing problem to get correct item link directly after event QUEST_COMPLETE
	-- try again after a second...
	local checkError,num,price = false,GetNumQuestChoices() or 0;
	-- resets
	bestPrice = 0;
	wipe(choices);
	-- now check the offered items
	for index=1, num do
		local QuestRewardItem = _G["QuestInfoRewardsFrameQuestInfoItem"..index];
		if QuestRewardItem and QuestRewardItem:IsVisible() and QuestRewardItem.objectType=="item" and QuestRewardItem.type=="choice" then
			local link,_ = GetQuestItemLink(QuestRewardItem.type,index);
			if link then
				_, _, _, _, _, _, _, _, _, _, price = C_Item.GetItemInfo(link);
			end
			if price then
				if QuestRewardItem.count>1 then
					price = price * QuestRewardItem.count;
				end
				choices[index] = price;
				if price > bestPrice then
					bestPrice = price;
				end
			else
				checkError = true;
			end
		end
	end

	if checkError then
		return false;
	end

	self:ShowButton();
	self:ShowPriceIcons();
	return true;
end

function BestSellButtonMixin:OnLoad()
	self:GetHeight(QuestFrameCompleteButton:GetHeight());
	local flvl = QuestFrame:GetFrameLevel();

	-- under
	local template = "CharacterFrameTabTemplate" -- retail clients
	if WOW_PROJECT_ID~=WOW_PROJECT_MAINLINE then
		template = "CharacterFrameTabButtonTemplate" -- classic clients
	end
	self.sellbutton_under = CreateFrame("Button",addon.."Under",self,template);
	self.sellbutton_under:SetPoint("TOP",QuestFrameCompleteButton,"BOTTOM",-3,0);
	self.sellbutton_under:SetScript("OnClick",function(self) self:GetParent():SelectRewardItem(); end);
	self.sellbutton_under:Hide();
	if self.sellbutton_under.Text then
		self.sellbutton_under.Text:SetText(L["Best sell"]);
		self.sellbutton_under.LeftActive:Hide();
		self.sellbutton_under.MiddleActive:Hide();
		self.sellbutton_under.RightActive:Hide();
	else
		_G[addon.."UnderText"]:SetText(L["Best sell"]);
		_G[addon.."UnderLeftDisabled"]:Hide();
		_G[addon.."UnderMiddleDisabled"]:Hide();
		_G[addon.."UnderRightDisabled"]:Hide();
	end
	PanelTemplates_TabResize(self.sellbutton_under,12,nil,64);

	-- beside
	_G[addon.."BesideText"]:SetText(L["Best sell"]);
	self.sellbutton_beside:SetFrameLevel(flvl+3);
	self.sellbutton_beside:SetWidth(self.sellbutton_under:GetWidth());

	-- over
	_G[addon.."OverText"]:SetText(L["Best sell"]);
	self.sellbutton_over:SetFrameLevel(flvl+3);
	self.sellbutton_over:SetWidth(self.sellbutton_under:GetWidth());

	if not hooked then
		QuestFrame:HookScript("OnHide", HideOnHook);
		QuestFrameCompleteQuestButton:HookScript("OnClick", HideOnHook);
		QuestFrameCompleteButton:HookScript("OnClick", HideOnHook);
		QuestFrameGoodbyeButton:HookScript("OnClick", HideOnHook);
		hooked = true;
	end

	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent("QUEST_DETAIL"); -- display quest details
	self:RegisterEvent("QUEST_COMPLETE"); -- quest complete screen with quest complete button and reward items
	self:RegisterEvent("QUEST_FINISHED"); -- on close gossip frame or force it?

	BestSellButtonMixin=nil;
end

function BestSellButtonMixin:OnEvent(event,...)
	if event == "ADDON_LOADED" and addon==... then
		self:InitPriceIcons();

		self.db = LibStub("AceDB-3.0"):New("BestSellButtonDB",dbDefaults,true);
		options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);

		LibStub("AceConfig-3.0"):RegisterOptionsTable(addon, options);
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addon);

		LibStub("HizurosSharedTools").AddCredit(addon,options.args.credits.args);

		if self.db.profile.showAddOnLoaded or IsShiftKeyDown() then
			ns:print(L["AddOnLoaded"]);
		end
		self:UnregisterEvent(event);
	elseif event=="QUEST_COMPLETE" then
		if not self:CheckChoices() then
			C_Timer.After(1,function()
				self:CheckChoices(); -- try again
				-- see comment in function BestSellButtonMixin.CheckChoices
			end);
		end
	elseif (event=="QUEST_FINISHED" or event=="QUEST_DETAIL") and self:IsShown() then
		self:Hide();
		self:CleanPriceIcons();
	end
end

function BestSellButtonMixin:SelectRewardItem()
	for i=1, #choices do
		if choices[i]==bestPrice then
			QuestInfoFrame.itemChoice = i;
			QuestInfoItemHighlight:ClearAllPoints();
			QuestInfoItemHighlight:SetPoint("TOPLEFT",_G["QuestInfoRewardsFrameQuestInfoItem"..i],"TOPLEFT",-8,7);
			QuestInfoItemHighlight:Show();
			break;
		end
	end
end

function BestSellButtonMixin:HideButton()
end

function BestSellButtonMixin:ShowButton()
	if GetNumQuestChoices()>1 and (QuestInfoRewardsFrameQuestInfoItem2 and QuestInfoRewardsFrameQuestInfoItem2:IsVisible()) then
		if self.bestPrice~=0 then
			ShowButton(BestSellButton.db.profile.sellbutton);
			self:Show();
		end
	elseif self:IsShown() then
		self:Hide();
	end
end


-- [ price indicator icons ] --

function BestSellButtonMixin:ShowPriceIcons()
	if self.db.profile.priceIconsEnabled then
		for i=1, #choices do
			if not choices[i] or choices[i]==0 then
				self:SetPriceIcon(i,false);
			elseif choices[i]==bestPrice then
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
		if v then
			v:ClearAllPoints();
			v:Hide();
			tinsert(self.iconsUnused,v);
		end
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
