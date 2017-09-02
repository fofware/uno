-- main.lua leds
dev_info = {
    cmd="info",
    id="NodeMCU_"..node.chipid(),
    macAddres=wifi.sta.getmac(),
    name="Luces ("..node.chipid()..")",
    site="25 de Mayo",
    account="58f6ba53cc88a860403ba2a3",
--    account="591b488ea99da571af6ecd85",
    controler={
        cosa1={
            name="Led Verde",
            site="Comedor",
            actuador={
                pin=1,
                cmd="pinSet",
                pinSet={
                    on="off",
                    off="on"
                }
                ,value="off"
            }
--[[
            ,slide={
                pin=1,
                cmd="setDimer",
                setDimer={
                    min=30,
                    max=100
                }
                ,value=100
            }
            ,sensor={
                value=10
            }
]]
        }
        ,cosa2={
            name="Led Amarillo",
            site="Garage",
            actuador={
                pin=2,
                cmd="pinSet",
                pinSet={
                    on="off",
                    off="on"
                }
                ,value="off"
            }
        }
        ,cosa3={
            name="Led Rojo",
            site="Habitacion",
            actuador={
                pin=5,
                cmd="pinSet",
                pinSet={
                    on="off",
                    off="on"
                }
                ,value="off"
            }
        }
        ,cosa4={
            name="Led Blanco",
            site="Cueva",
            actuador={
                pin=7,
                cmd="pinSet",
                pinSet={
                    on="off",
                    off="on"
                }
                ,value="off"
            }
        }
        ,cosa5={
            name="Led Azul",
            site="Susana",
            actuador={
                pin=8,
                cmd="pinSet",
                pinSet={
                    on="off",
                    off="on"
                }
                ,value="off"
            }
        }
    }
}
pinstatus = {}
pinstatus[1]=1
pinstatus[2]=2
pinstatus[5]=3
pinstatus[7]=4
pinstatus[8]=5

function procesa(ws,msg,opcode)
    if opcode == 1 then
        -- procesa mensajes de texto
        local ok, data = pcall(cjson.decode,msg);
        if ok then
            print("cmd",data.cmd);
            if data.cmd == "setTime" then
                rtctime.set(data.sec,data.usec)
                print(data.sec,data.usec)
                tm = rtctime.epoch2cal(rtctime.get())
                print(string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
            elseif data.cmd == "pinSet" then
                local cosan = string.format("cosa%d",pinstatus[data.pin])
                if data.value == "off" then
                    gpio.write(data.pin,gpio.LOW)
--                    dev_info.controler[cosan].actuador.status = data.value
                elseif data.value == "on" then
                    gpio.write(data.pin,gpio.HIGH)
                else
--                    value = not gpio.read(data.pin)
--                    gpio.write(data.pin,value)
                end
                dev_info.controler[cosan].actuador.value = data.value
                local retData = {
                    ["cmd"]="new_data",
                    controler={}
                }
                local sec, usec = rtctime.get();
                retData.controler[cosan]={actuador={value=data.value,tstop={sec=sec,usec=usec,tick=tmr.now()}}}
                local strInfo = cjson.encode(retData);
                print(strInfo);
                ws:send(strInfo);
            elseif data.cmd == "getinfo" then
                local strInfo = cjson.encode(dev_info)
                print(strInfo);
                ws:send(strInfo);
            else
                print(msg) 
                mcu_command(data.cmd);                   
            end
        else
            print('got message:', msg, opcode) -- opcode is 1 for text message, 2 for binary
        end
    else
        -- recibe binary data
    end
end
function ping()
    local sec, usec = rtctime.get();
     ws:send('{"cmd":"ping","sec":'..sec..',"usec":'..usec..'}')
--[[
    local strInfo = cjson.encode(dev_info)
    print(strInfo);
    ws:send(strInfo);
]]
end

--print("Connecting to WiFi access point...")
--print(string.format("\tDefault station config\n\tssid:\"%s\"\tpassword:\"%s\"%s", def_sta_config.ssid, def_sta_config.pwd, (type(def_sta_config.bssid)=="string" and "\tbssid:\""..def_sta_config.bssid.."\"" or "")))
--ping_timer = tmr.create()
--ping_timer:register(10000, tmr.ALARM_AUTO, ping)
