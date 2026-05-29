#!/usr/bin/env bash
set -e

# 1) 全局替换 ImmortalWrt -> HSDrouterOS（源码层）
rg -l "ImmortalWrt" package feeds target | xargs -r sed -i 's/ImmortalWrt/HSDrouterOS/g'

# 2) 常见 OpenWrt 标题也替换成你的系统名（避免页面残留）
rg -l "OpenWrt" feeds/luci package | xargs -r sed -i 's/OpenWrt/HSDrouterOS/g'

# 3) 固件发行名
cat > package/base-files/files/etc/openwrt_release <<'EOF'
DISTRIB_ID='HSDrouterOS'
DISTRIB_RELEASE='1.0'
DISTRIB_REVISION='HSD'
DISTRIB_TARGET='qualcommax/ipq60xx'
DISTRIB_ARCH='aarch64_cortex-a53'
DISTRIB_DESCRIPTION='HSDrouterOS'
DISTRIB_TAINTS=''
EOF

# 4) 预置开机后品牌化脚本（确保登录页也替换）
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-hsd-branding <<'EOF'
#!/bin/sh
set -e

# 主机名
uci set system.@system[0].hostname='HSDrouterOS'
uci commit system

# 登录欢迎语（motd）
cat > /etc/motd <<'MOTD'
广州弘朔达技术有限公司
弘朔达SD-WAN网络管理平台
HSDrouterOS
MOTD

# 尝试替换LuCI中可见文案
for f in \
  /usr/lib/lua/luci/version.lua \
  /usr/lib/lua/luci/controller/admin/index.lua \
  /www/luci-static/resources/view/system/flash.js \
  /www/luci-static/resources/view/status/include/10_system.js
do
  [ -f "$f" ] && sed -i 's/ImmortalWrt/HSDrouterOS/g; s/OpenWrt/HSDrouterOS/g' "$f"
done

# 写入登录副标题（若主题支持读取自定义HTML）
mkdir -p /www
cat > /www/hsd-login-subtitle.html <<'HTML'
<div style="text-align:center;margin-top:8px;font-size:14px;color:#1f6fb2;">
  弘朔达SD-WAN网络管理平台
</div>
HTML

# 覆盖常见logo路径（不同主题可能只命中其中一部分）
for p in \
  /www/logo.png \
  /www/luci-static/bootstrap/logo.png \
  /www/luci-static/argon/img/logo.png \
  /www/luci-static/resources/icons/logo.png
do
  if [ -f /www/hsd-logo.png ]; then
    cp /www/hsd-logo.png "$p" 2>/dev/null || true
  fi
done

rm -f /etc/uci-defaults/99-hsd-branding
exit 0
EOF
chmod +x files/etc/uci-defaults/99-hsd-branding
