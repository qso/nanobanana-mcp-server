#!/bin/bash

# Cursor MCP 服务器快速设置脚本
# 用于配置 Nano Banana MCP 服务器在 Cursor 中使用

set -e

echo "🍌 Nano Banana MCP Server - Cursor 设置脚本"
echo "=============================================="
echo ""

# 获取项目根目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "📁 项目目录: $PROJECT_DIR"
echo ""

# 检查 Python 版本
echo "🐍 检查 Python 版本..."
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
REQUIRED_VERSION="3.11"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ 错误: 需要 Python $REQUIRED_VERSION 或更高版本"
    echo "   当前版本: $PYTHON_VERSION"
    exit 1
fi
echo "✅ Python 版本: $PYTHON_VERSION"
echo ""

# 检查 uv 是否安装
echo "📦 检查 uv 是否安装..."
if ! command -v uv &> /dev/null; then
    echo "❌ uv 未安装"
    echo "正在安装 uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "✅ uv 安装完成"
else
    echo "✅ uv 已安装: $(uv --version)"
fi
echo ""

# 检查并修复虚拟环境
echo "🔧 检查虚拟环境..."
if [ -d "$PROJECT_DIR/.venv" ]; then
    VENV_PYTHON=$(readlink "$PROJECT_DIR/.venv/bin/python" 2>/dev/null || echo "")
    if [[ "$VENV_PYTHON" == *"miniconda"* ]]; then
        echo "⚠️  检测到虚拟环境使用 miniconda Python"
        echo "正在重新创建虚拟环境..."
        rm -rf "$PROJECT_DIR/.venv"
    else
        echo "✅ 虚拟环境正常"
    fi
fi

if [ ! -d "$PROJECT_DIR/.venv" ]; then
    echo "📦 创建虚拟环境（使用 Homebrew Python）..."
    cd "$PROJECT_DIR"
    
    # 尝试找到 Homebrew Python
    if [ -f "/opt/homebrew/bin/python3.11" ]; then
        uv venv --python /opt/homebrew/bin/python3.11
    elif [ -f "/opt/homebrew/bin/python3" ]; then
        uv venv --python /opt/homebrew/bin/python3
    else
        echo "⚠️  未找到 Homebrew Python，使用默认 Python"
        uv venv --python 3.11
    fi
    
    echo "✅ 虚拟环境创建完成"
fi
echo ""

# 验证虚拟环境 Python
echo "🔍 验证虚拟环境 Python..."
VENV_PYTHON_PATH=$(readlink "$PROJECT_DIR/.venv/bin/python" 2>/dev/null || echo "$PROJECT_DIR/.venv/bin/python")
echo "   Python 路径: $VENV_PYTHON_PATH"

if [[ "$VENV_PYTHON_PATH" == *"miniconda"* ]]; then
    echo "❌ 错误: 虚拟环境仍然使用 miniconda Python"
    echo "   请手动运行: rm -rf .venv && uv venv --python /opt/homebrew/bin/python3.11"
    exit 1
fi
echo "✅ 虚拟环境 Python 正确"
echo ""

# 安装项目依赖
echo "📦 安装项目依赖..."
cd "$PROJECT_DIR"
uv pip install -e .
echo "✅ 依赖安装完成"
echo ""

# 验证模块导入
echo "🔍 验证模块导入..."
if uv run python -c "import nanobanana_mcp_server.server; print('✅ 模块导入成功')" 2>&1; then
    echo "✅ 模块验证通过"
else
    echo "❌ 模块导入失败"
    exit 1
fi
echo ""

# 检查 GEMINI_API_KEY
echo "🔑 检查 GEMINI_API_KEY..."
if [ -z "$GEMINI_API_KEY" ]; then
    echo "⚠️  警告: GEMINI_API_KEY 环境变量未设置"
    echo ""
    echo "请访问 https://makersuite.google.com/app/apikey 获取 API Key"
    echo ""
    read -p "请输入你的 GEMINI_API_KEY (或按 Enter 跳过): " API_KEY
    if [ -n "$API_KEY" ]; then
        export GEMINI_API_KEY="$API_KEY"
        echo "✅ API Key 已设置"
    else
        echo "⚠️  跳过 API Key 设置，请稍后在配置文件中添加"
    fi
else
    echo "✅ GEMINI_API_KEY 已设置"
fi
echo ""

# 生成配置文件
echo "📝 生成 Cursor 配置..."
CONFIG_FILE="$PROJECT_DIR/cursor_mcp_config.json"

# 使用虚拟环境的 Python 而不是 uv run（避免 miniconda 冲突）
cat > "$CONFIG_FILE" << EOF
{
  "mcpServers": {
    "nanobanana-local": {
      "command": "$PROJECT_DIR/.venv/bin/python",
      "args": ["-m", "nanobanana_mcp_server.server"],
      "cwd": "$PROJECT_DIR",
      "env": {
        "GEMINI_API_KEY": "${GEMINI_API_KEY:-your-gemini-api-key-here}",
        "NANOBANANA_MODEL": "auto",
        "LOG_LEVEL": "INFO",
        "LOG_FORMAT": "standard"
      }
    }
  }
}
EOF

echo "✅ 配置文件已生成: $CONFIG_FILE"
echo ""

# 显示配置内容
echo "📋 配置内容:"
echo "----------------------------------------"
cat "$CONFIG_FILE"
echo "----------------------------------------"
echo ""

# 提供下一步指引
echo "🎉 设置完成！"
echo ""
echo "📌 下一步操作:"
echo "1. 如果需要修改 API Key，编辑配置文件:"
echo "   $CONFIG_FILE"
echo ""
echo "2. 将配置内容复制到 Cursor 的 MCP 配置文件:"
echo "   macOS: ~/Library/Application Support/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
echo ""
echo "3. 完全重启 Cursor"
echo ""
echo "4. 在 Cursor 中测试:"
echo "   '使用 Nano Banana 生成一张图片：一只可爱的猫咪'"
echo ""
echo "📚 更多信息:"
echo "   - 使用指南: $PROJECT_DIR/docs/NANO_BANANA_PRO_USAGE.md"
echo "   - 设置文档: $PROJECT_DIR/CURSOR_SETUP.md"
echo "   - 修复日志: $PROJECT_DIR/CHANGELOG_FIX.md"
echo ""
echo "🐛 遇到问题？查看: $PROJECT_DIR/CURSOR_SETUP.md"
echo ""
