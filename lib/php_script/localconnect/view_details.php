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
  die(json_encode(array('error' => 'Connection failed: ' . $conn->connect_error)));
}

if (!isset($_GET['doc_no']) || !isset($_GET['doc_type'])) {
  die(json_encode(array('error' => 'doc_no and doc_type parameters are required')));
}

$doc_no = $_GET['doc_no'];
$doc_type = $_GET['doc_type'];

$sql = "SELECT * FROM tbl_gl_transaction_listing WHERE doc_no = ? AND doc_type = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $doc_no, $doc_type); // doc_no and doc_type as strings
$stmt->execute();

$result = $stmt->get_result();

$checkDetails = array();

if ($result->num_rows > 0) {
  while ($row = $result->fetch_assoc()) {
    $checkDetails[] = $row;
  }
  echo json_encode($checkDetails);
} else {
  echo json_encode(array('error' => 'No check details found for the given doc_no and doc_type'));
}

$stmt->close();
$conn->close();
?>
