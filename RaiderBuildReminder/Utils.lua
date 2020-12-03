local AddonName, AddonTable = ...

AddonTable.utils = {}

AddonTable.utils.foreach_ = function(table, func)
    local i
    for i = 1, #table do
        func(table[i])        
    end      
end

AddonTable.utils.printVal = function(val)
    if type(val) == "table" then
        AddonTable.utils.printTable(val)
    else
        print(tostring(val))
    end
end

AddonTable.utils.printTable = function(table, indent)
    indent = indent or ""
	local key, val
	for key, val in pairs(table)
    do
        if type(val) == "table" then
            AddonTable.utils.printTable(val, indent..". ")
        else
            print(key, tostring(val))
        end
	end  
end