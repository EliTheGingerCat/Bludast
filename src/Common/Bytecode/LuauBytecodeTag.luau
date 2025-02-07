--[=[
	@class LuauBytecodeTag

	Bytecode tags, used internally for bytecode encoded as a string.
]=]
return {
    -- Bytecode version; runtime supports [MIN, MAX], compiler emits TARGET by default but may emit a higher version when flags are enabled
    LBC_VERSION_MIN = 3,
    LBC_VERSION_MAX = 5,
    LBC_VERSION_TARGET = 5,
    -- Type encoding version
    LBC_TYPE_VERSION_DEPRECATED = 1,
    LBC_TYPE_VERSION_MIN = 1,
    LBC_TYPE_VERSION_MAX = 3,
    LBC_TYPE_VERSION_TARGET = 3,
    -- Types of constant table entries
    LBC_CONSTANT_NIL = 0,
    LBC_CONSTANT_BOOLEAN = 1,
    LBC_CONSTANT_NUMBER = 2,
    LBC_CONSTANT_STRING = 3,
    LBC_CONSTANT_IMPORT = 4,
    LBC_CONSTANT_TABLE = 5,
    LBC_CONSTANT_CLOSURE = 6,
    LBC_CONSTANT_VECTOR = 7,
}