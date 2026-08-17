import 'package:flutter/material.dart';

import 'create_sequence_form.dart';

class CreateSequenceScreen extends StatelessWidget {
  const CreateSequenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF101828),
        ),
        title: const Text(
          'Create Sequence',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: const SafeArea(
        child: CreateSequenceForm(),
      ),
    );
  }
}