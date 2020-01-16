local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Promise = require(script.Parent.Promise)
local t = require(script.Parent.tPlus)

local IS_SERVER = RunService:IsServer()

local HttpPromise = {}

local requestInterface = t.strictInterface({
	Url = t.string,
	Method = t.optionalString,
	Headers = t.optionalDictionary,
	Body = t.optionalString,
})

--[[**
	Generates a UUID/GUID random string, optionally with curly braces.

	@param [t:optional<t:boolean>] wrapInCurlyBraces Whether the returned string should be wrapped in {curly braces}. Defaults to true.
	@returns [tPlus:promise] A promise which calls HttpService:GenerateGUID.
**--]]
function HttpPromise.promiseGuid(wrapInCurlyBraces)
	local typeSuccess, typeError = t.optionalBoolean(wrapInCurlyBraces)
	if not typeSuccess then
		return Promise.reject(typeError)
	end

	return Promise.new(function(resolve, reject)
		local success, value = pcall(HttpService.GenerateGUID, HttpService, wrapInCurlyBraces);
		(success and resolve or reject)(value)
	end)
end

--[[**
	Decodes a JSON string into a Lua table.

	@param [t:string] input The JSON object being decoded.
	@returns [tPlus:promise] A promise which calls HttpService:JSONDecode.
**--]]
function HttpPromise.promiseDecode(input)
	local typeSuccess, typeError = t.string(input)
	if not typeSuccess then
		return Promise.reject(typeError)
	end

	return Promise.new(function(resolve, reject)
		local success, value = pcall(HttpService.JSONDecode, HttpService, input);
		(success and resolve or reject)(value)
	end)
end

--[[**
	Generate a JSON string from a Lua table.

	@param [t:table] input The input Lua table.
	@returns [tPlus:promise] A promise which calls HttpService:JSONEncode.
**--]]
function HttpPromise.promiseEncode(input)
	local typeSuccess, typeError = t.table(input)
	if not typeSuccess then
		return Promise.reject(typeError)
	end

	return Promise.new(function(resolve, reject)
		local success, value = pcall(HttpService.JSONEncode, HttpService, input);
		(success and resolve or reject)(value)
	end)
end

--[[**
	Replaces URL-unsafe characters with ‘%’ and two hexadecimal characters.

	@param [t:string] input The string (URL) to encode.
	@returns [tPlus:promise] A promise which calls HttpService:UrlEncode.
**--]]
function HttpPromise.promiseUrlEncode(input)
	local typeSuccess, typeError = t.string(input)
	if not typeSuccess then
		return Promise.reject(typeError)
	end

	return Promise.new(function(resolve, reject)
		local success, value = pcall(HttpService.UrlEncode, HttpService, input);
		(success and resolve or reject)(value)
	end)
end

--[[**
	Sends an HTTP request using any HTTP method given a dictionary of information.

	@param [t:requestInterface] requestDictionary A dictionary containing information to be requested from the server specified.
	@returns [tPlus:promise] A promise which calls HttpService:RequestAsync.
**--]]
function HttpPromise.promiseRequest(requestOptions)
	if not IS_SERVER then
		return Promise.reject("promiseRequest cannot be called on the client!")
	end

	local typeSuccess, typeError = requestInterface(requestOptions)
	if not typeSuccess then
		return Promise.reject(typeError)
	end

	return Promise.async(function(resolve, reject)
		local success, value = pcall(HttpService.RequestAsync, HttpService, requestOptions);
		(success and resolve or reject)(value)
	end)
end

return HttpPromise