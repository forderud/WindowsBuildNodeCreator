# pip install requests
# pip install truststore

import os
import sys

try:
    import truststore
    truststore.inject_into_ssl() # inject root certificates
except ImportError:
    print("WARNING: truststore not found. Might experience certificate errors.")

import requests


def BoxJwtAuthenticate():
    # DOC: https://developer.box.com/guides/authentication/jwt/without-sdk
    import json
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives.serialization import load_pem_private_key

    # JSON file from "Generate a Public/Private Keypair" in the Box app configuration on https://ge.ent.box.com/developers/console
    with open(os.environ["USERPROFILE"]+"\\box_settings.json", "r") as f:
        config = json.load(f)

    # Decrypt private key
    appAuth = config["boxAppSettings"]["appAuth"]
    key = load_pem_private_key(
        data=appAuth["privateKey"].encode("utf8"),
        password=appAuth["passphrase"].encode("utf8"),
        backend=default_backend(),
    )

    import secrets
    import time
    import jwt
    # Create JWT assertion
    claims = {
        'iss': config['boxAppSettings']['clientID'],
        'sub': config['enterpriseID'],
        'box_sub_type': 'enterprise',
        'aud': 'https://api.box.com/oauth2/token',
        'jti': secrets.token_hex(64),
        'exp': round(time.time()) + 45
    }
    assertion = jwt.encode(
        claims,
        key,
        algorithm='RS512',
        headers={
            'kid': appAuth['publicKeyID']
        }
    )

    # Request Access Token
    params = {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': assertion,
        'client_id': config['boxAppSettings']['clientID'],
        'client_secret': config['boxAppSettings']['clientSecret']
    }
    response = requests.post("https://api.box.com/oauth2/token", params)
    if response.status_code != 200:
        raise RuntimeError("JWT ERROR: "+response.text)
    access_token = response.json()["access_token"]
    return access_token


def BoxDownload (file_id, dest_file_path):
    access_token = BoxJwtAuthenticate()

    # Download file to desired path
    # DOC: https://developer.box.com/guides/downloads/file
    headers = {
        "Authorization": f"Bearer "+access_token,
    }
    with requests.get(f"https://api.box.com/2.0/files/{file_id}/content", headers=headers, stream=True) as r:
        r.raise_for_status() # Raise an exception for bad status codes (4xx or 5xx)
        # Open a local file in binary write mode ('wb') and copy the streamed content
        with open(dest_file_path, 'wb') as fd:
            for chunk in r.iter_content(chunk_size=1024*1024): # 1MB chunk size
                fd.write(chunk)

    print(f"File '{dest_file_path}' downloaded successfully.")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("ERROR: Usage BoxDownload.py <box-file-id> <dest-file-path>")
        sys.exit(1)

    BoxDownload(sys.argv[1], sys.argv[2])
