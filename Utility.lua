
ETW_Utility = {}


-------------------------------------------------------------------------------------
--  Security functions
-------------------------------------------------------------------------------------

-- Creates a sha2 hash of the parameter
function ETW_Utility:CreateSha2Hash(msg)
	return sha2.hash256(string.lower(msg))
end
-- Converts base64 to base10 data
function ETW_Utility:ConvertBase64(data)
	-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
	-- licensed under the terms of the LGPL2
	local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end


-------------------------------------------------------------------------------------
--  Utility functions
-------------------------------------------------------------------------------------


-- Deep copy of table
function ETW_Utility:CopyTable(originalTable)
	local tableCopy = {}
	for key, value in pairs(originalTable) do

		-- Recurse sub tables
		if type(value) == "table" then tableCopy[key] = ETW_Utility:CopyTable(value)
		else tableCopy[key] = value end
	end
	return tableCopy
end

-- Get name of current zone, custom function and not semi-reliable WoW zone functions
function ETW_Utility:GetCurrentZone()
	local zone = GetMapNameByID(GetCurrentMapAreaID())
	if(zone == nil) then
		return GetRealZoneText()
	else
		return zone
	end
end

-- This function will attempt to grab a subzone, but if none is available then it might equal
-- GetCurrentZone
function ETW_Utility:GetSubZone()
	local subZone = GetSubZoneText()
	if(subZone == nil or string.len(subZone) <= 0) then
		return GetRealZoneText()
	else
		return subZone
	end
end

-- Convert RGB color value to hex string usable by WoW
function ETW_Utility:RGBToStringColor(r,g,b)
	-- http://wowprogramming.com/snippets/Convert_decimal_classcolor_into_hex_27
    return string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
end

-- single char string splitter, sep *must* be a single char pattern
-- *probably* escaped with % if it has any special pattern meaning, eg "%." not "."
-- so good for splitting paths on "/" or "%." which is a common need
--http://lua-users.org/wiki/SplitJoin
function ETW_Utility:SplitString(str,sep)
	local ret={}
	local n=1
	for w in str:gmatch("([^"..sep.."]*)") do
		ret[n]=ret[n] or w -- only set once (so the blank after a string is ignored)
		if w=="" then n=n+1 end -- step forwards on a blank but not a string
	end
	return ret
end

-- My own little table initializer, taking a table of default
-- values and initializing any nil value at the same location
-- in the target table with the corresponding default value.
function ETW_Utility:DefaultingTable(defaultTable, realTable, printInfo)
	for defKey, defValue in pairs(defaultTable) do

		-- Set default values
		if(type(defValue) ~= "table") then
			if (realTable[defKey] == nil) then
				print("IS |cFFFF3F40" .. tostring(realTable[defKey]) ..  "|r  |cFF00FF00["..defKey.."]|r  SET |cFF00FF00" .. tostring(defValue))
				realTable[defKey] = defValue
			end

		-- Recurse into tables
		else
			ETW_Utility:DefaultingTable(defValue, realTable[defKey])
		end
	end
end


-------------------------------------------------------------------------------------
--  Printing to chat
-------------------------------------------------------------------------------------


function ETW_Utility:PrintToChat(msg)
	print("|cFF00FF00[Explore the World]|r|cFFFFFB00:" .. msg)
end 
function ETW_Utility:PrintErrorToChat(msg)
	print("|cFF00FF00[Explore the World]|r|cFFFFFB00:|cFFFF3F40" .. msg)
end