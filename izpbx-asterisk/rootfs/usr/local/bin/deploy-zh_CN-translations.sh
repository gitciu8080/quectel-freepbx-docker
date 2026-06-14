#!/bin/bash
# FreePBX 中文翻译部署脚本
# 在容器启动时，将改进后的中文翻译部署到已安装的模块中

I18N_SRC="/usr/local/share/freepbx-i18n-zh_CN"
MODULES_DIR="/var/www/html/admin/modules"

echo "---> 正在部署 FreePBX 中文翻译..."

if [ ! -d "$I18N_SRC" ]; then
    echo "---> 警告: 未找到中文翻译源目录 $I18N_SRC"
    exit 0
fi

deployed=0
skipped=0

for module_dir in "$I18N_SRC"/*/; do
    [ -d "$module_dir" ] || continue
    module=$(basename "$module_dir")
    
    # 目标模块目录
    target_i18n="$MODULES_DIR/$module/i18n/zh_CN/LC_MESSAGES"
    
    if [ -d "$MODULES_DIR/$module" ]; then
        mkdir -p "$target_i18n"
        
        # 复制 .po 文件
        if [ -f "$module_dir/$module.po" ]; then
            cp -f "$module_dir/$module.po" "$target_i18n/$module.po"
            deployed=$((deployed + 1))
        fi
        
        # 编译 .po 为 .mo（如果 msgfmt 可用）
        if command -v msgfmt &>/dev/null && [ -f "$target_i18n/$module.po" ]; then
            msgfmt -o "$target_i18n/$module.mo" "$target_i18n/$module.po" 2>/dev/null && \
            chown asterisk:asterisk "$target_i18n/$module.po" "$target_i18n/$module.mo" 2>/dev/null
        fi
    else
        skipped=$((skipped + 1))
    fi
done

echo "---> 中文翻译部署完成: $deployed 个模块已更新, $skipped 个模块跳过"
