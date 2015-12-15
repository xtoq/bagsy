local ldb_tip
local crayon	= LibStub("LibCrayon-3.0")
local total	= { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0 }
local taken	= { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0 }
local free	= { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0 }
local class	= 1 + 2 + 4
local craft	= 8 + 16 + 32 + 64 + 128 + 512 + 1024
local frame	= CreateFrame("Button", "Bagsy")
local ldb_obj	= LibStub("LibDataBroker-1.1"):NewDataObject("Bagsy", {
  type  = 'data source', 
	icon		= "Interface\\Icons\\INV_Misc_Bag_08.png",
	label	= "Bagsy"
})

if not BagsyDB or BagsyDB.reset ~= "2.4.3-1.0" then
	BagsyDB           = {}
	BagsyDB.class     = false
	BagsyDB.craft     = false
	BagsyDB.sep_class = false
	BagsyDB.sep_craft = false
	BagsyDB.style     = false
	BagsyDB.color     = true
	BagsyDB.reset     = "3.3-1.0"
end

local function set_ldb_obj_text(_, event, bag)
	if event then
		if type(bag) ~= "number" then
			for bag = 0, 4 do
				total[bag] = GetContainerNumSlots(bag)
				free[bag]  = GetContainerNumFreeSlots(bag)
				taken[bag] = total[bag] - free[bag]
			end

		elseif bag >= 0 and bag < 5 then
			total[bag] = GetContainerNumSlots(bag)
			free[bag]  = GetContainerNumFreeSlots(bag)
			taken[bag] = total[bag] - free[bag]
		end
	end

	local total_all, taken_all, free_all, text, class_check, craft_check = 0, 0, 0, ""

	for bag = 0, 4 do
		local bag_type = GetItemFamily(GetBagName(bag))

		if bag_type then
			class_check = bit.bxor(class, bag_type) < class
			craft_check = bit.bxor(craft, bag_type) < craft
		end

		if not bag_type or (not class_check and not craft_check) or (class_check and BagsyDB.class) or (craft_check and BagsyDB.craft) then
			total_all = total_all + total[bag]
			taken_all = taken_all + taken[bag]
			free_all  = free_all  + free[bag]
		end

		if (class_check and BagsyDB.sep_class) or (craft_check and BagsyDB.sep_craft) then
			local icon  = GetInventoryItemLink("player", ContainerIDToInventoryID(bag))
			icon        = icon and "|T"..GetItemIcon(icon)..":20:20:0:0.3|t" or ""
			local color = BagsyDB.color and "|cff"..crayon:GetThresholdHexColor(free[bag], total[bag]) or ""
			text        = text.." |cffeeeeee-|r "..icon..color..(Bagsy.style and taken[bag] or free[bag]).."/"..total[bag]..(BagsyDB.color and "|r" or "")
		end
	end

	local color  = BagsyDB.color and "|cff"..crayon:GetThresholdHexColor(free_all, total_all) or ""
	text         = color..(BagsyDB.style and taken_all or free_all).."/"..total_all..(BagsyDB.color and "|r" or "")..text
	ldb_obj.text = text
end

local function is_backpack_open()
	for bag = 1, NUM_CONTAINER_FRAMES do
		local check = _G["ContainerFrame"..bag]

		if check:GetID() == 0 and check:IsVisible() then return true end
	end
end

local function toggle_value(value)
	BagsyDB[value] = not BagsyDB[value]

	set_ldb_obj_text()
	ldb_obj.OnTooltipShow(ldb_tip)
end

function ldb_obj.OnTooltipShow(tip)
	if not ldb_tip then ldb_tip = tip end

	tip:ClearLines()

	local state = (BagsyDB.style and "taken" or "free")

	tip:AddLine("Bagsy: A DataBroker Plugin")
	tip:AddLine(" ")
	tip:AddLine("|cff8888eeYour individual bags and their "..state.." slots:|r")

	for bag = 0, 4 do
		local link  = bag > 0 and GetInventoryItemLink("player", ContainerIDToInventoryID(bag)) or "|cffffffff[Backpack]|r"
		local color = crayon:GetThresholdHexColor(free[bag], total[bag])

		tip:AddDoubleLine("|cff69b950"..(bag + 1).." "..link.."|r", "|cff"..color..(BagsyDB.style and taken[bag] or free[bag]).."/"..total[bag].."|r")
	end

	tip:AddLine(" ")
	tip:AddLine("|cffffd700Class Bags:|r |cffeeeeee"..(BagsyDB.class and "Included" or "Not included").." in the overall count"..(BagsyDB.sep_class and ", "..(BagsyDB.class and "and " or "").."shown separately" or "")..".")
	tip:AddLine("|cffffd700Profession Bags:|r |cffeeeeee"..(BagsyDB.craft and "Included" or "Not included").." in the overall count"..(BagsyDB.sep_craft and ", "..(BagsyDB.craft and "and " or "").."shown separately" or "")..".")
	tip:AddLine("|cffffd700Currently Showing:|r |cffeeeeeeAmount of slots "..state..".|r")
	tip:AddLine(" ")
	tip:AddLine("|cff69b950Left-Click:|r |cffeeeeeeOpen/close backpack|r")
	tip:AddLine("|cff69b950Right-Click:|r |cffeeeeeeOpen/close all bags|r")
	tip:AddLine("|cff69b950Alt + Left-Click:|r |cffeeeeeeToggles free or taken slots|r")
	tip:AddLine("|cff69b950Alt + Right-Click:|r |cffeeeeeeColored counts|r")
	tip:AddLine("|cff69b950Shift + Left-Click:|r |cffeeeeeeInclude class bags in total count|r")
	tip:AddLine("|cff69b950Shift + Right-Click:|r |cffeeeeeeInclude class bags as separate count|r")
	tip:AddLine("|cff69b950Control + Left-Click:|r |cffeeeeeeInclude profession bags in total count|r")
	tip:AddLine("|cff69b950Control + Right-Click:|r |cffeeeeeeInclude profession bags as separate count|r")

	tip:Show()
end

function ldb_obj.OnClick(_, which)
	which = which == "RightButton"

	if IsAltKeyDown() then
		toggle_value(which and "color" or "style")

	elseif IsShiftKeyDown() then
		toggle_value((which and "sep_" or "").."class")

	elseif IsControlKeyDown() then
		toggle_value((which and "sep_" or "").."craft")

	else	local toggle = is_backpack_open() and "Close" or "Open"
		_G[which and toggle.."AllBags" or toggle.."Backpack"]()
	end
end

frame:RegisterEvent"PLAYER_LOGIN"
frame:RegisterEvent"BAG_UPDATE"

frame:SetScript("OnEvent", set_ldb_obj_text)