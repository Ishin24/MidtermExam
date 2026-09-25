<?php
include_once '../config/cors.php';
include_once '../config/database.php';

$database = new Database();
$db = $database->getConnection();

// DELETE requests are read the same way as PUT: from the raw request body.
$data = json_decode(file_get_contents("php://input"));

if (!empty($data->id)) {
    $id = intval($data->id);

    $query = "DELETE FROM heroes WHERE id = :id";
    $stmt = $db->prepare($query);
    $stmt->bindParam(":id", $id, PDO::PARAM_INT);

    if ($stmt->execute()) {
        if ($stmt->rowCount() > 0) {
            http_response_code(200);
            echo json_encode(["message" => "Hero deleted successfully."]);
        } else {
            http_response_code(404);
            echo json_encode(["message" => "Hero not found."]);
        }
    } else {
        http_response_code(503);
        echo json_encode(["message" => "Unable to delete hero."]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Hero id is required."]);
}
?>
