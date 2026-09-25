<?php
include_once '../config/cors.php';
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$id = isset($_GET['id']) ? intval($_GET['id']) : 0;

if ($id <= 0) {
    http_response_code(400);
    echo json_encode(["message" => "A valid hero id is required."]);
    exit();
}

$query = "SELECT id, name, localized_name, primary_attr, attack_type, roles, img_url, lore, created_at, updated_at
          FROM heroes WHERE id = :id LIMIT 1";
$stmt = $db->prepare($query);
$stmt->bindParam(":id", $id, PDO::PARAM_INT);
$stmt->execute();

$hero = $stmt->fetch(PDO::FETCH_ASSOC);

if ($hero) {
    $hero['id'] = (int)$hero['id'];
    http_response_code(200);
    echo json_encode($hero);
} else {
    http_response_code(404);
    echo json_encode(["message" => "Hero not found."]);
}
?>
