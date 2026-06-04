"""
/api/download  — Vercel Serverless Function

NOTE: On Vercel, functions are stateless and short-lived, so we cannot
run background threads or store job state between requests.

This function downloads the video SYNCHRONOUSLY and returns the file
directly in the response (streaming download). This works within
Vercel's 60-second timeout (Pro plan) for short/medium videos.

For very large videos, use a dedicated backend (Railway / Render).
"""

import sys
import json
import uuid
import subprocess
import tempfile
import os
from pathlib import Path
from http.server import BaseHTTPRequestHandler

sys.path.insert(0, "/var/task/api")
from _utils import detect_platform, build_cmd


class handler(BaseHTTPRequestHandler):

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors_headers()
        self.end_headers()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        try:
            data = json.loads(body)
        except Exception:
            data = {}

        url     = (data.get("url") or "").strip()
        quality = data.get("quality", "best")
        fmt     = data.get("format", "mp4")

        if not url:
            self._json(400, {"error": "No URL provided"})
            return

        # Use /tmp — the only writable directory in Vercel serverless
        job_id  = str(uuid.uuid4())
        out_dir = Path(tempfile.gettempdir()) / job_id
        out_dir.mkdir(parents=True, exist_ok=True)

        output_template = str(out_dir / "%(title)s.%(ext)s")
        cmd = build_cmd(url, quality, fmt, output_template)

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=55)

            if result.returncode != 0:
                lines = [l.strip() for l in (result.stderr or result.stdout).splitlines() if l.strip()]
                self._json(400, {"error": lines[-1] if lines else "Download failed"})
                return

            files = list(out_dir.glob("*"))
            if not files:
                self._json(500, {"error": "No file was downloaded"})
                return

            downloaded = max(files, key=lambda f: f.stat().st_size)
            file_bytes = downloaded.read_bytes()

            # Detect MIME type
            ext = downloaded.suffix.lower()
            mime = "audio/mpeg" if ext == ".mp3" else "video/mp4"

            self.send_response(200)
            self._cors_headers()
            self.send_header("Content-Type", mime)
            self.send_header("Content-Length", str(len(file_bytes)))
            self.send_header(
                "Content-Disposition",
                f'attachment; filename="{downloaded.name}"'
            )
            self.end_headers()
            self.wfile.write(file_bytes)

        except subprocess.TimeoutExpired:
            self._json(408, {"error": "Download timed out. Try a shorter video or use a dedicated backend."})
        except FileNotFoundError:
            self._json(500, {"error": "yt-dlp not installed"})
        except Exception as e:
            self._json(500, {"error": str(e)})
        finally:
            # Cleanup /tmp
            try:
                import shutil
                shutil.rmtree(str(out_dir), ignore_errors=True)
            except Exception:
                pass

    def _cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _json(self, code: int, payload: dict):
        body = json.dumps(payload).encode()
        self.send_response(code)
        self._cors_headers()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass
