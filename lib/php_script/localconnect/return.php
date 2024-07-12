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

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $doc_type = isset($_POST['doc_type']) ? $_POST['doc_type'] : null;
    $doc_no = isset($_POST['doc_no']) ? $_POST['doc_no'] : null;
    $approverRemarks = isset($_POST['approver_remarks']) ? $_POST['approver_remarks'] : '';

    if ($doc_type && $doc_no) {
        $updateStmt = $conn->prepare("UPDATE tbl_gl_cdb_list SET online_processing_status = 'R', transaction_status = 'R' WHERE doc_type = ? AND doc_no = ?");
        $updateStmt->bind_param("ss", $doc_type, $doc_no);

        $updateRemarksStmt = $conn->prepare("UPDATE tbl_gl_cdb_list SET approver_remarks = ? WHERE doc_type = ? AND doc_no = ?");
        $updateRemarksStmt->bind_param("sss", $approverRemarks, $doc_type, $doc_no);

        if ($updateStmt->execute()) {
            if ($updateRemarksStmt->execute()) {
                echo json_encode(array("status" => "success", "message" => "Record updated successfully"));
            } else {
                echo json_encode(array("status" => "error", "message" => "Error updating approver remarks: " . $updateRemarksStmt->error));
            }
        } else {
            echo json_encode(array("status" => "error", "message" => "Error updating record: " . $updateStmt->error));
        }
        $updateStmt->close();
        $updateRemarksStmt->close();
    } else {
        echo json_encode(array("status" => "error", "message" => "Invalid input data"));
    }

} else {
    echo json_encode(array("status" => "error", "message" => "Invalid request method"));
}

$conn->close();
?>
