import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/feedback/glam_toast.dart';
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
        name: widget.currentName, // Pasamos el original sin cambios
        bio: _bioController.text.trim(),
        imageFile: _selectedImage,
      );

      if (mounted) {
        GlamToast.showSuccess(context, 'Perfil actualizado correctamente');
        Navigator.of(context).pop(true); // Retornar true para recargar
      }
    } catch (e) {
      if (mounted) {
        GlamToast.showError(context, 'Error al actualizar: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 20.0),
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
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: AppColors.upsYellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Fondo Base (Gradiente Oscuro)
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.darkBackground,
            ),
          ),

          // 2. Efecto Vidrio Global (Sutil)
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),

          // 3. Contenido Central
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- AVATAR EDITABLE ---
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Círculo de brillo exterior
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.upsBlue.withOpacity(0.4),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        // Avatar
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 4,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: AppColors.cardBackground,
                            backgroundImage: _getAvatarImage(),
                          ),
                        ),
                        // Overlay de "Editar"
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white70,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Toca para cambiar foto',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),

                  const SizedBox(height: 48),

                  // --- ESTADO (BIO) EDITABLE ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.glassWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.glassBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'ESTADO',
                          style: TextStyle(
                            color: AppColors.upsYellow, // Resaltar título
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _bioController,
                          maxLength: 60,
                          textAlign: TextAlign.center,
                          minLines: 1,
                          maxLines: 4, // Permitir crecimiento vertical
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Escribe algo sobre ti...',
                            hintStyle: TextStyle(color: Colors.white24),
                            border: InputBorder.none,
                            counterText:
                                '', // Ocultar contador por limpieza visual
                            isDense: true,
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 30),
                        Text(
                          '${_bioController.text.length} / 60',
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
}
