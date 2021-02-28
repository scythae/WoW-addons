local function RunTests()
	--basic table's tests
	local t = {}
	local passed = true
	local str
	
	table.insert(t, "asd");
	table.insert(t, "qwe");
	passed = passed and #t == 2 and t[1] == "asd" and t[2] == "qwe";
	
	str = ""
	local i
	for i = #t, 1, -1
	do
		str = str..t[i]
	end
	passed = passed and str == "qweasd"
	
	str = table.remove(t);
	passed = passed and #t == 1 and str == "qwe";
	
	str = table.remove(t);
	passed = passed and #t == 0 and str == "asd";
	
	table.insert(t, "asd");
	table.insert(t, "qwe");
	table.insert(t, 1, "zxc")
	passed = passed and #t == 3 and t[1] == "zxc" and t[3] == "qwe"
	
	local function TestArray()
		return "qwe", "asd", "zxc"
	end
	t = {TestArray()}
	passed = passed and #t == 3 and t[1] == "qwe" and t[3] == "zxc"
	
	local function TestUnpack(a, b, c)
		return a == 1 and b == 2 and c == 3
	end
	passed = passed and TestUnpack(unpack({1, 2, 3}))
	
	passed = passed and ({"a", "s", "d"})[3] == "d"

	--sparsed array
	t = {}
	t[123] = "a"
	t[234] = "b"
	str = ""
	local key, val
	for key, val in pairs(t)
	do
		str = str..key..val
	end
	passed = passed and str == "123a234b"
	
	--oop
	local obj = {val = 10}
	function obj:TestVal()		
		return val == nil and self.Val == nil and self.val == 10
	end
	passed = passed and obj:TestVal() 
	
	print("Healing Reporter tests passed: "..tostring(passed));
end

RunTests()