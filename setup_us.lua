wifi.setmode(wifi.STATIONAP)
--wifi.ap.setip({ip="192.168.4.1", netmask="255.255.255.0", gateway="192.168.4.1"})
--wifi.ap.config({ssid="ESP8266", auth=wifi.OPEN})
enduser_setup.manual(false)

enduser_setup.start(
  function()
    print("Conectado na rede wifi com o ip: ".. wifi.sta.getip())
    --enduser_setup.stop()
  end,
  function(err, str)
    print("enduser_setup: Erro #" .. err .. ": " .. str)
  end,
  function(str)
    print("debug: " .. str)
  end
)
