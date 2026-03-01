#!/usr/bin/env python3
"""Google Drive file download with Google Workspace export support.

Usage:
    python3 gdrive_download.py <file_id> <output_path>

Behavior:
    - Google Docs/Sheets/Slides: exports as PDF via files.export
    - Binary files (PDF, images, etc): downloads via files.get alt=media

Token management:
    Reads from ~/.claude/gdrive_token.json
    Auto-refreshes using /tmp/gdrive_config.json credentials
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

TOKEN_PATH = Path.home() / ".claude" / "gdrive_token.json"
CONFIG_PATH = Path("/tmp") / "gdrive_config.json"
DRIVE_API = "https://www.googleapis.com/drive/v3/files"
QUOTA_PROJECT = "riko-assistant"

# Google Workspace MIME types that need export (all export to PDF)
EXPORT_MIME_TYPES: dict[str, str] = {
    "application/vnd.google-apps.document": "application/pdf",
    "application/vnd.google-apps.spreadsheet": "application/pdf",
    "application/vnd.google-apps.presentation": "application/pdf",
    "application/vnd.google-apps.drawing": "application/pdf",
}


def load_token() -> dict[str, Any]:
    """Load token data from disk."""
    if not TOKEN_PATH.exists():
        print(f"Error: Token file not found at {TOKEN_PATH}", file=sys.stderr)
        sys.exit(1)
    with open(TOKEN_PATH) as f:
        return json.load(f)


def save_token(token_data: dict[str, Any]) -> None:
    """Persist updated token data to disk."""
    with open(TOKEN_PATH, "w") as f:
        json.dump(token_data, f, indent=2)


def refresh_access_token(token_data: dict[str, Any]) -> str:
    """Refresh the access token using the refresh token."""
    refresh_token = token_data.get("refresh_token")
    if not refresh_token:
        print("Error: No refresh_token available. Re-authenticate.", file=sys.stderr)
        sys.exit(1)

    client_id = token_data.get("client_id", "")
    client_secret = token_data.get("client_secret", "")
    token_uri = token_data.get("token_uri", "https://oauth2.googleapis.com/token")

    if CONFIG_PATH.exists():
        with open(CONFIG_PATH) as f:
            config = json.load(f)
        installed = config.get("installed", {})
        client_id = installed.get("client_id", client_id)
        client_secret = installed.get("client_secret", client_secret)
        token_uri = installed.get("token_uri", token_uri)

    if not client_id or not client_secret:
        print("Error: Missing client_id/client_secret for token refresh.", file=sys.stderr)
        sys.exit(1)

    payload = urllib.parse.urlencode({
        "client_id": client_id,
        "client_secret": client_secret,
        "refresh_token": refresh_token,
        "grant_type": "refresh_token",
    }).encode()

    req = urllib.request.Request(token_uri, data=payload, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")

    try:
        with urllib.request.urlopen(req) as resp:
            result: dict[str, Any] = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"Error: Token refresh failed ({e.code}): {body}", file=sys.stderr)
        sys.exit(1)

    new_token: str = result["access_token"]
    token_data["token"] = new_token
    if "refresh_token" in result:
        token_data["refresh_token"] = result["refresh_token"]
    save_token(token_data)
    return new_token


def get_access_token(token_data: dict[str, Any]) -> str:
    """Get a valid access token, refreshing if needed."""
    return token_data.get("token", "") or refresh_access_token(token_data)


def get_file_metadata(file_id: str, token: str, token_data: dict[str, Any]) -> dict[str, Any]:
    """Fetch file metadata to determine MIME type."""
    params = urllib.parse.urlencode({
        "fields": "id,name,mimeType,size",
        "supportsAllDrives": "true",
    })
    url = f"{DRIVE_API}/{file_id}?{params}"

    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("X-Goog-User-Project", QUOTA_PROJECT)

    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        if e.code == 401:
            new_token = refresh_access_token(token_data)
            req2 = urllib.request.Request(url)
            req2.add_header("Authorization", f"Bearer {new_token}")
            req2.add_header("X-Goog-User-Project", QUOTA_PROJECT)
            try:
                with urllib.request.urlopen(req2) as resp2:
                    return json.loads(resp2.read())
            except urllib.error.HTTPError as e2:
                body = e2.read().decode()
                print(f"Error: Metadata fetch failed ({e2.code}): {body}", file=sys.stderr)
                sys.exit(1)
        else:
            body = e.read().decode()
            print(f"Error: Metadata fetch failed ({e.code}): {body}", file=sys.stderr)
            sys.exit(1)


def download_binary(file_id: str, token: str, token_data: dict[str, Any], output_path: Path) -> None:
    """Download a binary file using alt=media."""
    params = urllib.parse.urlencode({
        "alt": "media",
        "supportsAllDrives": "true",
    })
    url = f"{DRIVE_API}/{file_id}?{params}"
    _download(url, token, token_data, output_path)


def export_file(file_id: str, export_mime: str, token: str, token_data: dict[str, Any], output_path: Path) -> None:
    """Export a Google Workspace file to the specified MIME type."""
    params = urllib.parse.urlencode({"mimeType": export_mime})
    url = f"{DRIVE_API}/{file_id}/export?{params}"
    _download(url, token, token_data, output_path)


def _download(url: str, token: str, token_data: dict[str, Any], output_path: Path) -> None:
    """Perform the actual download with auto-retry on 401."""
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("X-Goog-User-Project", QUOTA_PROJECT)

    try:
        with urllib.request.urlopen(req) as resp:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            with open(output_path, "wb") as f:
                while True:
                    chunk = resp.read(8192)
                    if not chunk:
                        break
                    f.write(chunk)
    except urllib.error.HTTPError as e:
        if e.code == 401:
            new_token = refresh_access_token(token_data)
            req2 = urllib.request.Request(url)
            req2.add_header("Authorization", f"Bearer {new_token}")
            req2.add_header("X-Goog-User-Project", QUOTA_PROJECT)
            try:
                with urllib.request.urlopen(req2) as resp2:
                    output_path.parent.mkdir(parents=True, exist_ok=True)
                    with open(output_path, "wb") as f:
                        while True:
                            chunk = resp2.read(8192)
                            if not chunk:
                                break
                            f.write(chunk)
            except urllib.error.HTTPError as e2:
                body = e2.read().decode()
                print(f"Error: Download failed after refresh ({e2.code}): {body}", file=sys.stderr)
                sys.exit(1)
        else:
            body = e.read().decode()
            print(f"Error: Download failed ({e.code}): {body}", file=sys.stderr)
            sys.exit(1)


def main() -> None:
    if len(sys.argv) != 3:
        print("Usage: python3 gdrive_download.py <file_id> <output_path>", file=sys.stderr)
        sys.exit(1)

    file_id = sys.argv[1]
    output_path = Path(sys.argv[2])

    token_data = load_token()
    token = get_access_token(token_data)

    metadata = get_file_metadata(file_id, token, token_data)
    mime_type: str = metadata.get("mimeType", "")
    file_name: str = metadata.get("name", file_id)

    # Re-read token in case it was refreshed during metadata fetch
    token_data = load_token()
    token = get_access_token(token_data)

    export_mime = EXPORT_MIME_TYPES.get(mime_type)
    if export_mime:
        # Google Workspace file - export as PDF
        if not output_path.suffix:
            output_path = output_path.with_suffix(".pdf")
        export_file(file_id, export_mime, token, token_data, output_path)
        print(json.dumps({
            "status": "ok",
            "file_id": file_id,
            "name": file_name,
            "mime_type": mime_type,
            "exported_as": export_mime,
            "output": str(output_path),
        }, ensure_ascii=False))
    else:
        # Binary file - direct download
        download_binary(file_id, token, token_data, output_path)
        print(json.dumps({
            "status": "ok",
            "file_id": file_id,
            "name": file_name,
            "mime_type": mime_type,
            "output": str(output_path),
        }, ensure_ascii=False))


if __name__ == "__main__":
    main()
