import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_api.dart';

class DashboardController
    extends ChangeNotifier {

  UserModel? user;

  bool isLoading = false;

  String? errorMessage;

  // ============================================================
  // FETCH LOGGED-IN USER
  // ============================================================

  Future<void> fetchUserDetails() async {

    isLoading = true;

    errorMessage = null;

    notifyListeners();

    try {

      final response =
          await AuthApi.getUserDetails();

      if (response['success'] == true) {

        final userData =
            response['user'];

        if (userData != null) {

          user = UserModel.fromJson(
            Map<String, dynamic>.from(
              userData,
            ),
          );
        }

      } else {
        final fallbackEmployerCode =
            await AuthApi.readStoredEmployerCode();

        if (fallbackEmployerCode != null &&
            fallbackEmployerCode.isNotEmpty) {
          user = UserModel(
            id: '',
            firstName: '',
            lastName: '',
            employerCode: fallbackEmployerCode,
            email: '',
            phone: '',
            isEmailVerified: false,
            isLogIn: true,
          );
        }

        errorMessage =
            response['message'] ??
                'Unable to load user details.';
      }

    } catch (e) {

      errorMessage =
          'Something went wrong.';
    }

    isLoading = false;

    notifyListeners();
  }
}