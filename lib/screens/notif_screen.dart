import 'dart:convert';

import 'package:enforcer_app/network/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../utils/colors.dart';
import '../widgets/text_widget.dart';

class NotifScreen extends StatefulWidget {
  const NotifScreen({super.key});

  @override
  State<NotifScreen> createState() => _NotifScreenState();
}

class _NotifScreenState extends State<NotifScreen> {
  @override
  void initState() {
    super.initState();
    getAnnouncements();
  }

  List notifications = [];

  final box = GetStorage();
  bool hasLoaded = false;

  Future<void> getAnnouncements() async {
    final token = box.read('token');

    final url =
        Uri.parse('${ApiEndpoints.baseUrl}announcements?archived=false');

    print(token);

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        notifications = data['data'];
        hasLoaded = true;
      });
    } else {
      print('Failed to retrieve user data: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: primary,
        title: TextWidget(
          text: 'Announcements',
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      body: hasLoaded
          ? Padding(
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
                      leading: const Icon(
                        Icons.info_outline,
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
                        notifications[index]['content']!,
                        style: TextStyle(
                          fontFamily: 'Regular',
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            notifications[index]['user']!,
                            style: TextStyle(
                              fontFamily: 'Regular',
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(DateTime.now()),
                            style: TextStyle(
                              fontFamily: 'Regular',
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
