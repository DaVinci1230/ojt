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
    die("Connection failed: " . $conn->connect_error);
}

$sql = "SELECT * FROM tbl_gl_cdb_list";
$result = $conn->query($sql);

$data = array();
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $data[] = array(
            'id' => $row['id'], // Ensure this matches your database field
            'transactingParty' => $row['transacting_party'],
            'docType' => $row['doc_type'],
            'docNo' => $row['doc_no'],
            'transactionStatus' => $row['transaction_status'],
            'checkAmount' => $row['check_amount'],
            'remarks' => $row['remarks'],
            'transTypeDescription' => $row['trans_type_description'],
        );
    }
}

// Close connection
$conn->close();

// Output JSON
echo json_encode(array('data' => $data));
?>
