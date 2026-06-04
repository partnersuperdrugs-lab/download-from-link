"""
Shared utilities for all Vercel API functions.
"""

import sys
import json
import subprocess


def detect_platform(url: str) -> str:
    url_lower = url.lower()
    if any(x in url_lower for x in ['tiktok.com', 'vm.tiktok.com', 'vt.tiktok.com']):
        return 'tiktok'
    if any(x in url_lower for x in ['instagram.com', 'instagr.am']):
        return 'instagram'
    if any(x in url_lower for x in ['youtube.com/shorts', 'youtu.be']) or \
       ('youtube.com' in url_lower and 'shorts' in url_lower):
        return 'yt_shorts'
    if 'youtube.com' in url_lower or 'youtu.be' in url_lower:
        return 'youtube'
    return 'generic'


def build_cmd(url: str, quality: str, fmt: str, output_template: str) -> list:
    platform = detect_platform(url)
    base = [
        sys.executable, "-m", "yt_dlp",
        "--output", output_template,
        "--no-playlist",
        "--socket-timeout", "30",
        "--retries", "3",
        "--fragment-retries", "3",
    ]

    if fmt == "mp3":
        return base + [
            "--format", "bestaudio/best",
            "--extract-audio",
            "--audio-format", "mp3",
            "--audio-quality", "0",
            url
        ]

    if platform == 'tiktok':
        return base + [
            "--format", "download_addr-0/bestvideo[height>=1080]+bestaudio/bestvideo+bestaudio/best",
            "--merge-output-format", "mp4",
            "--add-header", "Referer:https://www.tiktok.com/",
            "--add-header", "User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            url
        ]

    if platform == 'instagram':
        return base + [
            "--format", "bestvideo[height>=1080]+bestaudio/bestvideo+bestaudio/best",
            "--merge-output-format", "mp4",
            "--add-header", "User-Agent:Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15",
            "--add-header", "Referer:https://www.instagram.com/",
            url
        ]

    if platform == 'yt_shorts':
        return base + [
            "--format", "bestvideo[height>=1080][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height>=720]+bestaudio/best",
            "--merge-output-format", "mp4",
            url
        ]

    if platform == 'youtube':
        if quality == '1080':
            fmt_str = "bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=1080]+bestaudio/best"
        elif quality == '720':
            fmt_str = "bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/best[height<=720]"
        elif quality == '480':
            fmt_str = "bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]/best[height<=480]"
        else:
            fmt_str = "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best"
        return base + ["--format", fmt_str, "--merge-output-format", "mp4", url]

    # Generic fallback
    if quality == '1080':
        fmt_str = "bestvideo[height<=1080]+bestaudio/best"
    elif quality == '720':
        fmt_str = "bestvideo[height<=720]+bestaudio/best"
    elif quality == '480':
        fmt_str = "bestvideo[height<=480]+bestaudio/best"
    else:
        fmt_str = "bestvideo+bestaudio/best"

    return base + ["--format", fmt_str, "--merge-output-format", "mp4", url]
