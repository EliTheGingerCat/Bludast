local AstExpr = require("@Ast/AstExpr")
local AstExprBinary = require("@Ast/AstExprBinary")
local AstExprCall = require("@Ast/AstExprCall")
local AstExprConstantBool = require("@Ast/AstExprConstantBool")
local AstExprConstantNil = require("@Ast/AstExprConstantNil")
local AstExprConstantNumber = require("@Ast/AstExprConstantNumber")
local AstExprConstantString = require("@Ast/AstExprConstantString")
local AstExprFunction = require("@Ast/AstExprFunction")
local AstExprGlobal = require("@Ast/AstExprGlobal")
local AstExprGroup = require("@Ast/AstExprGroup")
local AstExprIfElse = require("@Ast/AstExprIfElse")
local AstExprIndexExpr = require("@Ast/AstExprIndexExpr")
local AstExprIndexName = require("@Ast/AstExprIndexName")
local AstExprInterpString = require("@Ast/AstExprInterpString")
local AstExprLocal = require("@Ast/AstExprLocal")
local AstExprTable = require("@Ast/AstExprTable")
local AstExprTypeAssertion = require("@Ast/AstExprTypeAssertion")
local AstExprUnary = require("@Ast/AstExprUnary")
local AstExprVarargs = require("@Ast/AstExprVarargs")
local AstLocal = require("@Ast/AstLocal")
local AstNode = require("@Ast/AstNode")
local AstStatLocal = require("@Ast/AstStatLocal")
local AstVisitor = require("@Ast/AstVisitor")
local BuiltinFolding = require("./BuiltinFolding")
local Constant = require("./CompilerConstant")
local ValueTracking = require("./ValueTracking")
local Vector = require("@Polyfill/Vector")

type AstExpr = AstExpr.AstExpr
type AstExprCall = AstExprCall.AstExprCall
type AstExprFunction = AstExprFunction.AstExprFunction
type AstExprIfElse = AstExprIfElse.AstExprIfElse
type AstExprIndexExpr = AstExprIndexExpr.AstExprIndexExpr
type AstExprIndexName = AstExprIndexName.AstExprIndexName
type AstExprInterpString = AstExprInterpString.AstExprInterpString
type AstExprTable = AstExprTable.AstExprTable
type AstExprTypeAssertion = AstExprTypeAssertion.AstExprTypeAssertion
type AstExprUnary = AstExprUnary.AstExprUnary
type AstLocal = AstLocal.AstLocal
type AstNode = AstNode.AstNode
type AstStatLocal = AstStatLocal.AstStatLocal
type AstVisitor = AstVisitor.AstVisitor
type Constant = Constant.Constant
local foldBuiltin = BuiltinFolding.foldBuiltin
local foldBuiltinMath = BuiltinFolding.foldBuiltinMath
type Variable = ValueTracking.Variable
type Vector<T> = Vector.Vector<T>

--[=[
	@class ConstantFolding
]=]
local ConstantFolding = {}

--[=[
	@within ConstantFolding
	@private
	@since v0.1.0
	@tag local
]=]
local function constantsEqual(la: Constant, ra: Constant): boolean
	assert(la.type ~= Constant.Type.Type_Unknown and ra.type ~= Constant.Type.Type_Unknown)

	if la.type == Constant.Type.Type_Nil then
		return ra.type == Constant.Type.Type_Nil
	end

	if la.type == Constant.Type.Type_Boolean then
		return ra.type == Constant.Type.Type_Boolean and la.valueBoolean == ra.valueBoolean
	end

	if la.type == Constant.Type.Type_Number then
		return ra.type == Constant.Type.Type_Number and la.valueNumber == ra.valueNumber
	end

	if la.type == Constant.Type.Type_Vector then
		return
			ra.type == Constant.Type.Type_Vector
			and la.valueVector[1] == ra.valueVector[1]
			and la.valueVector[2] == ra.valueVector[2]
			and la.valueVector[3] == ra.valueVector[3]
			and la.valueVector[4] == ra.valueVector[4]
	end

	if la.type == Constant.Type.Type_String then
		return ra.type == Constant.Type.Type_String and la.valueString == ra.valueString
	end

	error("Unexpected constant type in comparison")
end

--[=[
	@within ConstantFolding
	@private
	@since v0.1.0
	@tag local
]=]
local function foldUnary(result: Constant, op: number, arg: Constant): ()
	if op == AstExprUnary.Op.Not then
		if arg.type ~= Constant.Type.Type_Unknown then
			result.type = Constant.Type.Type_Boolean
			result.valueBoolean = not arg:isTruthful()
		end
		return
	end

	if op == AstExprUnary.Op.Minus then
		if arg.type == Constant.Type.Type_Number then
			result.type = Constant.Type.Type_Number
			result.valueNumber = -arg.valueNumber
		end
		return
	end

	if op == AstExprUnary.Op.Len then
		if arg.type == Constant.Type.Type_String then
			result.type = Constant.Type.Type_Number
			result.valueNumber = arg.stringLength
		end
		return
	end

	error("Unexpected unary operation")
end

--[=[
	@within ConstantFolding
	@private
	@since v0.1.0
	@tag local

	May return a Constant that `result` should be set to.
]=]
local function foldBinary(result: Constant, op: number, la: Constant, ra: Constant): Constant?
	if op == AstExprBinary.Op.Add then
		if la.type == Constant.Type.Type_Number and ra.type == Constant.Type.Type_Number then
			result.type = Constant.Type.Type_Number
			result.valueNumber = la.valueNumber + ra.valueNumber
		end
		return
	end

	if op == AstExprBinary.Op.Sub then
		if la.type == Constant.Type.Type_Number and ra.type == Constant.Type.Type_Number then
			result.type = Constant.Type.Type_Number
			result.valueNumber = la.valueNumber - ra.valueNumber
		end
		return
	end

	if op == AstExprBinary.Op.Mul then
		if la.type == Constant.Type.Type_Number and ra.type == Constant.Type.Type_Number then
			result.type = Constant.Type.Type_Number
			result.valueNumber = la.valueNumber * ra.valueNumber
		end
		return
	end

	if op == AstExprBinary.Op.Div then
		if la.type == Constant.Type.Type_Number and ra.type == Constant.Type.Type_Number then
			result.type = Constant.Type.Type_Number
			result.valueNumber = la.valueNumber / ra.valueNumber
		end
		return
	end

	if op == AstExprBinary.Op.FloorDiv then
		if la.type == Constant.Type.Type_Number and ra.type == Constant.Type.Type_Number then
			result.type = Constant.Type.Type_Number
			result.valueNumber = la.valueNumber // ra.valueNumber
		end
		return
	end

	if op == AstExprBinary.Op.Mod then
		if la.type == Constant.Type.Type_Number and ra.type == Constant.Type.Type_Number then
			result.type = Constant.Type.Type_Number
			result.valueNumber = la.valueNumber % ra.valueNumber
		end
		return
	end

	if op == AstExprBinary.Op.Pow then
		if la.type == Constant.Type.Type_Number and ra.type == Constant.Type.Type_Number then
			result.type = Constant.Type.Type_Number
			result.valueNumber = math.pow(la.valueNumber, ra.valueNumber)
		end
		return
	end

	if op == AstExprBinary.Op.Concat then
		return
	end

	if op == AstExprBinary.Op.CompareNe then
		if la.type ~= Constant.Type.Type_Unknown and ra.type ~= Constant.Type.Type_Unknown then
			result.type = Constant.Type.Type_Boolean
			result.valueBoolean = not constantsEqual(la, ra)
		end
		return
	end

	if op == AstExprBinary.Op.CompareEq then
		if la.type ~= Constant.Type.Type_Unknown and ra.type ~= Constant.Type.Type_Unknown then
			result.type = Constant.Type.Type_Boolean
			result.valueBoolean = constantsEqual(la, ra)
		end
		return
	end

	if op == AstExprBinary.Op.CompareLt then
		if la.type == Constant.Type.Type_Number and ra.type == Constant.Type.Type_Number then
			result.type = Constant.Type.Type_Boolean
			result.valueBoolean = la.valueNumber < ra.valueNumber
		end
		return
	end

	if op == AstExprBinary.Op.CompareLe then
		if la.type == Constant.Type.Type_Number and ra.type == Constant.Type.Type_Number then
			result.type = Constant.Type.Type_Boolean
			result.valueBoolean = la.valueNumber <= ra.valueNumber
		end
		return
	end

	if op == AstExprBinary.Op.CompareGt then
		if la.type == Constant.Type.Type_Number and ra.type == Constant.Type.Type_Number then
			result.type = Constant.Type.Type_Boolean
			result.valueBoolean = la.valueNumber > ra.valueNumber
		end
		return
	end

	if op == AstExprBinary.Op.CompareGe then
		if la.type == Constant.Type.Type_Number and ra.type == Constant.Type.Type_Number then
			result.type = Constant.Type.Type_Boolean
			result.valueBoolean = la.valueNumber >= ra.valueNumber
		end
		return
	end

	if op == AstExprBinary.Op.And then
		if la.type ~= Constant.Type.Type_Unknown then
			return if la:isTruthful() then ra else la
		end
		return
	end

	if op == AstExprBinary.Op.Or then
		if la.type ~= Constant.Type.Type_Unknown then
			return if la:isTruthful() then la else ra
		end
		return
	end

	error("Unexpected binary operation")
end

local prototypeVisitor = setmetatable({}, AstVisitor.metatable)
local metatableVisitor = {__index = prototypeVisitor}
local ConstantVisitor = {}
type ConstantVisitor = AstVisitor & {
	constants: {[AstExpr]: Constant},
	variables: {[AstLocal]: Variable},
	locals: {[AstLocal]: Constant},

	builtins: {[AstExprCall]: number},
	foldMathK: boolean,

	wasEmpty: boolean,

	builtinArgs: Vector<Constant>,

	analyze: (self: ConstantVisitor, node: AstExpr) -> Constant,
	recordConstant: <T>(self: ConstantVisitor, map: {[T]: Constant}, key: T, value: Constant) -> (),
	recordValue: (self: ConstantVisitor, astLocal: AstLocal, value: Constant) -> ()
}

function ConstantVisitor.new(
	constants: {[AstExpr]: Constant},
	variables: {[AstLocal]: Variable},
	locals: {[AstLocal]: Constant},
	builtins: {[AstExprCall]: number},
	foldMathK: boolean
): ConstantVisitor
	local self = AstVisitor.new() :: ConstantVisitor
	self.constants = constants
	self.variables = variables
	self.locals = locals
	self.builtins = builtins
	self.foldMathK = foldMathK
	-- since we do a single pass over the tree, if the initial state was empty we don't need to clear out old entries
	self.wasEmpty = next(constants) == nil and next(locals) == nil
	self.builtinArgs = Vector.new()
	setmetatable(self, metatableVisitor)
	return self
end

function prototypeVisitor.analyze(self: ConstantVisitor, node: AstExpr): Constant
	local result = Constant.new(Constant.Type.Type_Unknown)

	local exprGroup = node:as(AstExprGroup)
	local exprConstantNil = node:as(AstExprConstantNil)
	local exprConstantBool = node:as(AstExprConstantBool)
	local exprConstantNumber = node:as(AstExprConstantNumber)
	local exprConstantString = node:as(AstExprConstantString)
	local exprLocal = node:as(AstExprLocal)
	local exprCall = node:as(AstExprCall)
	local exprIndexName = node:as(AstExprIndexName)
	local exprIndexExpr = node:as(AstExprIndexExpr)
	local exprFunction = node:as(AstExprFunction)
	local exprTable = node:as(AstExprTable)
	local exprUnary = node:as(AstExprUnary)
	local exprBinary = node:as(AstExprBinary)
	local exprTypeAssertion = node:as(AstExprTypeAssertion)
	local exprIfElse = node:as(AstExprIfElse)
	local exprInterpString = node:as(AstExprInterpString)
	
	if exprGroup then
		result = self:analyze(exprGroup.expr)
	elseif exprConstantNil then
		result.type = Constant.Type.Type_Nil
	elseif exprConstantBool then
		result.type = Constant.Type.Type_Boolean
		result.valueBoolean = exprConstantBool.value
	elseif exprConstantNumber then
		result.type = Constant.Type.Type_Number
		result.valueNumber = exprConstantNumber.value
	elseif exprConstantString then
		result.type = Constant.Type.Type_String
		result.valueString = exprConstantString.value
		result.stringLength = #exprConstantString.value
	elseif exprLocal then
		local l = self.locals[exprLocal.localAst]
		
		if l then
			result = l
		end
	elseif node:is(AstExprGlobal) then
		-- nope
	elseif node:is(AstExprVarargs) then
		-- nope
	elseif exprCall then
		self:analyze(exprCall.func)

		local bfid = if self.builtins then self.builtins[exprCall] else nil
		if bfid then
			-- since recursive calls to analyze() may reuse the vector we need to be careful and preserve existing contents
			local offset = self.builtinArgs:size()
			local canFold = true

			self.builtinArgs:reserve(offset + #exprCall.args)

			for _, arg in exprCall.args do
				local ac = self:analyze(arg :: AstExpr)

				if ac.type == Constant.Type.Type_Unknown then
					canFold = false
				else
					self.builtinArgs:push_back(ac)
				end
			end

			if canFold then
				assert(self.builtinArgs:size() == offset + #exprCall.args)
				local args = {}
				for index, arg in self.builtinArgs:data() do
					if index > offset then
						table.insert(args, arg)
					end
				end
				result = foldBuiltin(bfid, args, #exprCall.args)
			end

			self.builtinArgs:resize(offset)
		else
			for _, arg in exprCall.args do
				self:analyze(arg :: AstExpr)
			end
		end
	elseif exprIndexName then
		self:analyze(exprIndexName.expr)

		if self.foldMathK then
			local eg = exprIndexName.expr:as(AstExprGlobal)
			if eg and eg.name.value == "math" then
				result = foldBuiltinMath(exprIndexName.index)
			end
		end
	elseif exprIndexExpr then
		self:analyze(exprIndexExpr.expr)
		self:analyze(exprIndexExpr.index)
	elseif exprFunction then
		-- this is necessary to propagate constant information in all child functions
		exprFunction.body:visit(self)
	elseif exprTable then
		for _, item in exprTable.items do
			if item.key then
				self:analyze(item.key :: AstExpr)
			end

			self:analyze(item.value :: AstExpr)
		end
	elseif exprUnary then
		local arg = self:analyze(exprUnary.expr)

		if arg.type ~= Constant.Type.Type_Unknown then
			foldUnary(result, exprUnary.op, arg)
		end
	elseif exprBinary then
		local la = self:analyze(exprBinary.left)
		local ra = self:analyze(exprBinary.right)

		-- note: ra doesn't need to be constant to fold and/or
		if la.type ~= Constant.Type.Type_Unknown then
			local newResult = foldBinary(result, exprBinary.op, la, ra)
			if newResult then
				result = newResult
			end
		end
	elseif exprTypeAssertion then
		local arg = self:analyze(exprTypeAssertion.expr)

		result = arg
	elseif exprIfElse then
		local cond = self:analyze(exprIfElse.condition)
		local trueExpr = self:analyze(exprIfElse.trueExpr)
		local falseExpr = self:analyze(exprIfElse.falseExpr)

		if cond.type ~= Constant.Type.Type_Unknown then
			result = if cond:isTruthful() then trueExpr else falseExpr
		end
	elseif exprInterpString then
		for _, expression in exprInterpString.expressions do
			self:analyze(expression :: AstExpr)
		end
	else
		error("Unknown expression type")
	end

	self:recordConstant(self.constants, node, result)

	return result
end

function prototypeVisitor.recordConstant<T>(self: ConstantVisitor, map: {[T]: Constant}, key: T, value: Constant): ()
	local old = map[key]

	if value.type ~= Constant.Type.Type_Unknown then
		map[key] = value
	elseif self.wasEmpty then

	elseif old then
		old.type = Constant.Type.Type_Unknown
	end
end

function prototypeVisitor.recordValue(self: ConstantVisitor, astLocal: AstLocal, value: Constant): ()
	-- note: we rely on trackValues to have been run before us
	local v = self.variables[astLocal]
	assert(v)

	if not v.written then
		v.constant = value.type ~= Constant.Type.Type_Unknown
		self:recordConstant(self.locals, astLocal, value)
	end
end

function prototypeVisitor.visitAstExpr(self: ConstantVisitor, node: AstExpr): boolean
	-- note: we short-circuit the visitor traversal through any expression trees by returning false
	-- recursive traversal is happening inside analyze() which makes it easier to get the resulting value of the subexpression
	self:analyze(node)

	return false
end

function prototypeVisitor.visitAstStatLocal(self: ConstantVisitor, node: AstStatLocal): boolean
	-- all values that align wrt indexing are simple - we just match them 1-1
	for i = 1, math.min(#node.vars, #node.values) do
		local arg = self:analyze(node.values[i])

		self:recordValue(node.vars[i], arg)
	end

	if #node.vars > #node.values then
		-- if we have trailing variables, then depending on whether the last value is capable of returning multiple values
        -- (aka call or varargs), we either don't know anything about these vars, or we know they're nil
		local last = if #node.values > 0 then node.values[#node.values] else nil
		local multRet = last and (last:is(AstExprCall) or last:is(AstExprVarargs))
		
		if not multRet then
			for i = #node.values + 1, #node.vars do
				local constantNil = Constant.new(Constant.Type.Type_Nil)
				self:recordValue(node.vars[i], constantNil)
			end
		end
	else
		-- we can have more values than variables; in this case we still need to analyze them to make sure we do constant propagation inside
        -- them

		for i = #node.vars + 1, #node.values do
			self:analyze(node.values[i])
		end
	end

	return false
end

--[=[
	@within ConstantFolding
	@since v0.1.0
]=]
function ConstantFolding.foldConstants(
	constants: {[AstExpr]: Constant},
	variables: {[AstLocal]: Variable},
	locals: {[AstLocal]: Constant},
	builtins: {[AstExprCall]: number},
	foldMathK: boolean,
	root: AstNode
): ()
	local visitor = ConstantVisitor.new(constants, variables, locals, builtins, foldMathK)
	root:visit(visitor)
end

ConstantFolding.Constant = Constant

return ConstantFolding