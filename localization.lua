
local addon, ns = ...;
ns.L = setmetatable({}, { __index = function(t, k) local v=tostring(k) rawset(t, k, v) return v end });
local L = ns.L;

if LOCALE_deDE then
	@localization(locale="deDE", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="none")@
end

--if LOCALE_esES or LOCALE_esMX then end

--if LOCALE_frFR then end

--if LOCALE_itIT then end

--if LOCALE_koKR then end

--if LOCALE_ptBR then end

--if LOCALE_ruRU then end

--if LOCALE_zhCN then end

--if LOCALE_zhTW then end
