# freeswitch

## 常用命令

```bash
fs_cli -p bytedesk123 -x "reloadxml"
fs_cli -p bytedesk123 -x "reloadacl" 
fs_cli -p bytedesk123 -x "sofia profile external restart"
fs_cli -p bytedesk123 -x "sofia profile internal restart"
```

## 拦截垃圾ip

```bash
# 顶部来源 IP（综合 INVITE/REGISTER/ACL 拒绝）
103.195.100.135 — 417
81.16.177.161 — 406
213.170.135.210 — 170
216.246.109.158 — 56
192.210.184.18 — 10
63.141.224.186 — 9
185.243.5.193 — 4
23.95.182.242 — 2
217.154.203.209 — 2
87.98.242.75 — 1
# INVITE 来源（按 Profile 区分）
internal: 103.195.100.135 — 417
external: 81.16.177.161 — 406
internal: 213.170.135.210 — 170
internal: 216.246.109.158 — 56
external: 63.141.224.186 — 9
internal: 192.210.184.18 — 5
external: 192.210.184.18 — 5
internal: 185.243.5.193 — 4
internal: 23.95.182.242 — 2
internal: 217.154.203.209 — 2
internal: 87.98.242.75 — 1
```
