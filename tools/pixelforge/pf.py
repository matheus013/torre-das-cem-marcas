#!/usr/bin/env python3
"""Gera sprites no PixelForge a partir de art/manifest.json e baixa para art/raw/."""
import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DEFAULT_MANIFEST = os.path.join(ROOT, "art", "manifest.json")
RAW_DIR = os.path.join(ROOT, "art", "raw")


def request(base, method, path, body=None, timeout=30):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(base + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    key = os.environ.get("PIXELFORGE_API_KEY")
    if key:
        req.add_header("X-API-Key", key)
    with urllib.request.urlopen(req, timeout=timeout) as response:
        raw = response.read()
        return json.loads(raw) if raw else None


def find_or_create_asset(base, project_id, entry):
    slug_name = entry["name"]
    for asset in request(base, "GET", f"/api/projects/{project_id}/assets"):
        if asset["name"] == slug_name and asset["asset_type"] == entry["asset_type"]:
            return asset["id"]
    created = request(base, "POST", f"/api/projects/{project_id}/assets", {
        "name": slug_name,
        "asset_type": entry["asset_type"],
        "description": entry.get("description", ""),
        "metadata_json": entry.get("metadata", {}),
        "tags": entry.get("tags", []),
    })
    return created["id"]


def build_prompt(base, manifest, entry):
    if "prompt" in entry:
        prompt = entry["prompt"]
        negative = entry.get("negative_prompt", manifest.get("negative_prompt", ""))
    else:
        preview = request(base, "POST", "/api/prompt-builder/preview", {
            "asset_type": entry["asset_type"],
            "name": entry["name"],
            "description": entry.get("description", ""),
            "metadata_json": entry.get("metadata", {}),
            "style_profile_id": manifest.get("style_profile_id"),
        })
        prompt, negative = preview["prompt"], preview["negative_prompt"]
    prefix = manifest.get("prompt_prefix", "")
    suffix = entry.get("suffix", manifest.get("prompt_suffix", ""))
    prompt = ", ".join(part for part in (prefix, prompt, suffix) if part)
    extra_negative = entry.get("extra_negative", manifest.get("extra_negative", ""))
    negative = ", ".join(part for part in (negative, extra_negative) if part)
    return prompt, negative


def wait_job(base, project_id, asset_id, job_id, limit=600):
    started = time.time()
    while time.time() - started < limit:
        job = request(base, "GET", f"/api/projects/{project_id}/assets/{asset_id}/generation-jobs/{job_id}")
        if job["status"] in ("completed", "failed", "cancelled"):
            return job
        time.sleep(3)
    raise TimeoutError(f"job {job_id} did not finish")


def latest_jobs(base, project_id, asset_id):
    return request(base, "GET", f"/api/projects/{project_id}/assets/{asset_id}/generation-jobs")


def generate(base, manifest, entry, seed, force):
    out_path = os.path.join(RAW_DIR, f"{entry['key']}_s{seed}.png")
    if os.path.exists(out_path) and not force:
        print(f"skip {out_path}")
        return
    project_id = manifest["project_id"]
    asset_id = find_or_create_asset(base, project_id, entry)
    prompt, negative = build_prompt(base, manifest, entry)
    size = entry.get("size", manifest.get("size", 512))
    body = {
        "prompt": prompt,
        "negative_prompt": negative,
        "width": size,
        "height": size,
        "seed": seed,
        "provider": manifest.get("provider", "diffusers"),
    }
    known = {job["id"] for job in latest_jobs(base, project_id, asset_id)}
    job = None
    try:
        job = request(base, "POST", f"/api/projects/{project_id}/assets/{asset_id}/generation-jobs", body, timeout=15)
    except (TimeoutError, urllib.error.URLError):
        pass  # O servidor responde só ao concluir; localizamos o job pela lista.
    if job is None:
        for _ in range(20):
            fresh = [j for j in latest_jobs(base, project_id, asset_id) if j["id"] not in known]
            if fresh:
                job = fresh[0]
                break
            time.sleep(1)
    if job is None:
        raise RuntimeError(f"job for {entry['key']} was not created")
    job = wait_job(base, project_id, asset_id, job["id"])
    if job["status"] != "completed":
        print(f"FAIL {entry['key']} seed {seed}: {job.get('error_message')}")
        return
    versions = request(base, "GET", f"/api/projects/{project_id}/assets/{asset_id}/versions")
    version = next(v for v in versions if v["id"] == job["result_version_id"])
    with urllib.request.urlopen(base + "/files/" + version["file_path"], timeout=60) as response:
        payload = response.read()
    os.makedirs(RAW_DIR, exist_ok=True)
    with open(out_path, "wb") as handle:
        handle.write(payload)
    print(f"ok   {out_path}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("keys", nargs="*", help="chaves do manifesto; vazio gera tudo")
    parser.add_argument("--manifest", default=DEFAULT_MANIFEST)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    with open(args.manifest, encoding="utf-8") as handle:
        manifest = json.load(handle)
    base = os.environ.get("PIXELFORGE_URL", manifest.get("base_url", "http://127.0.0.1:8000")).rstrip("/")
    entries = [e for e in manifest["assets"] if not args.keys or e["key"] in args.keys]
    if not entries:
        sys.exit("nenhuma entrada encontrada")
    for entry in entries:
        for seed in entry.get("seeds", [1]):
            generate(base, manifest, entry, seed, args.force)


if __name__ == "__main__":
    main()
