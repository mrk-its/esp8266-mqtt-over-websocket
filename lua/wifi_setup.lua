local config = require('config')

local function listap(t)
  for ssid, v in pairs(t) do
    print(ssid, v)
    if config.AP[ssid] then
      print("connecting to "..ssid)
      wifi.sta.config({ssid=ssid, pwd=config.AP[ssid], auto=false})
      wifi.sta.connect()
      break
    end
  end
end

local function wifi_status_cb(prev)
    local status = wifi.sta.status()
    print("Wifi status:", status)
    if status == wifi.STA_GOTIP and wifi.sta.getip() then
	print('Got ip:', wifi.sta.getip())
	sntp.sync('0.pl.pool.ntp.org', function()
		print('time set')
		require('mqtt_test')
	end)
	pwm.setduty(4, 256)
    elseif status == wifi.STA_FAIL or status == wifi.STA_APNOTFOUND then
        wifi.sta.getap(listap)
    else
	pwm.setduty(4, 768)
    end
end

wifi.sta.eventMonReg(wifi.STA_IDLE, wifi_status_cb)
wifi.sta.eventMonReg(wifi.STA_CONNECTING, wifi_status_cb)
wifi.sta.eventMonReg(wifi.STA_WRONGPWD, wifi_status_cb)
wifi.sta.eventMonReg(wifi.STA_APNOTFOUND, wifi_status_cb)
wifi.sta.eventMonReg(wifi.STA_FAIL, wifi_status_cb)
wifi.sta.eventMonReg(wifi.STA_GOTIP, wifi_status_cb)

print('MAC: ', wifi.sta.getmac())
print('chip: ', node.chipid())
print('heap: ', node.heap())

wifi.sta.disconnect()
gpio.mode(4, gpio.OUTPUT)

pwm.setup(4, 2, 768)
pwm.start(4)

wifi.setmode(wifi.STATION)
wifi.sta.eventMonStart()
wifi.sta.getap(listap)

