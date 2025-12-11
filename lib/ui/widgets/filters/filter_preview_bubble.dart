import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../../services/image/image_processing_service.dart';

/// Widget circular que muestra una vista previa de un filtro aplicado.
/// Similar a las burbujas de filtros de Instagram.
class FilterPreviewBubble extends StatefulWidget {
  final String filterKey;
  final String filterLabel;
  final IconData icon;
  final File originalImage;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasParams;

  const FilterPreviewBubble({
    super.key,
    required this.filterKey,
    required this.filterLabel,
    required this.icon,
    required this.originalImage,
    required this.isSelected,
    required this.onTap,
    this.hasParams = false,
  });

  @override
  State<FilterPreviewBubble> createState() => _FilterPreviewBubbleState();
}

class _FilterPreviewBubbleState extends State<FilterPreviewBubble>
    with SingleTickerProviderStateMixin {
  Uint8List? _previewImage;
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadPreview();
  }

  @override
  void didUpdateWidget(FilterPreviewBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalImage.path != widget.originalImage.path ||
        oldWidget.filterKey != widget.filterKey) {
      _loadPreview();
    }
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Carga la vista previa del filtro
  Future<void> _loadPreview() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      Uint8List? result;

      switch (widget.filterKey.toLowerCase()) {
        case 'original':
          // Para original, leer los bytes directamente
          result = await widget.originalImage.readAsBytes();
          break;
        case 'canny':
          result = await ImageProcessingService.applyCanny(
            widget.originalImage,
            kernelSize: 5,
            sigma: 2,
            lowThreshold: '0',
            highThreshold: '0',
            useAuto: true,
          );
          break;
        case 'gaussian':
          result = await ImageProcessingService.applyGaussian(
            widget.originalImage,
            kernelSize: 15,
            sigma: 5,
            useAuto: true,
          );
          break;
        case 'negative':
          result = await ImageProcessingService.applyNegative(
            widget.originalImage,
          );
          break;
        case 'emboss':
          result = await ImageProcessingService.applyEmboss(
            widget.originalImage,
            kernelSize: 3,
            biasValue: 128,
            useAuto: true,
          );
          break;
        case 'watermark':
          result = await ImageProcessingService.applyWatermark(
            widget.originalImage,
            scale: 0.3,
            transparency: 0.3,
            spacing: 0.5,
          );
          break;
        case 'ripple':
          result = await ImageProcessingService.applyRipple(
            widget.originalImage,
            edgeThreshold: 100,
            colorLevels: 8,
            saturation: 1.2,
          );
          break;
        case 'collage':
          result = await ImageProcessingService.applyCollage(
            widget.originalImage,
          );
          break;
        default:
          result = await widget.originalImage.readAsBytes();
      }

      if (mounted) {
        setState(() {
          _previewImage = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Burbuja circular con preview
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isSelected ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isSelected
                          ? AppColors.upsYellow
                          : Colors.white.withOpacity(0.3),
                      width: widget.isSelected ? 3 : 2,
                    ),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.upsYellow.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipOval(
                    child: _buildPreviewContent(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Nombre del filtro
          Text(
            widget.filterLabel,
            style: TextStyle(
              color: widget.isSelected
                  ? AppColors.upsYellow
                  : Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (_isLoading) {
      return Container(
        color: Colors.black.withOpacity(0.3),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.upsYellow,
            ),
          ),
        ),
      );
    }

    if (_hasError || _previewImage == null) {
      return Container(
        color: Colors.black.withOpacity(0.5),
        child: Icon(
          widget.icon,
          color: Colors.white.withOpacity(0.6),
          size: 32,
        ),
      );
    }

    return Image.memory(
      _previewImage!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.black.withOpacity(0.5),
          child: Icon(
            widget.icon,
            color: Colors.white.withOpacity(0.6),
            size: 32,
          ),
        );
      },
    );
  }
}

