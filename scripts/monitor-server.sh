#!/bin/bash

# Nano Banana MCP Server 状态监控脚本

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔍 Nano Banana MCP Server 状态监控"
echo "===================================="
echo ""
echo "📁 项目目录: $PROJECT_DIR"
echo ""

# 检查进程
echo "📌 进程状态:"
if ps aux | grep -v grep | grep "nanobanana_mcp_server" > /dev/null; then
    echo "✅ 服务器正在运行"
    echo ""
    ps aux | grep -v grep | grep "nanobanana_mcp_server" | head -1 | awk '{print "   PID: " $2 "\n   CPU: " $3 "% \n   MEM: " $4 "% \n   CMD: " $11 " " $12 " " $13}'
else
    echo "❌ 服务器未运行"
fi
echo ""

# 检查虚拟环境
echo "📌 虚拟环境:"
if [ -f "$PROJECT_DIR/.venv/bin/python" ]; then
    PYTHON_PATH=$(readlink "$PROJECT_DIR/.venv/bin/python" 2>/dev/null || echo "$PROJECT_DIR/.venv/bin/python")
    echo "✅ 虚拟环境存在"
    echo "   Python: $PYTHON_PATH"
    
    # 检查是否链接到 miniconda
    if [[ "$PYTHON_PATH" == *"miniconda"* ]]; then
        echo "   ⚠️  警告: 虚拟环境使用 miniconda Python"
        echo "   建议运行: rm -rf .venv && uv venv --python /opt/homebrew/bin/python3.11"
    fi
    
    # 显示 Python 版本
    PYTHON_VERSION=$("$PROJECT_DIR/.venv/bin/python" --version 2>&1)
    echo "   版本: $PYTHON_VERSION"
else
    echo "❌ 虚拟环境不存在"
    echo "   运行: uv venv --python /opt/homebrew/bin/python3.11"
fi
echo ""

# 检查模块
echo "📌 模块状态:"
if [ -f "$PROJECT_DIR/.venv/bin/python" ]; then
    if "$PROJECT_DIR/.venv/bin/python" -c "import nanobanana_mcp_server.server" 2>/dev/null; then
        echo "✅ 模块可以导入"
    else
        echo "❌ 模块导入失败"
        echo "   运行: cd $PROJECT_DIR && uv pip install -e ."
    fi
else
    echo "⚠️  虚拟环境不存在，无法检查模块"
fi
echo ""

# 检查配置
echo "📌 环境变量:"
if [ -n "$GEMINI_API_KEY" ]; then
    API_KEY_LENGTH=${#GEMINI_API_KEY}
    echo "✅ GEMINI_API_KEY 已设置 (长度: $API_KEY_LENGTH)"
else
    echo "⚠️  GEMINI_API_KEY 未在环境中设置"
    echo "   (应该在 Cursor 配置文件中设置)"
fi
echo ""

# 检查配置文件
echo "📌 配置文件:"
if [ -f "$PROJECT_DIR/cursor_mcp_config.json" ]; then
    echo "✅ 配置文件存在: cursor_mcp_config.json"
    
    # 检查配置文件中的命令
    COMMAND=$(grep -o '"command": "[^"]*"' "$PROJECT_DIR/cursor_mcp_config.json" | cut -d'"' -f4)
    echo "   命令: $COMMAND"
    
    # 检查是否使用了 uv run（不推荐）
    if [[ "$COMMAND" == "uv" ]]; then
        echo "   ⚠️  警告: 使用 'uv run' 可能导致 Python 环境问题"
        echo "   建议使用: $PROJECT_DIR/.venv/bin/python"
    fi
else
    echo "⚠️  配置文件不存在"
    echo "   运行: ./scripts/setup-cursor.sh"
fi
echo ""

# 检查输出目录
echo "📌 输出目录:"
OUTPUT_DIR="$HOME/nanobanana-images"
if [ -d "$OUTPUT_DIR" ]; then
    echo "✅ 输出目录存在: $OUTPUT_DIR"
    
    # 统计图片数量
    IMAGE_COUNT=$(ls "$OUTPUT_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
    echo "   图片数量: $IMAGE_COUNT"
    
    # 显示最近的图片
    if [ "$IMAGE_COUNT" -gt 0 ]; then
        echo "   最近生成:"
        ls -lt "$OUTPUT_DIR"/*.png 2>/dev/null | head -3 | awk '{print "      " $9 " (" $5 " bytes, " $6 " " $7 " " $8 ")"}'
    fi
    
    # 计算总大小
    TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" 2>/dev/null | awk '{print $1}')
    echo "   总大小: $TOTAL_SIZE"
else
    echo "ℹ️  输出目录不存在（首次运行时会自动创建）"
fi
echo ""

# 检查日志
echo "📌 Cursor 日志:"
CURSOR_LOG="$HOME/Library/Logs/Cursor/main.log"
if [ -f "$CURSOR_LOG" ]; then
    echo "✅ 日志文件存在"
    
    # 查找最近的 MCP 相关日志
    echo "   最近 5 条 MCP 相关日志:"
    grep -i "nanobanana\|mcp.*server" "$CURSOR_LOG" 2>/dev/null | tail -5 | while read -r line; do
        echo "      $line"
    done
    
    # 检查是否有错误
    ERROR_COUNT=$(grep -i "error.*nanobanana\|error.*mcp" "$CURSOR_LOG" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "   ⚠️  发现 $ERROR_COUNT 个错误，最近的错误:"
        grep -i "error.*nanobanana\|error.*mcp" "$CURSOR_LOG" 2>/dev/null | tail -3 | while read -r line; do
            echo "      $line"
        done
    fi
else
    echo "⚠️  Cursor 日志文件不存在"
fi
echo ""

# 检查端口（如果使用 HTTP 模式）
echo "📌 端口状态 (HTTP 模式):"
if lsof -i :9000 > /dev/null 2>&1; then
    echo "✅ 端口 9000 被占用"
    lsof -i :9000 | tail -n +2 | awk '{print "   PID: " $2 ", 进程: " $1}'
else
    echo "ℹ️  端口 9000 未被占用（stdio 模式正常）"
fi
echo ""

# 健康评分
echo "===================================="
echo "📊 健康评分:"
SCORE=0
TOTAL=6

[ -f "$PROJECT_DIR/.venv/bin/python" ] && ((SCORE++))
"$PROJECT_DIR/.venv/bin/python" -c "import nanobanana_mcp_server.server" 2>/dev/null && ((SCORE++))
[ -f "$PROJECT_DIR/cursor_mcp_config.json" ] && ((SCORE++))
[ -d "$OUTPUT_DIR" ] && ((SCORE++))
[ -f "$CURSOR_LOG" ] && ((SCORE++))
! [[ "$(readlink "$PROJECT_DIR/.venv/bin/python" 2>/dev/null)" == *"miniconda"* ]] && ((SCORE++))

PERCENTAGE=$((SCORE * 100 / TOTAL))

if [ $PERCENTAGE -ge 80 ]; then
    echo "✅ 健康状态: 良好 ($SCORE/$TOTAL - $PERCENTAGE%)"
elif [ $PERCENTAGE -ge 50 ]; then
    echo "⚠️  健康状态: 一般 ($SCORE/$TOTAL - $PERCENTAGE%)"
else
    echo "❌ 健康状态: 需要修复 ($SCORE/$TOTAL - $PERCENTAGE%)"
fi
echo ""

# 提供建议
echo "💡 快速操作:"
echo "   查看实时日志:"
echo "      tail -f ~/Library/Logs/Cursor/main.log | grep -i nanobanana"
echo ""
echo "   调试模式运行:"
echo "      cd $PROJECT_DIR"
echo "      LOG_LEVEL=DEBUG .venv/bin/python -m nanobanana_mcp_server.server"
echo ""
echo "   重新设置:"
echo "      cd $PROJECT_DIR"
echo "      ./scripts/setup-cursor.sh"
echo ""
echo "   查看 Cursor 输出面板:"
echo "      Cmd + Shift + U (macOS)"
echo ""
echo "===================================="
