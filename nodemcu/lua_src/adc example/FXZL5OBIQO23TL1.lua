-- ADC pin reader
-- Written by John Longworth July 2016
-- This program prints out the value of the ADC pin

tmr.alarm(0,500,1,function()
  print(adc.read(0))
end)