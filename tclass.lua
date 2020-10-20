local tclass= {}
local setmetatable=setmetatable
local getmetatable=getmetatable
local assert = assert
local rawequal=rawequal
local type=type
local mt = {}
local function get(func, t, k)
    if type(func)=="table" then
        return func[k]
    elseif type(func)=="function" then
        return func(t, k)
    else
        error("get(): Invalid __index type")
    end
end
instancebannedfunctions={}
function tclass:new(args)
    local o = {}
    setmetatable(o, setmetatable({__metatable=self,__index=setmetatable({}, {__index=function (t, k) local got=get(self, t, k) for _, v in pairs(instancebannedfunctions) do if got==v then return nil end end return got end})}, {__index=self}))
    if o.init then
        assert(type(o.init)=="function", "Class:init() must be a function (or nil)")
        o:init(args) end
    return o
end
function tclass:getSuperclass()
    return ((self==tclass) and tclass) or getmetatable(self)
end
function tclass:extend()
        local o = {}
        setmetatable(o, self)
        if o.init then
            assert(type(o.init)=="function", "Class:init() must be a function (or nil)") end
    o.__call=tclass.new
    o.__index=setmetatable({ getSuperclass=tclass.getSuperclass, is=tclass.is}, {__index=function (_, k) return o[k] end})
    return o
end
local notallowed={}
notallowed.__call=true
notallowed.__metatable=true
function tclass:include(mixin)
    for k, v in pairs(mixin) do
        if self[k] then
            if k=="init" then

                assert(type(v)=="function", "Mixin:init() must be a function (or nil)")
                assert(type(self.init)=="function", "Class:init() must be a function (or nil)")
                local o=self.init
                self.init = function(_o, args)
                    _o=v(_o, args)
                    _o=o(_o, args)
                    return _o
                end
            elseif k=="__index" then
                assert(type(v)=="function" or type(v)=="table", "Mixin.__index must be a function or a table.")
                assert(type(self.__index)=="function" or type(self.__index)=="table", "Class.__index must be a function or a table.")
                local o = self.__index
                self.__index = function(t, z)
                    if rawget(t, z)~=nil then return rawget(t, z) elseif v[z]~=nil then return v[z] else return get(o, t, z) end
                end
            else
                assert(not notallowed[k], k.." isn't allowed in a Mixin")
                if type(v)=="function" and type(self[k])=="function" then
                    local o = self[k]
                    self[k]=function(...)
                        v(...)
                        o(...)
                    end
                else
                    if not rawequal(self[k], v) then error("Conflicting Values from Class: ( " ..tostring(self[k]).." ) and Mixin ( " .. tostring(v) .. " )") end
                end
            end
        else self[k]=v end
    end
end
function tclass:is(class)
    local curclass=self
    local found=false
    repeat
        if curclass==class then found=true else curclass=curclass:getSuperclass() end
    until found==true or rawequal(tclass, curclass)
    return found or rawequal(tclass, class)
end
mt.__tostring=function() return "base class" end
mt.__call=tclass.extend
mt.__index=mt
tclass.__index=tclass
tclass.__call=tclass.new
setmetatable(tclass, mt)
table.insert(instancebannedfunctions, tclass.new)
table.insert(instancebannedfunctions, tclass.extend)
table.insert(instancebannedfunctions, tclass.include)
return tclass