# U30 必需模型文件清单（MiniMax-H3 Singularity Ref2VA）

> 来源：`workflow/API-U30-K.json` 节点 #301（ZealmanH3ModelLoader）、#124（LatentUpscaler3D）、#208（Preview tiny vae）、#214（SemanticBridge）+ `config/defaults_full_options.json`。
> 放置目录按 ComfyUI 0.41 惯例（`models/` 下），`minimax/` 为子目录前缀（即 `models/<type>/minimax/xxx`）。目标机装好对应插件后，路径以节点下拉框实际可选项为准。

## 一、必装（模板硬引用）

| 文件 | 类型 | 大小 | 建议目录 |
|---|---|---|---|
| `minimax/Minimax-h3_Singularity_ref2va_v1.3_int8.safetensors` | UNet（Ref2VA 完整 INT8） | 31.7 GB | `models/unet/minimax/`（或 diffusion_models） |
| `Minimax-h3_Singularity_ref2va_Pruned_v1.3_int8.safetensors` | UNet（剪枝 INT8，面板默认项） | 19.53 GB | 同上（二选一即可，见备注） |
| `qwen3vl_32b_minimax_h3_int8_convrot.safetensors` | CLIP（Qwen3VL 32B INT8） | 25.3 GB | `models/text_encoders/` |
| `minimax_h3_video_vae_int8_convrot.safetensors` | Video VAE | ~1 GB 级 | `models/vae/` |
| `minimax_h3_audio_vae_fp32.safetensors` | Audio VAE | 小 | `models/vae/` |
| `minimax/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors` | LoRA（ref2v turbo 4step，强度 1.0，必开） | 小 | `models/loras/minimax/` |
| `minimax_h3_latent_upscaler_3d_bf16.safetensors` | 3D latent 放大器（#124） | 小 | 对应插件模型目录 |
| `t8_compat/MiniMaxH3_SemanticBridge_v1_T8_Compat.safetensors` | 语义桥接适配器（#214） | ~1-2 MB | `models/loras/t8_compat/`（SemanticBridge 插件目录） |
| `taeh3.safetensors` | Tiny VAE（#208 预览用） | 小 | `models/vae/` |

## 二、模板里默认关闭、可选安装的 LoRA（#301 lora_2~lora_6）

| LoRA | 文件 | 默认 |
|---|---|---|
| lora_2 | `minimax/MysticXXX_MMH3-V1.safetensors` | off (0.45) |
| lora_3 | `minimax/H3_Combat_V2.safetensors` | off (0.65) |
| lora_4 | `minimax/Motion_Repair_V2.safetensors` | off (0.35) |
| lora_5 | `minimax/H3_Fight_Flow_V1.safetensors` | off (0.35) |
| lora_6 | `minimax/motion_speed_slider_mmh3_v1.1.safetensors` | off (3.0) |

## 三、同系列可选模型（面板 U 系列共用，不影响 U30 基本运行）

- ref2va 官方档：`minimax_h3_ref2va_bf16.safetensors`(61.7G) / `minimax_h3_ref2va_pruned_bf16.safetensors`(37.5G) / `minimax_h3_ref2va_int8_convrot.safetensors`(31.7G) / `minimax_h3_ref2va_pruned_int8_convrot.safetensors`(19.5G)
- 社区/微调档：XUELUO、NVFP4 系列（需 Blackwell）、10Eros、Dasiwa、FeiHou、REDMIX 等（详见 `config/defaults_full_options.json`）
- CLIP 档：`qwen3vl_32b_minimax_h3_bf16.safetensors`(48G) / `qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors`(14.6G) / `qwen3vl_32b_minimax_h3_int4_convrot.safetensors`(13.9G)
- LoRA 档：`minimax_h3_turbo_4step_comfyui.safetensors`、`minimax_h3_turbo_4stepema_comfyui.safetensors`、`minimax_h3_turbo_v4_step600_ema_pruned_comfyui.safetensors` 等（全表见 `config/defaults_full_options.json` 的 loraOptions）

## 四、显存建议（U30 默认档）

- 32G 及以上：完整 INT8 版（31.7G UNet）+ qwen3vl_int8（25.3G CLIP，可换 nvfp4 14.6G 省显存）
- 24G 及以下：剪枝 INT8（19.53G）+ CLIP int4/nvfp4；长度建议 ≤15 秒，放大 ≤1.5
- 面板 `recommend` 内置档位：unet ≥44G 用 int8/pruned_int8/pruned_bf16/bf16；32G 用 pruned_int8/nvfp4 系；CLIP 40G 用 int8/nvfp4

> 备注：模板硬编码的是完整 INT8 版；面板 `u-series-defaults.json` 默认键为剪枝 INT8 版。镜像时二选一即可，若追求画质且显存充足用完整版，否则用剪枝版（面板注释：剪枝+INT8 画质接近 bf16，32G 卡稳妥主力档）。
