import 'package:flutter/material.dart';
import '../../models/user_transaction.dart';
import '/screens_user/uploading/uploader_hompage.dart';
import '../uploader_history.dart';
import '../../widgets/navBar.dart';
import '/loginScreen.dart';
import '../../api_services/api_services.dart';
import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart'; 

class UserMenuWindow extends StatefulWidget {
  const UserMenuWindow({Key? key}) : super(key: key);

  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<UserMenuWindow> {
  int _selectedIndex = 1;
   int notificationCount = 0;
     final ApiService _apiService = ApiService();


  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UploaderHomePage()),
        );
        break;
      case 1:
        // No action needed, already on the menu page
        break;
    }
  }

  Future<void> _countNotif() async {
    try {
      List<UserTransaction> transactions = await _apiService.fetchTransactionDetails();
      setState(() {
        notificationCount = transactions
            .where((transaction) =>
           transaction.onlineProcessingStatus == 'U' ||
           transaction.onlineProcessingStatus == 'ND' ||
           transaction.onlineProcessingStatus == 'R'  &&
                    transaction.notification == 'N')
            .length;
      });
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
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
                  'assets/logo.png',
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
                child: badges.Badge(
                  badgeContent: Text(
                    '$notificationCount',  // Display the number of notifications
                    style: TextStyle(color: Colors.white),
                  ),
                  badgeStyle: BadgeStyle(
                    badgeColor: Colors.red,
                    padding: EdgeInsets.all(6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //       builder: (context) => TransmittalNotification()),
                      // );
                    },
                    icon: const Icon(
                      Icons.notifications,
                      size: 24,
                      color: Color.fromARGB(255, 233, 227, 227),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UserMenuWindow()),
                  );
                },
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UploaderHistory(),
                    ),
                  );
                },
                child: _buildOption(
                    screenSize, Icons.fact_check_outlined, 'History'),
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
                child:
                    _buildOption(screenSize, Icons.login_outlined, 'Log out'),
              ),
              SizedBox(
                height: screenSize.height * 0.15,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
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
