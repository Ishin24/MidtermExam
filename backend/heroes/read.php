<?php
include_once '../config/cors.php';
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$query = "SELECT id, name, localized_name, primary_attr, attack_type, roles, img_url, lore, created_at, updated_at
          FROM heroes ORDER BY localized_name ASC";
$stmt = $db->prepare($query);
$stmt->execute();

$heroes = [];
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    $row['id'] = (int)$row['id'];
    $heroes[] = $row;
}

http_response_code(200);
echo json_encode($heroes);
?>
