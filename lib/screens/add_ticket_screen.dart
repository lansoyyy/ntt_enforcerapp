import 'dart:convert';

import 'package:enforcer_app/network/endpoints.dart';
import 'package:enforcer_app/screens/home_screen.dart';
import 'package:enforcer_app/services/sunmi_service.dart';
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

  List selectedViolations = [];

  List selectedViolationIds = [];

  bool hasSelected = false;

  final _formKey = GlobalKey<FormState>();

  final searchController = TextEditingController();
  String nameSearched = '';

  @override
  void initState() {
    // TODO: implement initState

    super.initState();

    getViolations();
  }

  bool hasLoaded = false;

  List newViolations = [];

  List finalViolations = [];

  Future<void> getViolations() async {
    final token = box.read('token');

    final url = Uri.parse(
        '${ApiEndpoints.baseUrl}violations?sortBy=number&descending=false&status=ACTIVE');

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
        newViolations = data['data'];
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: primary,
      ),
      body: hasLoaded
          ? Padding(
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
                          Form(
                            onChanged: () {
                              setState(() {});
                            },
                            child: SizedBox(
                              width: 270,
                              child: TextFieldWidget(
                                width: double.infinity,
                                hasValidator: true,
                                controller: license,
                                label: 'License No.',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a licese no.';
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.verified,
                              color: license.text != ''
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      TextFieldWidget(
                        hasValidator: false,
                        width: double.infinity,
                        controller: address,
                        label: 'Address',
                      ),
                      TextFieldWidget(
                        width: double.infinity,
                        controller: fname,
                        label: 'Firstname',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter drivers firstname';
                          }

                          return null;
                        },
                      ),
                      TextFieldWidget(
                        width: double.infinity,
                        controller: lname,
                        label: 'Lastname',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter drivers lastname';
                          }

                          return null;
                        },
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
                          Form(
                            onChanged: () {
                              setState(() {});
                            },
                            child: SizedBox(
                              width: 270,
                              child: TextFieldWidget(
                                width: double.infinity,
                                controller: plateno,
                                label: 'Plate No.',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.verified,
                              color: plateno.text != ''
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      TextFieldWidget(
                        width: double.infinity,
                        controller: vehicletype,
                        hasValidator: false,
                        label: 'Type of Vehicle',
                      ),
                      TextFieldWidget(
                        width: double.infinity,
                        controller: owner,
                        hasValidator: false,
                        label: 'Name of Owner',
                      ),
                      TextFieldWidget(
                        width: double.infinity,
                        controller: owneraddress,
                        hasValidator: false,
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
                              showToast('Ticket saved succesfully!');

                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => const HomeScreen()),
                                (route) {
                                  return false;
                                },
                              );
                            } else {
                              if (license.text != '') {
                                if (_formKey.currentState!.validate()) {
                                  showViolations();
                                }
                              } else {
                                showToast(
                                    'Cannot proceed! Please input license number');
                              }
                            }
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
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  showViolations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.only(top: 50),
            child: SizedBox(
              height: 625,
              width: double.infinity,
              child: Column(
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
                        selectedViolations.isEmpty
                            ? const SizedBox()
                            : IconButton(
                                onPressed: () {
                                  Navigator.pop(context);

                                  showViolationDetailsDialog(
                                      selectedViolations);
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
                    height: 450,
                    width: 375,
                    child: ListView.separated(
                      separatorBuilder: (context, index) {
                        var violation = newViolations[index];
                        return !violation['violation']
                                .toString()
                                .toLowerCase()
                                .contains(nameSearched.toLowerCase())
                            ? const SizedBox()
                            : Divider(
                                color: Colors.grey[200],
                                thickness: 2,
                              );
                      },
                      itemCount: newViolations.length,
                      itemBuilder: (context, index) {
                        var violation = newViolations[index];

                        return !violation['violation']
                                .toString()
                                .toLowerCase()
                                .contains(nameSearched.toLowerCase())
                            ? const SizedBox()
                            : SizedBox(
                                width: 300,
                                height: 110,
                                child: CheckboxListTile(
                                  title: Text(
                                    '${violation['violation']}',
                                    style: const TextStyle(
                                      fontFamily: 'Regular',
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (int i = 0;
                                          i < violation['fines'].length;
                                          i++)
                                        Text(
                                          '${violation['fines'][i]['recurrence']} Offense: ${violation['fines'][i]['fine']}',
                                          style: const TextStyle(
                                            fontFamily: 'Regular',
                                            color: Colors.green,
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                  value: selectedViolationIds
                                      .contains(violation['id']),
                                  onChanged: (bool? value) async {
                                    final token = box.read('token');
                                    final url = Uri.parse(
                                        '${ApiEndpoints.baseUrl}tickets/driver_violations/?license_number=null&violation_id=${violation['id']}');

                                    final response = await http.get(
                                      url,
                                      headers: {
                                        'Accept': 'application/json',
                                        'Authorization': 'Bearer $token',
                                      },
                                    );

                                    final response1 =
                                        jsonDecode(response.body)['violation'];

                                    setState(
                                      () {
                                        if (value!) {
                                          selectedViolationIds
                                              .add(violation['id']);
                                          selectedViolations.add(jsonEncode({
                                            "id": null,
                                            "violation_id": violation['id'],
                                            "violation": violation['violation'],
                                            "fine":
                                                response1['fine'].split('.')[0],
                                            "penalty": null,
                                            "recurrence":
                                                response1['recurrence'],
                                          }));
                                        } else {
                                          selectedViolationIds
                                              .remove(violation['id']);
                                          selectedViolations.remove(jsonEncode({
                                            "id": null,
                                            "violation_id": violation['id'],
                                            "violation": violation['violation'],
                                            "fine":
                                                response1['fine'].split('.')[0],
                                            "penalty": null,
                                            "recurrence":
                                                response1['recurrence'],
                                          }));
                                        }
                                      },
                                    );
                                  },
                                ),
                              );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  showViolationDetailsDialog(List newViolations) {
    int total = 0;

    for (int i = 0; i < newViolations.length; i++) {
      total += int.parse(jsonDecode(newViolations[i])['fine']);
    }
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 500,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < newViolations.length; i++)
                    Builder(builder: (context) {
                      dynamic violations = jsonDecode(newViolations[i]);

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 200,
                                child: TextWidget(
                                  maxLines: 3,
                                  align: TextAlign.start,
                                  text: '- ${violations['violation']}',
                                  fontSize: 14,
                                  fontFamily: 'Bold',
                                ),
                              ),
                              TextWidget(
                                text: '${violations['recurrence']} offense',
                                fontSize: 12,
                                fontFamily: 'Medium',
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      TextWidget(
                                        text: 'P ${violations['fine']}',
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
                      );
                    }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextWidget(
                        text: 'Total',
                        fontSize: 14,
                        fontFamily: 'Bold',
                      ),
                      TextWidget(
                        text: 'P $total.00',
                        fontSize: 14,
                        fontFamily: 'Bold',
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
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
                          for (int i = 0; i < newViolations.length; i++) {
                            finalViolations.add(jsonDecode(newViolations[i]));
                          }

                          addTicket(jsonEncode({
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
                            "violations": finalViolations,
                            "remarks": ""
                          }));
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
          ),
        );
      },
    );
  }

  SunmiService printer = SunmiService();
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
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                content: const Text(
                  'Do you want to print the citation ticket?',
                  style: TextStyle(fontFamily: 'QRegular'),
                ),
                actions: <Widget>[
                  MaterialButton(
                    onPressed: () {
                      showToast('Ticket created succesfully!');

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()),
                        (route) {
                          return false;
                        },
                      );
                    },
                    child: const Text(
                      'No',
                      style: TextStyle(
                          fontFamily: 'QRegular', fontWeight: FontWeight.bold),
                    ),
                  ),
                  MaterialButton(
                    onPressed: () async {
                      showToast('Ticket created succesfully!');

                      printer.printReceipt(
                          license.text,
                          address.text,
                          '${fname.text} ${lname.text}',
                          plateno.text,
                          vehicletype.text,
                          owner.text,
                          owneraddress.text,
                          finalViolations);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()),
                        (route) {
                          return false;
                        },
                      );
                    },
                    child: const Text(
                      'Yes',
                      style: TextStyle(
                          fontFamily: 'QRegular', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ));
    } else {
      showToast(jsonDecode(response.body)['message']);
    }
  }
}
