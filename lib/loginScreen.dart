import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/screens_user/transmitter_homepage.dart';
import '/screens_user/uploader_homepage.dart';
import 'admin_screens/Admin_Homepage.dart';


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
      final url = Uri.parse('http://192.168.68.116/localconnect/login.php');
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
          }
          else if (userRank.toLowerCase() == 'user' && approval_access.toLowerCase() == 'uploader'){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UploaderHomePage()),
            );
          }
          else if (userRank.toLowerCase() == 'user' && approval_access.toLowerCase() == 'uploader-transmitter'){            Navigator.push(
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
    return Scaffold(
      body: Stack(
        children: [
          Container(
            
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 79, 128, 189),
                  Color.fromARGB(255, 79, 128, 189),
                ],
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.only(top: 60.0, left: 22),
              child: Text(
                'Hello,\nWelcome back!',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tahoma Bold',
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 270, top: 25),
            child: Image.asset(
              'logo.png',
              width: 150,
              height: 155,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 200.0),
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                color: Colors.white,
              ),
              height: double.infinity,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(left: 18.0, right: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 335,
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
                      width: 335,
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
                        height: 35,
                        width: 100,
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