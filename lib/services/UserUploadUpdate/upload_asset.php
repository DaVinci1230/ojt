<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

// Response structure
$response = array('status' => 'error', 'message' => 'File upload failed.');

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['doc_type']) && isset($_POST['doc_no']) && isset($_POST['date_trans'])) {
    if (isset($_FILES['file']['name'])) {
        // File details
        $fileName = basename($_FILES['file']['name']);
        $filePath = "C:/Users/angel/OneDrive/Documents/xampp/htdocs/ojt/assets/$fileName";
        $docType = $_POST['doc_type'];
        $docNo = $_POST['doc_no'];
        $dateTrans = $_POST['date_trans'];

        // Upload file to server
        if (move_uploaded_file($_FILES['file']['tmp_name'], $filePath)) {
            $response['status'] = 'success';
            $response['message'] = 'File uploaded successfully.';
        } else {
            $response['message'] = 'File upload failed.';
        }
    } else {
        $response['message'] = 'No file uploaded.';
    }
} else {
    $response['message'] = 'Invalid request method or missing parameters (doc_type, doc_no, date_trans).';
}

// Output JSON response
echo json_encode($response);
?>
