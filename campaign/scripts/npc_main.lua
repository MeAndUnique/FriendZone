-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local canHandleExtraHealthFieldsOriginal;

function onInit()
	--todo trigger reparsing?
	canHandleExtraHealthFieldsOriginal = super.canHandleExtraHealthFields;
	super.canHandleExtraHealthFields = canHandleExtraHealthFields;

	super.onInit();
end

function canHandleExtraHealthFields()
	if not canHandleExtraHealthFieldsOriginal() then
		return FriendZone.isCohort(getDatabaseNode());
	end
	return true;
end