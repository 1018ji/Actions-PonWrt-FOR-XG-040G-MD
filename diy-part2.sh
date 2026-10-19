#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

LUCI_RPC=feeds/luci/modules/luci-base/root/usr/share/rpcd/ucode/luci
sed -i "s|popen('top -n1[^;]*;|popen('/sbin/cpuusage');|" "$LUCI_RPC"
grep -q "popen('/sbin/cpuusage')" "$LUCI_RPC" || exit 1

python3 - <<'PY' || exit 1
path = 'feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js'
old = "_('CPU usage (%)'),    cpuusage.cpuusage\n"
new = ("_('CPU usage (%)'),    ...((s) => { s = (s || '?').split('\\n'); "
       "return s[1] ? [ s[0], 'PPE', s[1] ] : [ s[0] ]; })(cpuusage.cpuusage)\n")
with open(path) as f:
    data = f.read()
if old not in data:
    raise SystemExit(1)
with open(path, 'w') as f:
    f.write(data.replace(old, new))
PY

# Remove LuCI menus: System > Plugins, Network > Diagnostics
python3 - <<'PY' || exit 1
import json
menus = {
    'feeds/luci/modules/luci-mod-system/root/usr/share/luci/menu.d/luci-mod-system.json': 'admin/system/plugins',
    'feeds/luci/modules/luci-mod-network/root/usr/share/luci/menu.d/luci-mod-network.json': 'admin/network/diagnostics',
}
for path, node in menus.items():
    with open(path) as f:
        data = json.load(f)
    data.pop(node)
    with open(path, 'w') as f:
        json.dump(data, f, indent='\t')
PY
rm -f feeds/luci/modules/luci-mod-system/htdocs/luci-static/resources/view/system/plugins.js
rm -f feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/diagnostics.js
