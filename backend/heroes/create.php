<?php
include_once '../config/cors.php';
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (
    !empty($data->name) &&
    !empty($data->localized_name) &&
    !empty($data->primary_attr) &&
    !empty($data->attack_type)
) {
    $query = "INSERT INTO heroes (name, localized_name, primary_attr, attack_type, roles, img_url, lore)
              VALUES (:name, :localized_name, :primary_attr, :attack_type, :roles, :img_url, :lore)";
    $stmt = $db->prepare($query);

    $name           = htmlspecialchars(strip_tags($data->name));
    $localized_name = htmlspecialchars(strip_tags($data->localized_name));
    $primary_attr   = htmlspecialchars(strip_tags($data->primary_attr));
    $attack_type    = htmlspecialchars(strip_tags($data->attack_type));
    $roles          = htmlspecialchars(strip_tags($data->roles ?? ""));
    $img_url        = htmlspecialchars(strip_tags($data->img_url ?? ""));
    $lore           = htmlspecialchars(strip_tags($data->lore ?? ""));

    $stmt->bindParam(":name", $name);
    $stmt->bindParam(":localized_name", $localized_name);
    $stmt->bindParam(":primary_attr", $primary_attr);
    $stmt->bindParam(":attack_type", $attack_type);
    $stmt->bindParam(":roles", $roles);
    $stmt->bindParam(":img_url", $img_url);
    $stmt->bindParam(":lore", $lore);

    if ($stmt->execute()) {
        http_response_code(201);
        echo json_encode([
            "message" => "Hero created successfully.",
            "id" => (int)$db->lastInsertId()
        ]);
    } else {
        http_response_code(503);
        echo json_encode(["message" => "Unable to create hero."]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Incomplete data. name, localized_name, primary_attr and attack_type are required."]);
}
?>
