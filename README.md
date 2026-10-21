# DS-U.3 — MiniMax-H3 Singularity 参考生视频工作流（Ref2VA）

**镜像发布配套仓库** | AutoDL Art（镜像名：DS-U.3）｜ ComfyUI 0.41.0 ｜ zealman Control Panel 2026.10.21.1816

U30 是 MiniMax-H3 **Singularity 参考生视频（Ref2VA 全参考模式）** 工作流：支持最多 9 张参考图 + 3 段参考音频，输出带音效与 BGM 的 10 秒 16:9 视频，配合 **六段式提示词**（主体定义 / 摘要 / 保留度分析 / 详细描述 / 环境音效 / BGM）。

## 特性

- 🎬 Ref2VA 全参考模式（图参考 + 音频参考，画面与声音双重对齐）
- ✂️ 一采/二采分段调度 + 3D latent 放大（默认 1.5×）
- 🧠 Singularity 剪枝 INT8 模型，32G 显存可跑；Turbo 4-step LoRA 加速
- 📝 内置 H3 官方六段式提示词模板（fullReference / FL2VA / I2VA / T2VA）
- ✅ 镜像内自检脚本 `scripts/check.py`（零依赖，符合 AutoDL Art 审核标准）

## 环境要求

| 项 | 要求 |
|---|---|
| GPU | 24G（剪枝 INT8）/ 32G+（完整 INT8） |
| ComfyUI | 0.41.0（内置 MiniMaxH3ReferenceToVideo / BlockSparseAttention 等节点） |
| 面板 | zealman Control Panel（v2026.10.21.1816 及以上，U30 变体已内置） |
| 系统盘 | ≥ 100 GB（模型约 80 GB） |

## 快速开始（镜像内）

```bash
# 1. 环境自检（审核标准：仓库内可执行简单代码）
cd /root/U30-MiniMaxH3-Ref2VA && python3 scripts/check.py

# 2. 放置工作流模板（面板 public 目录，路径以实例为准）
cp workflows/API-U30-K.json /root/zealman-app/public/API-U30-K.json

# 3. 放置默认配置与提示词
cp config/u-series-defaults.json /root/zealman-app/u-series-defaults.json
cp prompts/h3_skill_prompts.json /root/zealman-app/skill-prompt.json

# 4. 启动面板（以实例实际启动方式为准），打开 U30 页面
```

> 模型与插件安装清单见 `docs/`。模型权重、面板本体、API 密钥**不在本仓库**内。

## 目录结构

```
├── workflows/          # API-U30-K.json（28 节点，ComfyUI API 格式）
├── prompts/            # H3 六段式提示词模板（fullReference/FL2VA/I2VA/T2VA）+ 示例
├── config/             # u-series-defaults.json / defaults_u30.json / variant_u30.js
├── docs/               # 节点可读版、模型清单、插件清单
└── scripts/check.py    # 环境自检（零依赖）
```

## 提示词示例（六段式）

```text
1. subject_definitions（主体定义）：<Subject 1> … <Subject 2> …
2. summary（摘要）
3. retention_analysis（保留度分析）：<Picture 1-9> <Video> <Audio 1-3>
4. detailed_description（详细描述）：<Video> <Audio>
5. overall_sound_effects（环境音效）：<Audio>
6. bgm（BGM）：<Audio>
```

完整模板见 `prompts/prompts_fullReference.txt`。

## 免责声明

- 本仓库仅包含工作流 JSON、配置与提示词模板；**不包含** zealman 面板程序、模型权重与任何 API 密钥。
- 工作流源自 zealman Control Panel，版权归原作者所有；镜像内分发请自行确认授权（建议镜像发布后仅供指定账号使用或取得授权后再公开）。
- 商用与二次分发请遵守模型与软件各自的许可条款。

## License

见各上游项目许可；本仓库内容按“仅供参考与自用”提供。
