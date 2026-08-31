import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:high_custom_frontend/widgets/app_feedback.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/integration_api.dart';
import '../../widgets/app_skeleton.dart';

class IntegrationScreen extends StatefulWidget {
  const IntegrationScreen({
    super.key,
  });

  @override
  State<IntegrationScreen> createState() =>
      _IntegrationScreenState();
}

class _IntegrationScreenState
    extends State<IntegrationScreen>
    with WidgetsBindingObserver {
  // ============================================================
  // APP LINKS
  // ============================================================

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _appLinkSubscription;

  bool _appLinksInitialized = false;

  // ============================================================
  // GMAIL
  // ============================================================

  bool isGmailConnected = false;

  String? gmailEmail;

  DateTime? gmailConnectedAt;

  bool isGmailLoading = false;

  // ============================================================
  // ZOHO
  // ============================================================

  bool isZohoConnected = false;

  String? zohoEmail;

  DateTime? zohoConnectedAt;

  bool isZohoLoading = false;

  // ============================================================
  // PAGE LOADING
  // ============================================================

  bool isLoadingStatus = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initializeAppLinks();

    // IMPORTANT:
    // Do not use the old logic that returned immediately
    // because isLoadingStatus was already true.
    _loadIntegrationStatus();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _appLinkSubscription?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint(
        'Flutter application resumed.',
      );

      if (!mounted) {
        return;
      }

      _loadIntegrationStatus(
        showLoader: false,
      );
    }
  }

  // ============================================================
  // APP LINKS INITIALIZATION
  // ============================================================

  Future<void> _initializeAppLinks() async {
    if (_appLinksInitialized) {
      return;
    }

    _appLinksInitialized = true;

    try {
      // --------------------------------------------------------
      // INITIAL LINK
      // --------------------------------------------------------

      final Uri? initialUri =
          await _appLinks.getInitialLink();

      if (initialUri != null) {
        debugPrint(
          'Initial App Link: $initialUri',
        );

        await _handleAppLink(
          initialUri,
        );
      }

      // --------------------------------------------------------
      // STREAM
      // --------------------------------------------------------

      _appLinkSubscription =
          _appLinks.uriLinkStream.listen(
        (Uri uri) async {
          debugPrint(
            'Received App Link: $uri',
          );

          if (!mounted) {
            return;
          }

          await _handleAppLink(
            uri,
          );
        },
        onError: (error) {
          debugPrint(
            'App Link Error: $error',
          );
        },
      );
    } catch (error) {
      debugPrint(
        'App Link Initialization Error: $error',
      );
    }
  }

  // ============================================================
  // HANDLE APP LINK
  // ============================================================

  Future<void> _handleAppLink(
    Uri uri,
  ) async {
    debugPrint(
      '======================================',
    );

    debugPrint('INTEGRATION CALLBACK RECEIVED');

    debugPrint(
      'URI: $uri',
    );

    debugPrint(
      'SCHEME: ${uri.scheme}',
    );

    debugPrint(
      'HOST: ${uri.host}',
    );

    debugPrint(
      'PARAMETERS: ${uri.queryParameters}',
    );

    debugPrint(
      '======================================',
    );

    // ----------------------------------------------------------
    // CHECK SCHEME
    // ----------------------------------------------------------

    if (uri.scheme != 'highcustom') {
      debugPrint(
        'Wrong deep-link scheme.',
      );

      return;
    }

    // ----------------------------------------------------------
    // CHECK HOST
    // ----------------------------------------------------------

    if (uri.host != 'integration') {
      debugPrint(
        'Wrong deep-link host.',
      );

      return;
    }

    // ----------------------------------------------------------
    // PARAMETERS
    // ----------------------------------------------------------

    final success =
        uri.queryParameters['success'];

    final email =
        uri.queryParameters['email'];

    final error =
        uri.queryParameters['error'];

    final provider =
        uri.queryParameters['provider'] ?? 'gmail';

    debugPrint(
      'Success: $success',
    );

    debugPrint(
      'Email: $email',
    );

    debugPrint(
      'Error: $error',
    );

    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

    if (success == 'true') {
      if (!mounted) {
        return;
      }

      setState(() {
        if (provider == 'zoho') {
          isZohoConnected = true;
          zohoEmail = email;
        } else {
          isGmailConnected = true;
          if (email != null && email.trim().isNotEmpty) {
            gmailEmail = email;
          }
        }
      });

      _showMessage(
        provider == 'zoho'
            ? 'Zoho Mail connected successfully.'
            : 'Gmail connected successfully.',
      );

      if (provider == 'zoho') {
        await _getZohoStatus();
      } else {
        await _getGmailStatus();
      }

      return;
    }

    // ----------------------------------------------------------
    // FAILURE
    // ----------------------------------------------------------

    if (success == 'false') {
      final errorText =
          _friendlyOAuthError(
        error,
      );

      if (mounted) {
        _showMessage(
          errorText,
        );
      }

      if (provider == 'zoho') {
        await _getZohoStatus();
      } else {
        await _getGmailStatus();
      }
    }
  }

  // ============================================================
  // OAUTH ERROR MESSAGE
  // ============================================================

  String _friendlyOAuthError(
    String? error,
  ) {
    switch (error) {
      case 'cancelled':
        return 'Google authorization was cancelled.';

      case 'no_code':
        return 'Google authorization code was not received.';

      case 'no_state':
        return 'OAuth state was not received.';

      case 'invalid_state':
        return 'OAuth session expired. Please try again.';

      case 'no_user':
        return 'User information was not found.';

      case 'no_email':
        return 'Google account email was not received.';

      case 'no_access_token':
        return 'Google access token was not received.';

      case 'no_refresh_token':
        return 'Google refresh token was not received.';

      default:
        return 'Gmail connection failed. Please try again.';
    }
  }

  // ============================================================
  // LOAD STATUS
  // ============================================================

  Future<void> _loadIntegrationStatus({
    bool showLoader = true,
  }) async {
    // ----------------------------------------------------------
    // SHOW LOADER
    // ----------------------------------------------------------

    if (showLoader && mounted) {
      setState(() {
        isLoadingStatus = true;
      });
    }

    try {
      await Future.wait([
        _getGmailStatus(),
        _getZohoStatus(),
      ]);
    } catch (error) {
      debugPrint(
        'Integration Status Error: $error',
      );
    } finally {
      // --------------------------------------------------------
      // ALWAYS STOP LOADER
      // --------------------------------------------------------

      if (mounted) {
        setState(() {
          isLoadingStatus = false;
        });
      }
    }
  }

  Future<void> _getZohoStatus() async {
    try {
      final data = await IntegrationApi.zohoStatus();
      if (!mounted) return;
      if (data['success'] != true) {
        setState(() {
          isZohoConnected = false;
          zohoEmail = null;
          zohoConnectedAt = null;
        });
        return;
      }
      final connected = data['connected'] == true;
      setState(() {
        isZohoConnected = connected;
        zohoEmail = connected ? data['email']?.toString() : null;
        zohoConnectedAt = connected && data['connectedAt'] != null
            ? DateTime.tryParse(data['connectedAt'].toString())
            : null;
      });
    } catch (error) {
      debugPrint('Zoho Status Error: $error');
      if (!mounted) return;
      setState(() {
        isZohoConnected = false;
        zohoEmail = null;
        zohoConnectedAt = null;
      });
    }
  }

  // ============================================================
  // GET GMAIL STATUS
  // ============================================================

  Future<void> _getGmailStatus() async {
    try {
      final data =
          await IntegrationApi.gmailStatus();

      debugPrint(
        'Gmail Status Response: $data',
      );

      final statusCode =
          data['statusCode'];

      // --------------------------------------------------------
      // AUTH ERROR
      // --------------------------------------------------------

      if (statusCode == 401) {
        if (!mounted) {
          return;
        }

        setState(() {
          isGmailConnected = false;
          gmailEmail = null;
          gmailConnectedAt = null;
        });

        _showMessage(
          'Session expired. Please login again.',
        );

        return;
      }

      // --------------------------------------------------------
      // API ERROR
      // --------------------------------------------------------

      if (data['success'] != true) {
        debugPrint(
          'Gmail status failed: ${data['message']}',
        );

        if (mounted) {
          setState(() {
            isGmailConnected = false;
            gmailEmail = null;
            gmailConnectedAt = null;
          });
        }

        return;
      }

      // --------------------------------------------------------
      // UPDATE UI
      // --------------------------------------------------------

      if (!mounted) {
        return;
      }

      final connected =
          data['connected'] == true;

      DateTime? connectedAt;

      if (data['connectedAt'] != null) {
        connectedAt =
            DateTime.tryParse(
          data['connectedAt'].toString(),
        );
      }

      setState(() {
        isGmailConnected = connected;

        gmailEmail =
            connected
                ? data['email']?.toString()
                : null;

        gmailConnectedAt =
            connectedAt;
      });
    } catch (error) {
      debugPrint(
        'Gmail Status Error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isGmailConnected = false;
        gmailEmail = null;
        gmailConnectedAt = null;
      });
    }
  }

  // ============================================================
  // CONNECT GMAIL
  // ============================================================

  Future<void> _connectGmail() async {
    if (isGmailLoading) {
      return;
    }

    if (mounted) {
      setState(() {
        isGmailLoading = true;
      });
    }

    try {
      final data =
          await IntegrationApi.connectGmail();

      debugPrint(
        'Gmail Connect Response: $data',
      );

      if (data['statusCode'] == 401) {
        _showMessage(
          'Session expired. Please login again.',
        );

        return;
      }

      if (data['success'] != true) {
        _showMessage(
          data['message']?.toString() ??
              'Failed to connect Gmail.',
        );

        return;
      }

      final authUrl =
          data['authUrl']?.toString();

      if (authUrl == null ||
          authUrl.trim().isEmpty) {
        _showMessage(
          'Google authorization URL was not received.',
        );

        return;
      }

      final googleUri =
          Uri.parse(authUrl);

      final canOpen =
          await canLaunchUrl(
        googleUri,
      );

      if (!canOpen) {
        _showMessage(
          'Unable to open Google authorization.',
        );

        return;
      }

      await launchUrl(
        googleUri,
        mode: LaunchMode.externalApplication,
      );

      _showMessage(
        'Complete Gmail authorization in your browser.',
      );
    } catch (error) {
      debugPrint(
        'Connect Gmail Error: $error',
      );

      _showMessage(
        'Unable to connect Gmail.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isGmailLoading = false;
        });
      }
    }
  }

  // ============================================================
  // DISCONNECT GMAIL
  // ============================================================

  Future<void> _disconnectGmail() async {
    _showDisconnectDialog(
      serviceName: 'Gmail',
      onConfirm: _performDisconnectGmail,
    );
  }

  // ============================================================
  // PERFORM DISCONNECT GMAIL
  // ============================================================

  Future<void> _performDisconnectGmail() async {
    if (isGmailLoading) {
      return;
    }

    if (mounted) {
      setState(() {
        isGmailLoading = true;
      });
    }

    try {
      final data =
          await IntegrationApi.disconnectGmail();

      debugPrint(
        'Gmail Disconnect Response: $data',
      );

      if (data['statusCode'] == 401) {
        _showMessage(
          'Session expired. Please login again.',
        );

        return;
      }

      if (data['success'] != true) {
        _showMessage(
          data['message']?.toString() ??
              'Failed to disconnect Gmail.',
        );

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isGmailConnected = false;
        gmailEmail = null;
        gmailConnectedAt = null;
      });

      _showMessage(
        'Gmail disconnected successfully.',
      );
    } catch (error) {
      debugPrint(
        'Disconnect Gmail Error: $error',
      );

      _showMessage(
        'Failed to disconnect Gmail.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isGmailLoading = false;
        });
      }
    }
  }

  // ============================================================
  // CONNECT ZOHO
  // ============================================================

  Future<void> _connectZoho() async {
    if (isZohoLoading) {
      return;
    }

    if (mounted) setState(() => isZohoLoading = true);
    try {
      final data = await IntegrationApi.connectZoho();
      if (data['success'] != true) {
        _showMessage(data['message']?.toString() ?? 'Failed to connect Zoho Mail.');
        return;
      }
      final authUrl = data['authUrl']?.toString();
      if (authUrl == null || authUrl.isEmpty) {
        _showMessage('Zoho authorization URL was not received.');
        return;
      }
      final uri = Uri.parse(authUrl);
      if (!await canLaunchUrl(uri)) {
        _showMessage('Unable to open Zoho authorization.');
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _showMessage('Complete Zoho authorization in your browser.');
    } catch (error) {
      debugPrint('Connect Zoho Error: $error');
      _showMessage('Unable to connect Zoho Mail.');
    } finally {
      if (mounted) setState(() => isZohoLoading = false);
    }
  }

  // ============================================================
  // DISCONNECT ZOHO
  // ============================================================

  Future<void> _disconnectZoho() async {
    _showDisconnectDialog(
      serviceName: 'Zoho Mail',
      onConfirm: _performDisconnectZoho,
    );
  }

  Future<void> _performDisconnectZoho() async {
    if (isZohoLoading) return;
    if (mounted) setState(() => isZohoLoading = true);
    try {
      final data = await IntegrationApi.disconnectZoho();
      if (data['success'] != true) {
        _showMessage(data['message']?.toString() ?? 'Failed to disconnect Zoho Mail.');
        return;
      }
      if (!mounted) return;
      setState(() {
        isZohoConnected = false;
        zohoEmail = null;
        zohoConnectedAt = null;
      });
      _showMessage('Zoho Mail disconnected successfully.');
    } catch (error) {
      _showMessage('Failed to disconnect Zoho Mail.');
    } finally {
      if (mounted) setState(() => isZohoLoading = false);
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    AppFeedback.show(context, message);
  }

  // ============================================================
  // DISCONNECT DIALOG
  // ============================================================

  void _showDisconnectDialog({
    required String serviceName,
    required Future<void> Function()
        onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          title: Text(
            'Disconnect $serviceName?',
            style:
                const TextStyle(
              color:
                  Color(0xFF101828),
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to disconnect your $serviceName account?',
            style:
                const TextStyle(
              color:
                  Color(0xFF667085),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color:
                      Color(0xFF667085),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await onConfirm();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              child:
                  const Text(
                'Disconnect',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final width =
        MediaQuery.of(context).size.width;

    final isMobile =
        width < 700;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color:
          const Color(0xFFF5F7FA),
      child: isLoadingStatus
          ? const AppDashboardSkeleton(light: true)
          : RefreshIndicator(
              onRefresh: () =>
                  _loadIntegrationStatus(),
              child:
                  SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    EdgeInsets.symmetric(
                  horizontal:
                      isMobile
                          ? 20
                          : 32,
                  vertical:
                      isMobile
                          ? 24
                          : 30,
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(
                      isMobile:
                          isMobile,
                    ),

                    SizedBox(
                      height:
                          isMobile
                              ? 28
                              : 36,
                    ),

                    const Text(
                      'Available Integrations',
                      style:
                          TextStyle(
                        color:
                            Color(0xFF101828),
                        fontSize:
                            22,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    const Text(
                      'Connect services that you use with your application.',
                      style:
                          TextStyle(
                        color:
                            Color(0xFF667085),
                        fontSize:
                            14,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ==================================================
                    // GMAIL
                    // ==================================================

                    _buildIntegrationCard(
                      isMobile:
                          isMobile,
                      name:
                          'Gmail',
                      description:
                          'Connect your Gmail account to send emails directly from your application.',
                      logoIcon:
                          SimpleIcons.google,
                      logoColor:
                          SimpleIconColors.google,
                      isConnected:
                          isGmailConnected,
                      connectedEmail:
                          gmailEmail,
                      isLoading:
                          isGmailLoading,
                      onConnect:
                          _connectGmail,
                      onDisconnect:
                          _disconnectGmail,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // ZOHO
                    // ==================================================

                    _buildIntegrationCard(
                      isMobile:
                          isMobile,
                      name:
                          'Zoho Mail',
                      description:
                          'Connect your Zoho Mail account to send emails directly from your application.',
                      logoIcon:
                          SimpleIcons.zoho,
                      logoColor:
                          SimpleIconColors.zoho,
                      isConnected:
                          isZohoConnected,
                      connectedEmail:
                          zohoEmail,
                      isLoading:
                          isZohoLoading,
                      onConnect:
                          _connectZoho,
                      onDisconnect:
                          _disconnectZoho,
                    ),

                    const SizedBox(
                      height: 30,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader({
    required bool isMobile,
  }) {
    return Row(
      children: [
        Container(
          width:
              isMobile ? 54 : 60,
          height:
              isMobile ? 54 : 60,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFEFF4FF),
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          child: Icon(
            Icons
                .integration_instructions_outlined,
            color:
                const Color(0xFF315BEF),
            size:
                isMobile
                    ? 27
                    : 30,
          ),
        ),

        const SizedBox(
          width: 15,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Integration',
                style:
                    TextStyle(
                  color:
                      const Color(
                    0xFF101828,
                  ),
                  fontSize:
                      isMobile
                          ? 26
                          : 30,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                'Connect your external services to your account.',
                style:
                    TextStyle(
                  color:
                      const Color(
                    0xFF667085,
                  ),
                  fontSize:
                      isMobile
                          ? 13
                          : 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INTEGRATION CARD
  // ============================================================

  Widget _buildIntegrationCard({
    required bool isMobile,
    required String name,
    required String description,
    required IconData logoIcon,
    required Color logoColor,
    required bool isConnected,
    required String? connectedEmail,
    required bool isLoading,
    required Future<void> Function()
        onConnect,
    required Future<void> Function()
        onDisconnect,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFFE4E7EC,
          ),
          width: 1,
        ),
      ),
      child:
          Column(
        children: [
          // ======================================================
          // TOP SECTION
          // ======================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width:
                    isMobile
                        ? 46
                        : 52,
                height:
                    isMobile
                        ? 46
                        : 52,
                decoration:
                    BoxDecoration(
                  color:
                      logoColor
                          .withAlpha(
                    26,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    Icon(
                  logoIcon,
                  color:
                      logoColor,
                  size:
                      isMobile
                          ? 22
                          : 24,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF101828,
                        ),
                        fontSize:
                            18,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      description,
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF667085,
                        ),
                        fontSize:
                            13,
                        height:
                            1.5,
                      ),
                    ),
                  ],
                ),
              ),

              if (isConnected)
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        10,
                    vertical:
                        6,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFE6F9ED,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      999,
                    ),
                  ),
                  child:
                      const Text(
                    'Connected',
                    style:
                        TextStyle(
                      color:
                          Color(
                        0xFF0C9A5B,
                      ),
                      fontSize:
                          11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          // ======================================================
          // CONNECTED EMAIL
          // ======================================================

          if (isConnected)
            ...[
              const SizedBox(
                height: 16,
              ),

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF8F9FB,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child:
                    Row(
                  children: [
                    Icon(
                      connectedEmail !=
                              null
                          ? Icons
                              .email_outlined
                          : Icons
                              .check_circle_outline,
                      color:
                          const Color(
                        0xFF315BEF,
                      ),
                      size:
                          18,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child:
                          Text(
                        connectedEmail !=
                                    null &&
                                connectedEmail!
                                    .isNotEmpty
                            ? connectedEmail!
                            : 'Connected',
                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xFF101828,
                          ),
                          fontSize:
                              13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

          const SizedBox(
            height: 16,
          ),

          // ======================================================
          // BUTTON
          // ======================================================

          SizedBox(
            width:
                double.infinity,
            height:
                46,
            child:
                isConnected
                    ? ElevatedButton.icon(
                        onPressed:
                            isLoading
                                ? null
                                : onDisconnect,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(
                            0xFFFEF2F2,
                          ),
                          foregroundColor:
                              const Color(
                            0xFFB42318,
                          ),
                          elevation:
                              0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                        icon:
                            isLoading
                                ? const SizedBox(
                                    width:
                                        16,
                                    height:
                                        16,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .link_off_rounded,
                                  ),
                        label:
                            Text(
                          isLoading
                              ? 'Disconnecting...'
                              : 'Disconnect',
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed:
                            isLoading
                                ? null
                                : onConnect,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(
                            0xFF315BEF,
                          ),
                          foregroundColor:
                              Colors.white,
                          elevation:
                              0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                        icon:
                            isLoading
                                ? const SizedBox(
                                    width:
                                        16,
                                    height:
                                        16,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .add_link_rounded,
                                  ),
                        label:
                            Text(
                          isLoading
                              ? 'Connecting...'
                              : 'Connect',
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
