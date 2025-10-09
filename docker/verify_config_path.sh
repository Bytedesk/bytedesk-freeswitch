#!/bin/bash

# Detect system language
LANG_ENV="${LANG:-en_US.UTF-8}"
if [[ "$LANG_ENV" == zh_CN* ]] || [[ "$LANG_ENV" == zh_TW* ]]; then
    USE_CHINESE=true
else
    USE_CHINESE=false
fi

if [ "$USE_CHINESE" = true ]; then
    echo "========================================"
    echo "FreeSwitch Docker 配置路径验证工具"
    echo "========================================"
else
    echo "========================================"
    echo "FreeSwitch Docker Config Path Verifier"
    echo "========================================"
fi

CONTAINER_NAME="freeswitch-bytedesk"
ESL_PASSWORD="bytedesk123"

# 检查容器是否运行
if ! docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
    echo "❌ 错误: 容器 '$CONTAINER_NAME' 未运行"
    echo "请先启动 FreeSwitch 容器"
    exit 1
fi

echo ""
echo "[1] 验证 FreeSwitch 实际使用的配置路径..."

# 获取当前配置路径
ACTUAL_CONF_DIR=$(docker exec -it $CONTAINER_NAME fs_cli -p "$ESL_PASSWORD" -x 'global_getvar conf_dir' 2>/dev/null | tr -d '\r\n')

if [ -z "$ACTUAL_CONF_DIR" ]; then
    echo "❌ 无法获取配置路径，可能原因："
    echo "   - ESL密码错误"
    echo "   - FreeSwitch服务未完全启动"
    echo "   - ESL模块未加载"
    exit 1
fi

echo "✅ FreeSwitch 当前使用的配置路径: $ACTUAL_CONF_DIR"

echo ""
echo "[2] 检查容器内配置目录结构..."

# 检查两个可能的配置目录
PATHS_TO_CHECK=(
    "/usr/local/freeswitch/etc/freeswitch"
    "/usr/local/freeswitch/conf"
)

for path in "${PATHS_TO_CHECK[@]}"; do
    if docker exec -it $CONTAINER_NAME [ -d "$path" ] 2>/dev/null; then
        FILE_COUNT=$(docker exec -it $CONTAINER_NAME find "$path" -type f | wc -l | tr -d ' \r\n')
        if [ "$path" = "$ACTUAL_CONF_DIR" ]; then
            echo "✅ $path (实际使用) - 文件数量: $FILE_COUNT"
        else
            echo "⚠️  $path (备用目录) - 文件数量: $FILE_COUNT"
        fi
    else
        echo "❌ $path - 目录不存在"
    fi
done

echo ""
echo "[3] Docker Compose 挂载建议..."

if [ "$ACTUAL_CONF_DIR" = "/usr/local/freeswitch/etc/freeswitch" ]; then
    echo "✅ 正确的挂载配置:"
    echo "   volumes:"
    echo "     - ./your-config:/usr/local/freeswitch/etc/freeswitch"
    echo ""
    echo "❌ 错误的挂载配置:"
    echo "   volumes:"
    echo "     - ./your-config:/usr/local/freeswitch/conf  # 这将不会被FreeSWITCH读取"
elif [ "$ACTUAL_CONF_DIR" = "/usr/local/freeswitch/conf" ]; then
    echo "✅ 正确的挂载配置:"
    echo "   volumes:"
    echo "     - ./your-config:/usr/local/freeswitch/conf"
    echo ""
    echo "❌ 错误的挂载配置:"
    echo "   volumes:"
    echo "     - ./your-config:/usr/local/freeswitch/etc/freeswitch  # 这将不会被FreeSWITCH读取"
fi

echo ""
echo "[4] 验证关键配置文件..."

KEY_FILES=(
    "freeswitch.xml"
    "vars.xml"
    "autoload_configs/event_socket.conf.xml"
    "autoload_configs/modules.conf.xml"
)

for file in "${KEY_FILES[@]}"; do
    if docker exec -it $CONTAINER_NAME [ -f "$ACTUAL_CONF_DIR/$file" ] 2>/dev/null; then
        echo "✅ $file - 存在"
    else
        echo "❌ $file - 缺失"
    fi
done

echo ""
echo "========================================"
echo "验证完成"
echo "========================================"
echo ""
echo "📋 总结:"
echo "   - 实际配置路径: $ACTUAL_CONF_DIR"
echo "   - 挂载自定义配置时请使用此路径"
echo "   - 如需测试配置修改，请重启容器后再次运行此脚本验证"