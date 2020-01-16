local HttpPromise = require(script.HttpPromise)
local Promise = require(script.Promise)
local t = require(script.tPlus)

local JsonStore = {
	ClassName = "JsonStore",
	__tostring = function(self)
		return self.ClassName
	end,
}

JsonStore.__index = JsonStore

local optionalToken = t.optional(t.match("(%w+)$"))
local putTuple = t.tuple(t.string, t.table)

local API_URL = "https://www.jsonstore.io"
local REJECT_ERROR = "Couldn't reach JsonStore! Got status message %q with error code %d."
local JSON_HEADER = {["Content-Type"] = "application/json"}
local NULL = false and table.create(0) or nil -- So selene doesn't yell at me.

local function catchErrorCreator(functionName)
	assert(t.string(functionName))

	return function(error)
		warn(string.format("Function %s failed to execute, got error %s.", functionName, error))
	end
end

--[[**
	Instantiates a new JsonStore.
	@param [t:optional<t:match<(%w+)$>>] token The optional token for your jsonstore.io endpoint.
	@returns [t:table] API ready to communicate with your endpoint.
**--]]
function JsonStore.new(token)
	assert(optionalToken(token))

	if token then
		return setmetatable({
			_token = string.match(token, "(%w+)$"),
		}, JsonStore)
	else
		warn("You didn't put in a token, which means data will never be the saved properly.")
		local self = setmetatable({}, JsonStore)
		self:_generateEndpoint()
		return self
	end
end

function JsonStore:_generateEndpoint()
	local catchFunction = catchErrorCreator("JsonStore:_generateEndpoint")

	HttpPromise.promiseRequest({
		Url = API_URL .. "/get-token",
		Method = "GET",
	}):andThen(function(requestDictionary)
		if requestDictionary.Success and requestDictionary.Body then
			return HttpPromise.promiseDecode(requestDictionary.Body):andThen(function(bodyData)
				if bodyData.token then
					self._token = bodyData.token
				end
			end):catch(catchFunction)
		end
	end):catch(catchFunction):await()

	return self
end

--[[**
	Returns the formatted endpoint URL.
	@returns [t:string] Endpoint URL.
**--]]
function JsonStore:getUrl()
	return API_URL .. "/" .. self._token
end

--[[**
	Returns the current token for the store.
	@returns [t:string] The token of the current store.
**--]]
function JsonStore:getToken()
	return self._token
end

--[[**
	Verifies web server is alive.
	@returns [t:boolean] True iff server is online.
**--]]
function JsonStore:ping()
	local success, valueOrError = HttpPromise.promiseRequest({
		Url = self:getUrl(),
		Method = "HEAD",
	}):andThen(function(requestDictionary)
		if requestDictionary.Success then
			return Promise.resolve(true)
		else
			return Promise.reject(string.format(REJECT_ERROR, requestDictionary.StatusMessage, requestDictionary.StatusCode))
		end
	end):catch(catchErrorCreator("JsonStore:ping")):await()

	if success then
		return valueOrError
	else
		warn("JsonStore:ping failed!", valueOrError)
		return false
	end
end

--[[**
	Send a `GET` request to your endpoint asynchronously.
	@param [t:string] path Path to perform GET request to.
	@returns [tPlus:promise] A promise that can be used for handling the code.
**--]]
function JsonStore:getAsync(path)
	local typeSuccess, typeError = t.string(path)
	if not typeSuccess then
		return Promise.reject(typeError)
	end

	local catchFunction = catchErrorCreator("JsonStore:getAsync")

	return HttpPromise.promiseRequest({
		Url = self:getUrl() .. path,
		Method = "GET",
	}):andThen(function(requestDictionary)
		local rejectMessage = string.format(
			REJECT_ERROR,
			requestDictionary.StatusMessage,
			requestDictionary.StatusCode
		)

		if requestDictionary.Success and requestDictionary.Body then
			return HttpPromise.promiseDecode(requestDictionary.Body):andThen(function(bodyData)
				if bodyData.ok then
					bodyData.result = bodyData.result and bodyData.result or table.create(0)
					return Promise.resolve(bodyData.result)
				else
					return Promise.reject(rejectMessage)
				end
			end):catch(catchFunction)
		else
			return Promise.reject(rejectMessage)
		end
	end) -- :catch(catchFunction) -- Do I?
end

--[[**
	Send a `GET` request to your endpoint.
	@param [t:string] path Path to perform GET request to.
	@returns [t:table] Data returned from database.
**--]]
function JsonStore:get(path)
	assert(t.optionalString(path))
	local success, valueOrError = self:getAsync(path):catch(catchErrorCreator("JsonStore:get")):await()
	if success then
		return valueOrError
	else
		warn("JsonStore:get failed!", valueOrError)
		return false
	end
end

--[[**
	This function is similar to DataStore2's `GetTable`, where it will set the data to the default if it doesn't exist asynchronously.

	@param [t:string] path The path to use.
	@param [t:table] defaultData The default data if it doesn't exist.
	@returns [tPlus:promise] A promise that can be used for handling the code.
**--]]
function JsonStore:getDefaultAsync(path, defaultData)
	local typeSuccess, typeError = putTuple(path, defaultData)
	if not typeSuccess then
		return Promise.reject(typeError)
	end

	local catchFunction = catchErrorCreator("JsonStore:getDefaultAsync")
	return self:getAsync(path):andThen(function(currentData)
		if next(currentData) == nil then
			return self:postAsync(path, defaultData):andThen(function(savedData)
				return Promise.resolve(savedData)
			end):catch(catchFunction)
		else
			return Promise.resolve(currentData)
		end
	end)
end

--[[**
	This function is similar to DataStore2's `GetTable`, where it will set the data to the default if it doesn't exist.

	@param [t:string] path The path to use.
	@param [t:table] defaultData The default data if it doesn't exist.
	@returns [t:table] The data stored in the database.
**--]]
function JsonStore:getDefault(path, defaultData)
	assert(putTuple(path, defaultData))
	local success, valueOrError = self:getDefaultAsync(path, defaultData):catch(catchErrorCreator("JsonStore:getDefault")):await()
	if success then
		return valueOrError
	else
		warn("JsonStore:getDefault failed!", valueOrError)
		return false
	end
end

--[[**
	Send a `DELETE` request to your endpoint asynchronously.
	@param [t:string] path Path to perform DELETE request to.
	@returns [tPlus:promise] A promise that can be used for handling the code.
**--]]
function JsonStore:deleteAsync(path)
	local typeSuccess, typeError = t.string(path)
	if not typeSuccess then
		return Promise.reject(typeError)
	end

	local catchFunction = catchErrorCreator("JsonStore:deleteAsync")

	return HttpPromise.promiseRequest({
		Url = self:getUrl() .. path,
		Method = "DELETE",
	}):andThen(function(requestDictionary)
		local rejectMessage = string.format(
			REJECT_ERROR,
			requestDictionary.StatusMessage,
			requestDictionary.StatusCode
		)

		if requestDictionary.Success and requestDictionary.Body then
			return HttpPromise.promiseDecode(requestDictionary.Body):andThen(function(bodyData)
				if bodyData.ok then
					return Promise.resolve(bodyData.ok)
				else
					return Promise.reject(rejectMessage)
				end
			end):catch(catchFunction)
		else
			return Promise.reject(rejectMessage)
		end
	end) -- :catch(catchFunction)
end

--[[**
	Send a `DELETE` request to your endpoint.
	@param [t:string] path Path to perform DELETE request to.
	@returns [t:boolean] True if DELETE request was successful.
**--]]
function JsonStore:delete(path)
	assert(t.string(path))
	local success, valueOrError = self:deleteAsync(path):catch(catchErrorCreator("JsonStore:delete")):await()
	if success then
		return valueOrError
	else
		warn("JsonStore:delete failed!", valueOrError)
		return false
	end
end

--[[**
	Send a `PUT` request to your endpoint asynchronously.
	@param [t:string] Path Path to perform PUT request to.
	@param [t:table] Content Data to PUT into the database.
	@returns [tPlus:promise] A promise that can be used for handling the code.
**--]]
function JsonStore:putAsync(path, content)
	local typeSuccess, typeError = putTuple(path, content)
	if not typeSuccess then
		return Promise.reject(typeError)
	end

	local catchFunction = catchErrorCreator("JsonStore:putAsync")

	return HttpPromise.promiseEncode(content):andThen(function(newContent)
		return HttpPromise.promiseRequest({
			Url = self:getUrl() .. path,
			Method = "PUT",
			Body = newContent,
			Headers = JSON_HEADER,
		}):andThen(function(requestDictionary)
			local rejectMessage = string.format(
				REJECT_ERROR,
				requestDictionary.StatusMessage,
				requestDictionary.StatusCode
			)

			if requestDictionary.Success and requestDictionary.Body then
				return HttpPromise.promiseDecode(requestDictionary.Body):andThen(function(bodyData)
					if bodyData.ok then
						return HttpPromise.promiseDecode(newContent):andThen(function(final)
							return Promise.resolve(final)
						end):catch(catchFunction)
					else
						return Promise.reject(rejectMessage)
					end
				end):catch(catchFunction)
			else
				return Promise.reject(rejectMessage)
			end
		end):catch(catchFunction)
	end) -- :catch(catchFunction)
end

--[[**
	Send a `PUT` request to your endpoint.
	@param [t:string] path Path to perform PUT request to.
	@param [t:table] content Data to PUT into the database.
	@returns [t:table] The content PUT into the database.
**--]]
function JsonStore:put(path, content)
	assert(putTuple(path, content))
	local success, valueOrError = self:putAsync(path, content):catch(catchErrorCreator("JsonStore:put")):await()
	if success then
		return valueOrError
	else
		warn("JsonStore:put failed!", valueOrError)
		return false
	end
end

--[[**
	Send a `POST` request to your endpoint asynchronously.
	@param [t:string] path Path to perform POST request to.
	@param [t:table] content Data to POST to the database.
	@returns [tPlus:promise] A promise that can be used for handling the code.
**--]]
function JsonStore:postAsync(path, content)
	local typeSuccess, typeError = putTuple(path, content)
	if not typeSuccess then
		return Promise.reject(typeError)
	end

	local catchFunction = catchErrorCreator("JsonStore:postAsync")

	return HttpPromise.promiseEncode(content):andThen(function(newContent)
		return HttpPromise.promiseRequest({
			Url = self:getUrl() .. path,
			Method = "POST",
			Body = newContent,
			Headers = JSON_HEADER,
		}):andThen(function(requestDictionary)
			local rejectMessage = string.format(
				REJECT_ERROR,
				requestDictionary.StatusMessage,
				requestDictionary.StatusCode
			)

			if requestDictionary.Success and requestDictionary.Body then
				return HttpPromise.promiseDecode(requestDictionary.Body):andThen(function(bodyData)
					if bodyData.ok then
						return HttpPromise.promiseDecode(newContent):andThen(function(final)
							return Promise.resolve(final)
						end):catch(catchFunction)
					else
						return Promise.reject(rejectMessage)
					end
				end):catch(catchFunction)
			else
				return Promise.reject(rejectMessage)
			end
		end):catch(catchFunction)
	end) -- :catch(catchFunction)
end

--[[**
	Send a `POST` request to your endpoint.
	@param [t:string] path Path to perform POST request to.
	@param [t:table] content Data to POST to the database.
	@returns [t:table] The content POST'ed to the database.
**--]]
function JsonStore:post(path, content)
	assert(putTuple(path, content))
	local success, valueOrError = self:postAsync(path, content):catch(catchErrorCreator("JsonStore:post")):await()
	if success then
		return valueOrError
	else
		warn("JsonStore:post failed!", valueOrError)
		return false
	end
end

--[[**
	Destroys the JsonStore so it can't be used anymore.
	@returns [void]
**--]]
function JsonStore:destroy()
	setmetatable(self, NULL)
end

return JsonStore