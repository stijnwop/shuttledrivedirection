

ShuttleSettingFrame = {
    CONTROLS = {
        SETTINGS_CONTAINER = "settingsContainer",
        BOX_LAYOUT = "boxLayout",
        HELP_BOX = "shuttleSettingsHelpBox",
		HELP_BOX_TEXT = "shuttleSettingsHelpBoxText",
		CHECKBOX_ACTIVE = "checkActive",
    }
}

local shuttleSettingFrame_mt = Class(ShuttleSettingFrame, TabbedMenuFrameElement)

function ShuttleSettingFrame:new(subclass_mt, l10n)
	local subclass_mt = subclass_mt or shuttleSettingFrame_mt
	local self = TabbedMenuFrameElement:new(nil, subclass_mt or shuttleSettingFrame_mt)

	self:registerControls(ShuttleSettingFrame.CONTROLS)

	self.l10n = l10n
	self.isDirty = false
	self.hasCustomMenuButtons = true
	
	self.checkboxMapping = {}

	return self
end

function ShuttleSettingFrame:getMainElementSize()
	return self.settingsContainer.size
end

function ShuttleSettingFrame:getMainElementPosition()
	return self.settingsContainer.absPosition
end

function ShuttleSettingFrame:onFrameOpen(element)
	ShuttleSettingFrame:superClass().onFrameOpen(self)

	self:updateShuttleSettings()
	self.isDirty = false

	self.boxLayout:invalidateLayout()
	FocusManager:setFocus(self.boxLayout)
end

function ShuttleSettingFrame:onFrameClose()
	ShuttleSettingFrame:superClass().onFrameClose(self)

	--self:saveSettingsToXMLFile()
end

function ShuttleSettingFrame:onGuiSetupFinished()
	ShuttleSettingFrame:superClass().onGuiSetupFinished(self)
end

function ShuttleSettingFrame:copyAttributes(src)
	ShuttleSettingFrame:superClass().copyAttributes(self, src)

	self.l10n = src.l10n
end

function ShuttleSettingFrame:initialize(settings)
	print("initializing shuttleSettingFrame")
	local shuttleSettings = settings.shuttleSettings
	
	self.checkboxMapping[self.checkActive] = shuttleSettings.active

	self.settings = settings;

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}

	self:updateButtons();

end

function ShuttleSettingFrame:updateButtons()
	self.menuButtonInfo = {
		self.backButtonInfo
	}

	self:setMenuButtonInfoDirty()
end

-- function ShuttleSettingFrame:saveSettingsToXMLFile()
-- 	if self.isDirty then
-- 		self.settings:saveSettingsToXMLFile(g_modsSettingsPath)
-- 		self.isDirty = false
-- 	end
-- end

function ShuttleSettingFrame:updateShuttleSettings()
	for element, settingsKey in pairs(self.checkboxMapping) do
		self.settings.callFunction("update", settingsKey, element)
		element:setIsChecked(settingsKey.active)
	end
end

function ShuttleSettingFrame:updateToolTipBoxVisibility()
	local hasText = self.shuttleSettingsHelpBoxText.text ~= nil and self.shuttleSettingsHelpBoxText.text ~= ""

	self.shuttleSettingsHelpBox:setVisible(hasText)
end

function ShuttleSettingFrame:onToolTipBoxTextChanged(element, text)
	self:updateToolTipBoxVisibility()
end

function ShuttleSettingFrame:onClickCheckbox(state, checkboxElement)
	local checkboxMapping = self.checkboxMapping[checkboxElement]

	if checkboxMapping ~= nil then
		local newState = state == CheckedOptionElement.STATE_CHECKED

		checkboxMapping.active = newState
		self.settings.callFunction("callback", checkboxMapping, newState, checkboxElement)

		self.isDirty = true
	else
		print("Warning: Invalid settings checkbox event or key configuration for element " .. checkboxElement:toString())
	end
end