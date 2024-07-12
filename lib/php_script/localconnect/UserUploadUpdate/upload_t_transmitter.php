<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

// Response structure
$response = array('status' => 'error', 'message' => 'File upload failed.');

// Check request method and required parameters
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['doc_type']) && isset($_POST['doc_no']) && isset($_POST['date_trans'])) {
    if (isset($_FILES['file'])) {
        $file = $_FILES['file'];
        $allowedTypes = array('pdf', 'png', 'jpg', 'jpeg', 'docx', 'xlsx');
        $maxFileSize = 10 * 1024 * 1024; // 10 MB

        // Ensure the file type is allowed
        $fileType = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        if (!in_array($fileType, $allowedTypes)) {
            $response['message'] = 'Invalid file type.';
            echo json_encode($response);
            exit;
        }
        
        // Ensure the file size is within the limit
        if ($file['size'] > $maxFileSize) {
            $response['message'] = 'File size is too large.';
            echo json_encode($response);
            exit;
        }

        // Sanitize the file name to remove unwanted characters
        $fileName = preg_replace("/[^a-zA-Z0-9.]/", "", $file['name']);

        $filePath = "C:/Users/angel/OneDrive/Documents/xampp/htdocs/ojt/assets2/" . basename($fileName);
        if (move_uploaded_file($file['tmp_name'], $filePath)) {
            $servername = "localhost";
            $username = "root";  // Replace with your database username
            $password = "";      // Replace with your database password
            $dbname = "db_approval";

            // Connect to database
            $conn = new mysqli($servername, $username, $password, $dbname);

            // Check connection
            if ($conn->connect_error) {
                $response['message'] = 'Database connection failed: '. $conn->connect_error;
                echo json_encode($response);
                exit;
            } else {
                $conn->autocommit(FALSE);
                try {
                    $docType = $conn->real_escape_string($_POST['doc_type']);
                    $docNo = $conn->real_escape_string($_POST['doc_no']);
                    $dateTrans = $conn->real_escape_string($_POST['date_trans']);
                    $uploadedBy = 'USER'; // Set uploaded_by to 'USER'
                    $dateUploaded = date('Y-m-d'); // Set date_uploaded to current date

                    $stmt = $conn->prepare("INSERT INTO tbl_gl_ref_documents_uploaded (doc_type, doc_no, file_name, file_path, uploaded_by, date_uploaded) VALUES (?,?,?,?,?,?)");
                    $stmt->bind_param("ssssss", $docType, $docNo, $fileName, $filePath, $uploadedBy, $dateUploaded);
                    $stmt->execute();

                    $stmt = $conn->prepare("UPDATE tbl_gl_cdb_list SET online_processing_status = 'T', online_process_date = CURDATE() WHERE doc_type = ? AND doc_no = ? AND date_trans = ?");
                    $stmt->bind_param("sss", $docType, $docNo, $dateTrans);
                    $stmt->execute();

                    $conn->commit();

                    $response['status'] = 'success';
                    $response['message'] = 'Files uploaded and status updated in database.';
                } catch (Exception $e) {
                    $conn->rollback();
                    $response['message'] = 'Error: '. $e->getMessage();
                }

                // Close database connection
                $conn->close();
            }
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