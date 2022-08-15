-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local showTurnMessageOriginal;
local centerOnTokenOriginal;
local onNPCPostAddOriginal;
local onVehiclePostAddOriginal;
local addUnitOriginal;

function onInit()
	showTurnMessageOriginal = CombatManager.showTurnMessage;
	CombatManager.showTurnMessage = showTurnMessage;

	centerOnTokenOriginal = CombatManager.centerOnToken;
	CombatManager.centerOnToken = centerOnToken;

	onNPCPostAddOriginal = CombatRecordManager.getRecordTypePostAddCallback("npc");
	CombatRecordManager.setRecordTypePostAddCallback("npc", onNPCPostAdd);

	onVehiclePostAddOriginal = CombatRecordManager.getRecordTypePostAddCallback("vehicle");
	CombatRecordManager.setRecordTypePostAddCallback("vehicle", onVehiclePostAdd);

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

function onNPCPostAdd(tCustom)
	onNPCPostAddOriginal(tCustom);
	trySetCohortLinkAndFaction(tCustom);
end

function onVehiclePostAdd(tCustom)
	onVehiclePostAddOriginal(tCustom);
	trySetCohortLinkAndFaction(tCustom);
end

function addUnit(tCustom)
	addUnitOriginal(tCustom);
	trySetCohortLinkAndFaction(tCustom);
end

function trySetCohortLinkAndFaction(tCustom)
	local bIsCohort = FriendZone.isCohort(tCustom.nodeRecord);
	if tCustom.nodeCT and bIsCohort then
		local sClass = tCustom.sClass or LibraryData.getRecordDisplayClass(tCustom.sRecordType);
		local nodeCommander = FriendZone.getCommanderNode(tCustom.nodeRecord);
		local sFaction = ActorManager.getFaction(nodeCommander);
		DB.setValue(tCustom.nodeCT, "link", "windowreference", sClass, tCustom.nodeRecord.getPath());
		DB.setValue(tCustom.nodeCT, "friendfoe", "string", sFaction);
	end
end