questItems = require("questItems")


local lang = {}

lang["pickupSuccess"] = "You have picked up %s."
lang["unableDrop"] = "You can't drop the %s!"
lang["unableSell"] = "I don't buy quest items!"

local cmds = {}
cmds[1] = "qhlist"
cmds[2] = "qhhelp"

local cmdDesc = {}
cmdDesc[1] = "\n- displays quest items to enable for player"
cmdDesc[2] = "\n- displays available questHelper commands"

local menuCmd = {}
menuCmd[1] = color.SkyBlue .. "/" .. cmds[1]
menuCmd[2] = color.SkyBlue .. "/" .. cmds[2]


local Methods = {}

Methods.data = {}
Methods.guiId = {msg = 19283, itemList = 19284, choosePlList = 19285, help = 19286}
Methods.blockSellMerchant = {}
Methods.lastActivatedMerchant = {}
Methods.forceEnableItemIndex = {}

local merchants = jsonInterface.load("custom/merchants.json")

local function doMessage(pid, message, ...)

	local args = {...}
	local newMessage = lang[message]
	
	if #args > 0 then
		newMessage = string.format(newMessage, unpack(args))
	end

	tes3mp.MessageBox(pid, Methods.guiId.msg, newMessage)

end

function Methods.LoadData()
	local loadedData = jsonInterface.load("custom/questHelper.json")
	
	if loadedData then
		Methods.data = loadedData
	else
		Methods.SaveData()
	end
end

function Methods.SaveData()
	jsonInterface.save("custom/questHelper.json", Methods.data)
end

Methods.sortHelp = function()

	local newTable = {}
	
	for i = 1, #menuCmd do
		table.insert(newTable, menuCmd[i] .. cmdDesc[i])
	end
	
	table.sort(newTable)
	
	return newTable
end

function Methods.help(pid, cmd)

	local list = ""
	local title = color.Orange .. "\nAvailable questHelper commands"
	local divider = "\n"
	local helpTable = Methods.sortHelp()

	for i = 1, #helpTable do
		if i == #helpTable then
			divider = ""
		end
		
		list = list .. helpTable[i] .. divider
	end
	
	tes3mp.ListBox(pid, Methods.guiId.help, title, list)
end

function Methods.createJsonEntry(refId)
	local data = Methods.data
		
	if data[refId] == nil then
		data[refId] = {disabledFor = {}}
	end
end

function Methods.clearMerchantBlockVars(pid)
	if Methods.blockSellMerchant[pid] ~= nil then
		Methods.blockSellMerchant[pid] = nil
	end
	
	if Methods.lastActivatedMerchant[pid] ~= nil then
		Methods.lastActivatedMerchant[pid] = nil
	end
end

function Methods.isQuestItem(refId)
	return questItems[refId] ~= nil
end

function Methods.createItemListFromData()
	
	local itemList = {}
	local itemNamesList = {}
		
	for item, _ in pairs(questItems) do
		table.insert(itemList, item)
		table.insert(itemNamesList, questItems[item].name)
	end
	
	
	table.sort(itemList)
	table.sort(itemNamesList)
	
	if Methods.itemList == nil then Methods.itemList = {} end
	if Methods.itemNamesList == nil then Methods.itemNamesList = {} end
	
	if tableHelper.isEqualTo(itemList, Methods.itemList) then
		return
	else
		Methods.itemList = itemList
	end
	
	if tableHelper.isEqualTo(itemNamesList, Methods.itemNamesList) then
		return
	else
		Methods.itemNamesList = itemNamesList
	end
end

function Methods.enableItemForPlayer(targetPid, data)
	
	local name = Methods.itemNamesList[data]
	local item
	
	for refId, _ in pairs(questItems) do
		if name == questItems[refId].name then
			item = refId
		end
	end
			
	local cellDescription = tes3mp.GetCell(targetPid)
	
	if Methods.data[item] ~= nil then
		local pName = tes3mp.GetName(targetPid)
		
		if tableHelper.containsValue(Methods.data[item].disabledFor, pName) then
			tableHelper.removeValue(Methods.data[item].disabledFor, pName)
			Methods.SaveData()
		end
		
		if cellDescription == nil then
			return
		else
			Methods.updateCell(targetPid, cellDescription)
		end
		
	end
end

function Methods.guiItemList(pid, cmd)
	
	Methods.createItemListFromData()

	local lbTitle = color.DodgerBlue .. "\n- Quest items list -" 
	local list = ""
	local delimeter = "\n"
	
	for index, name in pairs(Methods.itemNamesList) do
		
		if index == #Methods.itemNamesList then
			delimeter = ""
		end

		list = list .. name .. delimeter
	end
	
	tes3mp.ListBox(pid, Methods.guiId.itemList, lbTitle, list)
	
end

function Methods.choosePlayerList(pid)

	local lbTitle = color.DodgerBlue .. "\n- Choose player to activate the item for -"
	local list = ""
	local delimeter = "\n"
	
	for id, player in pairs(Players) do
		
		if index == #Players then
			delimeter = ""
		end
		
		list = list .. Players[id].name .. delimeter
	end
	
	tes3mp.ListBox(pid, Methods.guiId.choosePlList, lbTitle, list)	
end

function Methods.OnGUIAction(EventStatus, pid, idGui, data)
	
	if idGui == Methods.guiId.itemList then
		if tonumber(data) == 18446744073709551615 then
			return
		else
			Methods.forceEnableItemIndex[pid] = tonumber(data) + 1
			Methods.choosePlayerList(pid)
			return
		end
	elseif idGui == Methods.guiId.choosePlList then
		if tonumber(data) == 18446744073709551615 then
			Methods.enableItemForPlayer(pid, Methods.forceEnableItemIndex[pid])
			Methods.forceEnableItemIndex[pid] = nil
			return
		else
			local target = tonumber(data)
			Methods.enableItemForPlayer(target, Methods.forceEnableItemIndex[pid])
			Methods.forceEnableItemIndex[pid] = nil
			return
		end		
	end
end

-- functions copied over from uramer's Visual Harvesting modified to fit the needs of this script
function Methods.sendObjectState(pid, cellDescription, uniqueIndex, state)
    local splitIndex = uniqueIndex:split("-")

    tes3mp.SetObjectRefNum(splitIndex[1])
    tes3mp.SetObjectMpNum(splitIndex[2])
    tes3mp.SetObjectState(state)

    tes3mp.AddObject()
end

function Methods.enableObject(pid, cellDescription, uniqueIndex) 
	
    LoadedCells[cellDescription].data.objectData[uniqueIndex].state = true
	-- LoadedCells[cellDescription]:SaveObjectStates(pid)
    
    Methods.sendObjectState(pid, cellDescription, uniqueIndex, true)
end

function Methods.disableObject(pid, cellDescription, uniqueIndex, itemId)
	
	if LoadedCells[cellDescription].data.objectData[uniqueIndex] and LoadedCells[cellDescription].data.objectData[uniqueIndex].refId == nil then 
		LoadedCells[cellDescription].data.objectData[uniqueIndex].refId = itemId
	end

	LoadedCells[cellDescription].data.objectData[uniqueIndex].state = false
	-- LoadedCells[cellDescription]:SaveObjectStates(pid)

    Methods.sendObjectState(pid, cellDescription, uniqueIndex, false)
end

function Methods.updateCell(pid, cellDescription)
    local cell = LoadedCells[cellDescription]
	local data = Methods.data
	local pName = tes3mp.GetName(pid)
	
    tes3mp.ClearObjectList()
    tes3mp.SetObjectListPid(pid)
    tes3mp.SetObjectListCell(cellDescription)
    
    for uniqueIndex, object in pairs(cell.data.objectData) do
		
		if Methods.isQuestItem(object.refId) then
			if not tableHelper.containsValue(data[object.refId].disabledFor, pName) then
				Methods.enableObject(pid, cellDescription, uniqueIndex)
			else
				Methods.disableObject(pid, cellDescription, uniqueIndex, object.refId)
			end
		end
    end
    
    tes3mp.SendObjectState(false, false)
end

function Methods.addItemToPlayer(pid, refId)

	inventoryHelper.addItem(Players[pid].data.inventory, refId, 1, -1, -1, "")
	
	tes3mp.ClearInventoryChanges(pid)
	tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
	tes3mp.AddItemChange(pid, refId, 1, -1, -1, "")
	tes3mp.SendInventoryChanges(pid)
end

function Methods.OnServerPostInit(eventStatus)
	Methods.LoadData()
end

function Methods.OnObjectActivateValidator(eventStatus, pid, cellDescription, objects, players)
    for _, object in pairs(objects) do
        if Methods.isQuestItem(object.refId) then
			local uniqueIndex = object.uniqueIndex
			local pName = tes3mp.GetName(pid)
			local data = Methods.data
			local itemName = questItems[object.refId].name
			
			LoadedCells[cellDescription]:SaveObjectStates(pid)
			
			Methods.createJsonEntry(object.refId)
			
			if not tableHelper.containsValue(data[object.refId].disabledFor, pName) then
				table.insert(data[object.refId].disabledFor, pName)
				Methods.SaveData()
			else
				return customEventHooks.makeEventStatus(false, false)
			end
			
			doMessage(pid, "pickupSuccess", color.DodgerBlue .. itemName .. color.GoldenRod)
			tes3mp.PlaySpeech(pid, "fx/item/item.wav")
			Methods.addItemToPlayer(pid, object.refId)
			
			tes3mp.ClearObjectList()
			tes3mp.SetObjectListPid(pid)
			tes3mp.SetObjectListCell(cellDescription)
			Methods.disableObject(pid, cellDescription, uniqueIndex, object.refId)

			tes3mp.SendObjectState(false, false)
		
			return customEventHooks.makeEventStatus(false, false)
        end
    end
end

--------------------------------------------------------------------------------------------------------
function Methods.OnObjectActivateHandler(eventStatus, pid, cellDescription, objects, players) -- sets temporary variable that helps prevent selling quest items to any merchant that is listed
	for _, object in pairs(objects) do
		
		local uniqueIndex = object.uniqueIndex
		local refId = object.refId
		
		if merchants[refId] ~= nil then
			Methods.lastActivatedMerchant[pid] = uniqueIndex
		end
	end
end	

function Methods.OnContainerValidator(eventStatus, pid, cellDescription, objects)  -- prevents player from placing quest item in any type of container
	
	tes3mp.ReadReceivedObjectList()
    tes3mp.CopyReceivedObjectListToStore()

    local action = tes3mp.GetObjectListAction()
	local cell = LoadedCells[cellDescription]

    if action == enumerations.container.ADD then
        for containerIndex = 0, tes3mp.GetObjectListSize() - 1 do
            local uniqueIndex = tes3mp.GetObjectRefNum(containerIndex) .. "-" .. tes3mp.GetObjectMpNum(containerIndex)

            for itemIndex = 0, tes3mp.GetContainerChangesSize(containerIndex) - 1 do
                local itemRefId = tes3mp.GetContainerItemRefId(containerIndex, itemIndex)
				local itemName = questItems[itemRefId].name

                if Methods.isQuestItem(itemRefId) and cell.data.objectData[uniqueIndex].refId ~= "kanabankcontainer" then
					Methods.clearMerchantBlockVars(pid)
					
					Methods.addItemToPlayer(pid, itemRefId)
					-- Players[pid]:SaveInventory()
					doMessage(pid, "unableDrop", color.DodgerBlue .. itemName .. color.GoldenRod)
                    cell:LoadContainers(pid, cell.data.objectData, {uniqueIndex})
                    return customEventHooks.makeEventStatus(false, false)
                end
            end
        end
    end
end

function Methods.OnObjectPlaceValidator(eventStatus, pid, cellDescription, objects) -- prevents player from placing quest item in the world

	for index, object in pairs(objects) do
		
		if Methods.isQuestItem(object.refId) then
			
			Methods.clearMerchantBlockVars(pid)
			
			local itemName = questItems[object.refId].name
		
			Methods.addItemToPlayer(pid, object.refId)
			-- Players[pid]:SaveInventory()
			
			doMessage(pid, "unableDrop", color.DodgerBlue .. itemName .. color.GoldenRod)
			
			return customEventHooks.makeEventStatus(false,false)
		end
	end
end

function Methods.OnPlayerInventoryHandler(eventStatus, pid) -- prevents player from selling quest item to merchant, losing gold and listing quest item in merchants barter inventory

	local action = tes3mp.GetInventoryChangesAction(pid)
    local itemChangesCount = tes3mp.GetInventoryChangesSize(pid)
	
	for index = 0, itemChangesCount - 1 do
        local itemRefId = tes3mp.GetInventoryItemRefId(pid, index)
		local itemCount = tes3mp.GetInventoryItemCount(pid, index)
		
		if Methods.blockSellMerchant[pid] ~= nil then
			local cellDesc = tes3mp.GetCell(pid)
			local cell = LoadedCells[cellDesc]
			local oData = cell.data.objectData
			
			local currTime = os.time()
			if currTime < Methods.blockSellMerchant[pid] + 1 then
				if itemRefId == "gold_001" and action == enumerations.inventory.ADD then
					tes3mp.ClearInventoryChanges(pid)
					tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.REMOVE)
					tes3mp.AddItemChange(pid, itemRefId, itemCount, -1, -1, "")
					tes3mp.SendInventoryChanges(pid)
					Players[pid]:SaveInventory()
					cell:LoadContainers(pid, oData, {Methods.lastActivatedMerchant[pid]})
					doMessage(pid, "unableSell")
					Methods.blockSellMerchant[pid] = nil
				end
			else
				Methods.blockSellMerchant[pid] = nil
			end
		end
			
		
		if Methods.isQuestItem(itemRefId) and action == enumerations.inventory.REMOVE and Methods.lastActivatedMerchant[pid] ~= nil then
			Methods.blockSellMerchant[pid] = os.time()
			Methods.addItemToPlayer(pid, itemRefId)
			-- Players[pid]:SaveInventory()
		end
	end
end

function Methods.OnPlayerDisconnectHandler(eventStatus, pid)
	Methods.clearMerchantBlockVars(pid)
end
	

function Methods.OnServerExit()
    Methods.SaveData()
end

function Methods.OnCellLoadHandler(eventStatus, pid, cellDescription)
    if eventStatus.validCustomHandlers then
        Methods.updateCell(pid, cellDescription)
        Methods.SaveData()
    end
end

customCommandHooks.registerCommand(cmds[1], Methods.guiItemList)
customCommandHooks.setRankRequirment(cmds[1], 1)
customCommandHooks.registerCommand(cmds[2], Methods.help)

customEventHooks.registerHandler("OnServerPostInit", Methods.OnServerPostInit)
customEventHooks.registerHandler("OnGUIAction", Methods.OnGUIAction)
customEventHooks.registerHandler("OnCellLoad", Methods.OnCellLoadHandler)
customEventHooks.registerValidator("OnObjectActivate", Methods.OnObjectActivateValidator)
customEventHooks.registerHandler("OnObjectActivate", Methods.OnObjectActivateHandler)
customEventHooks.registerValidator("OnContainer", Methods.OnContainerValidator)
customEventHooks.registerValidator("OnObjectPlace", Methods.OnObjectPlaceValidator)
customEventHooks.registerHandler("OnPlayerInventory", Methods.OnPlayerInventoryHandler)
customEventHooks.registerHandler("OnPlayerDisconnect", Methods.OnPlayerDisconnectHandler)
customEventHooks.registerHandler("OnServerExit", Methods.OnServerExit)

