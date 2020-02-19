questItems = require("questItems")

local lang = {}

lang["pickupSuccess"] = "You have picked up %s."
lang["unableDrop"] = "You can't drop the %s!"
lang["unableSell"] = "I don't buy quest items!"
lang["reenableSuccess"] = "You have succcessfully re-enabled %s " .. color.Default .. "(%s" .. color.Default .. ") for player %s" .. color.Default .. "!\n"

local cmds = {}
cmds[1] = "qhlist"
cmds[2] = "qhhelp"

local cmdDesc = {}
cmdDesc[1] = "\n- displays quest items to enable for player"
cmdDesc[2] = "\n- displays available questHelper commands"

local menuCmd = {}
menuCmd[1] = color.SkyBlue .. "/" .. cmds[1]
menuCmd[2] = color.SkyBlue .. "/" .. cmds[2]

local merchants = jsonInterface.load("custom/merchants.json")

local Methods = {}

Methods.data = {}
Methods.guiId = {msg = 19283, itemList = 19284, choosePlList = 19285, help = 19286}
Methods.blockSellMerchant = {}
Methods.lastActivatedMerchant = {}
Methods.forceEnableItemIndex = {}

Methods.itemNameRefIdPairs = {}
Methods.itemNamesByIndex = {}

local function doMessage(pid, message, chat, ...)

	local args = {...}
	local newMessage = lang[message]
	
	if #args > 0 then
		newMessage = string.format(newMessage, unpack(args))
	end
	
	if chat == true then
		tes3mp.SendMessage(pid, color.Warning .. "[questHelper] " .. color.Default .. newMessage, false)
	else
		tes3mp.MessageBox(pid, Methods.guiId.msg, newMessage)
	end
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
		data[refId] = {}
		Methods.SaveData()
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

function Methods.fillItemListDependencies()
		
	for item, name in pairs(questItems) do
		Methods.itemNameRefIdPairs[name] = item
		table.insert(Methods.itemNamesByIndex, name)
	end
	
	
	table.sort(Methods.itemNamesByIndex)
end

function Methods.enableItemForPlayer(pid, targetPid, tName, itemIndex)
	
	local name = Methods.itemNamesByIndex[itemIndex]
	local item = Methods.itemNameRefIdPairs[name]
	local doUpdate = false
	
	if Methods.data[item] ~= nil and Methods.data[item][tName] then
			Methods.data[item][tName] = nil
			Methods.SaveData()
			doUpdate = true
	end
	
	if doUpdate then
		if Players[targetPid] ~= nil and Players[targetPid]:IsLoggedIn() then
				
			local cellDescription = tes3mp.GetCell(targetPid)
			
			Methods.updateCell(targetPid, cellDescription)	
		end
		doMessage(pid, "reenableSuccess", true, color.DodgerBlue .. name, color.GoldenRod .. item, color.Yellow .. tName)
	end
end

function Methods.guiQuestItemList(pid, cmd)
	
	local lbTitle = color.DodgerBlue .. "\n- Quest items list -" 
	local list = " - CANCEL -\n"
	local delimeter = "\n"
	
	for index, name in ipairs(Methods.itemNamesByIndex) do
		
		if index == #Methods.itemNamesByIndex then
			delimeter = ""
		end

		list = list .. name .. delimeter
	end
	
	tes3mp.ListBox(pid, Methods.guiId.itemList, lbTitle, list)
end

function Methods.choosePlayerList(pid)
	
	Methods.playerNamesByIndex = {}
	Methods.playerNamePidPairs = {}
	Methods.playerNamesByIndex[pid] = {}
	Methods.playerNamePidPairs[pid] = {}
	
	for id, player in pairs(Players) do
		Methods.playerNamePidPairs[pid][player.name] = id
		table.insert(Methods.playerNamesByIndex[pid], player.name)
	end
	
	table.sort(Methods.playerNamesByIndex[pid])
	
	local lbTitle = color.DodgerBlue .. "\n- Choose player to activate the item for -"
	local list = " - CANCEL -\n"
	local delimeter = "\n"
	
	for index = 1, #Methods.playerNamesByIndex[pid] do
		
		if index == #Methods.playerNamesByIndex[pid] then
			delimeter = ""
		end
		
		list = list .. Methods.playerNamesByIndex[pid][index] .. delimeter
	end
	
	tes3mp.ListBox(pid, Methods.guiId.choosePlList, lbTitle, list)
end

function Methods.OnGUIAction(EventStatus, pid, idGui, data)
	
	if idGui == Methods.guiId.itemList then
		if tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then
			return
		else
			Methods.forceEnableItemIndex[pid] = tonumber(data)
			Methods.choosePlayerList(pid)
		end
	elseif idGui == Methods.guiId.choosePlList then
		
		if tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then
			Methods.forceEnableItemIndex[pid] = nil
			Methods.playerNamesByIndex[pid] = nil
			Methods.playerNamePidPairs[pid] = nil
			return
		else
			local target = Methods.playerNamesByIndex[pid][tonumber(data)]
			Methods.enableItemForPlayer(pid, Methods.playerNamePidPairs[pid][target], target, Methods.forceEnableItemIndex[pid])
			Methods.forceEnableItemIndex[pid] = nil
			Methods.playerNamesByIndex[pid] = nil
			Methods.playerNamePidPairs[pid] = nil
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
	
	if LoadedCells[cellDescription].data.objectData[uniqueIndex] == nil then
		LoadedCells[cellDescription].data.objectData[uniqueIndex] = {}
	end
	
	if LoadedCells[cellDescription].data.objectData[uniqueIndex].refId == nil then 
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
			Methods.createJsonEntry(object.refId)
			if not data[object.refId][pName] then
				Methods.enableObject(pid, cellDescription, uniqueIndex)
			else
				Methods.disableObject(pid, cellDescription, uniqueIndex, object.refId)
			end
		end
    end
    
    tes3mp.SendObjectState(false, false)
end

function Methods.addItemToPlayer(pid, refId, count)

	local count = count
	
	if not count then
		count = 1
	end

	inventoryHelper.addItem(Players[pid].data.inventory, refId, count, -1, -1, "")
	
	tes3mp.ClearInventoryChanges(pid)
	tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
	tes3mp.AddItemChange(pid, refId, count, -1, -1, "")
	tes3mp.SendInventoryChanges(pid)
end

function Methods.OnServerPostInit(eventStatus)
	Methods.LoadData()
	tableHelper.cleanNils(Methods.data)
	Methods.fillItemListDependencies()
end

function Methods.OnObjectActivateValidator(eventStatus, pid, cellDescription, objects, players)
    for _, object in pairs(objects) do
        if Methods.isQuestItem(object.refId) then
			local uniqueIndex = object.uniqueIndex
			local pName = tes3mp.GetName(pid)
			local data = Methods.data
			local itemName = questItems[object.refId]
			
			LoadedCells[cellDescription]:SaveObjectStates(pid)
			
			Methods.createJsonEntry(object.refId)
			
			if not data[object.refId][pName] then
				data[object.refId][pName] = true
				Methods.SaveData()
			else
				return customEventHooks.makeEventStatus(false, false)
			end
			
			doMessage(pid, "pickupSuccess", false, color.DodgerBlue .. itemName .. color.GoldenRod)
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
				local itemCount = tes3mp.GetContainerItemCount(containerIndex, itemIndex)

                if Methods.isQuestItem(itemRefId) and cell.data.objectData[uniqueIndex].refId ~= "kanabankcontainer" then
					local itemName = questItems[itemRefId]
					Methods.clearMerchantBlockVars(pid)
					
					Methods.addItemToPlayer(pid, itemRefId, itemCount)
					-- Players[pid]:SaveInventory()
					doMessage(pid, "unableDrop", false, color.DodgerBlue .. itemName .. color.GoldenRod)
                    cell:LoadContainers(pid, cell.data.objectData, {uniqueIndex})
                    return customEventHooks.makeEventStatus(false, false)
                end
            end
        end
    end
end

function Methods.OnObjectPlaceValidator(eventStatus, pid, cellDescription, objects) -- prevents player from placing quest item in the world

	tes3mp.ReadReceivedObjectList()

    for objectIndex = 0, tes3mp.GetObjectListSize() - 1 do

		local itemRefId = tes3mp.GetObjectRefId(objectIndex)
		local itemCount = tes3mp.GetObjectCount(objectIndex)
		
		if Methods.isQuestItem(itemRefId) then
			
			Methods.clearMerchantBlockVars(pid)
			
			local itemName = questItems[itemRefId]
		
			Methods.addItemToPlayer(pid, itemRefId, itemCount)
			-- Players[pid]:SaveInventory()
			
			doMessage(pid, "unableDrop", false, color.DodgerBlue .. itemName .. color.GoldenRod)
			
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
					doMessage(pid, "unableSell", false)
					Methods.blockSellMerchant[pid] = nil
				end
			else
				Methods.blockSellMerchant[pid] = nil
			end
		end
			
		
		if Methods.isQuestItem(itemRefId) and action == enumerations.inventory.REMOVE and Methods.lastActivatedMerchant[pid] ~= nil then
			Methods.blockSellMerchant[pid] = os.time()
			Methods.addItemToPlayer(pid, itemRefId, itemCount)
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

customCommandHooks.registerCommand(cmds[1], Methods.guiQuestItemList)
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
