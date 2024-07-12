import 'package:flutter/material.dart';

import '../utlis/colors.dart';
import '../widgets/text_widget.dart';

class NotifScreen extends StatefulWidget {
  const NotifScreen({super.key});

  @override
  State<NotifScreen> createState() => _NotifScreenState();
}

class _NotifScreenState extends State<NotifScreen> {
  final List<Map<String, String>> notifications = [
    {
      'title': 'New Message',
      'subtitle': 'You have received a new message.',
      'time': '5 mins ago'
    },
    {
      'title': 'Update Available',
      'subtitle': 'A new update is available for your app.',
      'time': '10 mins ago'
    },
    {
      'title': 'Meeting Reminder',
      'subtitle': 'Don\'t forget about the meeting at 3 PM.',
      'time': '30 mins ago'
    },
    {
      'title': 'Task Completed',
      'subtitle': 'You have completed your task.',
      'time': '1 hour ago'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: primary,
        title: TextWidget(
          text: 'Notifications',
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: Icon(
                  Icons.notifications,
                  color: primary,
                  size: 40,
                ),
                title: Text(
                  notifications[index]['title']!,
                  style: const TextStyle(
                    fontFamily: 'Bold',
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  notifications[index]['subtitle']!,
                  style: TextStyle(
                    fontFamily: 'Regular',
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                trailing: Text(
                  notifications[index]['time']!,
                  style: TextStyle(
                    fontFamily: 'Regular',
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
