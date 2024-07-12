<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "db_approval";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$docType = $_GET['doc_type'];
$docNo = $_GET['doc_no'];

$sql = "SELECT file_name, file_path FROM tbl_gl_ref_documents_uploaded WHERE doc_type = ? AND doc_no = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("si", $docType, $docNo); 
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $attachments = array();
    while ($row = $result->fetch_assoc()) {
        $attachments[] = $row;
    }
    echo json_encode($attachments);
} else {
    echo json_encode(array());
}

$conn->close();
?>