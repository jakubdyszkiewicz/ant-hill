import base64
import datetime
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

KEY = Path('/run/secrets/private-key.pem')
OUTPUT = Path('/output/token')


def b64(data):
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('ascii')


def jwt(app_id, now):
    header = b64(b'{"alg":"RS256","typ":"JWT"}')
    payload = b64(json.dumps({'iat': now - 60, 'exp': now + 540, 'iss': app_id}, separators=(',', ':')).encode())
    message = f'{header}.{payload}'.encode()
    signature = subprocess.run(['openssl', 'dgst', '-sha256', '-sign', str(KEY)], input=message, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True).stdout
    return f'{header}.{payload}.{b64(signature)}'


def refresh(app_id, installation_id):
    signed = jwt(app_id, int(time.time()))
    req = urllib.request.Request(
        f'https://api.github.com/app/installations/{installation_id}/access_tokens',
        data=b'{}', method='POST', headers={
            'Authorization': f'Bearer {signed}', 'Accept': 'application/vnd.github+json',
            'Content-Type': 'application/json', 'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'isodev-github-app-token-refresher',
        })
    with urllib.request.urlopen(req, timeout=30) as response:
        result = json.load(response)
    token = result['token']
    expires = datetime.datetime.fromisoformat(result['expires_at'].replace('Z', '+00:00')).timestamp()
    if not isinstance(token, str) or not token or '\n' in token or expires <= time.time() + 60:
        raise ValueError('GitHub returned an invalid or nearly expired token')
    fd, temporary = tempfile.mkstemp(prefix='.token-', dir=OUTPUT.parent)
    try:
        with os.fdopen(fd, 'w') as f:
            f.write(token + '\n')
        os.replace(temporary, OUTPUT)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    return expires


def main():
    app_id = os.environ.get('GITHUB_APP_ID', '')
    installation_id = os.environ.get('GITHUB_INSTALLATION_ID', '')
    if not app_id.isdecimal() or not installation_id.isdecimal():
        sys.exit('Set numeric GITHUB_APP_ID and GITHUB_INSTALLATION_ID in github-app-token/config.env')
    while True:
        try:
            expires = refresh(app_id, installation_id)
            print('Token refreshed; expires at ' + datetime.datetime.fromtimestamp(expires, datetime.timezone.utc).isoformat(), flush=True)
            time.sleep(max(10, expires - time.time() - 300))
        except (OSError, ValueError, KeyError, subprocess.CalledProcessError, urllib.error.URLError) as e:
            # Do not print API response bodies or credentials.
            print(f'Token refresh failed ({type(e).__name__}); retrying in 60 seconds', file=sys.stderr, flush=True)
            time.sleep(60)


if __name__ == '__main__':
    main()
