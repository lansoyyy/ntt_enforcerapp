import 'package:enforcer_app/screens/add_ticket_screen.dart';
import 'package:enforcer_app/screens/auth/login_screen.dart';
import 'package:enforcer_app/screens/notif_screen.dart';
import 'package:enforcer_app/utlis/colors.dart';
import 'package:enforcer_app/widgets/date_picker_widget.dart';
import 'package:enforcer_app/widgets/logout_widget.dart';
import 'package:enforcer_app/widgets/text_widget.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? selectedDate;
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
                        Icons.notifications,
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      TextWidget(
                        text: 'Notifications',
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              elevation: 2,
              child: SizedBox(
                width: double.infinity,
                height: 150,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
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
                ),
              ),
            ),
            const SizedBox(
              height: 10,
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
                    final DateTime? pickedDate = await datePickerWidget(
                      context,
                      selectedDate!,
                    );

                    if (pickedDate != null && pickedDate != selectedDate) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }

                    print(selectedDate);
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 380,
                child: SingleChildScrollView(
                  child: DataTable(
                      headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                          return Colors.white; // Row color
                        },
                      ),
                      border: TableBorder.all(color: Colors.black),
                      columns: [
                        DataColumn(
                          label: TextWidget(
                            text: 'ID',
                            fontSize: 14,
                            fontFamily: 'Bold',
                          ),
                        ),
                        DataColumn(
                          label: TextWidget(
                            text: 'Name',
                            fontSize: 14,
                            fontFamily: 'Bold',
                          ),
                        ),
                        DataColumn(
                          label: TextWidget(
                            text: 'Date and Time',
                            fontSize: 14,
                            fontFamily: 'Bold',
                          ),
                        ),
                      ],
                      rows: [
                        for (int i = 0; i < 50; i++)
                          DataRow(
                              color: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                                  return i % 2 != 0
                                      ? Colors.white
                                      : Colors.grey[100]; // Row color
                                },
                              ),
                              cells: [
                                DataCell(
                                  TextWidget(
                                    text: '${i + 1}',
                                    fontSize: 12,
                                    fontFamily: 'Bold',
                                  ),
                                ),
                                DataCell(
                                  TextWidget(
                                    align: TextAlign.start,
                                    text: 'Lance Olana',
                                    fontSize: 12,
                                  ),
                                ),
                                DataCell(
                                  TextWidget(
                                    align: TextAlign.start,
                                    text: 'January 01, 2001',
                                    fontSize: 12,
                                  ),
                                ),
                              ])
                      ]),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
