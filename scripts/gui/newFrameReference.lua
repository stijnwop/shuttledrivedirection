NewFrameReference = {}

local NewFrameReference_mt = Class(NewFrameReference, TabbedMenuFrameElement)

NewFrameReference.CONTROLS = {
	PAGE_ADDITIONAL_SETTINGS = "pageShuttleSettings",
}

function NewFrameReference:new(subclass_mt)
	local self = TabbedMenuFrameElement:new(nil, subclass_mt or NewFrameReference_mt)

	self:registerControls(NewFrameReference.CONTROLS)

	return self
end