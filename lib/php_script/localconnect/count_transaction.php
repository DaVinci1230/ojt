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

$currentDate = isset($_GET['date_trans']) ? $_GET['date_trans'] : date("Y-m-d");

$sql = "SELECT * FROM tbl_gl_cdb_list WHERE doc_type = 'CV'";

// Execute SQL query
$result = $conn->query($sql);

if ($result->num_rows > 0) {
  // Initialize an array to store all fetched rows
  $transactions = array();

  // Fetch all rows
  while ($row = $result->fetch_assoc()) {
    $transactions[] = $row;
  }
  
  // Output transactions array as JSON
  echo json_encode($transactions);
} else {
  // If no results found, output an empty array
  echo json_encode(array());
}

// Close database connection
$conn->close();
?>
