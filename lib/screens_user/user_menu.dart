import 'package:flutter/material.dart';
import 'no_support.dart';
import 'user_upload.dart';
import 'transmitter_homepage.dart';
import '/loginScreen.dart';
class MenuWindow extends StatefulWidget {
  const MenuWindow({Key? key}) : super(key: key);

  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<MenuWindow> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TransmitterHomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NoSupportScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MenuWindow()),
        );
        break;
    }
  }
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double circleDiameter = screenSize.width * 0.4;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 79, 128, 189),
        toolbarHeight: screenSize.height * 0.1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  'logo.png',
                  width: screenSize.width * 0.15, 
                  height: screenSize.height * 0.1,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 233, 227, 227),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: EdgeInsets.only(right: screenSize.width * 0.02),
                  child: IconButton(
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //       builder: (context) => NotificationScreen()),
                      // );
                    },
                    icon: const Icon(
                      Icons.notifications,
                      size: 24,
                      color: Color.fromARGB(255, 233, 227, 227),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.person,
                    size: 24,
                    color: Color.fromARGB(255, 233, 227, 227),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: circleDiameter,
                    height: circleDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Color.fromARGB(255, 79, 128, 189),
                          width: screenSize.width * 0.0158),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        size: screenSize.width * 0.16,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue,
                          width: screenSize.width * 0.0108,
                        ),
                      ),
                      padding: EdgeInsets.all(screenSize.width * 0.02),
                      child: Icon(
                        Icons.camera_alt,
                        size: screenSize.width * 0.05,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(screenSize.width * 0.01),
                child: Text(
                  '[Name]',
                  style: TextStyle(fontSize: 17),
                ),
              ),
              Container(
                child: Text(
                  'Uploader',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: screenSize.height * 0.025,
              ),
              InkWell(
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => TransactionsScreen(),
                  //   ),
                  // );
                },
                child: _buildOption(screenSize, Icons.fact_check_outlined, 'History'),
              ),
              _buildOption(screenSize, Icons.fingerprint_rounded, 'Biometrics'),
              _buildOption(screenSize, Icons.security, 'Change Password'),
              InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                },
                child: _buildOption(screenSize, Icons.login_outlined, 'Log out'),
              ),
              SizedBox(
                height: screenSize.height * 0.15,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file_outlined),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_sharp),
            label: 'No Support',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_sharp),
            label: 'Menu',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 0, 110, 255),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildOption(Size screenSize, IconData iconData, String text) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.05,
          vertical: screenSize.height * 0.02),
      width: screenSize.width * 0.98,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconData),
              SizedBox(
                width: screenSize.width * 0.02,
              ),
              Text(
                text,
                style: TextStyle(
                    fontSize: 15, color: const Color.fromARGB(255, 0, 0, 0)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
