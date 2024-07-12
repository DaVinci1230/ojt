<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "db_approval";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die(json_encode(array("status" => "error", "message" => "Connection failed: " . $conn->connect_error)));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $doc_type = isset($_POST['doc_type']) ? $_POST['doc_type'] : null;
    $doc_no = isset($_POST['doc_no']) ? $_POST['doc_no'] : null;

    if ($doc_type !== null && $doc_no !== null) {
        $updateStmt = $conn->prepare("UPDATE tbl_gl_cdb_list SET online_processing_status = NULL, transaction_status = 'N', cancel_date = CURDATE() WHERE doc_type = ? AND doc_no = ?");
        $updateStmt->bind_param("ss", $doc_type, $doc_no);

        $deleteStmt = $conn->prepare("DELETE FROM tbl_gl_ref_documents_uploaded WHERE doc_type = ? AND doc_no = ?");
        $deleteStmt->bind_param("ss", $doc_type, $doc_no);
        $updateSuccess = $updateStmt->execute();
        $deleteSuccess = $deleteStmt->execute();

        if ($updateSuccess && $deleteSuccess) {
            echo json_encode(array("status" => "success", "message" => "Record updated and attachments deleted successfully"));
        } else {
            echo json_encode(array("status" => "error", "message" => "Error updating record or deleting attachments: " . $conn->error));
        }
        $updateStmt->close();
        $deleteStmt->close();
    } else {
        echo json_encode(array("status" => "error", "message" => "Invalid input data"));
    }
} else {
    echo json_encode(array("status" => "error", "message" => "Invalid request method"));
}
$conn->close();
?>
