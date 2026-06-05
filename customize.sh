#!/usr/bin/env bash
set -e

SYSNAME='弘朔达SD-WAN网络平台'
COMPANY='广州弘朔达技术有限公司'
SUBTITLE='弘朔达SD-WAN网络管理平台'

# 1) 替换 LuCI / 源码中的 OpenWrt 显示名
rg -l "OpenWrt" feeds/luci package/base-files 2>/dev/null | xargs -r sed -i "s/OpenWrt/${SYSNAME}/g" || true
rg -l "ImmortalWrt" package feeds target 2>/dev/null | xargs -r sed -i "s/ImmortalWrt/${SYSNAME}/g" || true

# 2) 发行信息
mkdir -p package/base-files/files/etc
cat > package/base-files/files/etc/openwrt_release <<EOF
DISTRIB_ID='${SYSNAME}'
DISTRIB_RELEASE='1.0'
DISTRIB_REVISION='HSD'
DISTRIB_TARGET='qualcommax/ipq60xx'
DISTRIB_ARCH='aarch64_cortex-a53'
DISTRIB_DESCRIPTION='${SYSNAME}'
DISTRIB_TAINTS=''
EOF

# 3) 首次启动写入品牌
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-hsd-branding <<'EOF'
#!/bin/sh
set -e

uci set system.@system[0].hostname='HSD-SDWAN'
uci commit system

cat > /etc/motd <<'MOTD'
广州弘朔达技术有限公司
弘朔达SD-WAN网络管理平台
弘朔达SD-WAN网络平台
MOTD

for f in \
  /usr/share/ucode/luci/version.uc \
  /usr/lib/lua/luci/version.lua
do
  [ -f "$f" ] && sed -i 's/OpenWrt/弘朔达SD-WAN网络平台/g; s/ImmortalWrt/弘朔达SD-WAN网络平台/g' "$f"
done

mkdir -p /www/luci-static/resources/icons /www/luci-static/bootstrap
if [ -f /www/hsd-logo.png ]; then
  cp /www/hsd-logo.png /www/logo.png
  cp /www/hsd-logo.png /www/luci-static/resources/icons/logo.png
  cp /www/hsd-logo.png /www/luci-static/bootstrap/logo.png
fi

rm -f /etc/uci-defaults/99-hsd-branding
exit 0
EOF
chmod +x files/etc/uci-defaults/99-hsd-branding

# 4) 编译时预置 logo
mkdir -p files/www/luci-static/resources/icons files/www/luci-static/bootstrap
if [ -f files/www/hsd-logo.png ]; then
  cp files/www/hsd-logo.png files/www/logo.png
  cp files/www/hsd-logo.png files/www/luci-static/resources/icons/logo.png
  cp files/www/hsd-logo.png files/www/luci-static/bootstrap/logo.png
fi
