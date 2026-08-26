import 'package:flutter/material.dart';

import 'create_sequence_form.dart';

// ============================================================
// CREATE SEQUENCE SCREEN
// ============================================================

class CreateSequenceScreen extends StatelessWidget {
  const CreateSequenceScreen({
    super.key,
    this.sequence,
  });

  final Map<String, dynamic>? sequence;

  bool get isEditing => sequence != null;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color background = Color(0xFF020507);

  static const Color appBarColor = Color(0xFF020507);

  static const Color borderColor = Color(0xFF20242B);

  static const Color gold = Color(0xFFFFC629);

  static const Color white = Colors.white;

  static const Color mutedText = Color(0xFF9298A3);

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: appBarColor,
        surfaceTintColor: appBarColor,

        elevation: 0,

        automaticallyImplyLeading: false,

        toolbarHeight: 84,

        titleSpacing: 18,

        title: Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(30),
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF9CA3AF),
                  size: 28,
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEditing
                        ? 'Edit Sequence'
                        : 'Create Sequence',
                    style: const TextStyle(
                      color: white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    isEditing
                        ? 'Update your automated email campaign'
                        : 'Build your automated email campaign',
                    style: const TextStyle(
                      color: mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        top: false,
        child: CreateSequenceForm(
          sequence: sequence,
        ),
      ),
    );
  }
}
