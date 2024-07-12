import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/transmittal_screens/transmitter_homepage.dart';
import 'admin_screens/Admin_Homepage.dart';
import 'screens_user/uploader_hompage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String username = '';
  String password = '';
  bool isPasswordVisible = false;
  bool isPasswordValid = true;
  final TextEditingController passwordController = TextEditingController();

  Future<void> loginUser(BuildContext context, String username, String password) async {
    try {
      final url = Uri.parse('http://192.168.131.94/localconnect/login.php');
      final response = await http.post(
        url,
        body: {
          'username': username,
          'password': password,
        },
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          String userRank = jsonResponse['user_rank'];
          String approval_access = jsonResponse['approval_access'];

          if (userRank.toLowerCase() == 'admin') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomePage()),
            );
          } else if (userRank.toLowerCase() == 'user' && approval_access.toLowerCase() == 'uploader') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UploaderHomePage()),
            );
          } else if (userRank.toLowerCase() == 'user' && approval_access.toLowerCase() == 'uploader-transmitter') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TransmitterHomePage()),
            );
          }
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Login Failed'),
                content: Text(jsonResponse['message']),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        throw Exception('Failed to authenticate: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to connect to server. Error: $e'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  void validatePassword(String value) {
    setState(() {
      isPasswordValid = value.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: screenHeight,
            width: screenWidth,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 79, 128, 189),
                  Color.fromARGB(255, 79, 128, 189),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.08, left: screenWidth * 0.06),
              child: Text(
                'Hello,\nWelcome back!',
                style: TextStyle(
                  fontSize: screenWidth * 0.08,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tahoma Bold',
                ),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.03,
            right: screenWidth * 0.035,
            child: Image.asset(
              'logo.png',
              width: screenWidth * 0.32,
              height: screenHeight * 0.2,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.25),
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                color: Colors.white,
              ),
              height: screenHeight * 0.75,
              width: screenWidth,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: screenWidth * 0.9,
                      child: TextField(
                        onChanged: (value) {
                          username = value;
                        },
                        decoration: const InputDecoration(
                          suffixIcon: Icon(
                            Icons.check,
                            color: Colors.grey,
                          ),
                          labelText: 'Username',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 79, 128, 189),
                            fontFamily: 'Tahoma Bold',
                          ),
                        ),
                        style: TextStyle(fontFamily: 'Tahoma Bold'),
                      ),
                    ),
                    Container(
                      width: screenWidth * 0.9,
                      child: TextField(
                        controller: passwordController,
                        onChanged: (value) {
                          password = value;
                          validatePassword(value);
                        },
                        obscureText: !isPasswordVisible,
                        decoration: InputDecoration(
                          suffixIcon: GestureDetector(
                            onTap: togglePasswordVisibility,
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: 200),
                              child: isPasswordVisible
                                  ? Icon(Icons.visibility, key: UniqueKey())
                                  : Icon(Icons.visibility_off, key: UniqueKey()),
                            ),
                          ),
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 79, 128, 189),
                            fontFamily: 'Tahoma Bold',
                          ),
                          errorText: isPasswordValid ? null : 'Password cannot be empty',
                          errorStyle: TextStyle(color: Colors.red, fontFamily: 'Tahoma Bold'),
                        ),
                        style: TextStyle(fontFamily: 'Tahoma Bold'),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            // Implement Forgot Password functionality
                          },
                          child: TextButton(
                            onPressed: () {},
                            child: Text('Forgot Password?', style: TextStyle(fontFamily: 'Tahoma Bold')),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onTap: () {
                        loginUser(context, username, password);
                      },
                      child: Container(
                        height: screenHeight * 0.05,
                        width: screenWidth * 0.3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 79, 128, 189),
                              Color.fromARGB(255, 148, 173, 203),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Tahoma Bold',
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        // Implement biometric login functionality
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fingerprint, color: Color.fromARGB(255, 79, 128, 189)),
                          SizedBox(width: 10),
                          Text(
                            'Sign in with Biometrics',
                            style: TextStyle(
                              color: Color.fromARGB(255, 79, 128, 189),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tahoma Bold',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}