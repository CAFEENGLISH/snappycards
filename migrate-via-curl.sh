#!/bin/bash

# Storage Migration via cURL Commands
# This approach uses direct REST API calls to migrate files

PERSONAL_ACCESS_TOKEN="sbp_6d50add440dc1960b3efbd639d932f4b42ece0f2"
OLD_PROJECT_ID="ycxqxdhaxehspypqbnpi"
NEW_PROJECT_ID="aeijlzokobuqcyznljvn"
OLD_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyMjUxNzc4NSwiZXhwIjoyMDM4MDkzNzg1fQ.VgBAmJ4R2xKE1rORWqL-_dVQ4lKH3C9UtjYFgd87E7E"
NEW_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanduIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyMjUxNTM5NCwiZXhwIjoyMDM4MDkxMzk0fQ.o0aGWqgfqiMRnLKFOa4dItlzHJpCqaF5f60VcDshJZM"

echo "🚀 STORAGE MIGRATION VIA CURL"
echo "============================="
echo "📊 Source: $OLD_PROJECT_ID"
echo "📊 Target: $NEW_PROJECT_ID"
echo ""

# Create temp directory for files
mkdir -p temp_storage_files

# Test file to migrate
TEST_FILE="6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754058275584_l0my16tnvb.jpeg"

echo "🧪 Testing with file: $TEST_FILE"
echo "--------------------------------"

# Download test file from OLD project
echo "📥 Downloading from OLD project..."
curl -L -o "temp_storage_files/test_file.jpeg" \
  -H "Authorization: Bearer $OLD_SERVICE_KEY" \
  "https://$OLD_PROJECT_ID.supabase.co/storage/v1/object/media/$TEST_FILE"

if [ -f "temp_storage_files/test_file.jpeg" ]; then
    file_size=$(wc -c < "temp_storage_files/test_file.jpeg")
    echo "✅ Downloaded $file_size bytes"
    
    # Upload to NEW project
    echo "📤 Uploading to NEW project..."
    response=$(curl -X POST \
      -H "Authorization: Bearer $NEW_SERVICE_KEY" \
      -H "Content-Type: image/jpeg" \
      --data-binary "@temp_storage_files/test_file.jpeg" \
      "https://$NEW_PROJECT_ID.supabase.co/storage/v1/object/media/$TEST_FILE" \
      -w "%{http_code}" -s -o temp_response.json)
    
    echo "HTTP Response: $response"
    cat temp_response.json
    echo ""
    
    if [ "$response" = "200" ] || [ "$response" = "201" ]; then
        echo "✅ Upload successful!"
        
        # Test public URL
        public_url="https://$NEW_PROJECT_ID.supabase.co/storage/v1/object/public/media/$TEST_FILE"
        echo "🔍 Testing public URL: $public_url"
        
        test_response=$(curl -I "$public_url" -w "%{http_code}" -s -o /dev/null)
        if [ "$test_response" = "200" ]; then
            echo "✅ File is accessible publicly!"
        else
            echo "⚠️ File may not be publicly accessible (HTTP $test_response)"
        fi
    else
        echo "❌ Upload failed"
    fi
else
    echo "❌ Download failed"
fi

# Cleanup
rm -f temp_response.json
echo ""
echo "🧹 Cleaning up temporary files..."
rm -rf temp_storage_files

echo "✅ Test completed"