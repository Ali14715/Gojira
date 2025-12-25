import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'auth_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  bool _loading = false;
  bool _editing = false;
  Map<String, dynamic>? _profileData;

  @override
  Widget build(BuildContext context) {
    // If somehow reached while not logged in, send back to AuthWrapper.
    if (_authService.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            onPressed: () {
              setState(() {
                _editing = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.orange),
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthWrapper()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _authService.getProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load profile'));
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists ||
              snapshot.data!.data() == null) {
            return const Center(child: Text('Profile not found'));
          }

          final data = snapshot.data!.data()!;

          // Simpan data awal hanya sekali untuk sinkronisasi dengan controller
          _profileData ??= Map<String, dynamic>.from(data);

          void syncControllersFromProfile() {
            final src = _profileData!;
            _nameCtrl.text = (src['name'] ?? '') as String;
            _phoneCtrl.text = (src['phone'] ?? '') as String;
            _imageUrlCtrl.text = (src['imageUrl'] ?? '') as String;
            if (src['birthDate'] != null) {
              _birthDate = DateTime.tryParse(src['birthDate'] as String);
            } else {
              _birthDate = null;
            }
            _gender = src['gender'] as String?;
          }

          // Jika controller belum sinkron dengan _profileData (pertama kali buka
          // atau setelah cancel), lakukan sinkronisasi.
          if (_nameCtrl.text.isEmpty &&
              _phoneCtrl.text.isEmpty &&
              _imageUrlCtrl.text.isEmpty &&
              _birthDate == null &&
              _gender == null) {
            syncControllersFromProfile();
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: (_imageUrlCtrl.text.isNotEmpty)
                        ? NetworkImage(_imageUrlCtrl.text)
                        : null,
                    child: _imageUrlCtrl.text.isEmpty
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    data['email'],
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: _nameCtrl,
                    readOnly: !_editing,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    readOnly: !_editing,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Birth date picker
                  InkWell(
                    onTap: !_editing
                        ? null
                        : () async {
                            final now = DateTime.now();
                            final initial =
                                _birthDate ?? DateTime(now.year - 20);
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initial,
                              firstDate: DateTime(1900),
                              lastDate: now,
                            );
                            if (picked != null) {
                              setState(() => _birthDate = picked);
                            }
                          },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Lahir',
                        border: OutlineInputBorder(),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _birthDate == null
                              ? 'Pilih tanggal lahir'
                              : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_editing)
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kelamin',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('Laki-laki'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Perempuan'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Lainnya'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _gender = value);
                      },
                    )
                  else
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kelamin',
                        border: OutlineInputBorder(),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _gender == 'male'
                              ? 'Laki-laki'
                              : _gender == 'female'
                              ? 'Perempuan'
                              : _gender == 'other'
                              ? 'Lainnya'
                              : '-',
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  if (_editing)
                    TextField(
                      controller: _imageUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (Foto Profil)',
                        border: OutlineInputBorder(),
                      ),
                    ),

                  const SizedBox(height: 24),

                  if (_editing)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    // Kembalikan nilai controller ke data terakhir
                                    if (_profileData != null) {
                                      _nameCtrl.text =
                                          (_profileData!['name'] ?? '')
                                              as String;
                                      _phoneCtrl.text =
                                          (_profileData!['phone'] ?? '')
                                              as String;
                                      _imageUrlCtrl.text =
                                          (_profileData!['imageUrl'] ?? '')
                                              as String;
                                      if (_profileData!['birthDate'] != null) {
                                        _birthDate = DateTime.tryParse(
                                          _profileData!['birthDate'] as String,
                                        );
                                      } else {
                                        _birthDate = null;
                                      }
                                      _gender =
                                          _profileData!['gender'] as String?;
                                    }
                                    setState(() {
                                      _editing = false;
                                    });
                                  },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () async {
                                    setState(() => _loading = true);
                                    await _authService.updateName(
                                      name: _nameCtrl.text,
                                      phone: _phoneCtrl.text.isEmpty
                                          ? null
                                          : _phoneCtrl.text,
                                      imageUrl: _imageUrlCtrl.text.isEmpty
                                          ? null
                                          : _imageUrlCtrl.text,
                                      birthDate: _birthDate,
                                      gender: _gender,
                                    );

                                    // Simpan perubahan ke _profileData
                                    _profileData ??= {};
                                    _profileData!['name'] = _nameCtrl.text;
                                    _profileData!['phone'] = _phoneCtrl.text;
                                    _profileData!['imageUrl'] =
                                        _imageUrlCtrl.text;
                                    _profileData!['birthDate'] = _birthDate
                                        ?.toIso8601String();
                                    _profileData!['gender'] = _gender;

                                    setState(() {
                                      _loading = false;
                                      _editing = false;
                                    });

                                    _showProfileDialog(
                                      context,
                                      message: 'Profile updated',
                                    );
                                  },
                            child: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showProfileDialog(
    BuildContext dialogContext, {
    required String message,
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
          backgroundColor: Colors.green[50],
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 40),
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
}
