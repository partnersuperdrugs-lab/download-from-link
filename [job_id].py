"""
/api/status/[job_id]  — Vercel Serverless Function

NOTE: Vercel functions are stateless — there is no shared memory between
invocations. The original job-queue system (in-memory `jobs` dict) does
not work on Vercel.

The new /api/download endpoint is synchronous: it downloads and returns
the file in a single request, so polling /api/status is no longer needed.

This stub is kept for frontend compatibility — it always returns "done"
so any frontend that still polls this route won't break.
"""

import json
from http.server import BaseHTTPRequestHandler


class handler(BaseHTTPRequestHandler):

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors_headers()
        self.end_headers()

    def do_GET(self):
        # Extract job_id from path: /api/status/<job_id>
        parts = self.path.strip("/").split("/")
        job_id = parts[-1] if parts else "unknown"

        # Since downloads are now synchronous, status is always "done"
        # if the job_id is valid (i.e., the download already completed).
        self._json(200, {
            "status":   "done",
            "job_id":   job_id,
            "message":  "Downloads are now synchronous on this deployment. No polling needed."
        })

    def _cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
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
