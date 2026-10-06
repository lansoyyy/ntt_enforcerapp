import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:enforcer_app/network/endpoints.dart';
import 'package:enforcer_app/screens/add_ticket_screen.dart';
import 'package:enforcer_app/screens/auth/login_screen.dart';
import 'package:enforcer_app/screens/notif_screen.dart';
import 'package:enforcer_app/screens/profile_screen.dart';
import 'package:enforcer_app/services/app_lock_controller.dart';
import 'package:enforcer_app/services/restriction_service.dart';
import 'package:enforcer_app/services/transaction_image_service.dart';
import 'package:enforcer_app/utils/colors.dart';
import 'package:enforcer_app/widgets/button_widget.dart';
import 'package:enforcer_app/widgets/date_picker_widget.dart';
import 'package:enforcer_app/widgets/logout_widget.dart';
import 'package:enforcer_app/widgets/restriction_dialog.dart';
import 'package:enforcer_app/widgets/text_widget.dart';
import 'package:enforcer_app/widgets/textfield_widget.dart';
import 'package:enforcer_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/sunmi_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  DateTime selectedDate = DateTime.now();

  final ImagePicker _imagePicker = ImagePicker();

  final fname = TextEditingController();
  final lname = TextEditingController();

  final address = TextEditingController();
  final license = TextEditingController();

  final plateno = TextEditingController();
  final owner = TextEditingController();
  final owneraddress = TextEditingController();

  final vehicletype = TextEditingController();

  final dob = TextEditingController();

  String? ticketQrCode;

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
      box.write('lgu_id', data['lgu']['id']);
      if (data['location_id'] != null) {
        box.write('location_id', data['location_id']);
      } else {
        box.remove('location_id');
      }

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

  RestrictionCheckResult? _restrictionCheck;
  bool _checkingRestriction = false;
  Timer? _restrictionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getUserData();
    getTicket();
    _refreshRestrictionStatus();
    _restrictionTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _refreshRestrictionStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restrictionTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshRestrictionStatus();
    }
  }

  Future<void> _refreshRestrictionStatus({bool requestPermission = false}) async {
    if (_checkingRestriction) return;

    setState(() {
      _checkingRestriction = true;
    });

    final result = await RestrictionService(
      requestPermission: requestPermission,
    ).check();

    if (!mounted) return;

    setState(() {
      _restrictionCheck = result;
      _checkingRestriction = false;
    });
  }

  Widget _buildRestrictionBanner() {
    final check = _restrictionCheck;

    final Color background;
    final Color border;
    final IconData icon;

    if (check == null || _checkingRestriction) {
      background = Colors.grey[100]!;
      border = Colors.grey[300]!;
      icon = Icons.location_searching;
    } else if (check.isAllowed) {
      background = Colors.green[50]!;
      border = Colors.green[200]!;
      icon = Icons.location_on;
    } else {
      background = Colors.red[50]!;
      border = Colors.red[200]!;
      icon = Icons.location_off;
    }

    final String text;
    if (check == null) {
      text = 'Verifying your assigned area...';
    } else if (check.isAllowed) {
      text = 'Within assigned area: ${check.restriction.area.name}';
    } else {
      text = check.message;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: InkWell(
        onTap: _checkingRestriction
            ? null
            : () async {
                final result = await runEnforcementRestrictionCheck(context);
                if (!mounted) return;
                setState(() {
                  _restrictionCheck = result;
                });
              },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: check?.isAllowed == true ? Colors.green : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'QRegular',
                    fontSize: 12,
                  ),
                ),
              ),
              if (_checkingRestriction)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.refresh,
                  size: 18,
                  color: Colors.grey[700],
                ),
            ],
          ),
        ),
      ),
    );
  }

  SunmiService printer = SunmiService();

  @override
  Widget build(BuildContext context) {
    final canCreateTicket = _restrictionCheck?.isAllowed ?? false;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: canCreateTicket ? primary : Colors.grey,
        onPressed: canCreateTicket
            ? () async {
                final allowed =
                    await ensureWithinEnforcementRestriction(context);
                if (!context.mounted) return;

                if (!allowed) {
                  _refreshRestrictionStatus();
                  return;
                }

                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const AddTicketScreen()),
                );
              }
            : null,
        child: Icon(
          canCreateTicket ? Icons.add : Icons.lock_outline,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildRestrictionBanner(),
        ),
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

    final url = Uri.parse('${ApiEndpoints.baseUrl}tickets/$id');

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
        ticketQrCode = data['ticket']['qr_code']?.toString();
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

    await getLicense(numberString);

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
      dob.text = data['driver_date_of_birth'] ?? '';
    });

    List<dynamic> transactionImages = [];
    try {
      transactionImages = await TransactionImageService().getImages(
        transactionId: numberString,
        type: 'violation',
      );
    } catch (e) {
      transactionImages = [];
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          Uint8List? imageBytes;
          int? currentImageId;

          if (transactionImages.isNotEmpty) {
            final latest = transactionImages.last;
            currentImageId = latest['id'] is int
                ? latest['id']
                : int.tryParse(latest['id']?.toString() ?? '');

            try {
              final base64 = (latest['base64'] ?? '').toString();
              if (base64.isNotEmpty) {
                imageBytes =
                    TransactionImageService.base64DataUriToBytes(base64);
              }
            } catch (e) {
              imageBytes = null;
            }
          }

          Future<void> refreshImages() async {
            try {
              final images = await TransactionImageService().getImages(
                transactionId: numberString,
                type: 'violation',
              );
              transactionImages = images;
            } catch (e) {
              transactionImages = [];
            }
            setDialogState(() {});
          }

          Future<void> replacePhoto() async {
            AppLockController.instance.suppressNextLock();

            XFile? photo;
            try {
              photo = await _imagePicker.pickImage(
                source: ImageSource.camera,
                imageQuality: 85,
              );
            } finally {
              AppLockController.instance.releaseLockSuppression();
            }

            if (photo == null) return;

            try {
              for (final imgItem in transactionImages) {
                final int? id = imgItem['id'] is int
                    ? imgItem['id']
                    : int.tryParse(imgItem['id']?.toString() ?? '');
                if (id != null) {
                  await TransactionImageService().deleteImage(id);
                }
              }

              final base64 =
                  await TransactionImageService.fileToResizedBase64DataUri(
                photo.path,
              );

              await TransactionImageService().createImage(
                transactionId: numberString,
                type: 'violation',
                base64: base64,
              );

              await refreshImages();
              showToast(context, 'Vehicle photo updated');
            } catch (e) {
              showToast(context, 'Failed to update vehicle photo');
            }
          }

          Future<void> deletePhoto() async {
            if (currentImageId == null) return;

            try {
              for (final imgItem in transactionImages) {
                final int? id = imgItem['id'] is int
                    ? imgItem['id']
                    : int.tryParse(imgItem['id']?.toString() ?? '');
                if (id != null) {
                  await TransactionImageService().deleteImage(id);
                }
              }
              await refreshImages();
              showToast(context, 'Vehicle photo deleted');
            } catch (e) {
              showToast(context, 'Failed to delete vehicle photo');
            }
          }

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
                      text: 'Vehicle Photo',
                      fontSize: 18,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (imageBytes == null)
                      TextWidget(
                        text: 'No vehicle photo uploaded',
                        fontSize: 14,
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          imageBytes,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ButtonWidget(
                            width: double.infinity,
                            height: 45,
                            label: imageBytes == null
                                ? 'Add Photo'
                                : 'Replace Photo',
                            onPressed: replacePhoto,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: ButtonWidget(
                            width: double.infinity,
                            height: 45,
                            label: 'Delete Photo',
                            onPressed: imageBytes == null ? () {} : deletePhoto,
                            color: Colors.red,
                          ),
                        ),
                      ],
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
                                    mainAxisAlignment: MainAxisAlignment.start,
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
                              data['date_issued'].toString(),
                              dob.text,
                              qrCode: ticketQrCode);
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
        });
      },
    );
  }
}
