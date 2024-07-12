import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 78, 128, 189),
        toolbarHeight: 77,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'For Approval',
              style: TextStyle(
                fontSize: 25,
                color: Color.fromARGB(255, 233, 227, 227),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: EdgeInsets.only(right: screenWidth * 0.02),
                  child: IconButton(
                    style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(124, 206, 193, 193),
                    padding: EdgeInsets.all(5),
                    shape: CircleBorder(),
                  ),
                    onPressed: () {
                      // Optionally, you can add logic here
                    },
                    icon: Icon(
                      Icons.notifications,
                      size: 25,
                      color: Color.fromARGB(125, 68, 65, 65),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 9, 41, 145),
                    padding: EdgeInsets.all(5),
                    shape: CircleBorder(),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 25,
                    color: Color.fromARGB(255, 235, 228, 228),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: 2,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Message', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 2),
                  Text('New file has been added', style: TextStyle(fontSize: 12)),
                  SizedBox(height: 6),
                  Text('[Uploaded by]', style: TextStyle(fontSize: 8)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('[Uploaded Date]', style: TextStyle(fontSize: 9)),
                  SizedBox(height: 1),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.all(4)),
                    onPressed: () {
                    },
                    child: Text('View Details', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
