--pulsecounter.lua
pincontador = {}
function pincontador:new( obj )
    local self = obj or {}
    self.value = 0
    self.tstop = {sec=0,usec=0,tick=0}
    self.tinit = {sec=0,usec=0,tick=0}
--    self.ppl = obj.ppl or 55000
--    print(self, self.pin)
    self.set = function ()
        if self.value == 0 then
            self.tinit.sec, self.tinit.usec = rtctime.get()
            self.tinit.tick = tmr.now()
        end
        self.value=self.value+1
    end
    self.read = function ()
        self.tstop.tick = tmr.now()
        self.tstop.sec, self.tstop.usec = rtctime.get()
        local time = 0
        if self.tstop.sec > 0 then
            time = (((self.tstop.sec*1000000)+self.tstop.usec) - ((self.tinit.sec*1000000)+self.tinit.usec))/1000
        else
            time = (self.tstop.tick - self.tinit.tick)/1000
        end
        return { 
            sensor={
                value=self.value,
                time=time
                ,tstop={
                    sec=self.tstop.sec,
                    usec=self.tstop.usec,
                    tick=self.tstop.tick
                }
--[[
                ,tinit={
                    sec=self.tinit.sec,
                    usec=self.tinit.usec,
                    tick=self.tinit.tick
                }
]]
            }
        }
    end
    self.reset = function ()
        local retData = self:read()
        self.value = 0
        self.tinit.tick = tmr.now()
        self.tinit.sec, self.tinit.usec = rtctime.get()
        return retData
    end
    gpio.mode(self.pin, gpio.INT ) --  (interrupt mode)
--    gpio.trig(self.pin, "both", 
    gpio.trig(self.pin, "up", 
--    gpio.trig(self.pin, "down", 
        function()
            self:set()
        end
    )
    return self
end
function read_new_data()
--[[
    if gpio.read(4) == gpio.HIGH then
        gpio.write( 4, gpio.LOW )
    else
        gpio.write( 4, gpio.HIGH )
    end
]]
    local msg = {} --data_header()
    msg["cmd"] = "new_data"
    msg.controler = {}
    local new_data = false
    if ct_uno then 
        if ct_uno.value > 0 then
            msg.controler.s1 = ct_uno:reset()
--            data.value.s1.id = "s1"
--            data.value.s1.name = "Caudalimetro 1"
            new_data = true
        end
    end
    if ct_dos then 
        if ct_dos.value > 0 then
            msg.controler.s2 = ct_dos:reset() 
--            data.value.s2.id = "s2"
--            data.value.s2.name = "Caudalimetro 2"
            new_data = true
        end
    end
    if ct_tres then 
        if ct_tres.value > 0 then
            msg.controler.s3 = ct_tres:reset() 
--            data.value.s3.id = "s3" 
--            data.value.sr3.name = "Caudalimetro 3"
            new_data = true
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
                if file.open("/SD0/tosend.dat", "a+") then
                    -- write 'foo bar' to the end of the file
                    file.writeline(str_data)
                    file.close()
                    print("store",str_data)
                    stored_data.size = file_size("/SD0/tosend.dat")
                    stored_data.register(1000)
                end
            end
            str_data = nil
        end
--        stored_data.timer:start()
    end
    new_data = nil
end
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
ct_uno = pincontador:new({pin = 1})
ct_dos = pincontador:new({pin = 2})

new_data_timer = tmr.create()
new_data_timer:register(1000, tmr.ALARM_AUTO, read_new_data )
new_data_timer:start()
