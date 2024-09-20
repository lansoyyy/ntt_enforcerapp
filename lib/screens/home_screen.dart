import 'dart:convert';

import 'package:enforcer_app/network/endpoints.dart';
import 'package:enforcer_app/screens/add_ticket_screen.dart';
import 'package:enforcer_app/screens/auth/login_screen.dart';
import 'package:enforcer_app/screens/notif_screen.dart';
import 'package:enforcer_app/screens/profile_screen.dart';
import 'package:enforcer_app/utils/colors.dart';
import 'package:enforcer_app/widgets/button_widget.dart';
import 'package:enforcer_app/widgets/date_picker_widget.dart';
import 'package:enforcer_app/widgets/logout_widget.dart';
import 'package:enforcer_app/widgets/text_widget.dart';
import 'package:enforcer_app/widgets/textfield_widget.dart';
import 'package:enforcer_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../services/sunmi_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();

  final fname = TextEditingController();
  final lname = TextEditingController();

  final address = TextEditingController();
  final license = TextEditingController();

  final plateno = TextEditingController();
  final owner = TextEditingController();
  final owneraddress = TextEditingController();

  final vehicletype = TextEditingController();

  final box = GetStorage();

  bool hasLoaded = false;

  List violations = [];

  Map enforcerData = {};

  Future<void> getUserData() async {
    final token = box.read('token');
    final url = Uri.parse('${ApiEndpoints.baseUrl}me');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token', // Add 'Bearer' prefix
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('User data retrieved successfully: $data');

      box.write('id', data['id']);
      box.write('name', '${data['first_name']} ${data['last_name']}');
      box.write('location', data['lgu']['name']);

      setState(() {
        enforcerData = data;
      });
    } else {
      print('Failed to retrieve user data: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  Future<void> getTicket() async {
    final token = box.read('token');

    final url = Uri.parse(
        '${ApiEndpoints.baseUrl}tickets?sortBy=date_issued&descending=true&page=1&rowsPerPage=15&rowsNumber=0&search=&date_issued={%22from%22:%22${DateFormat('MM/dd/yyyy').format(selectedDate)}%22,%22to%22:%22${DateFormat('MM/dd/yyyy').format(selectedDate)}%22}');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token', // Add 'Bearer' prefix
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        violations = data['data'];
        hasLoaded = true;
      });
    } else {
      print('Failed to retrieve user data: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData();
    getTicket();
  }

  SunmiService printer = SunmiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddTicketScreen()),
          );
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      appBar: AppBar(
        backgroundColor: primary,
        title: TextWidget(
          text: 'Home',
          fontSize: 18,
          color: Colors.white,
        ),
        actions: [
          PopupMenuButton(
            iconColor: Colors.white,
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const NotifScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      TextWidget(
                        text: 'Announcements',
                        fontSize: 14,
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_circle,
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      TextWidget(
                        text: 'Profile',
                        fontSize: 14,
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () {
                    logout(context, const LoginScreen());
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout,
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      TextWidget(
                        text: 'Logout',
                        fontSize: 14,
                      ),
                    ],
                  ),
                ),
              ];
            },
          )
        ],
      ),
      body: hasLoaded
          ? Padding(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    child: SizedBox(
                      width: double.infinity,
                      height: 550,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const CircleAvatar(
                                  minRadius: 50,
                                  maxRadius: 50,
                                  backgroundImage: AssetImage(
                                    'assets/images/profile.png',
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                VerticalDivider(
                                  color: Colors.grey[200],
                                  thickness: 2,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextWidget(
                                      text: 'Name',
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                    TextWidget(
                                      text:
                                          '${enforcerData['first_name']} ${enforcerData['last_name']}',
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontFamily: 'Bold',
                                    ),
                                    TextWidget(
                                      text: 'LGU',
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                    TextWidget(
                                      text: enforcerData['lgu']['name'],
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontFamily: 'Bold',
                                    ),
                                    TextWidget(
                                      text: 'Role',
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                    TextWidget(
                                      text: enforcerData['roles'].first,
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontFamily: 'Bold',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextWidget(
                                  text: 'History',
                                  fontSize: 18,
                                  fontFamily: 'Bold',
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final DateTime? pickedDate =
                                        await datePickerWidget(
                                      context,
                                      selectedDate ?? DateTime.now(),
                                    );

                                    if (pickedDate != null &&
                                        pickedDate != selectedDate) {
                                      setState(() {
                                        selectedDate = pickedDate;
                                        hasLoaded = false;
                                      });

                                      getTicket();
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.calendar_month,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Expanded(
                              child: ListView.separated(
                                itemCount: violations.length,
                                separatorBuilder: (context, index) {
                                  return const Divider();
                                },
                                itemBuilder: (context, index) {
                                  // Ensure the list is sorted by date_issued in descending order
                                  violations.sort((a, b) {
                                    DateTime dateA =
                                        DateTime.parse(a['date_issued']);
                                    DateTime dateB =
                                        DateTime.parse(b['date_issued']);
                                    return dateB.compareTo(
                                        dateA); // Sort in descending order
                                  });

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          TextWidget(
                                            text: 'Ticket Number',
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          TextWidget(
                                            text:
                                                '${violations[index]['number']}',
                                            fontSize: 15,
                                            color: Colors.black,
                                            fontFamily: 'Bold',
                                          ),
                                          TextWidget(
                                            text: 'Name',
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          TextWidget(
                                            text:
                                                '${violations[index]['driver_first_name']} ${violations[index]['driver_last_name']}',
                                            fontSize: 15,
                                            color: Colors.black,
                                            fontFamily: 'Bold',
                                          ),
                                          TextWidget(
                                            text: 'Violation',
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                          for (int i = 0;
                                              i <
                                                  violations[index]
                                                          ['violations']
                                                      .length;
                                              i++)
                                            SizedBox(
                                              width: 250,
                                              child: TextWidget(
                                                align: TextAlign.start,
                                                text:
                                                    '• ${violations[index]['violations'][i]['violation']}',
                                                fontSize: 12,
                                                color: Colors.black,
                                                fontFamily: 'Bold',
                                              ),
                                            ),
                                          TextWidget(
                                            text: 'Date and Time Issued',
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                          TextWidget(
                                            text: violations[index]
                                                ['date_issued'],
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontFamily: 'Bold',
                                          ),
                                        ],
                                      ),
                                      const Expanded(child: SizedBox()),
                                      IconButton(
                                        onPressed: () {
                                          showViolationDetails(
                                              violations[index]);
                                        },
                                        icon: const Icon(
                                          size: 35,
                                          Icons.visibility,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 20,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Future<void> getLicense(String id) async {
    final token = box.read('token');

    final url = Uri.parse('${ApiEndpoints.baseUrl}/tickets/$id');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token', // Add 'Bearer' prefix
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        license.text = data['ticket']['driver']['license_number'];
      });
    } else {
      print('Failed to retrieve user data: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  final driveremail = TextEditingController();
  final phone = TextEditingController();
  final place = TextEditingController();

  showViolationDetails(data) async {
    String input = data['number'];
    // Extract the substring starting after the last hyphen
    String numberString = input.substring(input.lastIndexOf('-') + 1);
    // Remove leading zeros
    numberString = numberString.replaceFirst(RegExp(r'^0+'), '');

    await getLicense(numberString).whenComplete(
      () {
        setState(() {
          address.text = data['driver_address'] ?? '';
          fname.text = data['driver_first_name'] ?? '';
          lname.text = data['driver_last_name'] ?? '';
          plateno.text = data['vehicle_plate'] ?? '';
          vehicletype.text = data['vehicle_type'] ?? '';
          owner.text = data['vehicle_owner'] ?? '';
          owneraddress.text = data['vehicle_owner_address'] ?? '';
          driveremail.text = data['driver_email'] ?? '';
          phone.text = data['driver_phone'] ?? '';
          place.text = data['place_of_apprehension'] ?? '';
        });
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: 'TRAFFIC CITATION TICKET',
                        fontSize: 18,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextWidget(
                        text: data['number'],
                        fontSize: 14,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextWidget(
                        text: 'Name: ${fname.text} ${lname.text}',
                        fontSize: 14,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextWidget(
                        text: 'Address: ${address.text}',
                        fontSize: 14,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextWidget(
                        text: 'Driver Email: ${driveremail.text}',
                        fontSize: 14,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextWidget(
                        text: 'Phone Number: ${phone.text}',
                        fontSize: 14,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextWidget(
                        text: 'Place: ${place.text}',
                        fontSize: 14,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(),
                      const SizedBox(
                        height: 10,
                      ),
                      TextWidget(
                        text: 'License Number: ${license.text}',
                        fontSize: 14,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextWidget(
                        text: 'Plate Number: ${plateno.text}',
                        fontSize: 14,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextWidget(
                        text: 'Type of Vehicle: ${vehicletype.text}',
                        fontSize: 14,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextWidget(
                        text: 'Name of Owner: ${owner.text}',
                        fontSize: 14,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextWidget(
                        text: 'Address of Owner: ${owneraddress.text}',
                        fontSize: 14,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(),
                      const SizedBox(
                        height: 10,
                      ),
                      TextWidget(
                        text: 'Violations',
                        fontSize: 18,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      for (int i = 0; i < data['violations'].length; i++)
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: TextWidget(
                                    maxLines: 3,
                                    align: TextAlign.start,
                                    text:
                                        '- ${data['violations'][i]['violation']}',
                                    fontSize: 14,
                                    fontFamily: 'Bold',
                                  ),
                                ),
                                TextWidget(
                                  text:
                                      '${data['violations'][i]['recurrence']} offense',
                                  fontSize: 12,
                                  fontFamily: 'Medium',
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        TextWidget(
                                          text:
                                              'P ${data['violations'][i]['fine']}',
                                          fontSize: 12,
                                          fontFamily: 'Medium',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(),
                          ],
                        ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                            text: 'Total fine:',
                            fontSize: 16,
                            fontFamily: 'Bold',
                          ),
                          TextWidget(
                            text: '${data['violations'].fold(0.0, (sum, item) {
                              // Convert 'fine' to double if it is a String
                              var fineValue = item['fine'];
                              double fine = (fineValue is String
                                      ? double.tryParse(fineValue)
                                      : fineValue) ??
                                  0.0;
                              return sum + fine;
                            })}',
                            fontSize: 18,
                            fontFamily: 'Bold',
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Center(
                        child: ButtonWidget(
                          width: double.infinity,
                          label: 'Reprint Ticket',
                          onPressed: () {
                            Navigator.pop(context);
                            printer.printReceipt(
                                license.text,
                                address.text,
                                '${fname.text} ${lname.text}',
                                plateno.text,
                                vehicletype.text,
                                owner.text,
                                owneraddress.text,
                                data['violations'],
                                data['number'],
                                '${data['violations'].fold(0.0, (sum, item) {
                                  // Convert 'fine' to double if it is a String
                                  var fineValue = item['fine'];
                                  double fine = (fineValue is String
                                          ? double.tryParse(fineValue)
                                          : fineValue) ??
                                      0.0;
                                  return sum + fine;
                                })}',
                                data['date_issued'].toString());
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Center(
                        child: ButtonWidget(
                          width: double.infinity,
                          label: 'Close',
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 25,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
