#!/bin/bash
set -o errexit
set -o pipefail

echo "=== 初始化配置 ==="

# ================= CN 规则源 (国内直连) =================

# 1. Felixonmars (DNSMasq)
URL_FELIX="https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf"
FILE_FELIX="cn-dnsmasq-china-list.txt"

# 2. Pexcn (China List)
URL_PEXCN_CN="https://raw.githubusercontent.com/pexcn/daily/gh-pages/chinalist/chinalist.txt"
FILE_PEXCN_CN="cn-chinadns-ng.txt"

# 3. Xmdhs (Ext JSON)
URL_XMDHS="https://raw.githubusercontent.com/xmdhs/cn-domain-list/refs/heads/rule-set/ext-cn-list.json"
FILE_XMDHS_TEMP="cn-ext-chnlist.txt"

# 4. Loyalsoldier (Direct & China)
URL_LOYAL_DIRECT="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt"
FILE_LOYAL_DIRECT="cn-v2ray-direct.txt"

URL_LOYAL_CHINA="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/china-list.txt"
FILE_LOYAL_CHINA="cn-v2ray-china.txt"

# 5. Loyalsoldier (Google CN - 特殊处理)
URL_LOYAL_GOOGLE="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/google-cn.txt"
FILE_LOYAL_GOOGLE="cn-v2ray-googlecn.txt"

# 6. ACL4SSR (Clash - 特殊处理)
URL_ACL4SSR="https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/ChinaDomain.list"
FILE_ACL4SSR="cn-acl4ssr-clash.txt"

# 自定义 CN 文件 (你的库里的文件)
FILE_MY_CN="mycn.txt"

# 最终 CN 输出
FILE_FINAL_CN="final_cn.txt"


# ================= GFW 规则源 =================

# 1. Pexcn (GFW List)
URL_PEXCN_GFW="https://raw.githubusercontent.com/pexcn/daily/gh-pages/gfwlist/gfwlist.txt"
FILE_PEXCN_GFW="gfw-chinadns-ng.txt"

# 2. Loyalsoldier (GFW List) [新增]
URL_LOYAL_GFW="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt"
FILE_LOYAL_GFW="gfw-v2ray.txt"

# 自定义 GFW 文件 (你的库里的文件)
FILE_MY_GFW="mygfw.txt"

# 最终 GFW 输出
FILE_FINAL_GFW="final_gfw.txt"


echo "=== 开始下载并处理 CN 规则 ==="

# --- 1. Felixonmars ---
echo "处理 Felixonmars..."
curl -4fsSkL "$URL_FELIX" | grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' | awk -F/ '{print $2}' | sort | uniq > "$FILE_FELIX"

# --- 2. Pexcn China ---
echo "处理 Pexcn China..."
curl -4fsSkL "$URL_PEXCN_CN" | grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' | sort | uniq > "$FILE_PEXCN_CN"

# --- 3. Xmdhs JSON ---
echo "处理 Xmdhs JSON..."
if command -v jq >/dev/null 2>&1; then
    curl -4fsSkL "$URL_XMDHS" | jq -r '.rules[].domain_suffix[]' > "$FILE_XMDHS_TEMP"
else
    # Fallback for sed
    curl -4fsSkL "$URL_XMDHS" | grep -vE 'version|rules|domain_suffix|[\{\}\[\]]' | sed 's/^[[:space:]]*//; s/,$//; s/"//g' | grep -v '^[[:space:]]*$' > "$FILE_XMDHS_TEMP"
fi

# --- 4. Loyalsoldier (Direct & China) ---
echo "处理 Loyalsoldier Direct..."
curl -4fsSkL "$URL_LOYAL_DIRECT" | grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' | sort | uniq > "$FILE_LOYAL_DIRECT"

echo "处理 Loyalsoldier China..."
curl -4fsSkL "$URL_LOYAL_CHINA" | grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' | sort | uniq > "$FILE_LOYAL_CHINA"

# --- 5. Loyalsoldier Google CN (特殊: 提取 full 后两段) ---
echo "处理 Loyalsoldier Google CN..."
curl -4fsSkL "$URL_LOYAL_GOOGLE" | \
grep '^full:' | \
sed 's/^full://' | \
awk -F. '{if (NF>=2) print $(NF-1)"."$NF; else print $0}' | \
sort | uniq > "$FILE_LOYAL_GOOGLE"

# --- 6. ACL4SSR Clash (特殊: 提取 DOMAIN/DOMAIN-SUFFIX) ---
echo "处理 ACL4SSR Clash..."
curl -4fsSkL "$URL_ACL4SSR" | \
grep -E '^(DOMAIN-SUFFIX|DOMAIN),' | \
awk -F, '{print $2}' | \
sort | uniq > "$FILE_ACL4SSR"


echo "=== 开始下载并处理 GFW 规则 ==="

# --- 1. Pexcn GFW ---
echo "处理 Pexcn GFW..."
curl -4fsSkL "$URL_PEXCN_GFW" | grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' | sort | uniq > "$FILE_PEXCN_GFW"

# --- 2. Loyalsoldier GFW [新增] ---
echo "处理 Loyalsoldier GFW..."
curl -4fsSkL "$URL_LOYAL_GFW" | grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' | sort | uniq > "$FILE_LOYAL_GFW"


echo "=== 开始合并文件 ==="

# 合并 CN
echo "正在生成 $FILE_FINAL_CN ..."
{
    [ -f "$FILE_FELIX" ] && cat "$FILE_FELIX"
    [ -f "$FILE_PEXCN_CN" ] && cat "$FILE_PEXCN_CN"
    [ -f "$FILE_XMDHS_TEMP" ] && cat "$FILE_XMDHS_TEMP"
    [ -f "$FILE_LOYAL_DIRECT" ] && cat "$FILE_LOYAL_DIRECT"
    [ -f "$FILE_LOYAL_CHINA" ] && cat "$FILE_LOYAL_CHINA"
    [ -f "$FILE_LOYAL_GOOGLE" ] && cat "$FILE_LOYAL_GOOGLE"
    [ -f "$FILE_ACL4SSR" ] && cat "$FILE_ACL4SSR"
    [ -f "$FILE_MY_CN" ] && cat "$FILE_MY_CN"
} | sort -u > "$FILE_FINAL_CN"

# 合并 GFW
echo "正在生成 $FILE_FINAL_GFW ..."
{
    [ -f "$FILE_PEXCN_GFW" ] && cat "$FILE_PEXCN_GFW"
    [ -f "$FILE_LOYAL_GFW" ] && cat "$FILE_LOYAL_GFW"
    [ -f "$FILE_MY_GFW" ] && cat "$FILE_MY_GFW"
} | sort -u > "$FILE_FINAL_GFW"


echo "=== 更新 README.md ==="

get_count() { wc -l < "$1" | xargs; }
get_size() { du -h "$1" | cut -f1 | xargs; }

UPDATE_TIME=$(date "+%Y-%m-%d %H:%M:%S")
CN_COUNT=$(get_count "$FILE_FINAL_CN")
CN_SIZE=$(get_size "$FILE_FINAL_CN")
GFW_COUNT=$(get_count "$FILE_FINAL_GFW")
GFW_SIZE=$(get_size "$FILE_FINAL_GFW")

cat > README.md <<EOF
# Domain Rules Auto-Update

自动聚合多个源的域名列表 (CN直连 / GFW被墙)。

- **上次更新**: ${UPDATE_TIME}

## 📊 汇总统计

| 类型 | 文件名 | 规则总数 | 文件大小 |
| :--- | :--- | :--- | :--- |
| **CN (直连)** | **${FILE_FINAL_CN}** | **${CN_COUNT}** | **${CN_SIZE}** |
| **GFW** | **${FILE_FINAL_GFW}** | **${GFW_COUNT}** | **${GFW_SIZE}** |

## 📂 详细来源文件

### CN 类 (China List)
| 来源 | 临时文件名 | 数量 | 大小 |
| :--- | :--- | :--- | :--- |
| **自定义** | ${FILE_MY_CN} | $(get_count "$FILE_MY_CN") | $(get_size "$FILE_MY_CN") |
| Felixonmars | ${FILE_FELIX} | $(get_count "$FILE_FELIX") | $(get_size "$FILE_FELIX") |
| Pexcn | ${FILE_PEXCN_CN} | $(get_count "$FILE_PEXCN_CN") | $(get_size "$FILE_PEXCN_CN") |
| Xmdhs | ${FILE_XMDHS_TEMP} | $(get_count "$FILE_XMDHS_TEMP") | $(get_size "$FILE_XMDHS_TEMP") |
| Loyal (Direct) | ${FILE_LOYAL_DIRECT} | $(get_count "$FILE_LOYAL_DIRECT") | $(get_size "$FILE_LOYAL_DIRECT") |
| Loyal (China) | ${FILE_LOYAL_CHINA} | $(get_count "$FILE_LOYAL_CHINA") | $(get_size "$FILE_LOYAL_CHINA") |
| Loyal (Google) | ${FILE_LOYAL_GOOGLE} | $(get_count "$FILE_LOYAL_GOOGLE") | $(get_size "$FILE_LOYAL_GOOGLE") |
| ACL4SSR | ${FILE_ACL4SSR} | $(get_count "$FILE_ACL4SSR") | $(get_size "$FILE_ACL4SSR") |

### GFW 类 (GFW List)
| 来源 | 临时文件名 | 数量 | 大小 |
| :--- | :--- | :--- | :--- |
| **自定义** | ${FILE_MY_GFW} | $(get_count "$FILE_MY_GFW") | $(get_size "$FILE_MY_GFW") |
| Pexcn | ${FILE_PEXCN_GFW} | $(get_count "$FILE_PEXCN_GFW") | $(get_size "$FILE_PEXCN_GFW") |
| Loyal (GFW) | ${FILE_LOYAL_GFW} | $(get_count "$FILE_LOYAL_GFW") | $(get_size "$FILE_LOYAL_GFW") |

EOF

echo "=== 全部完成 ==="
