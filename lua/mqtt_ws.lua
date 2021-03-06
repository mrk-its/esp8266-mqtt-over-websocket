local mqtt_packet = require('mqtt_packet')

local function emit(self, event, ...)
	local cb = self.events[event]
	if cb then
		cb(self, ...)
	end
end

local function connect(self, url)
	self.ws:connect(url)
end

local function close(self)
        self.ws:close()
end

local function on(self, event, callback)
	self.events[event] = callback
end

local function subscribe(self, topic, qos)
	if type(topic) ~= 'table' then
		topic = {[topic] = qos or 0}
	end
	self.ws:send(mqtt_packet.subscribe({msg_id=self.msg_id, topics=topic}), 2)
	self.msg_id = self.msg_id + 1
end

local function publish(self, topic, message)
	self.ws:send(mqtt_packet.publish({topic=topic, payload=message}), 2)
end

local function Client()
	local ws = websocket.createClient()
	ws:config({headers={["sec-websocket-protocol"] = "mqtt"}})
	local client = {
		connect = connect,
		close = close,
		subscribe = subscribe,
		publish = publish,
		on = on,
		emit = emit,
		events = {},
		ws = ws,
		msg_id = 1,
	}

	ws:on('receive', function(_, msg, opcode, x)
		print("received", msg:len(), "bytes:", mqtt_packet.toHex(msg))
		local parsed = mqtt_packet.parse(msg)
		for k, v in pairs(parsed) do
			print('>', k, v)
		end
		if parsed.cmd == 3 then
		    client:emit('message', parsed.topic, parsed.payload)
		end
		if parsed.cmd == 2 then
		    client:emit('connect')
		end
	end)

	ws:on('close', function(_, status)
		print('websocket closed, status:', status)
		client:emit('offline')
		-- client.ws = nil
		-- client.ws = create_ws()
	end)

	ws:on('connection', function(_)
		print("websocket connected")
		ws:send(string.char(0x10, 0x0c, 0x00, 0x04, 0x4d, 0x51, 0x54, 0x54, 0x04, 0x02, 0x00, 0x00, 0x00, 0x00), 2)
	end)

	return client
end

return {
	Client = Client
}
