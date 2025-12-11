import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/colors.dart';
import '../../../services/users/user_profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentBio;
  final String? currentPhotoUrl;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentBio,
    this.currentPhotoUrl,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _bioController;

  File? _selectedImage;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.currentBio);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Optimizar
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    // Ya no validamos el nombre porque no es editable

    setState(() => _isSaving = true);

    try {
      await UserProfileService.updateProfile(
        name: widget
            .currentName, // Pasamos el original sin cambios solo por cumplir con la firma si fuera necesario
        bio: _bioController.text.trim(),
        imageFile: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retornar true para recargar
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.upsYellow,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.upsYellow),
              onPressed: _saveProfile,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ==================
            // SECCIÓN DE AVATAR
            // ==================
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _getAvatarImage(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.upsBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _pickImage,
              child: const Text(
                'Cambiar foto de perfil',
                style: TextStyle(color: AppColors.upsBlue, fontSize: 16),
              ),
            ),

            const SizedBox(height: 32),

            // ==================
            // FORMULARIO
            // ==================

            // Campo Estado (Bio)
            _buildTextField(
              controller: _bioController,
              label: 'Estado',
              icon: Icons.chat_bubble_outline,
              maxLength: 60, // Corto para el estilo "Note"
              helperText: 'Este mensaje aparecerá junto a tu foto de perfil.',
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getAvatarImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }
    if (widget.currentPhotoUrl != null && widget.currentPhotoUrl!.isNotEmpty) {
      return NetworkImage(widget.currentPhotoUrl!);
    }
    // Fallback UI Avatar
    return NetworkImage(
      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.currentName)}&background=333&color=fff',
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLength,
    String? helperText,
    bool readOnly = false, // Parámetro opcional
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          readOnly: readOnly, // Aplicamos readOnly
          style: TextStyle(
            color: readOnly
                ? Colors.white38
                : Colors.white, // Color gris si está bloqueado
            fontSize: 16,
          ),
          decoration: InputDecoration(
            helperText: helperText,
            helperStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: readOnly ? Colors.white24 : AppColors.upsBlue,
              ), // Borde gris si bloqueado
            ),
            fillColor: Colors.white.withOpacity(0.05),
            filled: true,
            counterStyle: const TextStyle(color: Colors.white24),
          ),
        ),
      ],
    );
  }
}
