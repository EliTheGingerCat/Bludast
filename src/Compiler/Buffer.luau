local NumberConversions = require("@Polyfill/NumberConversions")

local btn = NumberConversions.booleanToNumber

local prototype = {}
local metatable = {__index = prototype}
--[=[
	@class Buffer
	@__index prototype

	A wrapper for the `buffer` primitive.
]=]
local Buffer = {}

export type Buffer = typeof(setmetatable({} :: {
    buf: buffer,
    pos: number
}, metatable))

--[=[
    @within Buffer
    @since 0.1.0
]=]
function Buffer.new(): Buffer
    return setmetatable({
        buf = buffer.create(100),
        pos = 0
    }, metatable)
end

--[=[
    @within Buffer
    @since 0.1.0
]=]
function prototype.clear(self: Buffer): ()
    self.buf = buffer.create(100)
    self.pos = 0
end

--[=[
    @within Buffer
    @since 0.1.0
    @private

    Increments cursor by `size` bytes, resizing the buffer if needed.
]=]
function prototype.alloc(self: Buffer, size: number): number
    if buffer.len(self.buf) < self.pos + size then
        local new_size = buffer.len(self.buf)

        repeat
            new_size += new_size / 2
        until new_size > self.pos + size

        local new_buf = buffer.create(new_size)
        buffer.copy(new_buf, 0, self.buf, 0, self.pos)
        self.buf = new_buf
    end

    local pos = self.pos
    self.pos += size
    return pos
end

--[=[
    @within Buffer
    @since 0.1.0

    Writes one byte.
]=]
function prototype.writeByte(self: Buffer, value: number): ()
    local pos = self:alloc(1)
    buffer.writeu8(self.buf, pos, value)
end

--[=[
    @within Buffer
    @since 0.1.0

    Writes a boolean as one byte.
]=]
function prototype.writeBoolean(self: Buffer, value: boolean): ()
    self:writeByte(btn(value))
end

--[=[
    @within Buffer
    @since 0.1.0

    Writes a 32-bit integer.
]=]
function prototype.writeInt(self: Buffer, value: number): ()
    local pos = self:alloc(4)
    buffer.writeu32(self.buf, pos, value)
end

--[=[
    @within Buffer
    @since 0.1.0

    Writes a 32-bit float.
]=]
function prototype.writeFloat(self: Buffer, value: number): ()
    local pos = self:alloc(4)
    buffer.writef32(self.buf, pos, value)
end

--[=[
    @within Buffer
    @since 0.1.0

    Writes a 64-bit float.
]=]
function prototype.writeDouble(self: Buffer, value: number): ()
    local pos = self:alloc(8)
    buffer.writef64(self.buf, pos, value)
end

--[=[
    @within Buffer
    @since 0.1.0

    Writes a variable-length integer.
]=]
function prototype.writeVarInt(self: Buffer, value: number): ()
    repeat
		self:writeByte(bit32.bor(
			bit32.band(value, 127),
			bit32.lshift(
				btn(value > 127),
				7
			)
		))
		value = bit32.rshift(value, 7)
	until value == 0
end

--[=[
    @within Buffer
    @since 0.1.0

    Writes a string.
]=]
function prototype.writeString(self: Buffer, value: string): ()
    local pos = self:alloc(#value)
    buffer.writestring(self.buf, pos, value)
end

--[=[
    @within Buffer
    @since 0.1.0

    Appends the contents of another Buffer.
]=]
function prototype.copyAtEnd(self: Buffer, other: Buffer): ()
    local pos = self:alloc(other.pos)
    buffer.copy(self.buf, pos, other.buf, 0, other.pos)
end

--[=[
    @within Buffer
    @since 0.1.0
    
    Prints each byte in hexadecimal.
]=]
function prototype.dumpBytes(self: Buffer): ()
    local result: {string} = {}
    for i = 0, self.pos - 1 do
        local value = buffer.readu8(self.buf, i)
        table.insert(result, string.format("%02X", value))
    end
    print(table.concat(result, " "))
end

return Buffer