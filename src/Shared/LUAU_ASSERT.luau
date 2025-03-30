local DebugFlags = require("@Shared/DebugFlags")

return if DebugFlags.AssertEnabled then assert else function() end :: never