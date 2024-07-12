<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "db_approval";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode(array("status" => "error", "message" => "Connection failed: " . $conn->connect_error)));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $file_path = isset($_POST['file_path']) ? $_POST['file_path'] : null;
    $file_name = isset($_POST['file_name']) ? $_POST['file_name'] : null;

    if ($file_path !== null && $file_name !== null) {
        $full_path = $file_path . '/' . $file_name;
        if (file_exists($full_path)) {
            unlink($full_path);
        }

        // Correct DELETE query syntax and bind_param usage
        $deleteStmt = $conn->prepare("DELETE FROM tbl_gl_ref_documents_uploaded WHERE file_name = ? AND file_path = ?");
        $deleteStmt->bind_param("ss", $file_name, $file_path);  // Use "ss" for two string parameters

        // Execute the statement
        $deleteSuccess = $deleteStmt->execute();

        if ($deleteSuccess) {
            echo json_encode(array("status" => "success", "message" => "Attachment deleted successfully"));
        } else {
            echo json_encode(array("status" => "error", "message" => "Error deleting attachment: " . $conn->error));
        }
        $deleteStmt->close();
    } else {
        echo json_encode(array("status" => "error", "message" => "Invalid input data"));
    }
} else {
    echo json_encode(array("status" => "error", "message" => "Invalid request method"));
}

$conn->close();
?>