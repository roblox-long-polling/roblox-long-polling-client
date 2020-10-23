--[[
# roblox-long-polling
Made by Harry Kruger
license MIT
--]]

local Promise = require(script.Parent.Promise)
local HttpService = game:GetService("HttpService")
local Neturl = require(script.Parent.url)
local EventEmitter = require(script.Parent.events)

function table.assign(...)
    local newTable = {}
    local arg = {...}

    for k, v in pairs(arg) do
        if type(v) == 'table' then
            for tk, tv in pairs(v) do
                newTable[tk] = tv
            end
        end
    end

    return newTable
end

local Constants = {}

Constants['ConnectionOptions'] = {
	url = 'http://127.0.0.1:5000/r',
	maxSockets = 2,
	maxRequests = 500
	refreshTime = 60 * 1000
}

local function createClass(object)
	object.__index = object
	object['new'] = function ()
		local instance = {}
		setmetatable(instance, object)

		if instance.constructor ~= nil then instance.constructor(...) end

		return instance
	end
end

local Connection = {
	sockets = {},
	_lastRefresh = 0
}

Connection = EventEmitter.new(Connection)

function Connection:constructor(options) 
	self.options = table.assign({}, Constants['ConnectionOptions'], options)
	self._remainingRequests = self.options.maxRequests
end

function Connection:start()
	self._interval()
end

function Connection:_interval()
	if #self.sockets < self.options.maxSockets and self.getRemainingRequests() > 0 then
		self._createSocket()
	end

	delay(self._getRate(), self._interval)
end


function Connection:getRemainingRequests()
	if self.getTimeUntilRefresh < 0 then
		self._remainingRequests = self.options.maxRequests
	end
	return self._remainingRequests
end

function Connection:removeRemainingRequest()
	self._remainingRequests = self.getRemainingRequests() - 1
end


function Connection:_createSocket(data)
	table.insert(self.sockets, Promise.new(function (resolve, reject)
		local success, result = pcall(self._sendRequest(data))

		if success then
			local body = HttpService.JSONDecode(result.Body)

			self.emit('data', body)

			resolve(body)
		else
			reject(result)
		end
	end))
end

function Connection:_sendRequest(data)
	self.removeRemainingRequest()
	if data == nil then data = {}

	return HttpService.RequestAsync({
		Url = self.options.url,
		Method = 'POST',
		Headers = {
			'Content-Type' = 'application/json'
		},
		Body = HttpService:JSONEncode(data)
	})
end

function Connection:getTimeUntilRefresh()
	return self._lastRefresh + self.options.refreshTime - os.time()
end

function Connection:_getRate()
	return self.getTimeUntilRefresh() / self.options.remainingRequests
end