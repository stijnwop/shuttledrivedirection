ShuttleSettings = {}

local ShuttleSettings_mt = Class(ShuttleSettings)

function ShuttleSettings:new(mission, missionInfo, missionDynamicInfo, baseDirectory, modName, i18n, gui, gameSettings, depthOfFieldManager, mpLoadingScreen, shopConfigScreen, mapManager)
    local self = setmetatable({}, ShuttleSettings_mt)
	print("shuttleSettings new")
	addModEventListener(self)
	mission:registerObjectToCallOnMissionStart(self)

	self.currentMission = mission
	self.i18n = i18n
	self.gui = gui
	self.gameSettings = gameSettings
	self.depthOfFieldManager = depthOfFieldManager
	self.mpLoadingScreen = mpLoadingScreen
	self.shopConfigScreen = shopConfigScreen
	self.mapManager = mapManager
	self.baseDirectory = baseDirectory

    self.shuttleSettings = self:createSettings();

	self:copyModEnvironmentTexts(true)
    self:addPage()

	return self

end

function ShuttleSettings:addPage()
	local shuttleSettingFrame = ShuttleSettingFrame:new(nil, self.i18n)
	local newFrameReference = NewFrameReference:new(nil)
	
	self.gui:loadGui(Utils.getFilename("xml/gui/ShuttleSettingFrame.xml", self.baseDirectory), "ShuttleSettingFrame", shuttleSettingFrame, true)
	self.gui:loadGui(Utils.getFilename("xml/gui/newFrameReference.xml", self.baseDirectory), "NewSettings", newFrameReference)
	
	local inGameMenu = self.currentMission.inGameMenu
	local pageShuttleSettings = newFrameReference.pageShuttleSettings

	if pageShuttleSettings ~= nil then
		local position = inGameMenu.pagingElement:getPageIndexByElement(inGameMenu.pageSettingsGeneral) + 1

		inGameMenu.pagingElement.addPage = Utils.overwrittenFunction(inGameMenu.pagingElement.addPage, function(object, superFunc, id, element, title, index)
			if element.name == "ingameMenuShuttleSettings" then
				index = position
			end

			return superFunc(object, id, element, title, index)
		end)

		inGameMenu.pagingElement:addElement(pageShuttleSettings)
		inGameMenu:registerPage(pageShuttleSettings, position, inGameMenu:makeIsGeneralSettingsEnabledPredicate())
		inGameMenu:addPageTab(pageShuttleSettings, g_baseUIFilename, getNormalizedUVs({390, 144, 65, 65}))
		inGameMenu.pageShuttleSettings = pageShuttleSettings
	end
end

function ShuttleSettings:createSettings()
    local settings = {
        active = {
            active = true
        }
    }
    
    for _, setting in pairs(settings) do
		self.callFunction("create", setting)
	end

	return settings
end

function ShuttleSettings.callFunction(funcName, object, ...)
	local func = object[funcName .. "Func"]

	if func ~= nil then
		if object.target ~= nil then
			if object.target ~= nil then
				func(object.target, object, ...)
			else
				func(object, ...)
			end
		end
	end
end

function ShuttleSettings:copyModEnvironmentTexts(add)
	local globalTexts = getfenv(0).g_i18n.texts

	for name, text in pairs(self.i18n.texts) do
		if not add then
			text = nil
		end
		print("name: " .. name .. " text: " .. text)
		globalTexts[name] = text
	end
end

function ShuttleSettings:loadMap(filename)
	print("Shuttle setting load map")
	local pageShuttleSettings = self.currentMission.inGameMenu.pageShuttleSettings
	if pageShuttleSettings ~= nil then
		pageShuttleSettings:initialize(self)
	end

end

function ShuttleSettings:onMissionStarted()
	print("ShuttleSettings Mission started")
end

function ShuttleSettings:deleteMap()

end