ShuttleSettings = {}

local ShuttleSettings_mt = Class(ShuttleSettings)

function ShuttleSettings:new(mission, missionInfo, missionDynamicInfo, baseDirectory, modName, modsSettingsPath, i18n, gui, gameSettings, depthOfFieldManager, mpLoadingScreen, shopConfigScreen, mapManager)
    local self = setmetatable({}, ShuttleSettings_mt)
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
	self.modsSettingsPath = modsSettingsPath

	self.uiFilename = Utils.getFilename("resources/guidanceSteering_1080p.png", baseDirectory)

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
		inGameMenu:addPageTab(pageShuttleSettings, self.uiFilename, getNormalizedUVs({0, 0, 65, 65}))
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
		globalTexts[name] = text
	end
end

function ShuttleSettings:loadMap(filename)
	local pageShuttleSettings = self.currentMission.inGameMenu.pageShuttleSettings
	if pageShuttleSettings ~= nil then
		pageShuttleSettings:initialize(self)
	end

end

function ShuttleSettings:onMissionStarted()
	self:loadSettingsFromXMLFile()
end

function ShuttleSettings:deleteMap()

end

function ShuttleSettings:loadSettingsFromXMLFile(loadingState)
	local filename = self.modsSettingsPath .. "/shuttleDriveSettings.xml"

	if fileExists(filename) then
		local xmlFile = loadXMLFile("shuttleDriveSettings", filename)
		if xmlFile ~= nil then
			local active = getXMLBool(xmlFile, "shuttleDriveSettings.active")
			if active ~= nil and self.shuttleSettings.active.active ~= active then
				self.shuttleSettings.active.active = active
			end
			delete(xmlFile)
		end
	end
end

function ShuttleSettings:saveSettingsToXMLFile()
	local xmlFile = createXMLFile("shuttleDriveSettings", self.modsSettingsPath .. "/shuttleDriveSettings.xml", "shuttleDriveSettings")

	if xmlFile ~= nil then
		setXMLBool(xmlFile, "shuttleDriveSettings.active" , self.shuttleSettings.active.active)

		saveXMLFile(xmlFile)
		delete(xmlFile)
	end
end