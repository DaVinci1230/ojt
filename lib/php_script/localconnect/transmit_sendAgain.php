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

// Debugging: Log the entire $_POST array
error_log(print_r($_POST, true));

// Check if doc_no and doc_type are set in POST request
if (!isset($_POST['doc_no']) || !isset($_POST['doc_type'])) {
    die(json_encode(array("status" => "error", "message" => "Missing doc_no or doc_type in POST data")));
}

$docNo = $_POST['doc_no'];
$docType = $_POST['doc_type'];

error_log("Received doc_no: $docNo, doc_type: $docType"); // Log received values

// Prepare and bind
$stmt = $conn->prepare("SELECT file_name, file_path FROM tbl_gl_ref_documents_uploaded WHERE doc_no = ? AND doc_type = ?");
$stmt->bind_param("ss", $docNo, $docType);

$stmt->execute();

// Get the result
$result = $stmt->get_result();

if ($result->num_rows == 0) {
    $updateQuery = "UPDATE tbl_gl_cdb_list SET online_processing_status = 'ND' WHERE doc_no = ? AND doc_type = ?";
    $updateStmt = $conn->prepare($updateQuery);
    $updateStmt->bind_param("ss", $docNo, $docType);
    $updateResult = $updateStmt->execute();

    if (!$updateResult) {
        die(json_encode(array("status" => "error", "message" => "Failed to send transaction: " . $updateStmt->error)));
    }
    
    die(json_encode(array("status" => "error", "message" => "Transaction send! mmwa")));
}

$transaction = $result->fetch_assoc();

$updateQuery = "UPDATE tbl_gl_cdb_list SET online_processing_status = 'U' WHERE doc_no = ? AND doc_type = ?";
$updateStmt = $conn->prepare($updateQuery);
$updateStmt->bind_param("ss", $docNo, $docType);

$updateResult = $updateStmt->execute();

if (!$updateResult) {
    die(json_encode(array("status" => "error", "message" => "Failed to send transaction" . $updateStmt->error)));
}

$conn->close();

// Prepare response data
$response = [
    'doc_no' => $docNo,
    'doc_type' => $docType,
    'file_name' => $transaction['file_name'],
    'file_path' => $transaction['file_path'],
];

// Convert data to JSON format
echo json_encode($response);
?>
