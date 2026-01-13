#!/bin/bash
set -o errexit
set -o pipefail

# =================配置区域=================
# 1. Felixonmars (DNSMasq China List)
URL_FELIX="https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf"
FILE_FELIX="cn-dnsmasq-china-list.txt"

# 2. Pexcn (GFW List)
URL_PEXCN_GFW="https://raw.githubusercontent.com/pexcn/daily/gh-pages/gfwlist/gfwlist.txt"
FILE_PEXCN_GFW="gfw-chinadns-ng.txt"

# 3. Pexcn (China List)
# 注意：你给的链接是blob，这里自动转换为raw链接以确保下载正确
URL_PEXCN_CN="https://raw.githubusercontent.com/pexcn/daily/gh-pages/chinalist/chinalist.txt"
FILE_PEXCN_CN="cn-chinadns-ng.txt"

# 4. Xmdhs (Ext CN List JSON)
URL_XMDHS="https://raw.githubusercontent.com/xmdhs/cn-domain-list/refs/heads/rule-set/ext-cn-list.json"
FILE_XMDHS_TEMP="ext-chnlist.txt"

# 自定义文件
FILE_MY_CN="mycn.txt"
FILE_MY_GFW="mygfw.txt"

# 最终输出文件
FILE_FINAL_CN="final_cn.txt"
FILE_FINAL_GFW="final_gfw.txt"

echo "=== 开始更新域名列表 ==="

# =================下载与预处理=================

# --- 1. 处理 Felixonmars ---
echo "1. 下载并处理 Felixonmars List..."
curl -4fsSkL "$URL_FELIX" | grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' | awk -F/ '{print $2}' | sort | uniq > "$FILE_FELIX"
echo "   -> 完成: $FILE_FELIX"

# --- 2. 处理 Pexcn GFW ---
echo "2. 下载并处理 Pexcn GFW List..."
# 使用你提供的逻辑：下载 -> 过滤空行和注释 -> 排序
curl -4fsSkL "$URL_PEXCN_GFW" | grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' | sort | uniq > "$FILE_PEXCN_GFW"
echo "   -> 完成: $FILE_PEXCN_GFW"

# --- 3. 处理 Pexcn China ---
echo "3. 下载并处理 Pexcn China List..."
curl -4fsSkL "$URL_PEXCN_CN" | grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' | sort | uniq > "$FILE_PEXCN_CN"
echo "   -> 完成: $FILE_PEXCN_CN"

# --- 4. 处理 Xmdhs Ext List ---
echo "4. 下载并处理 Xmdhs Ext List..."
if command -v jq >/dev/null 2>&1; then
    curl -4fsSkL "$URL_XMDHS" | jq -r '.rules[].domain_suffix[]' > "$FILE_XMDHS_TEMP"
else
    echo "警告: 未找到 jq，尝试使用 sed 处理..."
    curl -4fsSkL "$URL_XMDHS" | \
    grep -vE 'version|rules|domain_suffix|[\{\}\[\]]' | \
    sed 's/^[[:space:]]*//; s/,$//' | \
    sed 's/"//g' | \
    grep -v '^[[:space:]]*$' > "$FILE_XMDHS_TEMP"
fi
echo "   -> 完成: $FILE_XMDHS_TEMP"

# =================合并与生成最终文件=================

# --- 5. 生成 Final CN ---
echo "5. 生成最终 CN 列表 ($FILE_FINAL_CN)..."
{
    echo "cn"
    # 检查文件是否存在再合并，防止报错
    [ -f "$FILE_FELIX" ] && cat "$FILE_FELIX"
    [ -f "$FILE_PEXCN_CN" ] && cat "$FILE_PEXCN_CN"
    [ -f "$FILE_XMDHS_TEMP" ] && cat "$FILE_XMDHS_TEMP"
    [ -f "$FILE_MY_CN" ] && cat "$FILE_MY_CN"
} | sort -u > "$FILE_FINAL_CN"
echo "   -> 合并完成"

# --- 6. 生成 Final GFW ---
echo "6. 生成最终 GFW 列表 ($FILE_FINAL_GFW)..."
{
    [ -f "$FILE_PEXCN_GFW" ] && cat "$FILE_PEXCN_GFW"
    [ -f "$FILE_MY_GFW" ] && cat "$FILE_MY_GFW"
} | sort -u > "$FILE_FINAL_GFW"
echo "   -> 合并完成"

# =================更新 README=================
echo "7. 更新 README.md..."

# 统计行数和大小函数
get_count() { wc -l < "$1" | xargs; }
get_size() { du -h "$1" | cut -f1 | xargs; }

COUNT_FINAL_CN=$(get_count "$FILE_FINAL_CN")
SIZE_FINAL_CN=$(get_size "$FILE_FINAL_CN")
COUNT_FINAL_GFW=$(get_count "$FILE_FINAL_GFW")
SIZE_FINAL_GFW=$(get_size "$FILE_FINAL_GFW")
UPDATE_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# 准备 README 内容
cat > README.md <<EOF
# Domain Rules Auto-Update

自动更新的域名列表。

- **更新时间**: ${UPDATE_TIME}

## 文件统计

| 文件名 | 描述 | 包含规则数 | 文件大小 |
| :--- | :--- | :--- | :--- |
| **${FILE_FINAL_CN}** | **最终合并的中国域名列表 (含自定义)** | **${COUNT_FINAL_CN}** | **${SIZE_FINAL_CN}** |
| **${FILE_FINAL_GFW}** | **最终合并的 GFW 列表 (含自定义)** | **${COUNT_FINAL_GFW}** | **${SIZE_FINAL_GFW}** |
| ${FILE_FELIX} | Felixonmars dnsmasq-china-list | $(get_count "$FILE_FELIX") | $(get_size "$FILE_FELIX") |
| ${FILE_PEXCN_CN} | Pexcn chinalist | $(get_count "$FILE_PEXCN_CN") | $(get_size "$FILE_PEXCN_CN") |
| ${FILE_PEXCN_GFW} | Pexcn gfwlist | $(get_count "$FILE_PEXCN_GFW") | $(get_size "$FILE_PEXCN_GFW") |

## 数据源

1. [felixonmars/dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list)
2. [pexcn/daily](https://github.com/pexcn/daily)
3. [xmdhs/cn-domain-list](https://github.com/xmdhs/cn-domain-list)
4. 自定义规则: \`mycn.txt\`, \`mygfw.txt\`

EOF

echo "=== 全部完成 ==="
