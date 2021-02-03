local uci = require"luci.model.uci".cursor()
local api = require "luci.model.cbi.x.api.api"
local appname = api.appname

local v_ss_encrypt_method_list = {
    "aes-128-cfb", "aes-256-cfb", "aes-128-gcm", "aes-256-gcm", "chacha20", "chacha20-ietf", "chacha20-poly1305", "chacha20-ietf-poly1305"
}

local security_list = {"none", "auto", "aes-128-gcm", "chacha20-poly1305"}

local header_type_list = {
    "none", "srtp", "utp", "wechat-video", "dtls", "wireguard"
}
local force_fp = {
    "disable", "firefox", "chrome", "ios"
}

m = Map(appname, translate("Node Config"))
m.redirect = api.url()

s = m:section(NamedSection, arg[1], "nodes", "")
s.addremove = false
s.dynamic = false

share = s:option(DummyValue, "x", translate("Share Current"))
share.rawhtml  = true
share.template = "x/node_list/link_share_man"
share.value = arg[1]

remarks = s:option(Value, "remarks", translate("Node Remarks"))
remarks.default = translate("Remarks")
remarks.rmempty = false

type = s:option(ListValue, "type", translate("Type"))
if api.is_finded("xray") then
    type:value("Xray", translate("Xray"))
    type.description = translate("Xray is currently directly compatible with V2ray and used.")
end

protocol = s:option(ListValue, "protocol", translate("Protocol"))
protocol:value("vmess", translate("Vmess"))
protocol:value("vless", translate("VLESS"))
protocol:value("http", translate("HTTP"))
protocol:value("socks", translate("Socks"))
protocol:value("shadowsocks", translate("Shadowsocks"))
protocol:value("trojan", translate("Trojan"))
protocol:value("_balancing", translate("Balancing"))
protocol:value("_shunt", translate("Shunt"))
protocol:depends("type", "Xray")

local nodes_table = {}
for k, e in ipairs(api.get_valid_nodes()) do
    if e.node_type == "normal" then
        nodes_table[#nodes_table + 1] = {
            id = e[".name"],
            remarks = e.remarks_name
        }
    end
end

-- 负载均衡列表
balancing_node = s:option(DynamicList, "balancing_node", translate("Load balancing node list"), translate("Load balancing node list, <a target='_blank' href='https://toutyrater.github.io/routing/balance2.html'>document</a>"))
for k, v in pairs(nodes_table) do balancing_node:value(v.id, v.remarks) end
balancing_node:depends("protocol", "_balancing")

-- 分流
uci:foreach(appname, "shunt_rules", function(e)
    o = s:option(ListValue, e[".name"], '<a href="../shunt_rules/' .. e[".name"] .. '">' .. translate(e.remarks) .. "</a>")
    o:value("nil", translate("Close"))
    for k, v in pairs(nodes_table) do o:value(v.id, v.remarks) end
    o:depends("protocol", "_shunt")

    o = s:option(Flag, e[".name"] .. "_proxy", translate(e.remarks) .. translate("Preproxy"), translate("Use the default node for the transit."))
    o.default = 0
    o:depends("protocol", "_shunt")
end)

shunt_tips = s:option(DummyValue, "shunt_tips", " ")
shunt_tips.rawhtml = true
shunt_tips.cfgvalue = function(t, n)
    return string.format('<a style="color: red" href="../rule">%s</a>', translate("No shunt rules? Click me to go to add."))
end
shunt_tips:depends("protocol", "_shunt")

default_node = s:option(ListValue, "default_node", translate("Default") .. " " .. translate("Node"))
default_node:value("nil", translate("Close"))
for k, v in pairs(nodes_table) do default_node:value(v.id, v.remarks) end
default_node:depends("protocol", "_shunt")

default_proxy = s:option(Flag, "default_proxy", translate("Default") .. translate("Node") .. translate("Preproxy"), translate("Use the under node for the transit."))
default_proxy.default = 0
default_proxy:depends("protocol", "_shunt")

o = s:option(ListValue, "main_node", " ")
for k, v in pairs(nodes_table) do o:value(v.id, v.remarks) end
o:depends("default_proxy", "1")

domainStrategy = s:option(ListValue, "domainStrategy", translate("Domain Strategy"))
domainStrategy:value("AsIs")
domainStrategy:value("IPIfNonMatch")
domainStrategy:value("IPOnDemand")
domainStrategy.description = "<br /><ul><li>" .. translate("'AsIs': Only use domain for routing. Default value.")
.. "</li><li>" .. translate("'IPIfNonMatch': When no rule matches current domain, resolves it into IP addresses (A or AAAA records) and try all rules again.")
.. "</li><li>" .. translate("'IPOnDemand': As long as there is a IP-based rule, resolves the domain into IP immediately.")
.. "</li></ul>"
domainStrategy:depends("protocol", "_balancing")
domainStrategy:depends("protocol", "_shunt")

address = s:option(Value, "address", translate("Address (Support Domain Name)"))
address.rmempty = false
address:depends({ type = "Xray", protocol = "vmess" })
address:depends({ type = "Xray", protocol = "vless" })
address:depends({ type = "Xray", protocol = "http" })
address:depends({ type = "Xray", protocol = "socks" })
address:depends({ type = "Xray", protocol = "shadowsocks" })
address:depends({ type = "Xray", protocol = "trojan" })

--[[
use_ipv6 = s:option(Flag, "use_ipv6", translate("Use IPv6"))
use_ipv6.default = 0
use_ipv6:depends({ type = "Xray", protocol = "vmess" })
use_ipv6:depends({ type = "Xray", protocol = "vless" })
use_ipv6:depends({ type = "Xray", protocol = "http" })
use_ipv6:depends({ type = "Xray", protocol = "socks" })
use_ipv6:depends({ type = "Xray", protocol = "shadowsocks" })
use_ipv6:depends({ type = "Xray", protocol = "trojan" })
--]]

port = s:option(Value, "port", translate("Port"))
port.datatype = "port"
port.rmempty = false
port:depends({ type = "Xray", protocol = "vmess" })
port:depends({ type = "Xray", protocol = "vless" })
port:depends({ type = "Xray", protocol = "http" })
port:depends({ type = "Xray", protocol = "socks" })
port:depends({ type = "Xray", protocol = "shadowsocks" })
port:depends({ type = "Xray", protocol = "trojan" })

username = s:option(Value, "username", translate("Username"))
username:depends({ type = "Xray", protocol = "http" })
username:depends({ type = "Xray", protocol = "socks" })

password = s:option(Value, "password", translate("Password"))
password.password = true
password:depends({ type = "Xray", protocol = "http" })
password:depends({ type = "Xray", protocol = "socks" })
password:depends({ type = "Xray", protocol = "shadowsocks" })
password:depends({ type = "Xray", protocol = "trojan" })

security = s:option(ListValue, "security", translate("Encrypt Method"))
for a, t in ipairs(security_list) do security:value(t) end
security:depends({ type = "Xray", protocol = "vmess" })

encryption = s:option(Value, "encryption", translate("Encrypt Method"))
encryption.default = "none"
encryption:depends({ type = "Xray", protocol = "vless" })

v_ss_encrypt_method = s:option(ListValue, "v_ss_encrypt_method", translate("Encrypt Method"))
for a, t in ipairs(v_ss_encrypt_method_list) do v_ss_encrypt_method:value(t) end
v_ss_encrypt_method:depends("protocol", "shadowsocks")
function v_ss_encrypt_method.cfgvalue(self, section)
	return m:get(section, "method")
end
function v_ss_encrypt_method.write(self, section, value)
	m:set(section, "method", value)
end

uuid = s:option(Value, "uuid", translate("ID"))
uuid.password = true
uuid:depends({ type = "Xray", protocol = "vmess" })
uuid:depends({ type = "Xray", protocol = "vless" })

alter_id = s:option(Value, "alter_id", translate("Alter ID"))
alter_id:depends("protocol", "vmess")

tls = s:option(Flag, "tls", translate("TLS"))
tls.default = 0
tls.validate = function(self, value, t)
    if value then
        local type = type:formvalue(t) or ""
        if value == "0" and (type == "Trojan" or type == "Trojan-Plus") then
            return nil, translate("Original Trojan only supported 'tls', please choose 'tls'.")
        end
        return value
    end
end
tls:depends({ type = "Xray", protocol = "vmess" })
tls:depends({ type = "Xray", protocol = "vless" })
tls:depends({ type = "Xray", protocol = "socks" })
tls:depends({ type = "Xray", protocol = "trojan" })
tls:depends({ type = "Xray", protocol = "shadowsocks" })

xtls = s:option(Flag, "xtls", translate("XTLS"))
xtls.default = 0
xtls:depends({ type = "Xray", protocol = "vless", tls = "1" })
xtls:depends({ type = "Xray", protocol = "trojan", tls = "1" })

flow = s:option(Value, "flow", translate("flow"))
flow.default = "xtls-rprx-direct"
flow:value("xtls-rprx-origin")
flow:value("xtls-rprx-origin-udp443")
flow:value("xtls-rprx-direct")
flow:value("xtls-rprx-direct-udp443")
flow:value("xtls-rprx-splice")
flow:value("xtls-rprx-splice-udp443")
flow:depends("xtls", "1")

tls_serverName = s:option(Value, "tls_serverName", translate("Domain"))
tls_serverName:depends("tls", "1")
tls_serverName:depends("xtls", "1")

tls_allowInsecure = s:option(Flag, "tls_allowInsecure", translate("allowInsecure"), translate("Whether unsafe connections are allowed. When checked, Certificate validation will be skipped."))
tls_allowInsecure.default = "0"
tls_allowInsecure:depends("tls", "1")
tls_allowInsecure:depends("xtls", "1")

transport = s:option(ListValue, "transport", translate("Transport"))
transport:value("tcp", "TCP")
transport:value("mkcp", "mKCP")
transport:value("ws", "WebSocket")
transport:value("h2", "HTTP/2")
transport:value("ds", "DomainSocket")
transport:value("quic", "QUIC")
transport:depends({ type = "Xray", protocol = "vmess" })
transport:depends({ type = "Xray", protocol = "vless" })
transport:depends({ type = "Xray", protocol = "socks" })
transport:depends({ type = "Xray", protocol = "shadowsocks" })
transport:depends({ type = "Xray", protocol = "trojan" })

-- [[ TCP部分 ]]--

-- TCP伪装
tcp_guise = s:option(ListValue, "tcp_guise", translate("Camouflage Type"))
tcp_guise:value("none", "none")
tcp_guise:value("http", "http")
tcp_guise:depends("transport", "tcp")

-- HTTP域名
tcp_guise_http_host = s:option(DynamicList, "tcp_guise_http_host", translate("HTTP Host"))
tcp_guise_http_host:depends("tcp_guise", "http")

-- HTTP路径
tcp_guise_http_path = s:option(DynamicList, "tcp_guise_http_path", translate("HTTP Path"))
tcp_guise_http_path:depends("tcp_guise", "http")

-- [[ mKCP部分 ]]--

mkcp_guise = s:option(ListValue, "mkcp_guise", translate("Camouflage Type"), translate('<br />none: default, no masquerade, data sent is packets with no characteristics.<br />srtp: disguised as an SRTP packet, it will be recognized as video call data (such as FaceTime).<br />utp: packets disguised as uTP will be recognized as bittorrent downloaded data.<br />wechat-video: packets disguised as WeChat video calls.<br />dtls: disguised as DTLS 1.2 packet.<br />wireguard: disguised as a WireGuard packet. (not really WireGuard protocol)'))
for a, t in ipairs(header_type_list) do mkcp_guise:value(t) end
mkcp_guise:depends("transport", "mkcp")

mkcp_mtu = s:option(Value, "mkcp_mtu", translate("KCP MTU"))
mkcp_mtu.default = "1350"
mkcp_mtu:depends("transport", "mkcp")

mkcp_tti = s:option(Value, "mkcp_tti", translate("KCP TTI"))
mkcp_tti.default = "20"
mkcp_tti:depends("transport", "mkcp")

mkcp_uplinkCapacity = s:option(Value, "mkcp_uplinkCapacity", translate("KCP uplinkCapacity"))
mkcp_uplinkCapacity.default = "5"
mkcp_uplinkCapacity:depends("transport", "mkcp")

mkcp_downlinkCapacity = s:option(Value, "mkcp_downlinkCapacity", translate("KCP downlinkCapacity"))
mkcp_downlinkCapacity.default = "20"
mkcp_downlinkCapacity:depends("transport", "mkcp")

mkcp_congestion = s:option(Flag, "mkcp_congestion", translate("KCP Congestion"))
mkcp_congestion:depends("transport", "mkcp")

mkcp_readBufferSize = s:option(Value, "mkcp_readBufferSize", translate("KCP readBufferSize"))
mkcp_readBufferSize.default = "1"
mkcp_readBufferSize:depends("transport", "mkcp")

mkcp_writeBufferSize = s:option(Value, "mkcp_writeBufferSize", translate("KCP writeBufferSize"))
mkcp_writeBufferSize.default = "1"
mkcp_writeBufferSize:depends("transport", "mkcp")

mkcp_seed = s:option(Value, "mkcp_seed", translate("KCP Seed"))
mkcp_seed:depends("transport", "mkcp")

-- [[ WebSocket部分 ]]--
ws_host = s:option(Value, "ws_host", translate("WebSocket Host"))
ws_host:depends("transport", "ws")

ws_path = s:option(Value, "ws_path", translate("WebSocket Path"))
ws_path:depends("transport", "ws")

-- [[ HTTP/2部分 ]]--
h2_host = s:option(Value, "h2_host", translate("HTTP/2 Host"))
h2_host:depends("transport", "h2")

h2_path = s:option(Value, "h2_path", translate("HTTP/2 Path"))
h2_path:depends("transport", "h2")

-- [[ DomainSocket部分 ]]--
ds_path = s:option(Value, "ds_path", "Path", translate("A legal file path. This file must not exist before running."))
ds_path:depends("transport", "ds")

-- [[ QUIC部分 ]]--
quic_security = s:option(ListValue, "quic_security", translate("Encrypt Method"))
quic_security:value("none")
quic_security:value("aes-128-gcm")
quic_security:value("chacha20-poly1305")
quic_security:depends("transport", "quic")

quic_key = s:option(Value, "quic_key", translate("Encrypt Method") .. translate("Key"))
quic_key:depends("transport", "quic")

quic_guise = s:option(ListValue, "quic_guise", translate("Camouflage Type"))
for a, t in ipairs(header_type_list) do quic_guise:value(t) end
quic_guise:depends("transport", "quic")

-- [[ Mux ]]--
mux = s:option(Flag, "mux", translate("Mux"))
mux:depends({ type = "Xray", protocol = "vmess" })
mux:depends({ type = "Xray", protocol = "vless", xtls = false })
mux:depends({ type = "Xray", protocol = "http" })
mux:depends({ type = "Xray", protocol = "socks" })
mux:depends({ type = "Xray", protocol = "shadowsocks" })

mux_concurrency = s:option(Value, "mux_concurrency", translate("Mux Concurrency"))
mux_concurrency.default = 8
mux_concurrency:depends("mux", "1")

protocol.validate = function(self, value)
    if value == "_shunt" or value == "_balancing" then
        address.rmempty = true
        port.rmempty = true
    end
    return value
end

return m
