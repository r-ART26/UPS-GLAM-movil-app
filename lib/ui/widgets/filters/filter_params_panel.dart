import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/buttons/primary_button.dart';

/// Panel de parámetros para configurar filtros.
/// Se muestra cuando un filtro con parámetros está seleccionado.
class FilterParamsPanel extends StatefulWidget {
  final String filterName;
  final Map<String, dynamic> initialParams;
  final Function(Map<String, dynamic>) onApply;
  final VoidCallback onAuto;

  const FilterParamsPanel({
    super.key,
    required this.filterName,
    required this.initialParams,
    required this.onApply,
    required this.onAuto,
  });

  @override
  State<FilterParamsPanel> createState() => _FilterParamsPanelState();
}

class _FilterParamsPanelState extends State<FilterParamsPanel> {
  late Map<String, dynamic> _params;

  @override
  void initState() {
    super.initState();
    _params = Map<String, dynamic>.from(widget.initialParams);
  }

  @override
  void didUpdateWidget(FilterParamsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar parámetros si cambian desde el padre
    if (oldWidget.initialParams != widget.initialParams) {
      _params = Map<String, dynamic>.from(widget.initialParams);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Switch de automático al comienzo (solo para filtros que lo tienen)
        if (_hasAutoSwitch()) ...[
          _buildAutoSwitch(),
          const SizedBox(height: 16),
        ],
        _buildParams(),
        const SizedBox(height: 16),
        // Solo botón Aplicar
        PrimaryButton(
          label: 'Aplicar',
          onPressed: () => widget.onApply(_params),
        ),
      ],
    );
  }

  /// Verifica si el filtro tiene switch de automático
  bool _hasAutoSwitch() {
    return widget.filterName.toLowerCase() == 'canny' ||
        widget.filterName.toLowerCase() == 'gaussian' ||
        widget.filterName.toLowerCase() == 'emboss' ||
        widget.filterName.toLowerCase() == 'watermark' ||
        widget.filterName.toLowerCase() == 'ripple';
  }

  /// Construye el switch de automático
  Widget _buildAutoSwitch() {
    final isAuto = _params['use_auto'] ?? false;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Modo Automático',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: isAuto,
          onChanged: (value) {
            setState(() {
              _params['use_auto'] = value;
              if (value) {
                // Si se activa automático, aplicar inmediatamente
                widget.onAuto();
              }
            });
          },
          activeColor: AppColors.upsYellow,
        ),
      ],
    );
  }

  /// Verifica si el modo automático está activado
  bool get _isAutoMode => _params['use_auto'] ?? false;

  Widget _buildParams() {
    switch (widget.filterName.toLowerCase()) {
      case 'canny':
        return _buildCannyParams();
      case 'gaussian':
        return _buildGaussianParams();
      case 'emboss':
        return _buildEmbossParams();
      case 'watermark':
        return _buildWatermarkParams();
      case 'ripple':
        return _buildRippleParams();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCannyParams() {
    final isDisabled = _isAutoMode;
    return Column(
      children: [
        _buildSlider(
          label: 'Kernel Size',
          value: _params['kernel_size']?.toDouble() ?? 5.0,
          min: 3,
          max: 99,
          divisions: 48,
          isDisabled: isDisabled,
          onChanged: (value) {
            setState(() {
              _params['kernel_size'] = value.toInt();
            });
          },
        ),
        _buildSlider(
          label: 'Sigma',
          value: _params['sigma']?.toDouble() ?? 2.0,
          min: 1,
          max: 50,
          divisions: 49,
          isDisabled: isDisabled,
          onChanged: (value) {
            setState(() {
              _params['sigma'] = value.toInt();
            });
          },
        ),
        _buildSlider(
          label: 'Low Threshold',
          value: _params['low_threshold'] != null && _params['low_threshold'] != '' 
              ? double.tryParse(_params['low_threshold'].toString()) ?? 0.0 
              : 0.0,
          min: 0,
          max: 255,
          divisions: 255,
          isDisabled: isDisabled,
          suffix: '(Auto if 0)',
          onChanged: (value) {
            setState(() {
              _params['low_threshold'] = value.toInt().toString();
            });
          },
        ),
        _buildSlider(
          label: 'High Threshold',
          value: _params['high_threshold'] != null && _params['high_threshold'] != '' 
              ? double.tryParse(_params['high_threshold'].toString()) ?? 0.0 
              : 0.0,
          min: 0,
          max: 255,
          divisions: 255,
          isDisabled: isDisabled,
          suffix: '(Auto if 0)',
          onChanged: (value) {
            setState(() {
              _params['high_threshold'] = value.toInt().toString();
            });
          },
        ),
      ],
    );
  }

  Widget _buildGaussianParams() {
    final isDisabled = _isAutoMode;
    return Column(
      children: [
        _buildSlider(
          label: 'Kernel Size',
          value: _params['kernel_size']?.toDouble() ?? 15.0,
          min: 3,
          max: 99,
          divisions: 48, // (99-3)/2 = 48 divisions (step 2)
          isDisabled: isDisabled,
          onChanged: (value) {
            setState(() {
              _params['kernel_size'] = value.toInt();
            });
          },
        ),
        _buildSlider(
          label: 'Sigma',
          value: _params['sigma']?.toDouble() ?? 5.0,
          min: 1,
          max: 25,
          divisions: 24, // (25-1)/1 = 24 divisions (step 1)
          isDisabled: isDisabled,
          onChanged: (value) {
            setState(() {
              _params['sigma'] = value.toInt();
            });
          },
        ),
      ],
    );
  }

  Widget _buildEmbossParams() {
    final isDisabled = _isAutoMode;
    return Column(
      children: [
        _buildSlider(
          label: 'Kernel Size',
          value: _params['kernel_size']?.toDouble() ?? 3.0,
          min: 3,
          max: 9,
          divisions: 3, // (9-3)/2 = 3 divisions (step 2)
          isDisabled: isDisabled,
          onChanged: (value) {
            setState(() {
              _params['kernel_size'] = value.toInt();
            });
          },
        ),
        _buildSlider(
          label: 'Bias Value',
          value: _params['bias_value']?.toDouble() ?? 128.0,
          min: 0,
          max: 255,
          divisions: 255, // (255-0)/1 = 255 divisions (step 1)
          isDisabled: isDisabled,
          onChanged: (value) {
            setState(() {
              _params['bias_value'] = value.toInt();
            });
          },
        ),
      ],
    );
  }

  Widget _buildWatermarkParams() {
    final isDisabled = _isAutoMode;
    return Column(
      children: [
        _buildSlider(
          label: 'Scale',
          value: _params['scale']?.toDouble() ?? 0.3,
          min: 0.1,
          max: 1.0,
          divisions: 18, // (1.0-0.1)/0.05 = 18 divisions (step 0.05)
          isDisabled: isDisabled,
          onChanged: (value) {
            setState(() {
              _params['scale'] = value;
            });
          },
        ),
        _buildSlider(
          label: 'Transparency',
          value: _params['transparency']?.toDouble() ?? 0.3,
          min: 0.0,
          max: 1.0,
          divisions: 20, // (1.0-0.0)/0.05 = 20 divisions (step 0.05)
          isDisabled: isDisabled,
          onChanged: (value) {
            setState(() {
              _params['transparency'] = value;
            });
          },
        ),
        _buildSlider(
          label: 'Spacing',
          value: _params['spacing']?.toDouble() ?? 0.5,
          min: 0.0,
          max: 2.0,
          divisions: 20, // (2.0-0.0)/0.1 = 20 divisions (step 0.1)
          isDisabled: isDisabled,
          onChanged: (value) {
            setState(() {
              _params['spacing'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRippleParams() {
    final isDisabled = _isAutoMode;
    return Column(
      children: [
        _buildSlider(
          label: 'Edge Threshold',
          value: _params['edge_threshold']?.toDouble() ?? 100.0,
          min: 0,
          max: 255,
          divisions: 255, // (255-0)/1 = 255 divisions (step 1)
          isDisabled: isDisabled,
          onChanged: (value) {
            setState(() {
              _params['edge_threshold'] = value.toInt();
            });
          },
        ),
        _buildSlider(
          label: 'Color Levels',
          value: _params['color_levels']?.toDouble() ?? 8.0,
          min: 2,
          max: 16,
          divisions: 14, // (16-2)/1 = 14 divisions (step 1)
          isDisabled: isDisabled,
          onChanged: (value) {
            setState(() {
              _params['color_levels'] = value.toInt();
            });
          },
        ),
        _buildSlider(
          label: 'Saturation',
          value: _params['saturation']?.toDouble() ?? 1.2,
          min: 0.0,
          max: 3.0,
          divisions: 30, // (3.0-0.0)/0.1 = 30 divisions (step 0.1)
          isDisabled: isDisabled,
          onChanged: (value) {
            setState(() {
              _params['saturation'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    bool isDisabled = false,
    String? suffix,
  }) {
    // Formatear el valor para mostrar
    String displayValue;
    if (value == value.toInt().toDouble()) {
      displayValue = value.toInt().toString();
    } else {
      displayValue = value.toStringAsFixed(2);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$label${suffix != null ? ' $suffix' : ''}',
                style: TextStyle(
                  color: isDisabled ? Colors.white.withOpacity(0.5) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                displayValue,
                style: TextStyle(
                  color: isDisabled 
                      ? AppColors.upsYellow.withOpacity(0.5)
                      : AppColors.upsYellow,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: AppColors.upsYellow,
              inactiveColor: Colors.white.withOpacity(0.3),
              onChanged: isDisabled ? null : onChanged,
            ),
          ),
        ],
      ),
    );
  }


}

