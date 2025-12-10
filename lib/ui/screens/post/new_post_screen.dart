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
import '../../widgets/filters/filter_preview_bubble.dart';
import '../../widgets/filters/filter_params_panel.dart';
import '../../widgets/dialogs/error_dialog.dart';
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
  final PageController _pageController = PageController();

  // Estado compartido entre páginas
  File? _originalImage;
  Uint8List? _originalImageBytes;
  Uint8List? _processedImage;
  String? _selectedFilter;
  Map<String, dynamic> _filterParams = {};
  bool _isProcessing = false;
  bool _isPublishing = false;
  int _currentStep = 0;

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
  void initState() {
    super.initState();
    // Auto-abrir image picker después de un pequeño delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showImageSourceDialog();
        }
      });
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Muestra diálogo para seleccionar fuente de imagen
  Future<void> _showImageSourceDialog() async {
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

    if (source == null) {
      // Si se cancela, mostrar opción de cámara directamente
      _openCamera();
      return;
    }

    await _pickImage(source);
  }

  /// Abre la cámara con cámara trasera por defecto
  Future<void> _openCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        await _processPickedImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          title: 'Error al abrir cámara',
          message: 'Ocurrió un error al abrir la cámara: ${e.toString()}',
        );
      }
    }
  }

  /// Selecciona imagen desde la fuente especificada
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile;
      if (source == ImageSource.camera) {
        pickedFile = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85,
          preferredCameraDevice: CameraDevice.rear,
        );
      } else {
        pickedFile = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85,
        );
      }

      if (pickedFile != null) {
        await _processPickedImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          title: 'Error al seleccionar imagen',
          message: 'Ocurrió un error al seleccionar la imagen: ${e.toString()}',
        );
      }
    }
  }

  /// Procesa la imagen seleccionada
  Future<void> _processPickedImage(File file) async {
    try {
      final imageBytes = await file.readAsBytes();
      final tempFile = await TempImageService.saveOriginalImage(file);
      
      if (tempFile != null && mounted) {
        setState(() {
          _originalImage = tempFile;
          _originalImageBytes = imageBytes;
          _processedImage = null;
          _selectedFilter = null;
        });
        // Avanzar a la página de filtros
        _goToStep(1);
      } else {
        if (mounted) {
          await ErrorDialog.show(
            context,
            title: 'Error',
            message: 'Error al guardar la imagen. Por favor, intenta nuevamente.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          title: 'Error',
          message: 'Error al procesar la imagen: ${e.toString()}',
        );
      }
    }
  }

  /// Navega a un paso específico
  void _goToStep(int step) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    setState(() {
      _currentStep = step;
    });
  }

  /// Navega al siguiente paso
  void _nextStep() {
    if (_currentStep < 3) {
      _goToStep(_currentStep + 1);
    }
  }

  /// Navega al paso anterior
  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
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
    });

    try {
      Uint8List? result;

      switch (filterName.toLowerCase()) {
        case 'original':
          if (_originalImageBytes != null) {
            result = _originalImageBytes;
          } else {
            result = await _originalImage!.readAsBytes();
          }
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
        _selectedFilter = filterName;
        _isProcessing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        await ErrorDialog.show(
          context,
          title: 'Error al aplicar filtro',
          message: 'Ocurrió un error al aplicar el filtro: ${e.toString()}',
        );
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

  /// Maneja la selección de un filtro
  void _onFilterSelected(String filterName) {
    final filter = _filters.firstWhere((f) => f['name'] == filterName);
    final hasParams = filter['hasParams'] as bool;

    if (hasParams) {
      _initializeFilterParams(filterName);
      setState(() {
        _selectedFilter = filterName;
      });
      // Ir a página de parámetros
      _goToStep(2);
    } else {
      // Aplicar filtro directamente y volver a página de filtros
      _applyFilter(filterName);
    }
  }

  /// Publica el post
  Future<void> _publishPost() async {
    if (_originalImage == null) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          title: 'Imagen requerida',
          message: 'Por favor, selecciona una imagen antes de publicar.',
        );
      }
      return;
    }

    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          title: 'Descripción requerida',
          message: 'Por favor, escribe una descripción para tu publicación.',
        );
      }
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      File imageToSend;
      if (_processedImage != null) {
        final tempDir = await getTemporaryDirectory();
        final processedPath = '${tempDir.path}/processed_post_${DateTime.now().millisecondsSinceEpoch}.png';
        final processedFile = File(processedPath);
        await processedFile.writeAsBytes(_processedImage!);
        imageToSend = processedFile;
      } else {
        imageToSend = _originalImage!;
      }

      await PostService.createPost(imageToSend, caption);

      await TempImageService.clearTempImage();
      
      if (_processedImage != null && imageToSend.existsSync()) {
        await imageToSend.delete();
      }

      if (mounted) {
        context.go('/home/feed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
        await ErrorDialog.show(
          context,
          title: 'Error al publicar',
          message: 'Ocurrió un error al intentar publicar tu post: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (_currentStep > 0) {
            _previousStep();
          } else {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home/feed');
            }
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
              // HEADER con indicador de paso
              _buildHeader(),
              
              // CONTENIDO PRINCIPAL - PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Deshabilitar swipe manual
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildStep1ImageSelection(),
                    _buildStep2FilterSelection(),
                    _buildStep3FilterParams(),
                    _buildStep4Description(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el header con indicador de paso
  Widget _buildHeader() {
    return Padding(
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
          // Indicador de paso
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentStep
                      ? AppColors.upsYellow
                      : Colors.white.withOpacity(0.3),
                ),
              );
            }),
          ),
          // Balancear layout
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// Página 1: Selección de imagen
  Widget _buildStep1ImageSelection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Área de imagen
          Expanded(
            child: Center(
              child: _originalImage != null && _originalImageBytes != null
                  ? _buildImagePreview(_originalImageBytes!)
                  : _buildEmptyImageArea(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Botones
          if (_originalImage != null) ...[
            PrimaryButton(
              label: 'Siguiente',
              onPressed: _nextStep,
            ),
          ] else ...[
            PrimaryButton(
              label: 'Seleccionar imagen',
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _openCamera,
              child: const Text(
                'Abrir cámara',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Página 2: Selección de filtros
  Widget _buildStep2FilterSelection() {
    if (_originalImage == null) {
      return const Center(
        child: Text(
          'Por favor, selecciona una imagen primero',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      children: [
        // Preview grande de la imagen
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildLargeImagePreview(),
          ),
        ),
        
        // Burbujas de filtros
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Filtros',
                  style: AppTypography.body,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final filterName = filter['name'] as String;
                    final isSelected = _selectedFilter == filterName ||
                        (filterName == 'Original' && _selectedFilter == null && _processedImage == null);
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: FilterPreviewBubble(
                        filterName: filterName,
                        icon: filter['icon'] as IconData,
                        originalImage: _originalImage!,
                        isSelected: isSelected,
                        hasParams: filter['hasParams'] as bool,
                        onTap: () => _onFilterSelected(filterName),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Botones de navegación
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Atrás',
                  variant: ButtonVariant.ghost,
                  onPressed: _previousStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Siguiente',
                  onPressed: _nextStep,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Página 3: Parámetros de filtro
  Widget _buildStep3FilterParams() {
    if (_originalImage == null || _selectedFilter == null) {
      return const Center(
        child: Text(
          'No hay filtro seleccionado',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      children: [
        // Preview grande de la imagen con filtro
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildLargeImagePreview(),
          ),
        ),
        
        // Panel de parámetros
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parámetros: $_selectedFilter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilterParamsPanel(
                    filterName: _selectedFilter!,
                    initialParams: _filterParams,
                    onApply: (params) {
                      _applyFilter(_selectedFilter!, params: params);
                    },
                    onAuto: () {
                      _applyFilterAuto(_selectedFilter!);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Botones de navegación
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Atrás',
                  variant: ButtonVariant.ghost,
                  onPressed: () {
                    _goToStep(1); // Volver a selección de filtros
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Aplicar',
                  onPressed: () {
                    // Avanzar al paso 4 (descripción) después de aplicar
                    _goToStep(3);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Página 4: Descripción y publicar
  Widget _buildStep4Description() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Preview de la imagen final
          Expanded(
            flex: 2,
            child: _buildLargeImagePreview(),
          ),
          
          const SizedBox(height: 24),
          
          // Campo de descripción
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
          
          // Botones de navegación
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Atrás',
                  variant: ButtonVariant.ghost,
                  onPressed: _previousStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: _isPublishing ? 'Publicando...' : 'Publicar',
                  isLoading: _isPublishing,
                  isDisabled: _isPublishing || _isProcessing,
                  onPressed: _publishPost,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye el área vacía para seleccionar imagen
  Widget _buildEmptyImageArea() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: double.infinity,
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

  /// Construye preview de imagen
  Widget _buildImagePreview(Uint8List imageBytes) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white38, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Construye preview grande de imagen (con o sin filtro)
  Widget _buildLargeImagePreview() {
    if (_isProcessing) {
      return Container(
        width: double.infinity,
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

    Uint8List? imageToShow;
    if (_processedImage != null) {
      imageToShow = _processedImage;
    } else if (_originalImageBytes != null) {
      imageToShow = _originalImageBytes;
    }

    if (imageToShow == null) {
      return _buildEmptyImageArea();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white38, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          imageToShow,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
