-- Esto se puede sacar 
uploadfile = nil
uploading = false;

function mcu_command(data)
    if data.cmd == "reset" then
        node.restart();
    elseif data.cmd == "fileupload" then
        if uploading then
            print("Ignore upload file")
        else 
            uploading = true
            uploadfile={}
            uploadfile.filename = data.filename
            uploadfile.stat = file.stat(data.filename)
            uploadfile.dst = data.dst
            uploadfile.send = 0;
            uploadfile.fd = file.open(data.filename,r);
            if uploadfile.fd then
                ws_upload(uploadfile)
            else
                uploading=false;
                uploadfile = nil
                retData = {cmd="error",dst=data.dst,data={cmd="error",data=data}}
            end
        end
    elseif data.cmd == "filecontinue" then
        ws_upload(uploadfile)
    elseif data.cmd == "filerecibe" then
        print(data.filename,data.data)
    elseif data.cmd == "filelist" then
        local dirs={"/FLASH","/SD0","/SD1"}
        local filesData = {}
        for _, dir in pairs(dirs) do
            if file.chdir(dir) then
                filesData[dir]={}
                filesData[dir].remaining, filesData[dir].used, filesData[dir].total=file.fsinfo()
                filesData[dir].files=file.list()
--                for f,d in pairs(filesData[dir].files) do
--                    filesData[dir].files[f] = file.stat(dir.."/"..f)
--                end
            end
        end
        
        local retData = {
            cmd="filelist"
            ,dst=data.dst
            ,data=filesData
        }
--        local l = file.list();
        local ok, strInfo = pcall(cjson.encode,retData);
        print(strInfo);
--        for k,v in pairs(retData.data) do
--            print("name:"..k..", size:"..v)
--        end
        ws:send(strInfo);
        strInfo = nil;
        filesData= nil;
        dirs=nil;
    else
    end
end
local cfgpin = 4  -- GPIO2 - D4
gpio.mode( cfgpin, gpio.INPUT, gpio.PULLUP )   -- GPIO 10 -- 
--gpio.write( cfgpin, gpio.LOW )
def_sta_config=wifi.sta.getdefaultconfig(true)
tmr.delay(2000000)
print("pin",cfgpin,gpio.read(cfgpin))
if gpio.read(cfgpin)==gpio.LOW  or def_sta_config.ssid == ""  then
    print("setup Mode")
--    gpio.mode( cfgpin, gpio.INPUT )   -- GPIO 10 -- 
--    gpio.write( cfgpin, gpio.LOW )
    dofile("wificonf.lua")
    wifi_setup()
else
--
--    gpio.mode( cfgpin, gpio.INPUT )
--    gpio.write( cfgpin, gpio.HIGH )
--
    gpio.mode( 0, gpio.OUTPUT ) -- GPIO 16   -- Si
    gpio.write( 0, gpio.LOW )

    gpio.mode( 1, gpio.OUTPUT ) -- GPIO 04   -- Si
    gpio.write( 1, gpio.LOW )
    gpio.mode( 2, gpio.OUTPUT ) -- GPIO 04   -- Si
    gpio.write( 2, gpio.LOW )
    gpio.mode( 3, gpio.OUTPUT ) -- GPIO 00   -- Si
    gpio.write( 3, gpio.LOW )
    gpio.mode( 4, gpio.OUTPUT ) -- GPIO 02 - D4  -- Si
    gpio.write( 4, gpio.LOW )
    gpio.mode( 5, gpio.OUTPUT ) -- GPIO 14   -- Si
    gpio.write( 5, gpio.LOW )
    gpio.mode( 7, gpio.OUTPUT )   -- GPIO 13 -- Si
    gpio.write( 7, gpio.LOW )
    gpio.mode( 8, gpio.INPUT, gpio.PULLUP )   -- GPIO 15 -- Si
    gpio.write( 8, gpio.HIGH )
--    gpio.mode( 9, gpio.OUTPUT )   -- GPIO 3 -- Si
--    gpio.write( 9, gpio.LOW )
--    gpio.mode( 10, gpio.OUTPUT )   -- GPIO 1 -- Si
--    gpio.write( 10, gpio.LOW )
--    gpio.mode( 11, gpio.OUTPUT )   -- GPIO 10 -- se cuelga
--    gpio.write( 11, gpio.LOW )
--    gpio.mode( 12, gpio.OUTPUT )   -- GPIO 9 -- se cuelga 
--    gpio.write( 12, gpio.LOW )
    dofile("main.lua")
    dofile("connect.lua")
end
print("Ready")
