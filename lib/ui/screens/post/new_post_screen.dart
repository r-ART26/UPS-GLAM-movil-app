import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/filters/filter_item.dart';
import '../../widgets/filters/filter_params_panel.dart';
import '../../../services/image/temp_image_service.dart';
import '../../../services/image/image_processing_service.dart';
import '../../../services/posts/post_service.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  File? _originalImage;
  Uint8List? _processedImage;
  String? _currentFilter;
  Map<String, dynamic> _filterParams = {};
  bool _isProcessing = false;
  bool _isPublishing = false;
  bool _showParamsPanel = false;
  String? _errorMessage;

  // Definición de filtros disponibles
  final List<Map<String, dynamic>> _filters = [
    {'name': 'Original', 'icon': Icons.image, 'hasParams': false},
    {'name': 'Canny', 'icon': Icons.auto_fix_high, 'hasParams': true},
    {'name': 'Gaussian', 'icon': Icons.blur_on, 'hasParams': true},
    {'name': 'Negative', 'icon': Icons.invert_colors, 'hasParams': false},
    {'name': 'Emboss', 'icon': Icons.texture, 'hasParams': true},
    {'name': 'Watermark', 'icon': Icons.water_drop, 'hasParams': true},
    {'name': 'Ripple', 'icon': Icons.waves, 'hasParams': true},
    {'name': 'Collage', 'icon': Icons.grid_view, 'hasParams': false},
  ];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  /// Muestra diálogo para seleccionar imagen desde cámara o galería
  Future<void> _selectImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.upsBlueDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Seleccionar imagen',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Tomar foto',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Desde galería',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Guardar imagen original temporalmente
        final tempFile = await TempImageService.saveOriginalImage(file);
        if (tempFile != null) {
          setState(() {
            _originalImage = tempFile;
            _processedImage = null;
            _currentFilter = null;
            _showParamsPanel = false;
            _errorMessage = null;
          });
        } else {
          _showError('Error al guardar la imagen');
        }
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  /// Convierte un valor dinámico a int de forma segura
  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return null;
  }

  /// Convierte un valor dinámico a double de forma segura
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return null;
  }

  /// Aplica un filtro sobre la imagen original
  Future<void> _applyFilter(String filterName, {Map<String, dynamic>? params}) async {
    if (_originalImage == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      Uint8List? result;

      switch (filterName.toLowerCase()) {
        case 'original':
          // Mostrar imagen original sin procesar
          result = await _originalImage!.readAsBytes();
          break;
        case 'canny':
          result = await ImageProcessingService.applyCanny(
            _originalImage!,
            kernelSize: _toInt(params?['kernel_size']),
            sigma: _toDouble(params?['sigma']),
            lowThreshold: params?['low_threshold']?.toString(),
            highThreshold: params?['high_threshold']?.toString(),
            useAuto: params?['use_auto'] as bool?,
          );
          break;
        case 'gaussian':
          result = await ImageProcessingService.applyGaussian(
            _originalImage!,
            kernelSize: _toInt(params?['kernel_size']),
            sigma: _toDouble(params?['sigma']),
            useAuto: params?['use_auto'] as bool?,
          );
          break;
        case 'negative':
          result = await ImageProcessingService.applyNegative(_originalImage!);
          break;
        case 'emboss':
          result = await ImageProcessingService.applyEmboss(
            _originalImage!,
            kernelSize: _toInt(params?['kernel_size']),
            biasValue: _toInt(params?['bias_value']),
            useAuto: params?['use_auto'] as bool?,
          );
          break;
        case 'watermark':
          result = await ImageProcessingService.applyWatermark(
            _originalImage!,
            scale: _toDouble(params?['scale']),
            transparency: _toDouble(params?['transparency']),
            spacing: _toDouble(params?['spacing']),
          );
          break;
        case 'ripple':
          result = await ImageProcessingService.applyRipple(
            _originalImage!,
            edgeThreshold: _toDouble(params?['edge_threshold']),
            colorLevels: _toInt(params?['color_levels']),
            saturation: _toDouble(params?['saturation']),
          );
          break;
        case 'collage':
          result = await ImageProcessingService.applyCollage(_originalImage!);
          break;
        default:
          throw Exception('Filtro no reconocido: $filterName');
      }

      if (!mounted) return;
      
      setState(() {
        _processedImage = result;
        _currentFilter = filterName;
        _isProcessing = false;
        // No cerrar el panel de parámetros
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showError('Error al aplicar filtro: $e');
      }
    }
  }

  /// Aplica filtro con parámetros automáticos
  Future<void> _applyFilterAuto(String filterName) async {
    Map<String, dynamic>? autoParams;

    switch (filterName.toLowerCase()) {
      case 'canny':
        autoParams = {'kernel_size': 5, 'sigma': 2, 'low_threshold': '0', 'high_threshold': '0', 'use_auto': true};
        break;
      case 'gaussian':
        autoParams = {'kernel_size': 15, 'sigma': 5, 'use_auto': true};
        break;
      case 'emboss':
        autoParams = {'kernel_size': 3, 'bias_value': 128, 'use_auto': true};
        break;
      case 'watermark':
        autoParams = {'scale': 0.3, 'transparency': 0.3, 'spacing': 0.5, 'use_auto': true};
        break;
      case 'ripple':
        autoParams = {'edge_threshold': 100, 'color_levels': 8, 'saturation': 1.2, 'use_auto': true};
        break;
    }

    await _applyFilter(filterName, params: autoParams);
  }

  /// Maneja la selección de un filtro
  void _onFilterSelected(String filterName) {
    final filter = _filters.firstWhere((f) => f['name'] == filterName);
    final hasParams = filter['hasParams'] as bool;

    if (hasParams) {
      // Inicializar parámetros por defecto según el filtro
      _initializeFilterParams(filterName);
      setState(() {
        _showParamsPanel = true;
        _currentFilter = filterName;
      });
    } else {
      // Aplicar filtro directamente
      _applyFilter(filterName);
    }
  }

  /// Inicializa parámetros por defecto para un filtro
  void _initializeFilterParams(String filterName) {
    switch (filterName.toLowerCase()) {
      case 'canny':
        _filterParams = {'kernel_size': 5, 'sigma': 2, 'low_threshold': '0', 'high_threshold': '0', 'use_auto': false};
        break;
      case 'gaussian':
        _filterParams = {'kernel_size': 15, 'sigma': 5, 'use_auto': false};
        break;
      case 'emboss':
        _filterParams = {'kernel_size': 3, 'bias_value': 128, 'use_auto': false};
        break;
      case 'watermark':
        _filterParams = {'scale': 0.3, 'transparency': 0.3, 'spacing': 0.5, 'use_auto': false};
        break;
      case 'ripple':
        _filterParams = {'edge_threshold': 100, 'color_levels': 8, 'saturation': 1.2, 'use_auto': false};
        break;
      default:
        _filterParams = {};
    }
  }

  /// Publica el post
  Future<void> _publishPost() async {
    if (_originalImage == null) {
      _showError('Selecciona una imagen primero');
      return;
    }

    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      _showError('Escribe una descripción');
      return;
    }

    setState(() {
      _isPublishing = true;
      _errorMessage = null;
    });

    try {
      // Si hay imagen procesada, guardarla temporalmente para enviarla
      File imageToSend;
      if (_processedImage != null) {
        // Guardar imagen procesada temporalmente
        final tempDir = await getTemporaryDirectory();
        final processedPath = '${tempDir.path}/processed_post_${DateTime.now().millisecondsSinceEpoch}.png';
        final processedFile = File(processedPath);
        await processedFile.writeAsBytes(_processedImage!);
        imageToSend = processedFile;
      } else {
        // Usar imagen original
        imageToSend = _originalImage!;
      }

      // Publicar post
      await PostService.createPost(imageToSend, caption);

      // Limpiar imagen temporal
      await TempImageService.clearTempImage();
      
      // Limpiar archivo procesado si existe
      if (_processedImage != null && imageToSend.existsSync()) {
        await imageToSend.delete();
      }

      if (mounted) {
        // Navegar al feed
        context.go('/home/feed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
        _showError('Error al publicar: $e');
      }
    }
  }

  /// Muestra un mensaje de error
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home/feed');
          }
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.welcomeBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home/feed');
                        }
                      },
                    ),
                    const Text(
                      'Nuevo Post',
                      style: AppTypography.subtitle,
                    ),
                    const SizedBox(width: 48), // Balancear el layout
                  ],
                ),
              ),

              // CONTENIDO PRINCIPAL
              Expanded(
                child: Column(
                  children: [
                    // ÁREA DE IMAGEN (FIJA)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildImageArea(),
                    ),

                    const SizedBox(height: 24),

                    // CONTENIDO SCROLLEABLE (FILTROS, PARÁMETROS, DESCRIPCIÓN)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LISTA DE FILTROS (solo si hay imagen)
                            if (_originalImage != null) ...[
                              _buildFiltersList(),
                              const SizedBox(height: 16),
                            ],

                            // PANEL DE PARÁMETROS (si está visible)
                            if (_showParamsPanel && _currentFilter != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Parámetros: ${_currentFilter!}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white70),
                                          onPressed: () {
                                            setState(() {
                                              _showParamsPanel = false;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    FilterParamsPanel(
                                      filterName: _currentFilter!,
                                      initialParams: _filterParams,
                                      onApply: (params) {
                                        _applyFilter(_currentFilter!, params: params);
                                      },
                                      onAuto: () {
                                        _applyFilterAuto(_currentFilter!);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // MENSAJE DE ERROR
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // CAMPO DE DESCRIPCIÓN
                            const Text(
                              'Descripción',
                              style: AppTypography.body,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white38),
                              ),
                              child: TextField(
                                controller: _captionController,
                                maxLines: 5,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Escribe algo sobre tu foto',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // BOTÓN PUBLICAR
                            PrimaryButton(
                              label: _isPublishing ? 'Publicando...' : 'Publicar',
                              isLoading: _isPublishing,
                              isDisabled: _originalImage == null || _isPublishing || _isProcessing,
                              onPressed: _publishPost,
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el área de selección/vista previa de imagen
  Widget _buildImageArea() {
    if (_isProcessing) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(40),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white38),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Aplicando filtro...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_processedImage != null) {
      // Mostrar imagen procesada
      return GestureDetector(
        onTap: _selectImage,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white38, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              _processedImage!,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
      );
    }

    if (_originalImage != null) {
      // Mostrar imagen original
      return GestureDetector(
        onTap: _selectImage,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white38, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              _originalImage!,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
      );
    }

    // Área de selección vacía
    return GestureDetector(
      onTap: _selectImage,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(40),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white38),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 60,
                color: Colors.white70,
              ),
              SizedBox(height: 12),
              Text(
                'Toca para seleccionar imagen',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la lista horizontal de filtros
  Widget _buildFiltersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtros',
          style: AppTypography.body,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final filterName = filter['name'] as String;
              final isActive = _currentFilter == filterName ||
                  (filterName == 'Original' && _currentFilter == null && _processedImage == null);

              return FilterItem(
                name: filterName,
                icon: filter['icon'] as IconData,
                isActive: isActive,
                onTap: () => _onFilterSelected(filterName),
              );
            },
          ),
        ),
      ],
    );
  }
}
