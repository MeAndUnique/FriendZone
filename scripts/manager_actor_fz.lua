-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local getActorRecordTypeFromPathOriginal;
local getDefenseValueOriginal;

function onInit()
	getActorRecordTypeFromPathOriginal = ActorManager.getActorRecordTypeFromPath;
	ActorManager.getActorRecordTypeFromPath = getActorRecordTypeFromPath;
	
	getDefenseValueOriginal = ActorManager5E.getDefenseValue;
	ActorManager5E.getDefenseValue = getDefenseValue;
end

function getActorRecordTypeFromPath(sActorNodePath)
	local result = getActorRecordTypeFromPathOriginal(sActorNodePath);
	if result == "charsheet" then
		if sActorNodePath:match("%.cohorts%.") then
			result = "npc";
		elseif sActorNodePath:match("%.units%.") then
			result = "unit";
		end
	end
	return result;
end

function getDefenseValue(rAttacker, rDefender, rRoll)
	local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus, bADV, bDIS = getDefenseValueOriginal(rAttacker, rDefender, rRoll);

	if FriendZone.isCohort(rDefender) then
		local sAcText = DB.getValue(ActorManager.getCreatureNode(rDefender), "actext", "");
		if sAcText:gmatch("+ ?PB") then
			local nodeCommander = FriendZone.getCommanderNode(rDefender);
			local nProfBonus = DB.getValue(nodeCommander, "profbonus", 0);
			if nProfbonus == 0 then
				local sCR = DB.getValue(nodeCommander, "cr");
				if StringManager.isNumber(sCR) then
					nProfBonus = math.max(2, math.floor((tonumber(sCR) - 1) / 4) + 2);
				end
			end
			nDefenseVal = nDefenseVal + nProfBonus;
		end
	end

	return nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus, bADV, bDIS;
end