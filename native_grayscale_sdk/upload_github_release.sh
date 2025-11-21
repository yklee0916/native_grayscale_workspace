#!/bin/bash

TAG=$1
if [ -z "$TAG" ]; then
    echo "TAG number is empty."
    echo "Usage: $0 <tag>"
    echo "Example: $0 1.0.0"
    exit 1
fi

# GitHub 설정
GITHUB_OWNER="yklee0916"
GITHUB_REPO="native_grayscale_sdk"
GITHUB_API_URL="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}"
GITHUB_TOKEN=""

# GitHub Personal Access Token 확인
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is not set."
    echo "Please set your GitHub Personal Access Token:"
    echo "  export GITHUB_TOKEN=your_token_here"
    exit 1
fi

# 빌드 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BUILD_DIR="${SCRIPT_DIR}/out/ios/Release/zip"

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found: $BUILD_DIR"
    echo "Please run build_xcframework_release.sh first to generate zip files."
    exit 1
fi

cd "$BUILD_DIR"

echo "Uploading xcframework files to GitHub Releases for tag $TAG..."

# XCFramework zip 파일 목록
ZIP_FILES=(
    "App.xcframework.zip"
    "Flutter.xcframework.zip"
    "FlutterPluginRegistrant.xcframework.zip"
    "grayscale.xcframework.zip"
    "NativeGrayscaleSDK.xcframework.zip"
)

# 파일 존재 확인
for zip_file in "${ZIP_FILES[@]}"; do
    if [ ! -f "$zip_file" ]; then
        echo "Error: File not found: $zip_file"
        exit 1
    fi
done

# Release 존재 여부 확인
echo "Checking if release $TAG exists..."
RELEASE_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "${GITHUB_API_URL}/releases/tags/${TAG}")

HTTP_CODE=$(echo "$RELEASE_RESPONSE" | tail -n1)
RELEASE_BODY=$(echo "$RELEASE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo "Release $TAG already exists. Using existing release..."
    # RELEASE_ID와 UPLOAD_URL 추출
    RELEASE_ID=$(echo "$RELEASE_BODY" | grep -oE '"id"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' | head -1)
    UPLOAD_URL_TEMPLATE=$(echo "$RELEASE_BODY" | grep -oE '"upload_url"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"upload_url"[[:space:]]*:[[:space:]]*"//;s/"$//' | head -1)
    # upload_url에서 {?name,label} 부분 제거
    UPLOAD_URL_TEMPLATE=$(echo "$UPLOAD_URL_TEMPLATE" | sed 's/{?name,label}//')
else
    echo "Creating new release $TAG..."
    CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -d "{\"tag_name\":\"${TAG}\",\"name\":\"Release ${TAG}\",\"draft\":false,\"prerelease\":false}" \
        "${GITHUB_API_URL}/releases")
    
    CREATE_HTTP_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
    CREATE_BODY=$(echo "$CREATE_RESPONSE" | sed '$d')
    
    if [ "$CREATE_HTTP_CODE" != "201" ]; then
        echo "Error: Failed to create release. HTTP code: $CREATE_HTTP_CODE"
        echo "Response: $CREATE_BODY"
        exit 1
    fi
    
    # RELEASE_ID와 UPLOAD_URL 추출
    RELEASE_ID=$(echo "$CREATE_BODY" | grep -oE '"id"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' | head -1)
    UPLOAD_URL_TEMPLATE=$(echo "$CREATE_BODY" | grep -oE '"upload_url"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"upload_url"[[:space:]]*:[[:space:]]*"//;s/"$//' | head -1)
    # upload_url에서 {?name,label} 부분 제거
    UPLOAD_URL_TEMPLATE=$(echo "$UPLOAD_URL_TEMPLATE" | sed 's/{?name,label}//')
    
    if [ -z "$RELEASE_ID" ]; then
        echo "Error: Failed to extract release ID from response"
        echo "Response body: $CREATE_BODY"
        exit 1
    fi
    
    if [ -z "$UPLOAD_URL_TEMPLATE" ]; then
        echo "Warning: Failed to extract upload_url from response, using fallback URL"
    fi
    
    echo "Release created successfully with ID: $RELEASE_ID"
    if [ -n "$UPLOAD_URL_TEMPLATE" ]; then
        echo "Upload URL template: $UPLOAD_URL_TEMPLATE"
    fi
fi

if [ -z "$RELEASE_ID" ]; then
    echo "Error: Release ID is empty"
    echo "Response body: $RELEASE_BODY"
    exit 1
fi

# 각 zip 파일 업로드
for zip_file in "${ZIP_FILES[@]}"; do
    echo ""
    echo "Uploading $zip_file..."
    
    # GitHub uploads API URL 사용 (upload_url 템플릿 사용)
    if [ -n "$UPLOAD_URL_TEMPLATE" ]; then
        UPLOAD_URL="${UPLOAD_URL_TEMPLATE}?name=${zip_file}"
    else
        # fallback: 일반 API URL 사용
        UPLOAD_URL="${GITHUB_API_URL}/releases/${RELEASE_ID}/assets?name=${zip_file}"
    fi
    
    # curl 명령어 출력 (토큰은 마스킹)
    MASKED_TOKEN="${GITHUB_TOKEN:0:10}***"
    echo "curl -s -w \"\\n%{http_code}\" \\"
    echo "    -X POST \\"
    echo "    -H \"Authorization: token $MASKED_TOKEN\" \\"
    echo "    -H \"Accept: application/vnd.github.v3+json\" \\"
    echo "    -H \"Content-Type: application/zip\" \\"
    echo "    --data-binary \"@${zip_file}\" \\"
    echo "    \"$UPLOAD_URL\""
    
    UPLOAD_RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/zip" \
        --data-binary "@${zip_file}" \
        "$UPLOAD_URL")
    
    UPLOAD_HTTP_CODE=$(echo "$UPLOAD_RESPONSE" | tail -n1)
    UPLOAD_BODY=$(echo "$UPLOAD_RESPONSE" | sed '$d')
    
    if [ "$UPLOAD_HTTP_CODE" = "201" ]; then
        echo "✅ $zip_file uploaded successfully"
    else
        # 이미 업로드된 파일인 경우 (422 에러)
        if [ "$UPLOAD_HTTP_CODE" = "422" ]; then
            echo "⚠️  $zip_file already exists in release. Skipping..."
        else
            echo "❌ Failed to upload $zip_file. HTTP code: $UPLOAD_HTTP_CODE"
            echo "Response: $UPLOAD_BODY"
        fi
    fi
done

echo ""
echo "✅ All xcframework files uploaded successfully!"
echo "Release URL: https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/tag/${TAG}"

