# DS-U.3 — MiniMax-H3 Singularity 参考生视频工作流（Ref2VA）

**AutoDL Art 发布配套仓库**（镜像名：DS-U.3）｜ 干净重建版：官方 ComfyUI + MiniMax H3 开源权重

U30 是 MiniMax-H3 **Singularity 参考生视频（Ref2VA 全参考模式）** 工作流：支持参考图/参考视频/参考音频，输出带原生立体声音效的 10 秒 16:9 视频，配合 **六段式提示词**（主体定义 / 摘要 / 保留度分析 / 详细描述 / 环境音效 / BGM）。

本仓库同时提供两版工作流：

| 版本 | 文件 | 说明 |
|---|---|---|
| **干净重建版（推荐发布）** | `workflows/API-U30-K-clean.json` | 全部使用 ComfyUI 内核与公共插件节点，**不含任何第三方私有面板内容**，可公开分发 |
| 原版（参考） | `workflows/API-U30-K.json` | 逆向自 zealman 面板，含私有节点（ZealmanH3*），仅作参数对照，**不建议二次分发** |

## 特性

- 🎬 Ref2VA 全参考模式（图片参考 + 音频参考，画面与声音双重对齐）
- ✂️ 一采/二采分段调度 + 3D latent 放大（默认 1.5×）
- 🧠 Ref2VA 剪枝 INT8 模型（20.97 GB），32G 显存可跑；Turbo 4-step LoRA 加速
- 📝 内置 H3 官方六段式提示词模板（fullReference / FL2VA / I2VA / T2VA）
- ✅ 一键搭建脚本 `scripts/build_u30_clean.sh` + 依赖自检 `scripts/verify_clean.py`

## 环境要求（干净重建版）

| 项 | 要求 |
|---|---|
| GPU | 24G（剪枝 INT8）/ 32G+（完整 INT8） |
| ComfyUI | 0.30.0+（推荐 master，内置 `MiniMaxH3ReferenceToVideo`） |
| 第三方节点 | ComfyUI-KJNodes、ComfyUI-Easy-Use、ComfyUI-VideoHelperSuite、Comfyui_Minimax_h3_latent_Upscaler、Comfyui-Memory_Cleanup |
| 模型 | `Comfy-Org/MiniMax-H3`（HF）：ref2va pruned int8 20.97G + qwen3vl int8 27.14G + video vae int8 2.81G + audio vae fp32 0.61G + Turbo LoRA 1.96G；upscaler 权重见 `LBH-123-AI/Minimax_h3_latent_Upscaler` |
| 系统盘 | ≥ 120 GB（模型约 53 GB + 环境） |

## 快速开始（新实例一键搭建）

```bash
# 1. 克隆仓库
cd /root && git clone https://github.com/jzwjczc-cmd/DS-U.3.git && cd DS-U.3

# 2. 一键搭建（装 ComfyUI + 插件 + 下模型 + 自检 + 出片自测）
bash scripts/build_u30_clean.sh
```

脚本会自动：克隆官方 ComfyUI → 安装 5 个插件 → 从 hf-mirror 下载模型（约 53 GB）→ 放置参考素材与工作流 → 启动 :8188 → 依赖自检 → 提交一次出片测试。

依赖自检（可单独运行，缺可选节点会自动降级重接）：

```bash
curl -s http://127.0.0.1:8188/object_info -o /root/object_info.json
python3 scripts/verify_clean.py /root/object_info.json workflows/API-U30-K-clean.json workflows/API-U30-K-clean-final.json
```

> 完整 INT8（34 GB）可换 `diffusion_models/minimax_h3_ref2va_int8_convrot.safetensors`，改工作流 `UNETLoader.unet_name` 即可；48G 显存推荐。

## 目录结构

```
├── workflows/
│   ├── API-U30-K-clean.json      # 干净重建版（发布用，32 节点标准节点）
│   └── API-U30-K.json            # 原版（参考对照，含私有节点）
├── prompts/                      # H3 六段式提示词模板（fullReference/FL2VA/I2VA/T2VA）+ 示例
├── config/                       # u-series-defaults.json / defaults_u30.json / variant_u30.js
├── samples/                      # 演示参考图 ref_sample_1/2.png
├── docs/                         # 节点可读版、模型清单、插件清单
└── scripts/
    ├── check.py                  # 环境自检（零依赖，AutoDL Art 审核标准）
    ├── build_u30_clean.sh        # 干净版一键搭建（新实例执行）
    └── verify_clean.py           # 依赖自检 + 可选节点自动降级
```

## 六段式提示词（内置在 clean 工作流中）

```text
1. subject_definitions（主体定义）：<Subject 1> … <Subject 2> … <Picture 1-9>
2. summary（摘要）
3. retention_analysis（保留度分析）：<Picture 1-9> <Video> <Audio 1-3>
4. detailed_description（详细描述）：<Video> <Audio>
5. overall_sound_effects（环境音效）：<Audio>
6. bgm（BGM）：<Audio>
```

完整模板见 `prompts/prompts_fullReference.txt`；clean 工作流已内置一段完整示例（双人机翼格斗，10s / 0.7MP / 16:9）。

## AutoDL Art 发布提示

1. 新实例装好并出片验证通过后，**关机 → 控制台「保存镜像」**（镜像名 `DS-U.3`）
2. 发布页：GitHub 仓库地址填本仓库；镜像名称 `DS-U.3`（若小数点不被接受改用 `DS-U-3`）；README 用本文件
3. 审核标准：/root 下含 Git 仓库（`/root/DS-U.3`，搭建脚本自动 clone）+ 可执行简单代码（`scripts/check.py`）

## 免责声明与许可

- 干净重建版仅依赖 **ComfyUI（GPL）**、**MiniMax H3 开源权重（MiniMax H3 Community License）** 与各公共插件仓库，不包含任何第三方闭源面板内容。
- 原版 `API-U30-K.json` 逆向自 zealman Control Panel，版权归原作者所有，仅作参数对照，请勿二次分发。
- 商用请遵守 MiniMax H3 Community License（商业许可需通过 Comfy 官方渠道）与各插件仓库许可。
