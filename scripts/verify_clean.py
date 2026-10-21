#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verify_clean.py — 干净版 U30 工作流依赖自检 + 可选节点自动降级
用法:
  python3 verify_clean.py [object_info.json] [workflow.json] [out.json]
    object_info.json : 由 build_u30_clean.sh 从 ComfyUI /object_info 抓取
    workflow.json    : 默认 workflows/API-U30-K-clean.json
    out.json         : 最终可用工作流（缺可选节点时已自动重接），默认 workflows/API-U30-K-clean-final.json
判定:
  FATAL   缺失=必须装（脚本会自动报错提示装哪个插件）
  OPTIONAL 缺失=自动降级重接，不影响出片
"""
import json, sys, os

BASE = os.path.dirname(os.path.abspath(__file__))
OBJ = sys.argv[1] if len(sys.argv) > 1 else os.path.join(BASE, "object_info.json")
WF  = sys.argv[2] if len(sys.argv) > 2 else os.path.join(BASE, "workflows", "API-U30-K-clean.json")
OUT = sys.argv[3] if len(sys.argv) > 3 else os.path.join(BASE, "workflows", "API-U30-K-clean-final.json")

oi = json.load(open(OBJ, encoding='utf-8'))
wf = json.load(open(WF, encoding='utf-8'))

FATAL = {
    "MiniMaxH3ReferenceToVideo": "ComfyUI 内核(0.30.0+)",
    "BlockSparseAttention": "ComfyUI 内核 comfy_extras/nodes_sparse_attention.py",
    "LTXVSeparateAVLatent": "ComfyUI 内核 comfy_api_nodes/nodes_ltxv.py",
    "LTXVConcatAVLatent": "ComfyUI 内核 comfy_api_nodes/nodes_ltxv.py",
    "UNETLoader": "ComfyUI 内核",
    "CLIPLoader": "ComfyUI 内核",
    "VAELoader": "ComfyUI 内核",
    "LoraLoaderModelOnly": "ComfyUI 内核",
    "LoadImage": "ComfyUI 内核",
    "BasicGuider": "ComfyUI 内核",
    "BasicScheduler": "ComfyUI 内核",
    "KSamplerSelect": "ComfyUI 内核",
    "RandomNoise": "ComfyUI 内核",
    "ExtendIntermediateSigmas": "ComfyUI 内核",
    "SplitSigmas": "ComfyUI 内核",
    "SamplerCustomAdvanced": "ComfyUI 内核",
    "DisableNoise": "ComfyUI 内核",
    "VAEDecode": "ComfyUI 内核",
    "VAEDecodeAudio": "ComfyUI 内核",
    "ModelPreviewOverrideKJ": "ComfyUI-KJNodes",
    "VHS_VideoCombine": "ComfyUI-VideoHelperSuite",
    "easy float": "ComfyUI-Easy-Use",
}
OPTIONAL = {
    "MiniMaxChunkFeedForward": ("未找到公开仓库，跳过(仅省显存)", "208.model -> 121"),
    "MinimaxH3LatentUpscaler3D": ("LBH-123-AI/Comfyui_Minimax_h3_latent_Upscaler 未装，跳过放大 pass(108/128 合一)", "128.latent_image -> 104, 删 124/198"),
    "VRAMCleanup": ("LAOGOU-666/Comfyui-Memory_Cleanup 未装，跳过(仅清显存)", "109/110.samples -> 106"),
}

missing = [c for c in set(list(FATAL) + list(OPTIONAL)) if c not in oi and c in
           {v["class_type"] for v in wf.values()}]
fatal_missing = [c for c in missing if c in FATAL]
opt_missing = [c for c in missing if c in OPTIONAL]

print("== 依赖检查 ==")
for c in sorted({v['class_type'] for v in wf.values()}):
    print("  [%s] %s" % ("OK " if c in oi else "MISS", c))

if fatal_missing:
    print("\n!! FATAL: 以下内核/必装节点缺失，请先修复：")
    for c in fatal_missing:
        print("   - %s  <- %s" % (c, FATAL[c]))
    print("   升级 ComfyUI 或安装对应插件后重跑。")
    sys.exit(2)

for c in opt_missing:
    print("  可选节点缺失: %s (%s)" % (c, OPTIONAL[c][0]))

# 自动降级重接
wf_classes = {v["class_type"] for v in wf.values()}
if "MiniMaxChunkFeedForward" not in oi and "MiniMaxChunkFeedForward" in wf_classes:
    src = wf["143"]["inputs"]["model"]
    wf["208"]["inputs"]["model"] = src
    del wf["143"]
    print("  已降级: 143 MiniMaxChunkFeedForward -> 直连 121")

if "VRAMCleanup" not in oi and "VRAMCleanup" in wf_classes:
    for nid in ("109", "110"):
        wf[nid]["inputs"]["samples"] = ["106", 0]
    del wf["313"]
    print("  已降级: 313 VRAMCleanup -> 106 直连解码")

if "MinimaxH3LatentUpscaler3D" not in oi and "MinimaxH3LatentUpscaler3D" in wf_classes:
    wf["128"]["inputs"]["latent_image"] = ["104", 0]
    del wf["124"]
    del wf["198"]
    print("  已降级: 124 LatentUpscaler3D 移除(198 easy float 一并移除)，两遍采样合一")

# CLIPLoader type 修正
clip_ok = False
if "CLIPLoader" in oi:
    types = oi["CLIPLoader"]["input"]["required"]["type"][0]
    clip_ok = "minimax" in types
    if not clip_ok:
        cand = [t for t in types if "minimax" in t.lower()]
        if cand:
            for nid, v in wf.items():
                if v.get("class_type") == "CLIPLoader":
                    v["inputs"]["type"] = cand[0]
            print("  CLIPLoader type 已修正为: %s" % cand[0])
        else:
            print("!! 警告: CLIPLoader 无 minimax 系 type，需升级 ComfyUI")

# 最终断链校验
broken = []
for nid, v in wf.items():
    for val in v["inputs"].values():
        if isinstance(val, list) and val[0] not in wf:
            broken.append((nid, val))
if broken:
    print("!! 断链:", broken)
    sys.exit(2)

json.dump(wf, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("\n== 完成 ==")
print("  最终工作流: %s (节点数 %d)" % (OUT, len(wf)))
print("  依赖齐全，可 POST /prompt 出片。")
