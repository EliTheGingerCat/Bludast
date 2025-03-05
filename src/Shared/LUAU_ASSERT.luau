local DebugFlags = require("@Shared/DebugFlags")

return (if DebugFlags.AssertEnabled then assert else function() end) :: (value: unknown, errorMessage: string?) -> ()