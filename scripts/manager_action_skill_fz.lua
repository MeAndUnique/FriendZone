-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local performNPCRollOriginal;

local nCommanderProfBonus = 0;

function onInit()
	performNPCRollOriginal = ActionSkill.performNPCRoll;
	ActionSkill.performNPCRoll = performNPCRoll;

	if CombatManagerKw then
		addUnitOriginal = CombatManagerKw.addUnit;
		CombatManagerKw.addUnit = addUnit;
	end
end

function setCommanderProfBonus(nProfBonus)
	nCommanderProfBonus = nProfBonus;
end

function performNPCRoll(draginfo, rActor, sSkill, nSkill)
	nSkill = nSkill + nCommanderProfBonus;
	performNPCRollOriginal(draginfo, rActor, sSkill, nSkill);
	nCommanderProfBonus = 0;
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