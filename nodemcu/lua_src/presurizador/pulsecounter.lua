--pulsecounter.lua
pincontador = {}
function pincontador:new( obj )
    local self = obj or {}
    self.value = 0
    self.tstop = {sec=0,usec=0,tick=0}
    self.tinit = {sec=0,usec=0,tick=0}
    self.acumulador = obj.acumulador or 0
    self.acuinit = obj.acuinit or {sec=0,usec=0,tick=0}
--    self.ppl = obj.ppl or 55000
--    print(self, self.pin)
    self.set = function ()
        if self.value == 0 then
            local sec, usec = rtctime.get()
            local tick = tmr.now()
            self.tinit.sec = sec
            self.tinit.usec = usec
            self.tinit.tick = tick
            if self.acumulador == 0 then
                self.acuinit.sec=sec
                self.acuinit.usec = usec
                self.tinit.tick = tick
            end
        end
        self.value=self.value+1
        self.acumulador=self.acumulador+1
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
                value=self.value
                ,time=time
                ,tstop={
                    sec=self.tstop.sec,
                    usec=self.tstop.usec,
                    tick=self.tstop.tick
                }
                ,acumulador=self.acumulador
                ,acuinit=self.acuinit
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
    self.zero = function ()
        local retData = self:read()
        
        self.value=0
        self.acumulador = 0
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
