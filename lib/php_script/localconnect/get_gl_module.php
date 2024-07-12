<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "db_approval";

if (!isset($_GET['type'])) {
  die(json_encode(['error' => 'Missing type parameter']));
}

$type = $_GET['type'];

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
  die(json_encode(['error' => 'Connection failed: ' . $conn->connect_error]));
}

$sql = $conn->prepare("SELECT date_trans FROM tbl_gl_transaction_listing WHERE gl_module = 'CDB'");
$sql->bind_param("s", $type);
$sql->execute();
$result = $sql->get_result();

$date = '';
if ($result->num_rows > 0) {
  $row = $result->fetch_assoc();
  $date = $row['date_trans'];
}

echo json_encode(['date' => $date]);

$conn->close();
?>
