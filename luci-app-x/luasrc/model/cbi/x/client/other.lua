local api = require "luci.model.cbi.x.api.api"
local appname = api.appname

m = Map(appname)

-- [[ Forwarding Settings ]]--
s = m:section(TypedSection, "global_forwarding",
              translate("Forwarding Settings"))
s.anonymous = true
s.addremove = false

---- TCP No Redir Ports
o = s:option(Value, "tcp_no_redir_ports", translate("TCP No Redir Ports"))
o.default = "disable"
o:value("disable", translate("No patterns are used"))
o:value("1:65535", translate("All"))

---- UDP No Redir Ports
o = s:option(Value, "udp_no_redir_ports", translate("UDP No Redir Ports"),
             "<font color='red'>" .. translate(
                 "Fill in the ports you don't want to be forwarded by the agent, with the highest priority.") ..
                 "</font>")
o.default = "disable"
o:value("disable", translate("No patterns are used"))
o:value("1:65535", translate("All"))

---- TCP Redir Ports
o = s:option(Value, "tcp_redir_ports", translate("TCP Redir Ports"))
o.default = "22,25,53,143,465,587,993,995,80,443"
o:value("1:65535", translate("All"))
o:value("22,25,53,143,465,587,993,995,80,443", translate("Common Use"))
o:value("80,443", translate("Only Web"))
o:value("80:65535", "80 " .. translate("or more"))
o:value("1:443", "443 " .. translate("or less"))

---- UDP Redir Ports
o = s:option(Value, "udp_redir_ports", translate("UDP Redir Ports"))
o.default = "1:65535"
o:value("1:65535", translate("All"))
o:value("53", "DNS")

--[[
---- Proxy IPv6
o = s:option(Flag, "proxy_ipv6", translate("Proxy IPv6"),
             translate("The IPv6 traffic can be proxyed when selected"))
o.default = 0
--]]

--[[
---- TCP Redir Port
o = s:option(Value, "tcp_redir_port", translate("TCP Redir Port"))
o.datatype = "port"
o.default = 1041
o.rmempty = true

---- UDP Redir Port
o = s:option(Value, "udp_redir_port", translate("UDP Redir Port"))
o.datatype = "port"
o.default = 1051
o.rmempty = true
--]]

-- [[ Other Settings ]]--
s = m:section(TypedSection, "global_other", translate("Other Settings"))
s.anonymous = true
s.addremove = false

o = s:option(MultiValue, "status", translate("Status info"))
o:value("show_check_port", translate("Show node check")) -- 显示节点检测
o:value("show_ip111", translate("Show Show IP111")) -- 显示IP111

-- [[ App Settings ]]--
s = m:section(TypedSection, "global_app", "")
s.anonymous = true
s:append(Template(appname .. "/xray_version"))

o = s:option(Value, "xray_file", translatef("%s App Path", "Xray"))
o.default = "/usr/bin/xray"
o.rmempty = false

return m
