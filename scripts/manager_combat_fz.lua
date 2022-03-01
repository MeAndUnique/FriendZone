-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local showTurnMessageOriginal;
local centerOnTokenOriginal;
local addNPCHelperOriginal;
local addUnitOriginal;

function onInit()
	showTurnMessageOriginal = CombatManager.showTurnMessage;
	CombatManager.showTurnMessage = showTurnMessage;

	centerOnTokenOriginal = CombatManager.centerOnToken;
	CombatManager.centerOnToken = centerOnToken;

	addNPCHelperOriginal = CombatManager.addNPCHelper;
	CombatManager.addNPCHelper = addNPCHelper;

	if CombatManagerKw then
		addUnitOriginal = CombatManagerKw.addUnit;
		CombatManagerKw.addUnit = addUnit;
	end
end

function showTurnMessage(nodeEntry, bActivate, bSkipBell)
	showTurnMessageOriginal(nodeEntry, bActivate, bSkipBell);

	local sClass, sRecord = DB.getValue(nodeEntry, "link", "", "");
	local bHidden = CombatManager.isCTHidden(nodeEntry);
	if not bHidden and (sClass ~= "charsheet") then -- Allow non-character sheet turns as well for the sake of cohorts.
		if bActivate and not bSkipBell and OptionsManager.isOption("RING", "on") then
			if sRecord ~= "" then
				local nodeCohort = DB.findNode(sRecord);
				if nodeCohort then
					local sOwner = nodeCohort.getOwner();
					if sOwner then
						User.ringBell(sOwner);
					end
				end
			end
		end
	end
end

function centerOnToken(nodeEntry, bOpen)
	centerOnTokenOriginal(nodeEntry, bOpen);

	if not Session.IsHost and
	FriendZone.isCohort(nodeEntry) and
	DB.isOwner(ActorManager.getCreatureNode(nodeEntry)) then
		ImageManager.centerOnToken(CombatManager.getTokenFromCT(nodeEntry), bOpen);
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