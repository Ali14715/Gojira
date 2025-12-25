import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _authService = AuthService();

  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // Dark/Light mode button (floating, no AppBar)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16, right: 4),
                      child: IconButton(
                        icon: Icon(
                          Theme.of(context).brightness == Brightness.dark
                              ? Icons.wb_sunny_rounded
                              : Icons.dark_mode,
                          color: Colors.orange,
                        ),
                        onPressed: ThemeController.toggleTheme,
                        tooltip: 'Toggle dark/light mode',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // TabBar with shadow and rounded corners
                  Material(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF232323)
                        : const Color(0xFFF5F6F8),
                    elevation: 4,
                    shadowColor: Colors.black12,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: TabBar(
                        controller: _tabController,
                        overlayColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        splashFactory: NoSplash.splashFactory,
                        indicator: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF181818)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        indicatorColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.orange,
                        unselectedLabelColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                        tabs: const [
                          Tab(text: 'Login'),
                          Tab(text: 'Register'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Content
                  SizedBox(
                    height: 420,
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildLogin(),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildRegister(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ======================
  // LOGIN FORM
  // ======================
  Widget _buildLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome Back',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Login untuk melanjutkan',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 24),

        // Email
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _inputField(
            controller: _loginEmailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
          ),
        ),

        // Password + Lupa password
        Stack(
          children: [
            _inputField(
              controller: _loginPassCtrl,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: true,
              contentPadding: const EdgeInsets.only(right: 120),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Lupa password?',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        _authButton(
          text: 'Login',
          onPressed: () async {
            if (_loginEmailCtrl.text.isEmpty || _loginPassCtrl.text.isEmpty) {
              _showAuthDialog(
                context,
                message: 'Email dan password tidak boleh kosong',
                success: false,
              );
              return;
            }

            setState(() => _loading = true);
            try {
              await _authService.login(
                email: _loginEmailCtrl.text.trim(),
                password: _loginPassCtrl.text,
              );
            } on FirebaseAuthException catch (e) {
              // Jika user ternyata sudah dalam keadaan login (session lama),
              // jangan tampilkan error lagi agar tidak membingungkan.
              if (_authService.currentUser != null) {
                return;
              }

              String message;
              switch (e.code) {
                case 'user-not-found':
                  message =
                      'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
                  break;
                case 'wrong-password':
                  message = 'Password salah. Coba lagi.';
                  break;
                case 'invalid-email':
                  message = 'Format email tidak valid.';
                  break;
                default:
                  message = 'Login gagal: ${e.message ?? 'Terjadi kesalahan.'}';
              }

              if (mounted) {
                _showAuthDialog(context, message: message, success: false);
              }
            } catch (e) {
              // Sama seperti di atas: kalau sudah ada user aktif, abaikan error.
              if (_authService.currentUser != null) {
                return;
              }

              if (mounted) {
                _showAuthDialog(
                  context,
                  message:
                      'Login gagal. Periksa koneksi internet dan coba lagi.',
                  success: false,
                );
              }
            } finally {
              if (mounted) {
                setState(() => _loading = false);
              }
            }
          },
        ),
      ],
    );
  }

  // ======================
  // REGISTER FORM
  // ======================
  Widget _buildRegister() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Account',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Daftar akun baru', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 32),

        _inputField(
          controller: _regNameCtrl,
          label: 'Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),

        _inputField(
          controller: _regEmailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),

        _inputField(
          controller: _regPassCtrl,
          label: 'Password',
          icon: Icons.lock_outline,
          obscure: true,
        ),

        const SizedBox(height: 32),

        _authButton(
          text: 'Register',
          onPressed: () async {
            if (_regNameCtrl.text.isEmpty ||
                _regEmailCtrl.text.isEmpty ||
                _regPassCtrl.text.isEmpty) {
              _showAuthDialog(
                context,
                message: 'Semua field registrasi harus diisi',
                success: false,
              );
              return;
            }

            setState(() => _loading = true);
            try {
              await _authService.register(
                name: _regNameCtrl.text.trim(),
                email: _regEmailCtrl.text.trim(),
                password: _regPassCtrl.text,
              );

              // After register, force user to login: switch to Login tab and show message
              _tabController.animateTo(0);
              if (mounted) {
                _showAuthDialog(
                  context,
                  message:
                      'Registrasi berhasil. Silakan login terlebih dahulu.',
                  success: true,
                );
              }
            } on FirebaseAuthException catch (e) {
              String message;
              switch (e.code) {
                case 'email-already-in-use':
                  message = 'Email sudah terdaftar. Silakan login.';
                  break;
                case 'weak-password':
                  message = 'Password terlalu lemah.';
                  break;
                case 'invalid-email':
                  message = 'Format email tidak valid.';
                  break;
                default:
                  message =
                      'Registrasi gagal: ${e.message ?? 'Terjadi kesalahan.'}';
              }

              if (mounted) {
                _showAuthDialog(context, message: message, success: false);
              }
            } catch (e) {
              if (mounted) {
                _showAuthDialog(
                  context,
                  message:
                      'Registrasi gagal. Periksa koneksi internet dan coba lagi.',
                  success: false,
                );
              }
            } finally {
              if (mounted) {
                setState(() => _loading = false);
              }
            }
          },
        ),
      ],
    );
  }

  // ======================
  // AUTH DIALOG TEMPLATE
  // ======================
  void _showAuthDialog(
    BuildContext dialogContext, {
    required String message,
    required bool success,
  }) {
    showDialog(
      context: dialogContext,
      barrierDismissible: true,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: success ? Colors.green[50] : Colors.red[50],
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ======================
  // REUSABLE INPUT
  // ======================
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? hint,
    EdgeInsets? contentPadding,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF181818)
            : Colors.white,
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
      ),
    );
  }

  // ======================
  // BUTTON
  // ======================
  Widget _authButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
