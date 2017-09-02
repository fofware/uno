----
---- connect.lua
----
function server_connect()
    ws = websocket.createClient()
    local ok, device = pcall(cjson.encode,dev_info)
    if not ok then device = "error" end
    ws:config({headers={['User-Agent']='NodeMCU',["Publisher-Agent"]=device}})
    ws:on("connection", function(ws)
        ws_connect_timer:stop()
        ws_connected = true;
        print('got ws connection')
        local strInfo = cjson.encode(dev_info)
        print(strInfo);
        ws:send(strInfo);
    end)
    ws:on("close", function(_, status)
        print('ws connection closed', status)
        ws_connect_timer:start()
        ws_connected = false;
        ws = nil -- required to lua gc the websocket client
    end)
    ws:on("receive", procesa)
    ws:connect('ws://172.31.2.2')
end
function filetransfer(data)
    local fr = file.open(data.filename,r);
    local str_rd="";
    if fr then
        print("Read file ",data.filename);
        print("----------------------------------------")
        str_rd = fr:read(512)
        while str_rd do
            print(str_rd)
            print("****************")
            local retData = {
                cmd="filelist"
                ,dst=data.dst
                ,data=filesData
            }
            ws:send(str_rd);
            tmr.delay(1000000)
            str_rd = fr:read(512)
        end
        print("----------------------------------------")
        fr:close();
        fr = nil;
    end
end
function ws_upload(data)
--local fr = file.open(data.filename,r);
--local str_rd="";
--if fr then
    print("Read file ",data.filename);
    print("----------------------------------------")
    local retData = {
        cmd="fileread"
        ,dst=data.dst
        ,data={filename=data.filename,data=data.fd:read(512)}
    }
    if retData.data.data then
        if data.send == 0 then
            retData.data.stat = data.stat;
            retData.data.chunk="ini"
        else
            retData.data.chunk="part"
        end
        data.send = data.send + retData.data.data:len();
        if data.send >= data.stat.size then
            retData.data.chunk="end"
        end
        local ok, str_rd = pcall(cjson.encode,retData);
        --pepe = ws:send(str_rd);
        print(str_rd)
        if retData.data.chunk == "end" then
            uploading = false
            data.fd:close()
            data.fd=nil
            data=nil
        end
    else
        uploading = false
        data.fd:close()
        data.fd=nil
        data=nil
    end
    print("----------------------------------------")
end

ws_connected = false;

--local def_sta_config=wifi.sta.getdefaultconfig(true)
wifi.sta.eventMonReg(wifi.STA_IDLE, function() print("WIFI:STATION_IDLE") end)
wifi.sta.eventMonReg(wifi.STA_CONNECTING, function() print("WIFI:STATION_CONNECTING") end)
wifi.sta.eventMonReg(wifi.STA_WRONGPWD, function() 
    print("WIFI:STATION_WRONG_PASSWORD") 
    wifi.sta.eventMonStop()
    wifi.sta.disconnect()
    wifi_setup()
end)
wifi.sta.eventMonReg(wifi.STA_APNOTFOUND, function() 
    print("WIFI:STATION_NO_AP_FOUND")
    wifi.sta.eventMonStop()
    wifi.sta.disconnect()
    wifi_setup()
end)
wifi.sta.eventMonReg(wifi.STA_FAIL, function() 
    print("WIFI:STATION_CONNECT_FAIL") 
    wifi.sta.eventMonStop()
    wifi.sta.disconnect()
    wifi_setup()
end)
wifi.sta.eventMonReg(wifi.STA_GOTIP, function() 
--    print("STATION_GOT_IP")
    print ("wifi connected ok")
    print (wifi.sta.getip())
    ws_connect_timer:start()
end)
print("Connecting to WiFi access point...")
print(string.format("\tDefault station config\n\tssid:\"%s\"\tpassword:\"%s\"%s", def_sta_config.ssid, def_sta_config.pwd, (type(def_sta_config.bssid)=="string" and "\tbssid:\""..def_sta_config.bssid.."\"" or "")))

wifi.setmode(wifi.STATION)
wifi.sta.config(def_sta_config)
wifi.sta.eventMonStart(1000)

ws_connect_timer = tmr.create()
ws_connect_timer:register(5000, tmr.ALARM_AUTO, server_connect )
