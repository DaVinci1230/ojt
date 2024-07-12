<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

// Response structure
$response = array('status' => 'error', 'message' => 'Transaction update failed.');

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['doc_type']) && isset($_POST['doc_no']) && isset($_POST['date_trans'])) {
    // Database connection details
    $servername = "localhost";
    $username = "root";  // Replace with your database username
    $password = "";      // Replace with your database password
    $dbname = "db_approval";

    // Connect to database
    $conn = new mysqli($servername, $username, $password, $dbname);

    // Check connection
    if ($conn->connect_error) {
        $response['message'] = 'Database connection failed: ' . $conn->connect_error;
    } else {
        // Prepare and bind parameters
        $stmt = $conn->prepare("UPDATE tbl_gl_cdb_list SET online_processing_status = 'ND', online_process_date = CURDATE() WHERE doc_type = ? AND doc_no = ? AND date_trans = ?");
        if (!$stmt) {
            $response['message'] = 'Failed to prepare statement: ' . $conn->error;
        } else {
            $stmt->bind_param("sss", $_POST['doc_type'], $_POST['doc_no'], $_POST['date_trans']);

            // Execute query
            if (!$stmt->execute()) {
                $response['message'] = 'Database update failed: ' . $stmt->error;
            } else {
                $response['status'] = 'success';
                $response['message'] = 'Transaction updated successfully in database.';
            }

            // Close statement
            $stmt->close();
        }

        // Close database connection
        $conn->close();
    }
} else {
    $response['message'] = 'Invalid request method or missing parameters (doc_type, doc_no, date_trans).';
}

// Output JSON response
echo json_encode($response);
?>