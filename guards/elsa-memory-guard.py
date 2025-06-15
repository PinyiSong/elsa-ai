#!/usr/bin/env python3
import os, time, subprocess

MEMORY_JSONL = "/home/ollama/elsa_core/memory/memory.jsonl"
MEMORY_THOUGHTS = "/home/ollama/elsa_core/memory/memory_thoughts.jsonl"
LINK_TARGET_1 = "/mnt/S15T/brain/memory.jsonl"
LINK_TARGET_2 = "/mnt/S15T/brain/memory_thoughts.jsonl"

def is_link_ok(path, target):
    return os.path.islink(path) and os.readlink(path) == target

def is_loop_running():
    try:
        out = subprocess.check_output("pm2 ls | grep elsa-loop | grep online", shell=True)
        return b"online" in out
    except:
        return False

def fix_memory_links():
    print("🧠 掛載 Elsa 記憶連結...")
    os.system(f"ln -sf {LINK_TARGET_1} {MEMORY_JSONL}")
    os.system(f"ln -sf {LINK_TARGET_2} {MEMORY_THOUGHTS}")

def fix_loop():
    print("🔁 重啟 elsa-loop 模組...")
    os.system("pm2 restart elsa-loop")

print("🛡️ Elsa 記憶守護模組已啟動...")

while True:
    try:
        if not is_link_ok(MEMORY_JSONL, LINK_TARGET_1) or not is_link_ok(MEMORY_THOUGHTS, LINK_TARGET_2):
            print("⚠️ 記憶掛載異常，自動修復...")
            fix_memory_links()

        if not is_loop_running():
            print("⚠️ loop 模組未運作，自動重啟...")
            fix_loop()
    except Exception as e:
        print("❌ 例外錯誤:", str(e))
    
    time.sleep(5)
