# 网络排障脚本

## 观察是否有 conntrack 冲突
watch -n1 'conntrack -S | awk -F = "{print \$7}" | awk "{sum += \$1} END {print sum}"'