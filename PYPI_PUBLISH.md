# PyPI 发布指南

本文档说明如何将 `mcp-nanobanana` 发布到 PyPI。

## 前置要求

1. PyPI 账号 - https://pypi.org/account/register/
2. PyPI API Token (推荐) 或用户名密码
3. 安装构建工具：`uv` 已经包含构建功能

## 发布步骤

### 1. 确认版本号

检查 [pyproject.toml](pyproject.toml) 中的版本号：

```toml
version = "1.0.0"
```

### 2. 构建包

```bash
# 使用 uv 构建
uv build

# 构建产物会生成在 dist/ 目录：
# - dist/mcp_nanobanana-1.0.0.tar.gz (源码分发)
# - dist/mcp_nanobanana-1.0.0-py3-none-any.whl (wheel 包)
```

### 3. 检查构建产物

```bash
# 列出构建产物
ls -lh dist/

# 检查 wheel 包内容
unzip -l dist/mcp_nanobanana-1.0.0-py3-none-any.whl
```

### 4. 测试安装

```bash
# 在虚拟环境中测试安装
uv pip install dist/mcp_nanobanana-1.0.0-py3-none-any.whl

# 测试命令
mcp-nanobanana --help

# 或用 python 模块方式运行
python -m nanobanana_mcp_server.server
```

### 5. 发布到 TestPyPI（可选，推荐）

首先发布到 TestPyPI 测试：

```bash
# 使用 twine 发布到 TestPyPI
uv run twine upload --repository testpypi dist/*

# 或者使用 API token
uv run twine upload --repository testpypi dist/* --username __token__ --password YOUR_TESTPYPI_TOKEN
```

从 TestPyPI 测试安装：

```bash
# 使用 uvx 测试
uvx --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple/ mcp-nanobanana

# 或使用 pip
pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple/ mcp-nanobanana
```

### 6. 发布到 PyPI

确认无误后，发布到正式 PyPI：

```bash
# 使用 API Token（推荐）
uv run twine upload dist/* --username __token__ --password YOUR_PYPI_TOKEN

# 或使用用户名密码
uv run twine upload dist/*
```

### 7. 验证发布

```bash
# 等待几分钟让 PyPI 索引更新，然后测试安装
uvx mcp-nanobanana

# 检查 PyPI 页面
# https://pypi.org/project/mcp-nanobanana/
```

## API Token 配置

### 创建 PyPI API Token

1. 登录 PyPI: https://pypi.org/
2. 进入 Account Settings -> API Tokens
3. 点击 "Add API token"
4. 名称：`mcp-nanobanana-upload`
5. Scope: 选择 "Entire account" 或特定项目

### 配置 .pypirc（可选）

在 `~/.pypirc` 中配置 token：

```ini
[distutils]
index-servers =
    pypi
    testpypi

[pypi]
username = __token__
password = pypi-YOUR_PYPI_TOKEN_HERE

[testpypi]
repository = https://test.pypi.org/legacy/
username = __token__
password = pypi-YOUR_TESTPYPI_TOKEN_HERE
```

配置后可以简化发布命令：

```bash
# 直接发布，无需输入密码
uv run twine upload dist/*
```

## 版本发布流程

### 1. 准备新版本

```bash
# 1. 更新版本号（在 pyproject.toml）
# 2. 清理旧的构建产物
rm -rf dist/ build/ *.egg-info

# 3. 构建新版本
uv build

# 4. 测试安装
uv pip install dist/*.whl --force-reinstall
```

### 2. 提交代码

```bash
# 1. 提交版本更改
git add pyproject.toml
git commit -m "chore: bump version to 1.0.0"

# 2. 创建 git tag
git tag -a v1.0.0 -m "Release v1.0.0"

# 3. 推送到远程
git push origin master
git push origin v1.0.0
```

### 3. 发布到 PyPI

```bash
# 发布
uv run twine upload dist/*
```

## 故障排查

### 包名已存在

如果包名 `mcp-nanobanana` 已被占用：

```bash
# 检查是否已存在
pip search mcp-nanobanana
# 或访问: https://pypi.org/project/mcp-nanobanana/
```

如果已存在但是你的项目，使用 `--skip-existing` 跳过已有版本：

```bash
uv run twine upload dist/* --skip-existing
```

### 构建失败

```bash
# 清理缓存和旧文件
rm -rf dist/ build/ *.egg-info
rm -rf .venv/
uv sync
uv build
```

### 安装依赖失败

确保 [pyproject.toml](pyproject.toml) 中的依赖版本正确：

```toml
dependencies = [
    "fastmcp>=2.11.0",
    "google-genai>=1.41.0",
    "pillow>=10.4.0",
    "python-dotenv>=1.0.1",
    "pydantic>=2.0.0",
]
```

## 自动化发布（CI/CD）

可以使用 GitHub Actions 自动发布：

```yaml
# .github/workflows/publish.yml
name: Publish to PyPI

on:
  release:
    types: [published]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install uv
        run: pip install uv
      - name: Build
        run: uv build
      - name: Publish
        env:
          TWINE_USERNAME: __token__
          TWINE_PASSWORD: ${{ secrets.PYPI_TOKEN }}
        run: uv run twine upload dist/*
```

## 参考资料

- PyPI 官方文档: https://packaging.python.org/
- Twine 文档: https://twine.readthedocs.io/
- uv 文档: https://github.com/astral-sh/uv
