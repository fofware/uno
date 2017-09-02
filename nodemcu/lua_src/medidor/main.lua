--main.lua (sensores caudalimetro)
dev_info = {
    cmd="info",
    id="NodeMCU_"..node.chipid(),
    macAddres=wifi.sta.getmac(),
    name="NodeMCU_"..node.chipid(),
    site="25 de Mayo",
    account="58f6ba53cc88a860403ba2a3",
    controler={
        s1={
            name="Caudalimetro",
            site="Depto1",
            sensor={
                pin=1,
                rel=4637500,
                div=10000,
                unit="l",
                utime="ms",
                value=0,
                time=0
            }
        }
        ,s2={
            name="Caudalimetro"
            ,site="Depto2"
            ,sensor={
				pin=2,
                rel=4637500,
                div=10000,
                unit="l",
                utime="ms",
                value=0,
                time=0
            }
        }
--[[
        ,s3={
            name="Caudalimetro"
            ,site="Local1"
            ,sensor={
				pin=3,
                rel=4637500,
                div=10000,
                unit="l",
                utime="ms"
            }
        }
]]
    }
}
pinstatus = {}
pinstatus[1]=1
pinstatus[2]=2
pinstatus[5]=3
pinstatus[7]=4
pinstatus[8]=5

dofile("sd_card.lua")
dofile("pulsecounter.lua")

function procesa(ws,msg,opcode)
    if opcode == 1 then
        -- procesa mensajes de texto
        local ok, data = pcall(cjson.decode,msg);
        if ok then
            print(data.cmd);
            if data.cmd == "setTime" then
                rtctime.set(data.sec,data.usec)
                print(data.sec,data.usec)
                tm = rtctime.epoch2cal(rtctime.get())
                print(string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"]))
            elseif data.cmd == "pinSet" then
                local cosan = string.format("cosa%d",pinstatus[data.pin])
                if data.value == "off" then
                    gpio.write(data.pin,gpio.LOW)
                elseif data.value == "on" then
                    gpio.write(data.pin,gpio.HIGH)
                else
--                    value = not gpio.read(data.pin)
--                    gpio.write(data.pin,value)
                end
                dev_info.controler[cosan].actuador.status = data.value
                local strInfo = cjson.encode(dev_info)
                print(strInfo);
                ws:send(strInfo);
            elseif data.cmd == "getinfo" then
                local strInfo = cjson.encode(dev_info)
                print(strInfo);
                ws:send(strInfo);
            else
                print(msg);
                mcu_command(data);
            end
        else
            print('got message:', msg, opcode) -- opcode is 1 for text message, 2 for binary
        end
    else
        -- recibe binary data
    end
end
--[[
function ping()
    local sec, usec = rtctime.get();

    ws:send('{"type":"ping","sec":'..sec..',"usec":'..usec..'}')
end


ping_timer = tmr.create()
ping_timer:register(10000, tmr.ALARM_AUTO, ping)
ping_timer:start();
]]
