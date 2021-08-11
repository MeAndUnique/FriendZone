local getActorRecordTypeFromPathOriginal;

function onInit()
	getActorRecordTypeFromPathOriginal = ActorManager.getActorRecordTypeFromPath;
	ActorManager.getActorRecordTypeFromPath = getActorRecordTypeFromPath;
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