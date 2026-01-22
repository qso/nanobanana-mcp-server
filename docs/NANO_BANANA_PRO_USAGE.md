# Nano Banana Pro 使用指南

## 概述
Nano Banana Pro 是基于 Gemini 3 Pro Image 预览版模型的高质量图片生成服务，支持最高 4K 分辨率。

## 配置方式

### 在 Cursor 中配置

#### 方法 1: 使用已发布的包（推荐）

在 Cursor 的 MCP 配置文件中添加：

```json
{
  "mcpServers": {
    "nanobanana": {
      "command": "uvx",
      "args": ["nanobanana-mcp-server@latest"],
      "env": {
        "GEMINI_API_KEY": "your-gemini-api-key-here",
        "NANOBANANA_MODEL": "pro"
      }
    }
  }
}
```

#### 方法 2: 使用本地源码（开发模式）

**重要**: 使用本地源码前，需要先安装依赖：

```bash
cd /Users/hzlizhaoming/Project/nanobanana-mcp-server
uv pip install -e .
```

然后在 Cursor 配置中添加：

```json
{
  "mcpServers": {
    "nanobanana-local": {
      "command": "uv",
      "args": ["run", "python", "-m", "nanobanana_mcp_server.server"],
      "cwd": "/Users/hzlizhaoming/Project/nanobanana-mcp-server",
      "env": {
        "GEMINI_API_KEY": "your-gemini-api-key-here",
        "NANOBANANA_MODEL": "pro"
      }
    }
  }
}
```

**注意**: 
- 确保 `cwd` 路径指向你的项目目录
- 每次修改代码后，需要重启 Cursor 的 MCP 服务器才能生效

## 使用示例

### 1. 基础图片生成

```python
generate_image(
    prompt="Professional product photo of vintage camera on wooden desk",
    model_tier="pro"
)
```

### 2. 4K 高分辨率生成

```python
generate_image(
    prompt="Stunning landscape photography of mountain vista at golden hour",
    model_tier="pro",
    resolution="4k",
    aspect_ratio="21:9"  # 超宽电影格式
)
```

### 3. 启用 Google 搜索增强

```python
generate_image(
    prompt="The Eiffel Tower at sunset with accurate architectural details",
    model_tier="pro",
    enable_grounding=True,  # 使用 Google 搜索获取真实信息
    resolution="2k"
)
```

### 4. 文字渲染（Pro 模型优势）

```python
generate_image(
    prompt="Infographic showing 2024 market statistics with clear, readable labels and charts",
    model_tier="pro",
    resolution="4k"  # 4K 分辨率确保文字清晰
)
```

### 5. 指定宽高比

支持的宽高比：
- `1:1` - 正方形（Instagram、头像）
- `4:3` / `3:4` - 经典照片格式
- `16:9` / `9:16` - 宽屏/竖屏（YouTube、手机壁纸）
- `21:9` - 超宽电影格式
- `2:3`, `3:2`, `4:5`, `5:4` - 其他照片格式

```python
generate_image(
    prompt="Mobile wallpaper of serene mountain landscape",
    model_tier="pro",
    aspect_ratio="9:16",  # 手机竖屏
    resolution="2k"
)
```

### 6. 自动模型选择

```python
# 系统会自动选择 Pro 模型（因为包含质量关键词）
generate_image(
    prompt="Professional 4K product photography for magazine print",
    model_tier="auto"  # 自动检测
)

# 系统会自动选择 Flash 模型（因为包含速度关键词）
generate_image(
    prompt="Quick sketch of a cat for draft mockup",
    model_tier="auto"
)
```

## Pro 模型特性

### ✅ 优势
1. **超高分辨率**: 支持最高 4K (3840px)
2. **Google 搜索增强**: 基于真实世界知识生成图片
3. **文字渲染**: 图片中的文字清晰可读
4. **高级推理**: 更好地理解复杂提示词
5. **专业质量**: 适合生产环境使用

### 📊 分辨率对照表

| 宽高比 | 1K 分辨率 | 2K 分辨率 | 4K 分辨率 |
|--------|-----------|-----------|-----------|
| 1:1    | 1024x1024 | 2048x2048 | 4096x4096 |
| 16:9   | 1376x768  | 2752x1536 | 5504x3072 |
| 9:16   | 768x1376  | 1536x2752 | 3072x5504 |
| 21:9   | 1584x672  | 3168x1344 | 6336x2688 |

### ⚡ Flash vs Pro 对比

| 特性 | Flash | Pro |
|------|-------|-----|
| 速度 | 2-3秒 | 5-8秒 |
| 最高分辨率 | 1024px | 4K (3840px) |
| Google 搜索 | ❌ | ✅ |
| 文字渲染质量 | 一般 | 优秀 |
| 适用场景 | 快速迭代、草图 | 生产环境、专业输出 |
| 成本 | 较低 | 较高 |

## 常见问题

### Q: 如何获取 GEMINI_API_KEY？
A: 访问 [Google AI Studio](https://makersuite.google.com/app/apikey) 免费获取。

### Q: 为什么报错 "output_mime_type parameter is not supported"？
A: 这个问题已经在最新版本中修复。请确保使用最新版本：
```bash
uvx nanobanana-mcp-server@latest
```

### Q: Pro 模型支持哪些参数？
A: Pro 模型支持：
- `resolution`: "high", "1k", "2k", "4k"
- `aspect_ratio`: "1:1", "16:9", "9:16", "21:9" 等
- `enable_grounding`: true/false (Google 搜索增强)
- `thinking_level`: "low", "high" (注意：当前版本可能不支持)

### Q: 如何选择合适的分辨率？
A: 
- **1K**: 快速预览、社交媒体
- **2K**: 网页使用、演示文稿
- **4K**: 印刷品、专业摄影、需要文字的图片

## 参考资料
- [Gemini API 官方文档](https://ai.google.dev/gemini-api/docs/image-generation?hl=zh-cn)
- [项目 README](../README.md)
- [修复日志](../CHANGELOG_FIX.md)
