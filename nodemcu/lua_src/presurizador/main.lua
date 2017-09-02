-- main.lua leds

dev_info = {
    cmd="info",
    id="NodeMCU_"..node.chipid(),
    macAddres=wifi.sta.getmac(),
    name="Trapax ("..node.chipid()..")",
    site="Casa Trapito",
    account="58f6ba53cc88a860403ba2a3",
--    account="591b488ea99da571af6ecd85",
    controler={
        bomba={
            name="Bomba",
            site="(pin1-GPIO5-D1)(pin2-GPIO4-D2)",
            status=1,
            actuador={
                pin=1,
                mode="auto",
                cmd="pinSet",
                pinSet={
                    on="off",
                    off="on"
                }
                ,value="off"
            }
            ,sensor={
                pin=2,
                rel=4637500,
                div=10000,
                unit="l",
                utime="ms",
                value=0,
                time=0,
                acumulador=0,
                lastcounter={
                    tinit={sec=0,usec=0},
                    tstop={sec=0,usec=0},
                    value=0
                },
                counter={
                    tinit={sec=0,usec=0},
                    value=0
                }
            }
        }
        ,bombaup={
            name="Bomba"
            ,site="(pin0-GPIO16-D0)(Pin4-GPIO02-D4)"
            ,status=1
            ,actuador={
                pin=0,
                mode="auto",
                cmd="pinSet",
                pinSet={
                    on="off",
                    off="on"
                }
                ,value="off"
            }
            ,sensor={
                pin=4,
                rel=4637500,
                div=10000,
                unit="l",
                utime="ms",
                value=0,
                time=0,
                acumulador=0,
                lastcounter={
                    tinit={sec=0,usec=0},
                    tstop={sec=0,usec=0},
                    value=0
                },
                counter={
                    tinit={sec=0,usec=0},
                    value=0
                }
            }
        }
        ,cosa2={
            name="GPIO00 - Pin03 - D03"
            ,site="flash"
            ,status=1
            ,actuador={
                pin=3,
                mode="auto",
                cmd="pinSet",
                pinSet={
                    on="off",
                    off="on"
                }
                ,value="off"
            }
        }
        ,cosa1={
            name="(pin5-GPIO14-D5)"
            ,site=""
            ,status=1
            ,actuador={
                pin=5,
                mode="auto",
                cmd="pinSet",
                pinSet={
                    on="off",
                    off="on"
                }
                ,value="off"
            }
        }
--[[
        ,cosa3={
            name="Pin"
            ,site="5"
            ,status=1
            ,actuador={
                pin=5,
                mode="auto",
                cmd="pinSet",
                pinSet={
                    on="off",
                    off="on"
                }
                ,value="off"
            }
        }
]]
        ,cosa4={
            name="Pin07 - GPIO13"
            ,site="D7"
            ,status=1
            ,actuador={
                pin=7,
                mode="auto",
                cmd="pinSet",
                pinSet={
                    on="off",
                    off="on"
                }
                ,value="off"
            }
        }
--[[
        ,cosa5={
            name="Pin08 - GPIO15"
            ,site="D8"
            ,status=1
            ,actuador={
                pin=8,
                mode="auto",
                cmd="pinSet",
                pinSet={
                    on="off",
                    off="on"
                }
                ,value="off"
            }
        }
]]
    }
}
actuadorpin = {}
sensorpin = {}
for cosan, ct in pairs(dev_info.controler) do
    if (ct.actuador) then
        if (ct.actuador.pin) then
            actuadorpin[ct.actuador.pin]=cosan
        end
    end
    if (ct.sensor) then
        if (ct.sensor.pin) then
            sensorpin[ct.sensor.pin]=cosan
        end
    end
end


dofile("pulsecounter.lua")
ct_uno = pincontador:new({pin = 2,name=sensorpin[2]})
ct_cinco = pincontador:new({pin = 4,name=sensorpin[4]})
function read_new_data()
    local msg = {} --data_header()
    msg["cmd"] = "new_data"
    msg.controler = {}
    local new_data = false
    if ct_uno then 
        if ct_uno.value > 0 then
            msg.controler[ct_uno["name"]] = ct_uno:reset()
            gpio.write(1,gpio.HIGH)
            new_data = true
        else
            if dev_info.controler[ct_uno["name"]].actuador.mode == "auto" then
                gpio.write(1,gpio.LOW)
            end
            if gpio.read(1) == 1 and dev_info.controler[ct_uno["name"]].actuador.mode == "manual"then 
                if not ct_uno.vacio then ct_uno.vacio = 0 end
                ct_uno.vacio=ct_uno.vacio+1
                if ct_uno.vacio == 10 then
                    gpio.write(1,gpio.LOW)
                    ct_uno.vacio=0
                    msg.controler[ct_uno["name"]]={actuador={}}
                    msg.controler[ct_uno["name"]].actuador.value = "off"
                    dev_info.controler[ct_uno["name"]].actuador.mode = "auto"
                    new_data = true
                end
            end
        end
    end
    if ct_cinco then 
        if ct_cinco.value > 0 then
            msg.controler[ct_cinco["name"]] = ct_cinco:reset()
            gpio.write(0,gpio.HIGH)
            new_data = true
        else
            if dev_info.controler[ct_cinco["name"]].actuador.mode == "auto" then
                gpio.write(0,gpio.LOW)
            end
            if gpio.read(0) == 1 and dev_info.controler[ct_cinco["name"]].actuador.mode == "manual" then 
                if not ct_cinco.vacio then ct_cinco.vacio = 0 end
                ct_cinco.vacio=ct_cinco.vacio+1
                if ct_cinco.vacio == 10 then
                    gpio.write(0,gpio.LOW)
                    ct_cinco.vacio=0
                    msg.controler[ct_cinco["name"]]={actuador={}}
                    msg.controler[ct_cinco["name"]].actuador.value = "off"
                    dev_info.controler[ct_cinco["name"]].actuador.mode = "auto"
                    new_data = true
                end
            end
        end
    end
    

    if new_data then
--        if stored_data.timer:state() then stored_data.timer:stop() end
        local ok, str_data = pcall(cjson.encode,msg)
        msg = nil
        if ok then
            if ws_connected then
                ws:send(str_data)
                print("send",str_data)
            else
--[[
                if file.open("/SD0/tosend.dat", "a+") then
                    -- write 'foo bar' to the end of the file
                    file.writeline(str_data)
                    file.close()
                    print("store",str_data)
                    stored_data.size = file_size("/SD0/tosend.dat")
                    stored_data.register(1000)
                end
]]
            end
            str_data = nil
        end
--        stored_data.timer:start()
    end
    new_data = nil
end
--[[
function data_header()
    local sec, usec = rtctime.get()
    return {
        id="NodeMCU_"..node.chipid(),
        macAddres=wifi.sta.getmac(),
        name="NodeMCU_"..node.chipid(),
        site="25 de Mayo",
        account="58f6ba53cc88a860403ba2a3",
        ttime={sec=sec,usec=usec,tick=tmr.now()},
        id=node.chipid(),
        heap=node.heap(),
        macaddres=wifi.ap.getmac()
    }
end
]]
new_data_timer = tmr.create()
new_data_timer:register(200, tmr.ALARM_AUTO, read_new_data )
new_data_timer:start()

function procesa(ws,msg,opcode)
    if opcode == 1 then
        -- procesa mensajes de texto
        local ok, data = pcall(cjson.decode,msg);
        if ok then
            print("cmd",data.cmd);
--            print(msg)
            if data.cmd == "setTime" then
                rtctime.set(data.sec,data.usec)
                print(data.sec,data.usec)
                tm = rtctime.epoch2cal(rtctime.get())
                print(string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
            elseif data.cmd == "pinSet" then
--                local cosan = string.format("cosa%d",pinstatus[data.pin])
                local cosan = actuadorpin[data.pin]
                if data.value == "off" then
                    gpio.write(data.pin,gpio.LOW)
                    dev_info.controler[cosan].actuador.mode = "auto"
                elseif data.value == "on" then
                    gpio.write(data.pin,gpio.HIGH)
                    dev_info.controler[cosan].actuador.mode = "manual"
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
                mcu_command(data);                   
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
end

print ("leer 8",gpio.read(8))