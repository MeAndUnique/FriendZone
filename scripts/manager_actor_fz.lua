-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local getActorRecordTypeFromPathOriginal;
local getSaveOriginal;
local getCheckOriginal;
local getDefenseValueOriginal;

function onInit()
	getActorRecordTypeFromPathOriginal = ActorManager.getActorRecordTypeFromPath;
	ActorManager.getActorRecordTypeFromPath = getActorRecordTypeFromPath;

	getSaveOriginal = ActorManager5E.getSave;
	ActorManager5E.getSave = getSave;

	getCheckOriginal = ActorManager5E.getCheck;
	ActorManager5E.getCheck = getCheck;

	getDefenseValueOriginal = ActorManager5E.getDefenseValue;
	ActorManager5E.getDefenseValue = getDefenseValue;
end

function getActorRecordTypeFromPath(sActorNodePath)
	local result = getActorRecordTypeFromPathOriginal(sActorNodePath);
	if (not result) or (result == "charsheet") then
		if sActorNodePath:match("%.cohorts%.") then
			result = "npc";
		elseif sActorNodePath:match("%.units%.") then
			result = "unit";
		end
	end
	return result;
end

function getSave(rActor, sSave)
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return 0, false, false, "";
	end

	local nMod, bADV, bDIS, sAddText = getSaveOriginal(rActor, sSave);
	if sNodeType ~= "pc" and FriendZone.isCohort(rActor) then
		local sSaves = DB.getValue(nodeActor, "savingthrows", "");
		if sSaves:lower():match(sSave:sub(1,3):lower() .. "[^,]+%+ ?pb") or hasProfBonusTrait(nodeActor, "saving throw") then
			local nodeCommander = FriendZone.getCommanderNode(rActor);
			local nProfBonus = DB.getValue(nodeCommander, "profbonus", 0);
			nMod = nMod + nProfBonus;
		end
	end

	return nMod, bADV, bDIS, sAddText;
end

function getCheck(rActor, sCheck, sSkill)
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if not nodeActor then
		return 0, false, false, "";
	end

	local nMod, bADV, bDIS, sAddText = getCheckOriginal(rActor, sCheck, sSkill);
	if sNodeType ~= "pc" and FriendZone.isCohort(rActor) and hasProfBonusTrait(nodeActor, "ability check") then
		local nodeCommander = FriendZone.getCommanderNode(rActor);
		local nProfBonus = DB.getValue(nodeCommander, "profbonus", 0);
		nMod = nMod + nProfBonus;
	end

	return nMod, bADV, bDIS, sAddText;
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

function hasProfBonusTrait(nodeCohort, sType)
	for _,nodeTrait in pairs(DB.getChildren(nodeCohort, "traits")) do
		local sDesc = DB.getValue(nodeTrait, "desc", "");
		if sDesc:match("You can add your proficiency bonus to any .*" .. sType .. ".* makes.") then
			return true;
		end
	end
end