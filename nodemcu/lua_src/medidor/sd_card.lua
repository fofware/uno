-- sd_card.lua
spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 8)
function save_last(reg)
    if file.open("/SD0/lastsend.dat", "w+") then
        file.write(reg)
        file.close()
    end
end
function file_last()
    local last = 0
    if file.open("/SD0/lastsend.dat", "r") then
        last = tonumber(file.read() or 0)
        file.close()
    end
    return last
end
function file_size(file_name)
    local size = 0
    if file.open(file_name, "r") then
        size = file.seek("end")
        file.close()
    end
    return size
end
tosend = {}
function tosend:new(obj)
    local self = obj or {}
    self.last = obj.last or 0
    self.size = obj.size or file_size("/SD0/tosend.dat")
    self.interval = obj.interval or 100000
    if self.last > self.size then 
        self.last = 0 
        save_last(self.last)
    end
    if self.size then self.interval = 1000 end
    self.func = obj.func or function ()
        if sk_connected then
--            print (self.last,self.size)
            if self.last < self.size then
                self.register(1000)
                if file.open("/SD0/tosend.dat", "r") then
--                    print ("size: "..self.size.." bytes")
--                    print (self.size-self.last.." bytes to send")
                    if self.last < self.size then 
                        file.seek("set",self.last)
                        local str_data = file.read('\n')
                        if str_data then
                            print("send data ("..str_data:len()..") ="..str_data)
                            self.last = self.last + str_data:len()
                            sk:send(str_data)
                        end
                        file.close()
                        str_data = nil
                        if self.last == self.size then 
                            print("borra archivo")
                            file.remove("/SD0/tosend.dat")
                            self.last = 0
                            self.size = 0
                        end
                        save_last(self.last)
                    end
                end
            else
                self.register(100000)
                local new_data = data_header()
                new_data.tipo = "ping"
                tm = rtctime.epoch2cal(rtctime.get())
                new_data.fecha = string.format("%04d/%02d/%02d %02d:%02d:%02d", tm["year"], tm["mon"], tm["day"], tm["hour"], tm["min"], tm["sec"])

                local ok, str_data = pcall(cjson.encode,new_data)
                if ok then
                    sk:send(str_data.."\r\n")
                end
                new_data = nil
            end
        end
        print(node.heap())
        collectgarbage()
        print(node.heap())
    end
    self.register = function ( interval )
        if self.interval ~= interval then
            self.interval = interval
            self.timer:stop()
            self.timer:register(self.interval, tmr.ALARM_AUTO, self.func )
            self.timer:start()
        end
    end
    self.timer = tmr.create()
    self.timer:register(self.interval, tmr.ALARM_AUTO, self.func )
    return self
end

vol = file.mount("/SD0", 8)
if not vol then 
    print("retry mounting")
    vol = file.mount("/SD0", 8)
    if not vol then
        error ("mount failed")
    end
end
file.open("/SD0/config.json")
conf=file.read()
file.close()
print (conf)
