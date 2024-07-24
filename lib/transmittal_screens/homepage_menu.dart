import 'package:flutter/material.dart';
import '../models/user_transaction.dart';
import '/loginScreen.dart';
import 'package:badges/badges.dart' as badges;
import 'transmittal_notification.dart';
import 'transmitter_history.dart';
import 'transmitter_homepage.dart';
import 'package:intl/intl.dart';
import '../../api_services/transmitter_api.dart';

class HomepageMenuWindow extends StatefulWidget {
  const HomepageMenuWindow({Key? key}) : super(key: key);

  @override
  _MenuState createState() => _MenuState();
  
}

class _MenuState extends State<HomepageMenuWindow> {
  int _selectedIndex = 1;
   int notificationCount = 0;
     final TransmitterAPI _apiService = TransmitterAPI();

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
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const NoSupportTransmit()),
        // );
        break;
      // case 2:
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => const TransmitMenuWindow()),
      //   );
      //   break;
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
           transaction.onlineProcessingStatus == 'R' ||
                transaction.onlineProcessingStatus == 'TND' ||
                transaction.onlineProcessingStatus == 'T' &&
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
                      notificationCount > 0 ? '$notificationCount' : '',
                      style: TextStyle(color: Colors.white),
                    ),
                    badgeStyle: badges.BadgeStyle(
                      badgeColor: notificationCount > 0
                          ? Colors.red
                          : Colors.transparent,
                      padding: EdgeInsets.all(6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TransmittalNotification()),
                        );
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
                  'Transmitter',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: screenSize.height * 0.025,
              ),
              InkWell(
                onTap: () {
                  _showFilterDialog(context);
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
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

  Future<void> _showFilterDialog(BuildContext context) async {
    String selectedFilter = 'All';
    DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime endDate = DateTime.now();
    bool isOldestFirst = false;

    // Calculate dialog width based on screen size
    double dialogWidth = MediaQuery.of(context).size.width * 0.8;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Set Filters'),
              content: Container(
                width: dialogWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filter:'),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: DropdownButton<String>(
                              value: selectedFilter,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedFilter = newValue!;
                                });
                              },
                              items: <String>[
                                'All',
                                'Approved',
                                'Rejected',
                                'Returned',
                                'On Process'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Start Date:'),
                        ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              setState(() {
                                startDate = picked;
                              });
                            }
                          },
                          child: Text(
                              DateFormat('MMM dd, yyyy').format(startDate)),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('End Date:'),
                        ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              setState(() {
                                endDate = picked;
                              });
                            }
                          },
                          child:
                              Text(DateFormat('MMM dd, yyyy').format(endDate)),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    CheckboxListTile(
                      title: Text('Oldest First'),
                      value: isOldestFirst,
                      onChanged: (bool? newValue) {
                        setState(() {
                          isOldestFirst = newValue ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransmitterHistory(
                          selectedFilter: selectedFilter,
                          startDate: startDate,
                          endDate: endDate,
                          isOldestFirst: isOldestFirst,
                        ),
                      ),
                    );
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}