local addNPCHelperOriginal;
local addUnitOriginal;

function onInit()
	addNPCHelperOriginal = CombatManager.addNPCHelper;
	CombatManager.addNPCHelper = addNPCHelper;

	if CombatManagerKw then
		addUnitOriginal = CombatManagerKw.addUnit;
		CombatManagerKw.addUnit = addUnit;
	end
end

function addNPCHelper(nodeNPC, sName)
	local bIsCohort = FriendZone.isCohort(nodeNPC);
	local nodeEntry, nodeLastMatch = addNPCHelperOriginal(nodeNPC, sName);
	if nodeEntry and bIsCohort then
		DB.setValue(nodeEntry, "link", "windowreference", "npc", nodeNPC.getPath());
		DB.setValue(nodeEntry, "friendfoe", "string", "friend");
	end
	return nodeEntry, nodeLastMatch;
end

function addUnit(sClass, nodeUnit, sName)
	local nodeEntry = addUnitOriginal(sClass, nodeUnit, sName);
	if nodeEntry then
		local bIsCohort = FriendZone.isCohort(nodeUnit);
		if bIsCohort then
			DB.setValue(nodeEntry, "link", "windowreference", "reference_unit", nodeUnit.getPath());
			DB.setValue(nodeEntry, "friendfoe", "string", "friend");
		end
	end

	return nodeEntry;
end