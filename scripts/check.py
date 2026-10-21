#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
U30 (MiniMax-H3 Ref2VA) 发布镜像环境自检脚本
=============================================
AutoDL Art 审核标准要求：镜像内 /root 包含 GitHub 仓库，且可成功执行仓库中的简单代码。
本脚本即"简单代码"：零第三方依赖，验证工作流 JSON 完整性 + 报告运行环境。

用法:  python3 check.py
"""
import json
import os
import platform
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORKFLOW = os.path.join(ROOT, "workflows", "API-U30-K.json")


def section(title: str) -> None:
    print("\n== %s ==" % title)


def main() -> int:
    section("环境信息")
    print("Python    :", platform.python_version())
    print("Platform  :", platform.platform())

    # GPU
    nvidia = shutil.which("nvidia-smi")
    if nvidia:
        try:
            out = subprocess.run([nvidia, "--query-gpu=name,memory.total",
                                  "--format=csv,noheader"], capture_output=True,
                                 text=True, timeout=20)
            print("GPU       :", out.stdout.strip() or "n/a")
        except Exception as e:
            print("GPU       : 查询失败 (%s)" % e)
    else:
        print("GPU       : 未找到 nvidia-smi")

    # ComfyUI
    for cand in ["/root/ComfyUI", "/root/zealman-app/comfyui-versions/packages"]:
        if os.path.isdir(cand):
            print("ComfyUI   : %s 存在" % cand)
    # 面板
    for cand in ["/root/zealman-app", "/root/comfyui-control-panel"]:
        if os.path.isdir(cand):
            print("Panel     : %s 存在" % cand)

    section("工作流校验")
    if not os.path.exists(WORKFLOW):
        print("FAIL: 找不到 %s" % WORKFLOW)
        return 1
    with open(WORKFLOW, "r", encoding="utf-8") as f:
        wf = json.load(f)

    ids = set(wf.keys())
    if not ids or not all(str(i).isdigit() for i in ids):
        print("FAIL: 工作流顶层不是节点 ID 字典")
        return 1

    dangling = []
    classes = set()
    for nid, node in wf.items():
        classes.add(node.get("class_type", "?"))
        for k, v in node.get("inputs", {}).items():
            if isinstance(v, list) and v and isinstance(v[0], str) and v[0] not in ids:
                dangling.append((nid, k, v[0]))

    print("OK   : 节点数 = %d" % len(ids))
    print("OK   : class_type 数 = %d" % len(classes))
    if dangling:
        print("WARN : 断链 %d 处 -> %s" % (len(dangling), dangling[:5]))
    else:
        print("OK   : 无断链")

    required = {"MiniMaxH3ReferenceToVideo", "ZealmanH3PickReferenceMedia",
                "ZealmanH3ModelLoader", "VHS_VideoCombine"}
    have = required & classes
    missing = required - classes
    print("OK   : 核心节点命中 = %s" % sorted(have))
    if missing:
        print("WARN : 缺失节点类型 = %s（需安装对应插件）" % sorted(missing))

    section("结论")
    ok = not dangling and not missing
    print("环境就绪，可发布 ✅" if ok else "存在 WARN，请按提示安装依赖后重试 ⚠️")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
