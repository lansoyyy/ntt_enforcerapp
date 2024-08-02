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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              elevation: 2,
              child: SizedBox(
                width: double.infinity,
                height: 605,
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
                                text: 'Lance O. Olana',
                                fontSize: 15,
                                color: Colors.black,
                                fontFamily: 'Bold',
                              ),
                              TextWidget(
                                text: 'Station',
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              TextWidget(
                                text: 'Cagayan De Oro',
                                fontSize: 12,
                                color: Colors.black,
                                fontFamily: 'Bold',
                              ),
                              TextWidget(
                                text: 'Position',
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              TextWidget(
                                text: 'Team Leader',
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
                          itemCount: 5,
                          separatorBuilder: (context, index) {
                            return const Divider();
                          },
                          itemBuilder: (context, index) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
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
                                      text: 'Lance O. Olana',
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontFamily: 'Bold',
                                    ),
                                    TextWidget(
                                      text: 'Violation',
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                    TextWidget(
                                      text: 'No Helmet',
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontFamily: 'Bold',
                                    ),
                                    TextWidget(
                                      text: 'Date and Time',
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                    TextWidget(
                                      text: 'January 01, 2001',
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontFamily: 'Bold',
                                    ),
                                  ],
                                ),
                                const Expanded(child: SizedBox()),
                                IconButton(
                                  onPressed: () {
                                    showViolationDetails();
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
      ),
    );
  }

  showViolationDetails() {
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
                    width: double.infinity,
                    controller: license,
                    label: 'License No.',
                  ),
                  TextFieldWidget(
                    width: double.infinity,
                    controller: address,
                    label: 'Address',
                  ),
                  TextFieldWidget(
                    width: double.infinity,
                    controller: fname,
                    label: 'Firstname',
                  ),
                  TextFieldWidget(
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
                    width: double.infinity,
                    controller: plateno,
                    label: 'Plate No.',
                  ),
                  TextFieldWidget(
                    width: double.infinity,
                    controller: vehicletype,
                    label: 'Type of Vehicle',
                  ),
                  TextFieldWidget(
                    width: double.infinity,
                    controller: owner,
                    label: 'Name of Owner',
                  ),
                  TextFieldWidget(
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
