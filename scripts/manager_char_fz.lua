local addInfoDBOriginal;

--todo remove this file?
function onInit()
	addInfoDBOriginal = CharManager.addInfoDB;
	CharManager.addInfoDB = addInfoDB
end

function addInfoDB(nodeChar, sClass, sRecord)
	local result = addInfoDBOriginal(sIdentity, draginfo);
	--todo stuff i need
	if nodeChar and not result then
		if sClass == "npc" then
		end
	end
	return result;
end