#!/usr/bin/env bash
# =============================================================
#  build_u30_clean.sh — 干净重建版 U30 一键搭建（AutoDL 实例上执行）
# -------------------------------------------------------------
#  目标: 基于官方 ComfyUI + MiniMax H3 开源权重，重建 U30
#        参考生视频工作流，不含任何 zealman 私有内容，可公开发布。
#  用法: bash build_u30_clean.sh
#  前置: 新实例(建议 32G 以上显存)；系统盘 30GB 即可(镜像瘦身)，
#        数据盘需 ≥ 80GB(模型约 53GB 放数据盘)。
#  说明: 数据盘路径 /root/autodl-tmp (AutoDL 标准挂载)；
#        发布镜像只含系统盘(ComfyUI+插件+仓库≈6GB)，
#        开机自启 /root/autodl-init.sh 会在新实例首次开机时
#        自动把模型下载到数据盘(20-40 分钟)。
# =============================================================
set -e
# AutoDL 网络加速（若镜像存在则启用，加速 GitHub/pip/hf 下载）
[ -f /etc/network_turbo ] && source /etc/network_turbo 2>/dev/null || true
export HF_ENDPOINT=${HF_ENDPOINT:-https://hf-mirror.com}   # 国内镜像，可改官方 https://huggingface.co
export PIP_INDEX_URL=${PIP_INDEX_URL:-https://pypi.tuna.tsinghua.edu.cn/simple}

say() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$1"; }

CU=/root/ComfyUI
REPO=/root/DS-U.3
M=/root/autodl-tmp/u30_models   # 数据盘模型根目录（镜像不含，开机自启补齐）

say "== 0. 环境检查 =="
nvidia-smi -L || { say "!! 无 GPU，检查实例配置"; exit 1; }
df -h / | tail -1
df -h /root/autodl-tmp 2>/dev/null | tail -1 || say "!! 未发现数据盘挂载(/root/autodl-tmp)，请在控制台确认"
python3 --version
git --version || { apt-get update -y && apt-get install -y git; }

say "== 1. 克隆官方 ComfyUI =="
if [ ! -d "$CU/.git" ]; then
  git clone --depth 1 https://github.com/Comfy-Org/ComfyUI.git "$CU"
  pip install -r "$CU/requirements.txt" -q || pip install -r "$CU/requirements.txt"
else
  say "ComfyUI 已存在，跳过"
fi

say "== 2. 安装插件 =="
cd "$CU/custom_nodes"
for repo in \
  "https://github.com/ltdrdata/ComfyUI-Manager.git" \
  "https://github.com/kijai/ComfyUI-KJNodes.git" \
  "https://github.com/yolain/ComfyUI-Easy-Use.git" \
  "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git" \
  "https://github.com/LBH-123-AI/Comfyui_Minimax_h3_latent_Upscaler.git" \
  "https://github.com/LAOGOU-666/Comfyui-Memory_Cleanup.git"; do
  name=$(basename "$repo" .git)
  [ -d "$name" ] || { git clone --depth 1 "$repo" || say "!! 克隆失败: $name (可手动重试)"; }
done
# 语义桥(可选增强，装不上不影响出片)
[ -d "MiniMax-H3-Semantic-Bridge" ] || \
  git clone --depth 1 "https://github.com/Speach1sdef178/MiniMax-H3-Semantic-Bridge.git" 2>/dev/null || true

say "== 3. 配置模型目录(数据盘) + extra_model_paths =="
mkdir -p "$M"/{diffusion_models,text_encoders,vae,loras,minimax_h3_latent_upscaler}
cat > "$CU/extra_model_paths.yaml" <<EOF
u30_models:
    base_path: $M
    diffusion_models: diffusion_models
    text_encoders: text_encoders
    vae: vae
    loras: loras
    minimax_h3_latent_upscaler: minimax_h3_latent_upscaler
EOF
say "模型根目录: $M (extra_model_paths.yaml 已写入 $CU)"

say "== 4. 下载模型 (~53GB，走 hf-mirror) =="
cd /root
pip install -q huggingface_hub 2>/dev/null || true
dl() { # $1 repo $2 远端路径 $3 本地目标
  local l="$3"; [ -f "$l" ] && { say "已有 $l"; return; }
  say "下载 $2 -> $3"
  python3 - <<PY
from huggingface_hub import hf_hub_download
hf_hub_download("$1", "$2", local_dir="/root", local_dir_use_symlinks=False)
PY
  [ -f "/root/$2" ] && mv -f "/root/$2" "$3"
}
dl "Comfy-Org/MiniMax-H3" "diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors" "$M/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors"
dl "Comfy-Org/MiniMax-H3" "text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors" "$M/text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors"
dl "Comfy-Org/MiniMax-H3" "vae/minimax_h3_video_vae_int8_convrot.safetensors" "$M/vae/minimax_h3_video_vae_int8_convrot.safetensors"
dl "Comfy-Org/MiniMax-H3" "vae/minimax_h3_audio_vae_fp32.safetensors" "$M/vae/minimax_h3_audio_vae_fp32.safetensors"
dl "Comfy-Org/MiniMax-H3" "loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors" "$M/loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors"
# latent upscaler 3D 权重(扫描仓库，取含 3d 的 safetensors)
U3D=$(python3 - <<PY
from huggingface_hub import list_repo_files
for f in list_repo_files("LBH-123-AI/Minimax_h3_latent_Upscaler"):
    if "3d" in f.lower() and f.endswith(".safetensors"):
        print(f); break
PY
)
if [ -n "$U3D" ] && [ ! -f "$M/minimax_h3_latent_upscaler/$(basename "$U3D")" ]; then
  say "下载 upscaler: $U3D"
  python3 - <<PY
from huggingface_hub import hf_hub_download
hf_hub_download("LBH-123-AI/Minimax_h3_latent_Upscaler", "$U3D", local_dir="/root", local_dir_use_symlinks=False)
PY
  [ -f "/root/$U3D" ] && mv -f "/root/$U3D" "$M/minimax_h3_latent_upscaler/"
fi

say "== 5. 素材与发布仓库 =="
if [ ! -d "$REPO/.git" ]; then
  git clone https://github.com/jzwjczc-cmd/DS-U.3.git "$REPO"
fi
mkdir -p "$CU/input"
cp -f "$REPO/samples/ref_sample_1.png" "$CU/input/" 2>/dev/null || true
cp -f "$REPO/samples/ref_sample_2.png" "$CU/input/" 2>/dev/null || true
mkdir -p "$CU/user/default/workflows"
cp -f "$REPO/workflows/API-U30-K-clean.json" "$CU/user/default/workflows/" 2>/dev/null || true

say "== 6. 生成开机自启下载脚本(发布镜像用) =="
cat > /root/fetch_models.sh <<EOF
#!/usr/bin/env bash
# 把 53GB 模型下载到数据盘（幂等：已有文件跳过）。日志: /root/model_download.log
set -e
[ -f /etc/network_turbo ] && source /etc/network_turbo 2>/dev/null || true
export HF_ENDPOINT=${HF_ENDPOINT:-https://hf-mirror.com}
M=$M
mkdir -p \$M/{diffusion_models,text_encoders,vae,loras,minimax_h3_latent_upscaler}
pip install -q huggingface_hub 2>/dev/null || true
dl() { local l="\$2"; [ -f "\$l" ] && { echo "已有 \$l"; return; }; echo "下载 \$1 -> \$l"; python3 -c "
from huggingface_hub import hf_hub_download
hf_hub_download('\$1', '\$2', local_dir='/root', local_dir_use_symlinks=False)
"; [ -f "\$2" ] && mv -f "\$2" "\$l"; }
dl Comfy-Org/MiniMax-H3 diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors \$M/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors
dl Comfy-Org/MiniMax-H3 text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors \$M/text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors
dl Comfy-Org/MiniMax-H3 vae/minimax_h3_video_vae_int8_convrot.safetensors \$M/vae/minimax_h3_video_vae_int8_convrot.safetensors
dl Comfy-Org/MiniMax-H3 vae/minimax_h3_audio_vae_fp32.safetensors \$M/vae/minimax_h3_audio_vae_fp32.safetensors
dl Comfy-Org/MiniMax-H3 loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors \$M/loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors
echo "模型就绪: \$(du -sh \$M 2>/dev/null | cut -f1)"
EOF
chmod +x /root/fetch_models.sh

cat > /root/autodl-init.sh <<EOF
#!/usr/bin/env bash
# AutoDL 开机自动执行：模型缺失时后台下载到数据盘（已存在则跳过）
[ -f /etc/network_turbo ] && source /etc/network_turbo 2>/dev/null || true
M=$M
if [ -f "\$M/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors" ] && [ -f "\$M/text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors" ]; then
  echo "[autodl-init] 模型已就绪，跳过下载" >> /root/model_download.log
  exit 0
fi
nohup bash /root/fetch_models.sh >> /root/model_download.log 2>&1 &
echo "[autodl-init] 模型后台下载已启动，日志 /root/model_download.log" >> /root/model_download.log
EOF
chmod +x /root/autodl-init.sh
say "已生成 /root/autodl-init.sh(开机自启) + /root/fetch_models.sh(下载)"

say "== 7. 启动 ComfyUI 并自检 =="
cd "$CU"
nohup python3 main.py --listen 0.0.0.0 --port 8188 > /root/comfy.log 2>&1 &
for i in $(seq 1 60); do
  curl -sf "http://127.0.0.1:8188/system_stats" >/dev/null && break
  sleep 3
done
curl -sf "http://127.0.0.1:8188/object_info" -o /root/object_info.json || { say "!! ComfyUI 未启动，看 /root/comfy.log"; tail -20 /root/comfy.log; exit 1; }
cp -f "$REPO/workflows/API-U30-K-clean.json" /root/
python3 /root/DS-U.3/scripts/verify_clean.py /root/object_info.json /root/API-U30-K-clean.json /root/API-U30-K-clean-final.json

say "== 8. 出片自测 =="
python3 - <<PY
import json, urllib.request, time
wf = json.load(open("/root/API-U30-K-clean-final.json"))
req = urllib.request.Request("http://127.0.0.1:8188/prompt",
                             data=json.dumps({"prompt": wf}).encode(),
                             headers={"Content-Type": "application/json"})
r = json.loads(urllib.request.urlopen(req, timeout=60).read())
if r.get("node_errors"):
    print("!! node_errors:", r["node_errors"]); raise SystemExit(1)
pid = r["prompt_id"]; print("已提交 prompt_id:", pid)
for _ in range(240):
    time.sleep(5)
    h = json.loads(urllib.request.urlopen("http://127.0.0.1:8188/history/%s" % pid).read())
    if pid in h and h[pid].get("status", {}).get("completed"):
        print("出片成功:", list(h[pid]["outputs"].keys())); break
else:
    print("!! 超时未完成，检查 /root/comfy.log")
PY

say "== 完成 =="
say "面板: 浏览器开 http://<实例地址>:8188  导入 workflows/API-U30-K-clean-final.json 即可使用"
say "发布准备: 关机 -> 控制台保存镜像(瘦身版，不含模型) -> AutoDL Art 发布；新实例首次开机自动下载模型"
