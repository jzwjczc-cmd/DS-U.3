# U30 必需插件/自定义节点清单

> 依据：`workflow/API-U30-K.json` 各节点 class_type + 面板 `/api/comfy/plugin-profile`（系列 U “视频-MINIMAX-H3” 插件池，共 62 工作流）。
> ComfyUI 版本：0.41.0。**标记“待实测”的节点归属以目标机 ComfyUI Manager / object_info 反查为准。**

## 一、ComfyUI 0.41.0 内核自带（无需安装）

| class_type | 位置 |
|---|---|
| MiniMaxH3ReferenceToVideo | `comfy_extras/nodes_minimax_h3.py`（已核对官方源码） |
| BlockSparseAttention | `comfy_extras/nodes_sparse_attention.py`（sol-attn/sla/vsa 三模式） |
| BasicGuider / KSamplerSelect / RandomNoise / BasicScheduler / ExtendIntermediateSigmas / SplitSigmas / SamplerCustomAdvanced / DisableNoise / VAEDecode | ComfyUI 内核采样/调度 |
| VAEDecodeAudio | ComfyUI 内核（AV 视频支持） |

## 二、必须安装的第三方节点

| class_type | 插件仓库（面板安装名） | 说明 |
|---|---|---|
| ZealmanH3PickReferenceMedia | **comfyUI-zealman** | 面板私有素材拾取节点 |
| ZealmanH3ModelLoader | **comfyUI-zealman** | 面板私有模型加载器（unet/clip/vae/lora 合一） |
| SenseNovaH3DistilledBridge | **MiniMax_H3_Semantic_Bridge** | 语义桥接（模型路径 `t8_compat/...`） |
| ModelPreviewOverrideKJ | **ComfyUI-KJNodes** | 预览覆盖 |
| easy float | **ComfyUI-Easy-Use** | 放大系数 |
| VHS_VideoCombine | **ComfyUI-VideoHelperSuite** | 视频合成输出 |

## 三、归属待实测（给出候选，装齐后以 object_info 校验）

| class_type | 候选插件 | 备注 |
|---|---|---|
| MiniMaxChunkFeedForward | ComfyUI-KJNodes（另有资料称内核也提供，实测为准） | chunks=2, seq_threshold=4096 |
| MinimaxH3LatentUpscaler3D | ComfyUI-MiniMaxH3_LatentUpscaler / Comfyui_Minimax_h3_latent_Upscaler / ComfyUI-H3LatentUpscale-jingchen573 | 3D latent 放大，模型 `minimax_h3_latent_upscaler_3d_bf16.safetensors` |
| LTXVSeparateAVLatent / LTXVConcatAVLatent | ComfyUI-LTXVideo / ComfyUI-PT_H3ConcatAVLatent | 音视频 latent 分离/拼接 |
| VRAMCleanup | comfyui_memory_cleanup | 解码前显存清理 |

## 四、面板 U 系列插件池（完整安装清单，供参考）

面板系列 U（62 工作流）已安装插件共 70 个左右，U30 实际只用到上面二、三节列出的部分。若目标面板是同版本 zealman（插件 profile=all，禁用 0 个），无需单独处理，整套已装好。

U 系列主要插件（含未用到的）：BUNNY_H3_Conditioning_Bridge、ComfyUI-DaSiWa-Nodes、ComfyUI-FeiHou-Easy-H3、ComfyUI-FeiHou-Toolbox、ComfyUI-GGUF、ComfyUI-H3-AudioRefine、ComfyUI-H3-ClipStream、ComfyUI-H3-Context-Noise、ComfyUI-H3-Motion-Context、ComfyUI-H3-SLA-Attention、ComfyUI-H3LatentUpscale-jingchen573、ComfyUI-HyperFlow-H3、ComfyUI-LTXVideo、ComfyUI-LogicUtils、ComfyUI-MMH3Tools、ComfyUI-MiniMax-H3-Audio-Guide-Feather、ComfyUI-MiniMax-H3-PDD-Acc、ComfyUI-MiniMax-H3-Promptor、ComfyUI-MiniMax-H3-Sampler-Unlimited、ComfyUI-MiniMax-H3-Turbo、ComfyUI-MiniMaxH3-FirstBlockCache、ComfyUI-MiniMaxH3Mod、ComfyUI-MiniMaxH3_LatentUpscaler、ComfyUI-NB-H3-HyperStep、ComfyUI-PT_H3ConcatAVLatent、ComfyUI-SolAttn_triton、ComfyUI-Spectrum-MiniMax-H3、ComfyUI-VFI、ComfyUI-VideoHelperSuite、ComfyUI-Viggle-Animate-H3、ComfyUI-YCNodes-MiniMax-H3、ComfyUI_MiniMaxH3_Director、ComfyUI_MinimaxH3HybridLoader-master、ComfyUI_UniBlockSwap、Comfyui-MMH3-UltimateUpscale、Comfyui_Minimax_h3_latent_Upscaler、Goohai-MiniMax-H3_Integration、Goohaitools-comfyui、H3-Long-Video-Manager、H3-LongTakeNoCuts、MiniMax_H3_Semantic_Bridge、comfyUI-zealman、comfyui-SelfLift、comfyui-minimax-h3-audio-T8、comfyui-minimax-h3-blockcache-T8、comfyui-minimax-h3-prompt-enhancer-T8、nanfeng_prompt_nodes_v10/v15、selflift-Avatar、soundflow 等。

## 五、校验方法

目标机装好后：
1. ComfyUI 前端打开任意工作流 → 添加节点 → 搜索 `MiniMaxH3ReferenceToVideo`（内核）、`ZealmanH3PickReferenceMedia`（zealman）、`ModelPreviewOverrideKJ`（KJNodes）等。
2. 或直接 POST `workflow/API-U30-K.json` 到 `/prompt`，若返回 `node_errors` 为全空即依赖齐全。
