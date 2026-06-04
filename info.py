"""
/api/info  — Vercel Serverless Function
Returns metadata for a given video URL using yt-dlp.
"""

import sys
import json
import subprocess
from http.server import BaseHTTPRequestHandler

# Add parent dir so _utils is importable
sys.path.insert(0, "/var/task/api")
from _utils import detect_platform


class handler(BaseHTTPRequestHandler):

    def do_OPTIONS(self):
        """Handle CORS preflight."""
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

        url = (data.get("url") or "").strip()
        if not url:
            self._json(400, {"error": "No URL provided"})
            return

        platform = detect_platform(url)

        extra = []
        if platform == 'tiktok':
            extra = ["--add-header", "Referer:https://www.tiktok.com/"]
        elif platform == 'instagram':
            extra = ["--add-header", "User-Agent:Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)"]

        try:
            result = subprocess.run(
                [
                    sys.executable, "-m", "yt_dlp",
                    "--dump-json", "--no-playlist",
                    "--socket-timeout", "15",
                    *extra,
                    url
                ],
                capture_output=True, text=True, timeout=28
            )

            if result.returncode != 0:
                lines = [l.strip() for l in (result.stderr or result.stdout).splitlines() if l.strip()]
                self._json(400, {"error": lines[-1] if lines else "Could not fetch video info"})
                return

            info = json.loads(result.stdout.splitlines()[0])

            formats = info.get("formats", [])
            max_height = max((f.get("height") or 0 for f in formats), default=0)

            self._json(200, {
                "title":        info.get("title", "Unknown"),
                "thumbnail":    info.get("thumbnail", ""),
                "duration":     info.get("duration_string") or str(info.get("duration", "")),
                "uploader":     info.get("uploader") or info.get("channel", ""),
                "view_count":   info.get("view_count", 0),
                "like_count":   info.get("like_count", 0),
                "website":      info.get("extractor_key", ""),
                "platform":     platform,
                "max_height":   max_height,
                "no_watermark": platform in ("tiktok", "instagram"),
            })

        except subprocess.TimeoutExpired:
            self._json(408, {"error": "Timed out fetching video info"})
        except FileNotFoundError:
            self._json(500, {"error": "yt-dlp not installed"})
        except Exception as e:
            self._json(500, {"error": str(e)})

    # ── helpers ─────────────────────────────────────────────────────────

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
        pass  # silence default HTTP logging
