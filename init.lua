function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

function lines_from(file)
	if not file_exists(file) then return {} end
	lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
end

wifi.setmode(wifi.STATION)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, discon1)
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, connec1)
wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, timeou1)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, gotip1)
wifi.eventmon.register(wifi.eventmon.STA_AUTHMODE_CHANGE, authc1)

--wifi.sta.eventMonReg(wifi.STA_IDLE, function() print("STATION_IDLE") end)
--wifi.sta.eventMonReg(wifi.STA_CONNECTING, function() print("STATION_CONNECTING") end)
--wifi.sta.eventMonReg(wifi.STA_WRONGPWD, function() print("STATION_WRONG_PASSWORD") end)
--wifi.sta.eventMonReg(wifi.STA_APNOTFOUND, function() print("STATION_NO_AP_FOUND") end)
--wifi.sta.eventMonReg(wifi.STA_FAIL, function() print("STATION_CONNECT_FAIL") end)
--wifi.sta.eventMonReg(wifi.STA_GOTIP, function() print("STATION_GOT_IP") end)

sv = nil;

station_cfg={}
station_cfg.ssid="ssid"
station_cfg.pwd="password"
station_cfg.save=true
station_cfg.auto=true
wifi.sta.config(station_cfg)

function discon1(T)
	print("\n\tSTA - DISCONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..T.BSSID.."\n\treason: "..T.reason.."\n")
end

function connec1(T)
	print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..T.BSSID.."\n\tChannel: "..T.channel)
end

function timeou1(T)
	print("\n\tSTA - DHCP TIMEOUT")
end

function authc1(T)
	print("\n\tSTA - AUTHMODE CHANGE".."\n\told_auth_mode: "..T.old_auth_mode.."\n\tnew_auth_mode: "..T.new_auth_mode)
end

function gotip1(T)
	print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..T.netmask.."\n\tGateway IP: "..T.gateway)

	if (sv ~= nil) then
		sv:close();
		sv = nil;
	end

	sv=net.createServer(net.TCP,60)
	sv:listen(80,function(c)
		c:on("receive", function(sck, req)
			led = {string.find(req, "LED=")}
			print("Command received: " .. req)
			if (led[2] ~= nil) then
				cmd = string.sub(req, led[2] + 1, #req)
				if (cmd ~= nil) then
					print("--- Led --- " .. cmd .. "--- LED ---")
					if (cmd == "ON") then
						gpio.write(0, gpio.LOW)
					else if (cmd == "OFF") then
						gpio.write(0, gpio.HIGH)
					end
				end
			end
		end 

		local ht = {}
		table.insert(ht, "<html>")
		table.insert(ht, "<head><title>NodeMCU Led Control</title></head>")
		table.insert(ht, "<body>")
		table.insert(ht, "<h1>Led Control</h1>")
		table.insert(ht, "<form method=\"post\">")
		table.insert(ht, "<input type=\"submit\" name=\"LED\" value=\"ON\">")
		table.insert(ht, "<input type=\"submit\" name=\"LED\" value=\"OFF\">")
		table.insert(ht, "</form>")
		table.insert(ht, "</body>")
		table.insert(ht, "</html>")
		local sht = 0
		for key, value in pairs(ht) do
			sht = sht + string.len(value) + 1
		end

		table.insert(ht, 1, "HTTP/1.0 200 OK")
		table.insert(ht, 2, "Server: ESP (nodeMCU)")
		table.insert(ht, 3, "Content-Type: text/html; charset=UTF-8")
		table.insert(ht, 4, "Content-Length: " .. sht .. "\n")

		local function sender (sck)
			if #ht>0 then 
				sck:send(table.remove(ht,1) .. "\n")
			else 
				sck:close()
			end
		end
		sck:on("sent", sender)
		sender(sck)
	end)
	end)
end

