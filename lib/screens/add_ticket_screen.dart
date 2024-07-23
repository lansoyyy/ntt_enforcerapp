import 'package:enforcer_app/screens/home_screen.dart';
import 'package:enforcer_app/utils/violation_data.dart';
import 'package:enforcer_app/widgets/button_widget.dart';
import 'package:enforcer_app/widgets/text_widget.dart';
import 'package:enforcer_app/widgets/textfield_widget.dart';
import 'package:enforcer_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';

import '../utils/colors.dart';

class AddTicketScreen extends StatefulWidget {
  const AddTicketScreen({super.key});

  @override
  State<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends State<AddTicketScreen> {
  final name = TextEditingController();
  final address = TextEditingController();
  final license = TextEditingController();
  final expiry = TextEditingController();
  final bday = TextEditingController();
  final nationality = TextEditingController();
  final height = TextEditingController();
  final weight = TextEditingController();
  final gender = TextEditingController();

  final plateno = TextEditingController();
  final owner = TextEditingController();
  final owneraddress = TextEditingController();
  final maker = TextEditingController();
  final model = TextEditingController();
  final color = TextEditingController();
  final number = TextEditingController();

  String _selectedOption = 'Prof';

  Map<String, bool> checkedValues = {};

  bool hasSelected = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
                    'VIOLATOR INFORMATION',
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
                      width: 320,
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
                  controller: name,
                  label: 'Fullname',
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextFieldWidget(
                      width: 175,
                      controller: expiry,
                      label: 'Expiry',
                    ),
                    TextFieldWidget(
                      width: 175,
                      controller: gender,
                      label: 'Gender',
                    ),
                  ],
                ),
                TextWidget(
                    text: 'License Type', fontSize: 12, color: Colors.black),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 125,
                      child: RadioListTile<String>(
                        activeColor: primary,
                        title: const Text(
                          'Prof',
                          style: TextStyle(
                            fontFamily: 'Medium',
                            fontSize: 14,
                          ),
                        ),
                        value: 'Prof',
                        groupValue: _selectedOption,
                        onChanged: (value) {
                          setState(() {
                            _selectedOption = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 125,
                      child: RadioListTile<String>(
                        activeColor: primary,
                        title: const Text(
                          'Non Prof',
                          style: TextStyle(
                            fontFamily: 'Medium',
                            fontSize: 14,
                          ),
                        ),
                        value: 'Non Prof',
                        groupValue: _selectedOption,
                        onChanged: (value) {
                          setState(() {
                            _selectedOption = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 115,
                      child: RadioListTile<String>(
                        activeColor: primary,
                        title: const Text(
                          'SP',
                          style: TextStyle(
                            fontFamily: 'Medium',
                            fontSize: 14,
                          ),
                        ),
                        value: 'SP',
                        groupValue: _selectedOption,
                        onChanged: (value) {
                          setState(() {
                            _selectedOption = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextFieldWidget(
                      width: 175,
                      controller: bday,
                      label: 'Birthday',
                    ),
                    TextFieldWidget(
                      width: 175,
                      controller: nationality,
                      label: 'Nationality',
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextFieldWidget(
                      inputType: TextInputType.number,
                      width: 175,
                      controller: height,
                      label: 'Height (cm)',
                    ),
                    TextFieldWidget(
                      inputType: TextInputType.number,
                      width: 175,
                      controller: weight,
                      label: 'Weight (kg)',
                    ),
                  ],
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
                const SizedBox(
                  height: 10,
                ),
                TextFieldWidget(
                  width: 325,
                  controller: plateno,
                  label: 'Plate No.',
                ),
                TextFieldWidget(
                  width: 325,
                  controller: owner,
                  label: 'Owner',
                ),
                TextFieldWidget(
                  width: 325,
                  controller: owneraddress,
                  label: 'Owner Address',
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextFieldWidget(
                      width: 175,
                      controller: maker,
                      label: 'Maker',
                    ),
                    TextFieldWidget(
                      width: 175,
                      controller: color,
                      label: 'Color',
                    ),
                  ],
                ),
                TextFieldWidget(
                  width: 325,
                  controller: model,
                  label: 'Model',
                ),
                const SizedBox(
                  height: 20,
                ),
                Center(
                  child: ButtonWidget(
                    width: double.infinity,
                    label: hasSelected ? 'Save Ticket' : 'Continue',
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
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
                          showViolations();
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
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
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
                            setState(() {
                              hasSelected = true;
                            });
                            Navigator.pop(context);
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
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                    height: 300,
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
            ));
      },
    );
  }
}
