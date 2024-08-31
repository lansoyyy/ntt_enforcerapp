import 'dart:convert';

import 'package:enforcer_app/network/endpoints.dart';
import 'package:enforcer_app/screens/home_screen.dart';
import 'package:enforcer_app/widgets/button_widget.dart';
import 'package:enforcer_app/widgets/text_widget.dart';
import 'package:enforcer_app/widgets/textfield_widget.dart';
import 'package:enforcer_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    // TODO: implement initState

    getUserData();
    super.initState();
  }

  bool hasLoaded = false;
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) {
                  return false;
                },
              );
            },
            icon: const Icon(
              Icons.arrow_back,
            ),
          ),
          title: TextWidget(
            text: 'Profile',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        body: hasLoaded
            ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    enforcerData['avatar'] == null
                        ? const Icon(
                            Icons.account_circle_outlined,
                            size: 150,
                            color: Colors.blue,
                          )
                        : Center(
                            child: CircleAvatar(
                              minRadius: 50,
                              maxRadius: 50,
                              backgroundImage:
                                  NetworkImage(enforcerData['avatar']),
                            ),
                          ),
                    const SizedBox(
                      height: 10,
                    ),
                    const TabBar(
                        labelColor: Colors.blue,
                        indicatorColor: Colors.blue,
                        tabs: [
                          Tab(
                            text: 'Profile',
                          ),
                          Tab(
                            text: 'Password',
                          ),
                        ]),
                    const SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: TabBarView(children: [
                        profileTab(),
                        passwordTab(),
                      ]),
                    )
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  final id = TextEditingController();

  final fname = TextEditingController();

  final mname = TextEditingController();

  final lname = TextEditingController();

  final email = TextEditingController();

  final phone = TextEditingController();

  Widget profileTab() {
    setState(() {
      id.text = enforcerData['employee_id'] ?? ' ';
      fname.text = enforcerData['first_name'] ?? ' ';
      mname.text = enforcerData['middle_name'] ?? ' ';
      lname.text = enforcerData['last_name'] ?? ' ';
      email.text = enforcerData['email'] ?? ' ';
      phone.text = enforcerData['phone'] ?? ' ';
    });
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFieldWidget(label: 'Employee ID', controller: id),
            TextFieldWidget(label: 'First Name', controller: fname),
            TextFieldWidget(label: 'Middle Name', controller: mname),
            TextFieldWidget(label: 'Last Name', controller: lname),
            TextFieldWidget(label: 'Email', controller: email),
            TextFieldWidget(
              label: 'Phone',
              controller: phone,
              inputType: TextInputType.number,
            ),
            const SizedBox(
              height: 10,
            ),
            ButtonWidget(
              label: 'Save',
              onPressed: () {
                updateProfile({
                  "employee_id": id.text,
                  "first_name": fname.text,
                  "middle_name": mname.text,
                  "last_name": lname.text,
                  "phone": phone.text,
                  "roles": ["ENFORCER"]
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  final currentPassword = TextEditingController();

  final newPassword = TextEditingController();

  final confirmPassword = TextEditingController();

  Widget passwordTab() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFieldWidget(
                showEye: true,
                isObscure: true,
                label: 'Current Password',
                controller: currentPassword),
            TextFieldWidget(
              label: 'New Password',
              controller: newPassword,
              showEye: true,
              isObscure: true,
            ),
            TextFieldWidget(
                showEye: true,
                isObscure: true,
                label: 'Confirm Password',
                controller: confirmPassword),
            const SizedBox(
              height: 10,
            ),
            ButtonWidget(
              label: 'Submit',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateProfile(Map body) async {
    final token = box.read('token');
    final url = Uri.parse('${ApiEndpoints.baseUrl}users/3');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token', // Add 'Bearer' prefix
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      showToast('The User was succesfully updated.');
      getUserData();
    } else {
      showToast(jsonDecode(response.body)['message']);
    }
  }

  final box = GetStorage();

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

        id.text = data['employee_id'] ?? ' ';
        fname.text = data['first_name'] ?? ' ';
        mname.text = data['middle_name'] ?? ' ';
        lname.text = data['last_name'] ?? ' ';
        email.text = data['email'] ?? ' ';
        phone.text = data['phone'] ?? ' ';

        hasLoaded = true;
      });
    } else {
      print('Failed to retrieve user data: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }
}
