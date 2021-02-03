# Copyright (C) 2021 xiaorouji
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-x
PKG_VERSION:=1
PKG_RELEASE:=20210203-1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/config
endef

define Package/$(PKG_NAME)
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for X
  PKGARCH:=all
  DEPENDS:=+libmbedtls +iptables-mod-tproxy +ip +ipset +coreutils +coreutils-base64 +coreutils-nohup +luci-lib-jsonc \
  +curl +ca-certificates +resolveip +unzip +dnsmasq-full +tcping +libuci-lua \
  +xray-core
endef

define Build/Prepare
endef
 
define Build/Configure
endef
 
define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/x
/etc/config/x_server
/usr/share/x/rules/direct_host
/usr/share/x/rules/direct_ip
/usr/share/x/rules/proxy_host
/usr/share/x/rules/proxy_ip
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./root/etc/config/x $(1)/etc/config/x
	$(INSTALL_CONF) ./root/etc/config/x_server $(1)/etc/config/x_server
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/x $(1)/etc/init.d/x
	$(INSTALL_BIN) ./root/etc/init.d/x_server $(1)/etc/init.d/x_server
	
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_CONF) ./root/etc/uci-defaults/* $(1)/etc/uci-defaults
	
	$(INSTALL_DIR) $(1)/usr/share/x
	cp -pR ./root/usr/share/x/* $(1)/usr/share/x
	$(INSTALL_CONF) ./root/etc/config/x $(1)/usr/share/x/config.default
	
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	cp -pR ./root/usr/share/rpcd/acl.d/* $(1)/usr/share/rpcd/acl.d
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	po2lmo ./po/zh-cn/x.po $(1)/usr/lib/lua/luci/i18n/x.zh-cn.lmo
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
chmod a+x $${IPKG_INSTROOT}/usr/share/x/* >/dev/null 2>&1
chmod a+x $${IPKG_INSTROOT}/usr/lib/lua/luci/model/cbi/x/server/api/app.lua >/dev/null 2>&1
touch $${IPKG_INSTROOT}/etc/config/x_show >/dev/null 2>&1
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
