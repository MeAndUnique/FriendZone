--
-- Please see the license.txt file included with this distribution fo
-- attribution and copyright information.
--

function update()
	local bEdit = (window.parentcontrol.window.cohorts_iedit.getValue() == 1);
	for _,w in ipairs(getWindows()) do
		w.idelete.setVisibility(bEdit);
	end
end

function addEntry(bFocus)
	local w = createWindow();
	if bFocus then
		w.name.setFocus();
	end
	return w;
end
