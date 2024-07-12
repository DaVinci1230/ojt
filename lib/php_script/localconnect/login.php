<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// Database configuration
$servername = "localhost";
$username = "root";
$password = "";
$database = "db_approval";

// Create connection
$conn = new mysqli($servername, $username, $password, $database);

// Check connection
if ($conn->connect_error) {
    die(json_encode(array('status' => 'error', 'message' => 'Connection failed: ' . $conn->connect_error)));
}

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Check if username and password are provided
if (!isset($_POST['username']) || !isset($_POST['password'])) {
    die(json_encode(array('status' => 'error', 'message' => 'Username or password not provided.')));
}

$username = $_POST['username'];
$password = $_POST['password'];

// Prepare and execute SQL query
$stmt = $conn->prepare("SELECT * FROM tbl_main_users WHERE username = ?");
$stmt->bind_param("s", $username);

$stmt->execute();
$result = $stmt->get_result();

// Check if user exists and verify password
if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    // Example: Use password_verify() if passwords are hashed in database
    // Replace with your actual password field name and hashing method
    if ($password == $user['password']) {
        // Get approval_access and format it as value1-value2 if it contains a comma
        $approval_access_raw = array_map('trim', explode(',', $user['approval_access']));
        $approval_access_formatted = implode('-', $approval_access_raw);
        
        echo json_encode(array(
            'status' => 'success',
            'user_rank' => $user['user_rank'],
            'approval_access' => $approval_access_formatted
        ));
    } else {
        echo json_encode(array('status' => 'error', 'message' => 'Username and password do not match.'));
    }
} else {
    echo json_encode(array('status' => 'error', 'message' => 'Username not found.'));
}

$stmt->close();
$conn->close();
?>
