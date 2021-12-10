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