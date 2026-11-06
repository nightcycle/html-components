--!strict
-- Modules
local Release = require("../scripts/release/utils")
-- Variables
local count = 0
-- Private Functions
local function check(condition: boolean, message: string)
	assert(condition, message)
	count += 1
end
-- Class
for _, version in { "0.1.0", "v0.1.0" } do
	check(Release.version(version) == "0.1.0", "Version normalization")
	Release.validateTag("v0.1.0", version)
	Release.validateTag("0.1.0", version)
	check(not pcall(Release.validateTag, "v0.2.0", version), "Mismatched version must fail")
end
check(table.concat(Release.tags("0.1.0"), ",") == "0.1.0,v0.1.0", "Prefer requested bare tag")
check(table.concat(Release.tags("v0.1.0"), ",") == "v0.1.0,0.1.0", "Prefer requested prefixed tag")
for _, invalid in { "01.2.3", "v01.2.3", "vv0.1.0", "0.1", "v0.1.0-beta", "0.1.0extra", "--help", "../v0.1.0" } do
	check(not pcall(Release.version, invalid), `Reject invalid version {invalid}`)
end
check(not Release.published(true, "Registry error"), "Exit code zero is not publication confirmation")
check(not Release.published(false, "Package published successfully!"), "A failed process cannot confirm publication")
check(Release.published(true, "Package published successfully!"), "Accept confirmed successful publication")
print(`{count} release validation checks passed.`)
