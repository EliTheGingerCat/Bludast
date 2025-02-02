--[=[
	@class LuauProtoFlag

	Proto flag bitmask, stored in Proto::flags
]=]

--[=[
	@within LuauProtoFlag
	@prop LPF_NATIVE_MODULE number

	Used to tag main proto for modules with `--!native`.
]=]

--[=[
	@within LuauProtoFlag
	@prop LPF_NATIVE_COLD number

	Used to tag individual protos as not profitable to compile natively.
]=]

--[=[
	@within LuauProtoFlag
	@prop LPF_NATIVE_FUNCTION number

	Used to tag main proto for modules that have at least one function with native attribute
]=]

return {
	LPF_NATIVE_MODULE = bit32.lshift(1, 0),
	LPF_NATIVE_COLD = bit32.lshift(1, 1),
	LPF_NATIVE_FUNCTION = bit32.lshift(1, 2)
}