<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

// Check request method and required parameters
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['doc_type']) && isset($_POST['doc_no']) && isset($_POST['date_trans']) && isset($_FILES['file'])) {
    $docType = $_POST['doc_type'];
    $docNo = $_POST['doc_no'];
    $dateTrans = $_POST['date_trans'];
    $file = $_FILES['file'];

    $allowedTypes = array('pdf', 'png', 'jpg', 'jpeg', 'docx', 'xlsx');
    $maxFileSize = 10 * 1024 * 1024; // 10MB
    $uploadDir = "C:/Users/angel/OneDrive/Documents/xampp/htdocs/ojt/assets/assets/";
    
    $fileName = preg_replace("/[^a-zA-Z0-9.]/", "", $file['name']);
    $fileTmpName = $file['tmp_name'];
    $fileType = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));

    if (!in_array($fileType, $allowedTypes)) {
        $response = array('status' => 'error', 'message' => 'Invalid file type.');
    } elseif ($file['size'] > $maxFileSize) {
        $response = array('status' => 'error', 'message' => 'File size is too large.');
    } else {
        $filePath = $uploadDir . basename($fileName);
        if (move_uploaded_file($fileTmpName, $filePath)) {
            // Handle database operations or other tasks
            $response = array('status' => 'success', 'message' => 'File uploaded successfully.');
        } else {
            $response = array('status' => 'error', 'message' => 'File upload failed.');
        }
    }
} else {
    $response = array('status' => 'error', 'message' => 'Invalid request or missing parameters.');
}

echo json_encode($response);
?>
