import 'package:ojt/transmittal_screens/fetching_data.dart';

import 'no_support.dart';
import 'user_menu.dart';
import 'user_upload.dart';
import 'package:flutter/material.dart';

class TransmitterHomePage extends StatefulWidget {
  const TransmitterHomePage({Key? key}) : super(key: key);

  @override
  _TransmitterHomePageState createState() => _TransmitterHomePageState();
}

class _TransmitterHomePageState extends State<TransmitterHomePage> {
  int _selectedIndex = 0;

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
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
  
        backgroundColor: Color.fromARGB(255, 79, 128, 189),
        toolbarHeight: 77,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  'logo.png',
                  width: 60,
                  height: 55,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tasks',
                  style: TextStyle(
                    fontFamily: 'Tahoma', // Set font to Tahoma
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
                      //   MaterialPageRoute(builder: (context) => NotificationScreen()),
                      // );
                    },
                    icon: const Icon(
                      Icons.notifications,
                      size: 24, // Adjust size as needed
                      color: Color.fromARGB(255, 233, 227, 227),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.person,
                    size: 24, // Adjust size as needed
                    color: Color.fromARGB(255, 233, 227, 227),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white, // Set the background color to white
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDashboardCard(
                  screenSize,
                  title: 'For Reprocessing',
                  count: '0',
                  label: 'items',
                  icon: Icons.content_paste,
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => DisbursementDetailsScreen(),
                    //   ),
                    // );
                  },
                ),
                SizedBox(height: 20), // Add spacing between cards
                _buildDashboardCard(
                  screenSize,
                  title: 'For Transmittal',
                  count: '0',
                  label: 'items [month]',
                  icon: Icons.history,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransmittalHomePage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20), // Add spacing between cards
                _buildDashboardCard(
                  screenSize,
                  title: 'For Uploading',
                  count: '0',
                  label: 'items',
                  icon: Icons.upload_file,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(255, 79, 128, 189),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file_outlined),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'No Support',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_sharp),
            label: 'Menu',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(Size screenSize,
      {required String title,
      required String count,
      required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 10), // Adjust vertical padding
        height: 100,
        width: screenSize.width * 0.9,
        decoration: BoxDecoration(
          color: Color(0xFF4F80BD), // Set the card color to match the original
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center, // Ensure vertical alignment
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Tahoma', // Set font to Tahoma
                      fontSize: 16,
                      //fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Row(
                      children: [
                        Text(
                          count,
                          style: TextStyle(
                            fontFamily: 'Tahoma', // Set font to Tahoma
                            fontSize: 30,
                            //fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Tahoma', // Set font to Tahoma
                              fontSize: 16,
                              //fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow
                                .ellipsis, // Ensure text does not overflow
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 10),
              child: Icon(
                icon,
                size: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
