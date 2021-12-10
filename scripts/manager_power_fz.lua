-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local parseNPCPowerOriginal;
local parsePowerOriginal;

local nodeCohort;

local ENCODING_TYPE_BASE = 10000;
local ENCODING_OFFSET_BASE = 100;
local ADD_PROFICIENCY_ENCODING = 1;
local COMMANDER_GROUP_ENCODING = 2;
local MULTIPLY_PROFICIENCY_ENCODING = 3;
local DICE_PROFICIENCY_ENCODING = 4;

function onInit()
	--todo trigger reparsing (maybe needs to be in npc_main)
	parseNPCPowerOriginal = PowerManager.parseNPCPower;
	PowerManager.parseNPCPower = parseNPCPower;

	parsePowerOriginal = PowerManager.parsePower;
	PowerManager.parsePower = parsePower;
end

function parseNPCPower(nodePower, bAllowSpellDataOverride)
	local nodeNPC = nodePower.getChild("...");
	if FriendZone.isCohort(nodeNPC) then
		nodeCohort = nodeNPC;
	end
	return parseNPCPowerOriginal(nodePower, bAllowSpellDataOverride)
end

function parsePower(sPowerName, sPowerDesc, bPC, bMagic)
	if nodeCohort then
		sPowerDesc = sPowerDesc:gsub("[%+%-]%d+ %+ ?PB", encodeNumericAddition);
		sPowerDesc = sPowerDesc:gsub("%d+d%d+ %+ ?PB", encodeDiceAddition);
		sPowerDesc = sPowerDesc:gsub("a DC %d+ [p%+]l?u?s? ?PB", encodeNumericReplacement);
		sPowerDesc = sPowerDesc:gsub("DC Player", encodeDcPlayerReplacement);
		sPowerDesc = sPowerDesc:gsub("your .+ attack modifier", encodeAttackModifierReplacement);
		sPowerDesc = sPowerDesc:gsub("extra PB ?%w* damage", encodeExtraDamage);
		sPowerDesc = sPowerDesc:gsub("takes PB ?%w* damage", encodeExtraDamage);
		sPowerDesc = sPowerDesc:gsub("%d+ times PB", encodeNumericMultiplication);
		sPowerDesc = sPowerDesc:gsub("PBd%d+", encodeDiceMultiplication);
	end

	local aMasterAbilities = parsePowerOriginal(sPowerName, sPowerDesc, bPC, bMagic)

	if nodeCohort then
		local nodeCommander = FriendZone.getCommanderNode(nodeCohort);

		local nOffset = 0;
		for _,rAbility in ipairs(aMasterAbilities) do
			rAbility.startpos = rAbility.startpos + nOffset;

			if rAbility.type == "attack" then
				nOffset = nOffset + postProcessAttack(rAbility, nodeCohort, nodeCommander);
			elseif rAbility.type == "damage" or  rAbility.type == "heal" then
				nOffset = nOffset + postProcessDamageAndHeal(rAbility, nodeCohort, nodeCommander);
			elseif rAbility.type == "powersave" then
				nOffset = nOffset + postProcessSave(rAbility, nodeCohort, nodeCommander);
			elseif rAbility.type == "effect" then
				nOffset = nOffset + postProcessEffect(rAbility, nodeCohort, nodeCommander);
			end

			rAbility.endpos = rAbility.endpos + nOffset;
		end
		
		nodeCohort = nil;
	end

	return aMasterAbilities
end

function encodeNumericAddition(sMatch)
	local nMod = tonumber(sMatch:match("^[%+%-]%d+"));
	local bNegative = nMod < 0;
	if bNegative then
		nMod = -nMod;
	end
	local nLengthDiff = sMatch:len() - 6;
	nMod = nMod + ADD_PROFICIENCY_ENCODING * ENCODING_TYPE_BASE; -- Encode the fact that a swap has been made
	nMod = nMod + ENCODING_OFFSET_BASE * nLengthDiff; -- Encode the offset difference
	local sPrefix = "+";
	if bNegative then
		sPrefix = "-";
	end
	return sPrefix .. nMod;
end

function encodeDiceAddition(sMatch)
	local sDice = sMatch:match("^%d+d%d+");
	local nProfBonusStringLength = sMatch:len() - sDice:len() - 1;
	local nLengthDiff = nProfBonusStringLength - 6;
	local nMod = (ADD_PROFICIENCY_ENCODING + 1) * ENCODING_TYPE_BASE; -- add 1 because the offset difference will always be negative
	nMod = nMod + ENCODING_OFFSET_BASE * nLengthDiff; -- Encode the offset difference
	return sDice .. " +" .. nMod;
end

function encodeNumericReplacement(sMatch)
	local nMod = tonumber(sMatch:match("^a DC (%d+)"));
	local nLengthDiff = sMatch:len() - 5 - 5;

	nMod = nMod + ADD_PROFICIENCY_ENCODING * ENCODING_TYPE_BASE; -- Encode the fact that a swap has been made
	nMod = nMod + ENCODING_OFFSET_BASE * nLengthDiff; -- Encode the offset difference

	return "a DC " .. nMod;
end

function encodeDcPlayerReplacement(sMatch)
	return "DC " .. (COMMANDER_GROUP_ENCODING * ENCODING_TYPE_BASE) + (1 * ENCODING_OFFSET_BASE);
end

function encodeAttackModifierReplacement(sMatch)
	local nLengthDiff = sMatch:len() - 6;
	local nMod = COMMANDER_GROUP_ENCODING * ENCODING_TYPE_BASE; -- Encode the fact that a swap has been made
	nMod = nMod + ENCODING_OFFSET_BASE * nLengthDiff; -- Encode the offset difference
	return "+" .. nMod;
end

function encodeExtraDamage(sMatch)
	return sMatch:gsub("PB", tostring((ADD_PROFICIENCY_ENCODING * ENCODING_TYPE_BASE) + ((ENCODING_OFFSET_BASE - 3) * ENCODING_OFFSET_BASE)));
end

function encodeNumericMultiplication(sMatch)
	local nMod = tonumber(sMatch:match("^(%d+)"));
	local nLengthDiff = sMatch:len() - 5;

	nMod = nMod + MULTIPLY_PROFICIENCY_ENCODING * ENCODING_TYPE_BASE; -- Encode the fact that a swap has been made
	nMod = nMod + ENCODING_OFFSET_BASE * nLengthDiff; -- Encode the offset difference

	return tostring(nMod);
end

function encodeDiceMultiplication(sMatch)
	local nMod = tonumber(sMatch:match("%d+$"));
	local nLengthDiff = sMatch:len() - 5;

	nMod = nMod + DICE_PROFICIENCY_ENCODING * ENCODING_TYPE_BASE; -- Encode the fact that a swap has been made
	nMod = nMod + ENCODING_OFFSET_BASE * nLengthDiff; -- Encode the offset difference

	return tostring(nMod);
end

function postProcessAttack(rAttack, nodeCohort, nodeCommander)
	local nType = 0;
	local nOffset = 0;
	nType, nOffset, rAttack.modifier = decodeMetadata(rAttack.modifier);

	if nType == ADD_PROFICIENCY_ENCODING then
		local nProfBonus = DB.getValue(nodeCommander, "profbonus", 0);
		rAttack.modifier = rAttack.modifier + nProfBonus;
	elseif nType == COMMANDER_GROUP_ENCODING then
		local nodePowerGroup = findCommanderPowerGroup(nodeCohort, nodeCommander);
		if nodePowerGroup then
			rAttack.modifier = calculateCommanderGroupAttackModifier(nodePowerGroup, nodeCommander);
		end
	end

	return nOffset;
end

function postProcessDamageAndHeal(rDamage, nodeCohort, nodeCommander)
	local nType = 0;
	local nOffset = 0;
	local nProfBonus = DB.getValue(nodeCommander, "profbonus", 0);
	for _, rClause in ipairs(rDamage.clauses) do
		local nClauseOffset = 0;
		nType, nClauseOffset, rClause.modifier = decodeMetadata(rClause.modifier);
		nOffset = nOffset + nClauseOffset;

		if nType == ADD_PROFICIENCY_ENCODING then
			rClause.modifier = rClause.modifier + nProfBonus;
		elseif nType == MULTIPLY_PROFICIENCY_ENCODING then
				rClause.modifier = rClause.modifier * nProfBonus;
		elseif nType == DICE_PROFICIENCY_ENCODING then
			rClause.dice = {};
			for nCount=1,nProfBonus do
				table.insert(rClause.dice, "d" .. rClause.modifier);
			end
			rClause.modifier = 0;
		end
	end
	return nOffset
end

function postProcessSave(rSave, nodeCohort, nodeCommander)
	local nType = 0;
	local nOffset = 0;
	nType, nOffset, rSave.savemod = decodeMetadata(rSave.savemod);

	if nType == ADD_PROFICIENCY_ENCODING then
		local nodePowerGroup = findCommanderPowerGroup(nodeCohort, nodeCommander);
		if nodePowerGroup then
			rSave.savemod = calculateCommanderGroupSaveDc(nodePowerGroup, nodeCommander);
		else
			local nProfBonus = DB.getValue(nodeCommander, "profbonus", 0);
			rSave.savemod = rSave.savemod + nProfBonus;
		end
	elseif nType == COMMANDER_GROUP_ENCODING then
		local nodePowerGroup = findCommanderPowerGroup(nodeCohort, nodeCommander);
		if nodePowerGroup then
			rSave.savemod = calculateCommanderGroupSaveDc(nodePowerGroup, nodeCommander);
		end
	end

	return nOffset;
end

function postProcessEffect(rEffect, nodeCohort, nodeCommander)
	local nOffset = 0;
	local sEncodedDamage = rEffect.sName:match("DMG: (%d%d%d%d%d)");
	if sEncodedDamage then
		local nType, nValue;
		nType, nOffset, nValue = decodeMetadata(tonumber(sEncodedDamage));
		if nType == ADD_PROFICIENCY_ENCODING then
			local nProfBonus = DB.getValue(nodeCommander, "profbonus", 0);
			rEffect.sName = rEffect.sName:gsub(sEncodedDamage, tostring(nValue + nProfBonus));
		end
	end
	return nOffset;
end

function decodeMetadata(nValue)
	local nType = 0;
	local nOffset = 0;
	local bNegative = false;
	local nEncoding = nValue;
	if nEncoding <= -ENCODING_TYPE_BASE then
		bNegative = true;
		nEncoding = -nEncoding;
	end
	if nEncoding >= ENCODING_TYPE_BASE then
		nValue = (nEncoding % ENCODING_OFFSET_BASE);
		nEncoding = nEncoding - nValue;

		nOffset = nEncoding % ENCODING_TYPE_BASE;
		nType = nEncoding - nOffset;
		nType = nType / ENCODING_TYPE_BASE;

		nOffset = nOffset / ENCODING_OFFSET_BASE;
		if nOffset > (ENCODING_OFFSET_BASE / 2) then
			nOffset = nOffset - ENCODING_OFFSET_BASE;
		end

		if bNegative then
			nValue = -nValue;
		end
	end
	return nType, nOffset, nValue;
end

function findCommanderPowerGroup(nodeCohort, nodeCommander)
	local sText = DB.getValue(nodeCohort, "text", "");
	local aLines = StringManager.splitByPattern(sText, "<p>", true);
	for _,sLine in ipairs(aLines) do
		sLine = sLine:gsub("</?%w>", ""):lower();
		local sClass, sGroup;
		if StringManager.startsWith(sLine, "saving throw dcs:") then
			sClass, sGroup = sLine:lower():match("replace the dc with the (%w+)%'?s? (.+) save dc");
		elseif StringManager.startsWith(sLine, "features:") then
			sClass, sGroup = sLine:lower():match("to reflect the (%w+)%'?s? (.+) save dc");
		elseif StringManager.startsWith(sLine, "actions:") then
			sClass, sGroup = sLine:lower():match("with the (%w+)%'?s? actual (.+) attack modifier");
		end

		if sClass and sGroup then
			local bFoundClass = false;
			for _,nodeClass in pairs(DB.getChildren(nodeCommander, "classes")) do
				if DB.getValue(nodeClass, "name", ""):lower() == sClass then
					bFoundClass = true;
					break;
				end
			end
			if not bFoundClass then
				return nil;
			end
			
			local nodeMatch = nil;
			for _,nodeGroup in pairs(DB.getChildren(nodeCommander, "powergroup")) do
				local sName = DB.getValue(nodeGroup, "name", ""):lower();
				if sName:match("^" .. sGroup .. "s? %(" .. sClass .. "%)$") then
					return nodeGroup;
				elseif sName:match("^" .. sGroup .. "s?$") then
					nodeMatch = nodeGroup;
				end
			end
			return nodeMatch;
		end
	end
end

function calculateCommanderGroupSaveDc(nodePowerGroup, nodeCommander)
	local rCommander ActorManager.resolveActor(nodeCommander);
	local sSaveDCStat = DB.getValue(nodePowerGroup, "savestat", "");
	if sSaveDCStat == "" then
		sSaveDCStat = DB.getValue(nodePowerGroup, "stat", "");
	end

	local nDC = 8 + DB.getValue(nodePowerGroup, "savemod", 0);
	if (sSaveDCStat or "") ~= "" then
		nDC = nDC + ActorManager5E.getAbilityBonus(nodeCommander, sSaveDCStat);
	end
	if DB.getValue(nodePowerGroup, "saveprof", 1) == 1 then
		nDC = nDC + ActorManager5E.getAbilityBonus(nodeCommander, "prf");
	end
	return nDC;
end

function calculateCommanderGroupAttackModifier(nodePowerGroup, nodeCommander)
	local rCommander ActorManager.resolveActor(nodeCommander);
	local sAttackStat = DB.getValue(nodePowerGroup, "atkstat", "");
	if sAttackStat == "" then
		sAttackStat = DB.getValue(nodePowerGroup, "stat", "");
	end

	local nModifier = DB.getValue(nodePowerGroup, "atkmod", 0);
	if (sAttackStat or "") ~= "" then
		nModifier = nModifier + ActorManager5E.getAbilityBonus(nodeCommander, sAttackStat);
	end
	if DB.getValue(nodePowerGroup, "atkprof", 1) == 1 then
		nModifier = nModifier + ActorManager5E.getAbilityBonus(nodeCommander, "prf");
	end
	return nModifier;
end