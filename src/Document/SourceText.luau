--!strict
-- Packages
-- Modules
local Types = require(script.Parent.Parent.Types)
-- Types
export type Report = (Types.DocumentSeverity, Types.DocumentIssue, string, number) -> ()
export type Source = { Text: string, Locate: (number) -> Types.SourceLocation, Report: Report }
-- Constants
-- References
-- Global Variables
-- Private Functions
-- Class
return function(text: string, diagnostics: { Types.DocumentDiagnostic }): Source
	local lines: { number } = { 1 }
	for position in text:gmatch("()[\r\n]") do
		-- Offsets stay in the original source even though token values normalize newlines.
		if text:sub(position, position) == "\n" or text:sub(position + 1, position + 1) ~= "\n" then
			table.insert(lines, position + 1)
		end
	end
	local function locate(offset: number): Types.SourceLocation
		offset = math.clamp(offset, 1, #text + 1)
		local low, high = 1, #lines
		while low < high do
			local middle = math.ceil((low + high) / 2)
			if lines[middle] <= offset then
				low = middle
			else
				high = middle - 1
			end
		end
		return { Offset = offset, Line = low, Column = offset - lines[low] + 1 }
	end
	return {
		Text = text,
		Locate = locate,
		Report = function(severity, issue, message, offset)
			if severity == "Error" and #diagnostics >= 100 then
				table.remove(diagnostics)
			end
			if #diagnostics < 100 then
				table.insert(
					diagnostics,
					{ Severity = severity, Issue = issue, Message = message, Location = locate(offset) }
				)
			end
		end,
	}
end
