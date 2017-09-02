function wifi_setup()
    print("Starting setup mode")
    enduser_setup.start(
        function()
            print("Connected to wifi as:" .. wifi.sta.getip())
        end,
        function(err, str)
            print("enduser_setup: Err #" .. err .. ": " .. str)
        end
    );
        print("\n  Default SoftAP configuration:")
    print(wifi.ap.getip())
end
