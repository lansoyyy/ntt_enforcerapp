import 'dart:convert';

import 'package:enforcer_app/network/endpoints.dart';
import 'package:enforcer_app/screens/add_ticket_screen.dart';
import 'package:enforcer_app/screens/auth/login_screen.dart';
import 'package:enforcer_app/screens/notif_screen.dart';
import 'package:enforcer_app/utils/colors.dart';
import 'package:enforcer_app/widgets/button_widget.dart';
import 'package:enforcer_app/widgets/date_picker_widget.dart';
import 'package:enforcer_app/widgets/logout_widget.dart';
import 'package:enforcer_app/widgets/text_widget.dart';
import 'package:enforcer_app/widgets/textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

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

    final url = Uri.parse('${ApiEndpoints.baseUrl}tickets');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: () {
          getTicket();
          // Navigator.of(context).push(
          //   MaterialPageRoute(builder: (context) => const AddTicketScreen()),
          // );
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
                                      selectedDate,
                                    );

                                    if (pickedDate != null &&
                                        pickedDate != selectedDate) {
                                      setState(() {
                                        selectedDate = pickedDate;
                                      });
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
                                            TextWidget(
                                              text: violations[index]
                                                      ['violations'][i]
                                                  ['violation'],
                                              fontSize: 12,
                                              color: Colors.black,
                                              fontFamily: 'Bold',
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

  showViolationDetails(data) {
    setState(() {
      address.text = data['driver_address'];
      fname.text = data['driver_first_name'];
      lname.text = data['driver_last_name'];
      plateno.text = data['vehicle_plate'];
      vehicletype.text = data['vehicle_type'];
      owner.text = data['vehicle_owner'];
      owneraddress.text = data['vehicle_owner_address'];
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
                  const Center(
                    child: Text(
                      'DRIVER INFORMATION',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Bold'),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFieldWidget(
                    enabled: false,
                    width: double.infinity,
                    controller: address,
                    label: 'Address',
                  ),
                  TextFieldWidget(
                    enabled: false,
                    width: double.infinity,
                    controller: fname,
                    label: 'Firstname',
                  ),
                  TextFieldWidget(
                    enabled: false,
                    width: double.infinity,
                    controller: lname,
                    label: 'Lastname',
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Divider(
                    color: Colors.grey[200],
                    thickness: 2,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Center(
                    child: Text(
                      'VEHICLE INFORMATION',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontFamily: 'Bold',
                      ),
                    ),
                  ),
                  TextFieldWidget(
                    enabled: false,
                    width: double.infinity,
                    controller: plateno,
                    label: 'Plate No.',
                  ),
                  TextFieldWidget(
                    enabled: false,
                    width: double.infinity,
                    controller: vehicletype,
                    label: 'Type of Vehicle',
                  ),
                  TextFieldWidget(
                    enabled: false,
                    width: double.infinity,
                    controller: owner,
                    label: 'Name of Owner',
                  ),
                  TextFieldWidget(
                    enabled: false,
                    width: double.infinity,
                    controller: owneraddress,
                    label: 'Address of Owner',
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
  }
}
