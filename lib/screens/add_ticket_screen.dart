import 'dart:convert';

import 'package:enforcer_app/network/endpoints.dart';
import 'package:enforcer_app/screens/home_screen.dart';
import 'package:enforcer_app/utils/violation_data.dart';
import 'package:enforcer_app/widgets/button_widget.dart';
import 'package:enforcer_app/widgets/text_widget.dart';
import 'package:enforcer_app/widgets/textfield_widget.dart';
import 'package:enforcer_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../utils/colors.dart';

class AddTicketScreen extends StatefulWidget {
  const AddTicketScreen({super.key});

  @override
  State<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends State<AddTicketScreen> {
  final fname = TextEditingController();
  final lname = TextEditingController();

  final address = TextEditingController();
  final license = TextEditingController();

  final plateno = TextEditingController();
  final owner = TextEditingController();
  final owneraddress = TextEditingController();

  final vehicletype = TextEditingController();

  Map<String, bool> checkedValues = {};

  bool hasSelected = false;

  final _formKey = GlobalKey<FormState>();

  final searchController = TextEditingController();
  String nameSearched = '';

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    for (var violation in violations) {
      checkedValues[violation.code] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
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
                Row(
                  children: [
                    SizedBox(
                      width: 270,
                      child: TextFieldWidget(
                        width: double.infinity,
                        controller: license,
                        label: 'License No.',
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.verified,
                      ),
                    ),
                  ],
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
                Row(
                  children: [
                    SizedBox(
                      width: 270,
                      child: TextFieldWidget(
                        width: double.infinity,
                        controller: plateno,
                        label: 'Plate No.',
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.verified,
                      ),
                    ),
                  ],
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
                    label: hasSelected ? 'Save Ticket' : 'Continue',
                    onPressed: () {
                      if (hasSelected) {
                        addTicket(jsonEncode({
                          "number": "SAMPLE",
                          "enforcer_id": box.read('id'),
                          "enforcer_name": "${box.read('name')}",
                          "location": "${box.read('location')}",
                          "barangay_id": null,
                          "date_issued": DateFormat('yyyy-MM-ddTHH:mm')
                              .format(DateTime.now()),
                          "status": "UNPAID",
                          "driver": {
                            "license_number": license.text,
                            "first_name": fname.text,
                            "last_name": lname.text,
                            "address": address.text,
                            "email": "",
                            "phone": "",
                            "date_of_birth": ""
                          },
                          "vehicle_type": vehicletype.text,
                          "vehicle_plate": plateno.text,
                          "vehicle_owner": owner.text,
                          "vehicle_owner_address": owneraddress.text,
                          "verified_license": false,
                          "verified_plate": false,
                          "violations": [
                            {
                              "id": null,
                              "violation_id": 1,
                              "violation": "No Helmet",
                              "fine": "100.00",
                              "penalty": null,
                              "recurrence": 1
                            }
                          ],
                          "remarks": ""
                        }));
                      } else {
                        showViolations();
                      }
                      // if (_formKey.currentState!.validate()) {
                      //   if (hasSelected) {
                      //     showToast('Ticket saved succesfully!');

                      //     Navigator.of(context).pushAndRemoveUntil(
                      //       MaterialPageRoute(
                      //           builder: (context) => const HomeScreen()),
                      //       (route) {
                      //         return false;
                      //       },
                      //     );
                      //   } else {
                      //     showViolations();
                      //   }
                      // }
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
      ),
    );
  }

  showViolations() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
            height: 500,
            width: double.infinity,
            child: StatefulBuilder(builder: (context, setState) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'TRAFFIC VIOLATION',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Bold',
                          ),
                        ),
                        const Expanded(
                          child: SizedBox(),
                        ),
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              showViolationDetailsDialog();
                            },
                            icon: const Icon(
                              Icons.save,
                            )),
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.close,
                            )),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      height: 40,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(100)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: TextFormField(
                          style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'Regular',
                              fontSize: 14),
                          onChanged: (value) {
                            setState(() {
                              nameSearched = value;
                            });
                          },
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              labelStyle: TextStyle(
                                color: Colors.black,
                              ),
                              hintText: 'Search Violation',
                              hintStyle: TextStyle(
                                  fontFamily: 'Regular', fontSize: 14),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey,
                              )),
                          controller: searchController,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      height: 225,
                      width: 375,
                      child: ListView.separated(
                        separatorBuilder: (context, index) {
                          return Divider(
                            color: Colors.grey[200],
                            thickness: 2,
                          );
                        },
                        itemCount: violations.length,
                        itemBuilder: (context, index) {
                          var violation = violations[index];
                          return SizedBox(
                            width: 300,
                            height: 85,
                            child: CheckboxListTile(
                              title: Text(
                                '${violation.code} - ${violation.description}',
                                style: const TextStyle(
                                  fontFamily: 'Regular',
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'First Offense: ${violation.fines.values.elementAt(0)}',
                                    style: const TextStyle(
                                      fontFamily: 'Regular',
                                      color: Colors.green,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    'Second Offense: ${violation.fines.values.elementAt(1)}',
                                    style: const TextStyle(
                                      fontFamily: 'Regular',
                                      color: Colors.green,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    'Third Offense: ${violation.fines.values.elementAt(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'Regular',
                                      color: Colors.green,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              value: checkedValues[violation.code],
                              onChanged: (bool? value) {
                                setState(() {
                                  checkedValues[violation.code] = value!;
                                });
                              },
                            ),
                          );
                        },
                      )),
                  const SizedBox(height: 10),
                ],
              );
            }));
      },
    );
  }

  showViolationDetailsDialog() {
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 500,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 5; i++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                        text: 'No Helmet',
                        fontSize: 14,
                        fontFamily: 'Bold',
                      ),
                      TextWidget(
                        text: '3rd offense',
                        fontSize: 12,
                        fontFamily: 'Medium',
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: 'P 2000.00',
                                fontSize: 12,
                                fontFamily: 'Medium',
                              ),
                              TextWidget(
                                text: 'REV OF DL',
                                fontSize: 12,
                                fontFamily: 'Medium',
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.delete_outline_outlined,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      text: 'Total',
                      fontSize: 14,
                      fontFamily: 'Bold',
                    ),
                    TextWidget(
                      text: 'P 10,000.00',
                      fontSize: 14,
                      fontFamily: 'Bold',
                    ),
                  ],
                ),
                const Expanded(child: SizedBox()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MaterialButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                            fontFamily: 'QRegular',
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    MaterialButton(
                      onPressed: () async {
                        setState(() {
                          hasSelected = true;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                            fontFamily: 'QRegular',
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  final box = GetStorage();

  Future<void> addTicket(dynamic body) async {
    final token = box.read('token');
    final url = Uri.parse('${ApiEndpoints.baseUrl}tickets');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token', // Add 'Bearer' prefix
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      showToast('Ticket created succesfully!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) {
          return false;
        },
      );
    } else {
      showToast(jsonDecode(response.body)['message']);
    }
  }
}
