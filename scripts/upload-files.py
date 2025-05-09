import boto3
from pathlib import Path
from botocore.exceptions import ClientError
import sys

BUCKET_NAME = "secure-static-site-aws"
LOCAL_DIRECTORY = "./website"

s3 = boto3.client("s3")

def get_content_type(file_path):
    content_types = {
        ".html": "text/html",
        ".css": "text/css",
        ".js": "application/javascript",
        ".json": "application/json",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".gif": "image/gif"
    }
    return content_types.get(file_path.suffix.lower(), "application/octet-stream")

def check_permissions():
    try:
        s3.put_object(Bucket=BUCKET_NAME, Key="permission_check.txt", Body=b"test", ACL="private")
        print("Permission check passed: Able to write to the bucket.")

        s3.delete_object(Bucket=BUCKET_NAME, Key="permission_check.txt")
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'AccessDenied':
            print("Permission check failed: Access Denied")
        else:
            print(f"Permission check failed: {e}")
            sys.exit(1)

def upload_files():
    for file in Path(LOCAL_DIRECTORY).glob("*"):
        print(f"Uploading {file.name} with Content-Type: {get_content_type(file)}...")
        try:
            s3.upload_file(
                str(file),
                BUCKET_NAME,
                file.name,
                ExtraArgs={'ContentType': get_content_type(file)}
            )
            print(f"Successfully uploaded {file.name}")
        except ClientError as e:
            print(f"Failed to upload {file.name}: {e}")
            sys.exit(1)

if __name__ == "__main__":
    print("Starting permissions check...")
    check_permissions()
    print("Permissions check passed. Starting file uploads...")
    upload_files()