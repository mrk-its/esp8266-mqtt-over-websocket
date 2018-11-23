local config = {
}

local AP = {
}

AP["WIFI_SSID"] = 'WIFI_PASSWORD'

config.AP = AP
config.AWS_ACCESS_KEY = 'YOUR_AWS_ACCESS_KEY'
config.AWS_SECRET_KEY = 'YOUR_AWS_SECRET_KEY'
config.AWS_REGION = 'eu-central-1'
config.AWS_MQTT_URL = 'wss://xxxx.iot.eu-central-1.amazonaws.com/mqtt'

config.THING_NAME = 'thing'

return config
