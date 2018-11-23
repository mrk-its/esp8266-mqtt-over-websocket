local config = require('config')
local mqtt = require('mqtt_ws')

function aws_sign_url(url)
	local aws_sig = require('aws_sig')
	local url = aws_sig.createSignature(config.AWS_ACCESS_KEY, config.AWS_SECRET_KEY, config.AWS_REGION, 'iotdevicegateway', 'GET', config.AWS_MQTT_URL, '')
	aws_sig = nil
	package.loaded.aws_sig = nil
	return url
end


local c = mqtt.Client()

c:on('message', function(_, topic, message)
	print('topic:', topic, 'msg:', message)
	local data = cjson.decode(message)
	if data.service == 'gpio' then
		function delayed_gpio_write(pin, delay, value)
			tmr.alarm(pin, delay, tmr.ALARM_SINGLE, function()
				print("gpio.write", pin, value)
				gpio.write(pin, value)
			end)
		end
		for pin, out in pairs(data.output) do
			pin = tonumber(pin)
			gpio.write(pin, out.value)
			print("gpio.write", pin, out.value)
			if pin >= 1 and pin <= 6 and out.delay then
				delayed_gpio_write(pin, out.delay, 1-out.value)
			end
		end
		-- data.output = nil
		-- data.inputs = {}
		-- local i
		-- for i=0,7,1 do
		-- 	data.inputs[tostring(i)] = gpio.read(i)
		-- end
	end
end)

c:on('connect', function()
	print("mqtt: connected")
	c:subscribe("/things/" .. (config.THING_NAME or wifi.sta.getmac():lower()))
	pwm.setduty(4, 0)
end)

c:on('offline', function()
	print("mqtt: offline")
	pwm.setduty(4, 256)
        c:connect(aws_sign_url(config.AWS_MQTT_URL))
end)

print('connecting to amazon mqtt gateway')
c:connect(aws_sign_url(config.AWS_MQTT_URL))
