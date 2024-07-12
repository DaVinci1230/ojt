<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "your_database_name"; // Replace with your actual database name

// Establish connection to MySQL database
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode(array("status" => "error", "message" => "Connection failed: " . $conn->connect_error)));
}

// Handle POST request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Retrieve data from POST request
    $doc_no = isset($_POST['doc_no']) ? $_POST['doc_no'] : null;
    $doc_type = isset($_POST['doc_type']) ? $_POST['doc_type'] : null;
    $remarks = isset($_POST['remarks']) ? $_POST['remarks'] : null;

    // Validate input
    if ($doc_no !== null && $doc_type !== null && $remarks !== null) {
        // Prepare and bind SQL statement
        $stmt = $conn->prepare("UPDATE tbl_gl_cdb_list SET approver_remarks = ? WHERE doc_no = ? AND doc_type = ?");
        $stmt->bind_param("sss", $remarks, $doc_no, $doc_type);

        // Execute SQL statement
        if ($stmt->execute()) {
            echo json_encode(array("status" => "success", "message" => "Remarks updated successfully"));
        } else {
            echo json_encode(array("status" => "error", "message" => "Error updating remarks: " . $conn->error));
        }

        // Close statement
        $stmt->close();
    } else {
        echo json_encode(array("status" => "error", "message" => "Invalid input data"));
    }
} else {
    echo json_encode(array("status" => "error", "message" => "Invalid request method"));
}

// Close connection
$conn->close();
?>
