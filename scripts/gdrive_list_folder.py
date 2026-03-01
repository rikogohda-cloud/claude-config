#!/usr/bin/env python3
"""Google Drive folder listing with recursive support.

Usage:
    python3 gdrive_list_folder.py <folder_id> [--recursive]

Output:
    JSON array of [{id, name, mimeType, size, parents}]

Token management:
    Reads from ~/.claude/gdrive_token.json
    Auto-refreshes using /tmp/gdrive_config.json credentials
"""

from __future__ import annotations

import argparse
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

    # Try config file first, fall back to token_data fields
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


def drive_request(url: str, token: str, token_data: dict[str, Any]) -> dict[str, Any]:
    """Make a Drive API request with auto-retry on 401."""
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("X-Goog-User-Project", QUOTA_PROJECT)

    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        if e.code == 401:
            # Token expired, refresh and retry
            new_token = refresh_access_token(token_data)
            req2 = urllib.request.Request(url)
            req2.add_header("Authorization", f"Bearer {new_token}")
            req2.add_header("X-Goog-User-Project", QUOTA_PROJECT)
            try:
                with urllib.request.urlopen(req2) as resp2:
                    return json.loads(resp2.read())
            except urllib.error.HTTPError as e2:
                body = e2.read().decode()
                print(f"Error: Drive API request failed after refresh ({e2.code}): {body}", file=sys.stderr)
                sys.exit(1)
        else:
            body = e.read().decode()
            print(f"Error: Drive API request failed ({e.code}): {body}", file=sys.stderr)
            sys.exit(1)


def list_folder(
    folder_id: str,
    token: str,
    token_data: dict[str, Any],
    recursive: bool = False,
) -> list[dict[str, Any]]:
    """List files in a Drive folder, optionally recursing into subfolders."""
    results: list[dict[str, Any]] = []
    page_token: str | None = None
    query = f"'{folder_id}' in parents and trashed = false"

    while True:
        params: dict[str, str] = {
            "q": query,
            "fields": "nextPageToken,files(id,name,mimeType,size,parents)",
            "pageSize": "1000",
            "supportsAllDrives": "true",
            "includeItemsFromAllDrives": "true",
        }
        if page_token:
            params["pageToken"] = page_token

        url = f"{DRIVE_API}?{urllib.parse.urlencode(params)}"
        data = drive_request(url, token, token_data)

        files: list[dict[str, Any]] = data.get("files", [])
        for f in files:
            results.append({
                "id": f.get("id", ""),
                "name": f.get("name", ""),
                "mimeType": f.get("mimeType", ""),
                "size": f.get("size", ""),
                "parents": f.get("parents", []),
            })

        page_token = data.get("nextPageToken")
        if not page_token:
            break

    if recursive:
        subfolders = [f for f in results if f["mimeType"] == "application/vnd.google-apps.folder"]
        for sf in subfolders:
            sub_items = list_folder(sf["id"], token, token_data, recursive=True)
            results.extend(sub_items)

    return results


def main() -> None:
    parser = argparse.ArgumentParser(description="List files in a Google Drive folder")
    parser.add_argument("folder_id", help="Google Drive folder ID")
    parser.add_argument("--recursive", action="store_true", help="Recurse into subfolders")
    args = parser.parse_args()

    token_data = load_token()
    token = get_access_token(token_data)
    items = list_folder(args.folder_id, token, token_data, recursive=args.recursive)
    print(json.dumps(items, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
