import 'package:flutter/material.dart';

import '../utlis/colors.dart';

class AddTicketScreen extends StatelessWidget {
  const AddTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: primary,
      ),
    );
  }
}
