#!/bin/bash

# Script to update Apple Team ID in apple-app-site-association files
# Usage: ./update_team_id.sh YOUR_TEAM_ID

if [ -z "$1" ]; then
    echo "Usage: ./update_team_id.sh YOUR_TEAM_ID"
    echo "Example: ./update_team_id.sh ABC123XYZ4"
    exit 1
fi

TEAM_ID=$1
BUNDLE_ID="com.AnthonyC.FitHub"
APP_ID="${TEAM_ID}.${BUNDLE_ID}"

echo "Updating Team ID to: $TEAM_ID"
echo "App ID will be: $APP_ID"

# Update both association files
cat > public/.well-known/apple-app-site-association << EOF
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "${APP_ID}",
        "paths": [
          "/r/*",
          "/*?ref=*"
        ]
      }
    ]
  }
}
EOF

cat > public/apple-app-site-association << EOF
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "${APP_ID}",
        "paths": [
          "/r/*",
          "/*?ref=*"
        ]
      }
    ]
  }
}
EOF

echo "✅ Files updated successfully!"
echo "Next step: Run 'firebase deploy --only hosting' to deploy the changes"

