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

$docNo = $_GET['doc_no'];
$docType = $_GET['doc_type'];

$query = "SELECT * FROM tbl_gl_ref_documents_uploaded WHERE doc_no = '$docNo' AND doc_type = '$docType'";
$result = $conn->query($query);

if (!$result) {
    die(json_encode(array("status" => "error", "message" => "Query failed: " . $conn->error)));
}

// Fetch data into an associative array
$transaction = $result->fetch_assoc();

if (!$transaction) {
    die(json_encode(array("status" => "error", "message" => "Transaction not found")));
}

// Close database connection
$conn->close();

// Prepare response data
$response = [
    'doc_no' => $transaction['doc_no'],
    'doc_type' => $transaction['doc_type'],
    'file_name' => $transaction['file_name'],
    'file_path' => $transaction['file_path'],
    // Include other relevant transaction details as needed
];

// Convert data to JSON format
echo json_encode($response);

?>
