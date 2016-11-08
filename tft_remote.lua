--TFT -> D1 mini
--SCLK -> D5 (GPIO14)
--MISO -> D6 (GPIO12)
--MOSI -> D7 (GPIO13)
--CS -> D8 (GPIO15)
--DC -> D1 (GPIO5)
--RST -> D3 (GPIO0), or just connect to 3v3
--100k on LED line


topic_root = "test/display/"


function init_spi_display()

	local cs = 8 --pull down 10k to GND
	local dc = 3
	local res = 4

	spi.setup(1, spi.MASTER, spi.CPOL_LOW, spi.CPHA_LOW, 8, 8)
	gpio.mode(8, gpio.INPUT, gpio.PULLUP)

	disp = ucg.ili9341_18x240x320_hw_spi(cs, dc, res)

end

function draw_pixel(args)
	xI = tonumber(args[1])
	yI = tonumber(args[2])
	rI = tonumber(args[3])
	gI = tonumber(args[4])
	bI = tonumber(args[5])


	disp:setColor(0, rI, gI, bI)
	disp:drawPixel(xI, yI)
end

function draw_string(input, offset)
	disp:setColor(0, 255, 255, 255) -- Get rid of this, do in setup + give seperate call

	string = tostring(input)
	disp:drawString(240, (320 - offset), 2, string)
end

function printString(string)
	strings = split(string, " ")
	printLongest(strings, "", 20)
end

function printLongest(stack, buffer, offset) 

	if next(stack) == nil then
		return
	end

	fullStack = table.concat(stack, " ")
	s = table.remove(stack, 1)
	buffer = buffer..s.." "
	if disp:getStrWidth(fullStack) <= disp:getWidth() then --I do not like this
		offset = offset + 20
		draw_string(fullStack, offset)
		return
	elseif disp:getStrWidth(buffer) < disp:getWidth() then
		printLongest(stack, buffer, offset)
	else
		return
	end
	draw_string(buffer, offset)

	offset = offset + 20
	printLongest(stack, "", offset)
end



function handle_message(client, topic, data) 
	t = tostring(topic) --is this conversion needed?
	print("Got topic:"..topic)
	path = split(t,"/")
	cmd = path[3]
	if cmd == "draw" then
		--draw a pixel
		input = tostring(data)
		args = split(input,"/")
		draw_pixel(args)
	elseif cmd == "clear" then
		disp:clearScreen()
	elseif cmd == "print" then
		string = tostring(data)
		printString(string)
	end
end

function split(input, sep)
	res = {}
	regex = "([^"..sep.."]+)"
	for token in string.gmatch(input, regex) do
		table.insert(res, token)
	end
	return res
end


init_spi_display()

disp:begin(ucg.FONT_MODE_TRANSPARENT)
disp:setFont(ucg.font_ncenR14_hr)
disp:clearScreen()

m = mqtt.Client("espNode", 120, "", "")
m:on("connect",
	function()
		print("connected")
		m:subscribe(topic_root.."#", 0, print("subscribed to pixel"))
	end)

m:on("message",
	function(client, topic, data)
		handle_message(client, topic, data)
	end)

m:connect("192.168.1.12")