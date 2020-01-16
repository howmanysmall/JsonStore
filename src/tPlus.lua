-- tPlus - an extension to the t library.
local Promise = require(script.Parent.Promise)
local t = require(script.Parent.t)

local tPlus = {
	optionalBoolean = t.optional(t.boolean),
	optionalString = t.optional(t.string),
	optionalNumber = t.optional(t.number),
	optionalNumberPositive = t.optional(t.numberPositive),

	dictionary = t.keys(t.string),
	positiveInteger = t.intersection(t.integer, t.numberPositive),
	nonNegativeNumber = t.numberMin(0),
}

tPlus.optionalDictionary = t.optional(tPlus.dictionary)
tPlus.optionalNonNegativeNumber = t.optional(tPlus.nonNegativeNumber)

function tPlus.promise(promise)
	local isPromise = Promise.is(promise)
	if isPromise then
		return true
	else
		return false, string.format("Promise expected, got %s", typeof(promise))
	end
end

return setmetatable(tPlus, {
	__index = t,
	__metatable = "[tPlus] Requested metatable of read-only table is locked",

	__tostring = function()
		return "tPlus"
	end,

	__newindex = function()
		error("Attempt to modify read-only table tPlus!", 2)
	end,
})