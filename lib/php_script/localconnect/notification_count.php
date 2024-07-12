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

// Query to get counts for different transaction statuses
$sql_reprocessingCount = "
  SELECT COUNT(*) as reprocessing_count
  FROM tbl_gl_cdb_list
  WHERE doc_type = 'CV'
    AND online_processing_status = 'R'
    AND transaction_status = 'R'
";

$sql_transmittalCount = "
  SELECT COUNT(*) as transmittal_count
  FROM tbl_gl_cdb_list
  WHERE doc_type = 'CV'
    AND (online_processing_status = 'U' OR online_processing_status = 'ND')
";

$sql_uploadingCount = "
  SELECT COUNT(*) as uploading_count
  FROM tbl_gl_cdb_list
  WHERE doc_type = 'CV'
    AND transaction_status = 'R'
    AND online_processing_status = ''
";

// Execute queries
$result_reprocessingCount = $conn->query($sql_reprocessingCount);
$result_transmittalCount = $conn->query($sql_transmittalCount);
$result_uploadingCount = $conn->query($sql_uploadingCount);

if ($result_reprocessingCount && $result_transmittalCount && $result_uploadingCount) {
  $reprocessingCount = $result_reprocessingCount->fetch_assoc()['reprocessing_count'];
  $transmittalCount = $result_transmittalCount->fetch_assoc()['transmittal_count'];
  $uploadingCount = $result_uploadingCount->fetch_assoc()['uploading_count'];

  // Output the counts as JSON
  echo json_encode(array(
    'reprocessing_count' => $reprocessingCount,
    'transmittal_count' => $transmittalCount,
    'uploading_count' => $uploadingCount
  ));
} else {
  // If query failed, output an error
  echo json_encode(array('error' => 'Query failed: ' . $conn->error));
}

// Close database connection
$conn->close();
?>
