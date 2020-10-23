local RobloxPolling = require(script.Parent.Parent.Modules.RobloxPolling)

roboxPolling = RobloxPolling.Client.new({
	url = 'http://localhost:9999/' 
})

roboxPolling.send({
	message: 'hello'
})