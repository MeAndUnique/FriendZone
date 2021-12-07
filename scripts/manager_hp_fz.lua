-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local getNpcHitDiceOriginal;

function onInit()
	getNpcHitDiceOriginal = HpManager.getNpcHitDice;
	HpManager.getNpcHitDice = getNpcHitDice;
end

function getNpcHitDice(nodeNPC)
	local sHD = StringManager.trim(DB.getValue(nodeNPC, "hd", ""));
	if sHD == "(see notes)" and FriendZone.isCohort(nodeNPC) then
		local sText = DB.getValue(nodeNPC, "text", "");
		local aLines = StringManager.splitByPattern(sText, "<p>", true);
		for _,sLine in ipairs(aLines) do
			sLine = sLine:gsub("</?%w>", ""):lower();
			if StringManager.startsWith(sLine, "hit dice:") then
				local nodeCommander = FriendZone.getCommanderNode(nodeNPC);
				local nHDMult, nHDSides;
				if nodeCommander then
					local sClass = sLine:match("([%w]+)%'?s? level");
					if StringManager.contains(DataCommon.classes, sClass) then
						nHDMult = ActorManager5E.getClassLevel(nodeCommander, sClass);
					else
						nHDMult = DB.getValue(nodeCommander, "level", 0);
					end

					local sSides = sLine:match("d(%d+)");
					if sSides then
						nHDSides = tonumber(sSides)
					end
				end

				return nHDMult, nHDSides;
			end
		end
	else
		return getNpcHitDiceOriginal(nodeNPC);
	end
end

function updateNpcHitPoints(nodeNPC)
	local sHD = StringManager.trim(DB.getValue(nodeNPC, "hd", ""));
	if sHD == "(see notes)" and FriendZone.isCohort(nodeNPC) then
		local nodeCommander = FriendZone.getCommanderNode(nodeNPC);
		if nodeCommander then
			local sText = DB.getValue(nodeNPC, "text", "");
			local aLines = StringManager.splitByPattern(sText, "<p>", true);
			for _,sLine in ipairs(aLines) do
				sLine = sLine:gsub("</?%w>", ""):lower();
				if StringManager.startsWith(sLine, "hit points:") then
					local sClass = sLine:match("([%w]+)%'?s? level");
					local nLevels;
					if StringManager.contains(DataCommon.classes, sClass) then
						nLevels = ActorManager5E.getClassLevel(nodeCommander, sClass);
					else
						nLevels = DB.getValue(nodeCommander, "level", 0);
					end

					local nMod, nPerLevel;
					local sMod, sPerLevel = sLine:match("(%d?%d?) ?%+? ?(%d+) times the");
					if sMod then
						nMod = tonumber(sMod);
					end
					if sPerLevel then
						nPerLevel = tonumber(sPerLevel);
						local nHP = nMod + (nPerLevel * nLevels);
						DB.setValue(nodeNPC, "hp", "number", nHP);
						break;
					end
				end
			end
		end
	end
end