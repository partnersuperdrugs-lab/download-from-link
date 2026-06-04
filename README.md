# Video Downloader — Vercel Deployment Guide

## What Changed from Original app.py

| Original (Flask)                  | Vercel Version                        |
|-----------------------------------|---------------------------------------|
| Background threads + job queue    | Synchronous download in one request   |
| In-memory `jobs` dict             | Stateless (no shared memory needed)   |
| `/api/download` → returns job_id  | `/api/download` → returns file directly |
| `/api/status/<id>` → poll status  | Not needed (stub kept for compat)     |
| `/api/file/<id>` → fetch file     | Not needed (file returned directly)   |
| Runs on `localhost:5000`          | Runs on Vercel edge                   |

---

## File Structure

```
your-project/
├── vercel.json          ← Vercel routing config
├── requirements.txt     ← Python dependencies
├── index.html           ← Your existing frontend (unchanged)
└── api/
    ├── _utils.py        ← Shared platform detection + yt-dlp command builder
    ├── info.py          ← POST /api/info
    ├── download.py      ← POST /api/download  ← MAIN ENDPOINT
    ├── status/
    │   └── [job_id].py  ← GET /api/status/:id (compatibility stub)
    └── file/
        └── [job_id].py  ← GET /api/file/:id (compatibility stub)
```

---

## Deploy Steps

### 1. Install Vercel CLI
```bash
npm install -g vercel
```

### 2. Copy these files into your project root
Place all files above alongside your `index.html`.

### 3. Deploy
```bash
vercel
```
Follow the prompts. On first deploy it asks for project name and region.

### 4. Update your frontend
Change your frontend API URL from:
```js
const API_BASE = "http://localhost:5000";
```
to:
```js
const API_BASE = "";  // empty = same domain (Vercel handles routing)
```

---

## ⚠️ Important Limitations on Vercel

### Timeout
- **Free plan:** 10 seconds max → only very short videos will work
- **Pro plan:** 60 seconds max → works for most TikTok/Shorts/Reels
- **Hobby plan:** 15 seconds

### Recommendation for Large Videos
For YouTube videos or anything over a few minutes, deploy the backend to:
- [Railway.app](https://railway.app) — easiest, free tier available
- [Render.com](https://render.com) — free tier, sleeps after inactivity
- [Fly.io](https://fly.io) — free tier with Docker support

Then set `API_BASE` in your frontend to the Railway/Render URL.

---

## Frontend Changes Needed

Find where your frontend calls `http://localhost:5000` and update:

### Old flow (3 steps):
```js
// 1. Start download
const { job_id } = await fetch('/api/download', { method: 'POST', body: JSON.stringify({url}) }).then(r => r.json());

// 2. Poll status
const status = await fetch(`/api/status/${job_id}`).then(r => r.json());

// 3. Fetch file
window.location.href = `/api/file/${job_id}`;
```

### New flow (1 step):
```js
// Download and receive file directly
const response = await fetch('/api/download', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ url, quality, format })
});

if (!response.ok) {
  const err = await response.json();
  console.error(err.error);
  return;
}

// Trigger browser download
const blob = await response.blob();
const a = document.createElement('a');
a.href = URL.createObjectURL(blob);
a.download = response.headers.get('Content-Disposition')?.split('filename=')[1]?.replace(/"/g, '') || 'video.mp4';
a.click();
```
