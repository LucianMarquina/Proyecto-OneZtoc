import 'package:flutter/material.dart';
import 'package:one_ztoc_app/config/theme/app_theme.dart';

class CaptureSelectionView extends StatefulWidget {
  final Function(String) onCaptureSelected;

  const CaptureSelectionView({
    super.key,
    required this.onCaptureSelected,
  });

  @override
  State<CaptureSelectionView> createState() => _CaptureSelectionViewState();
}

class _CaptureSelectionViewState extends State<CaptureSelectionView> {
  final TextEditingController _captureCodeController = TextEditingController();
  String? _errorMessage;
  final String _validCaptureCode = '00001'; // Código válido de ejemplo

  @override
  void dispose() {
    _captureCodeController.dispose();
    super.dispose();
  }

  void _handleSelectCapture() {
    final captureCode = _captureCodeController.text.trim();

    if (captureCode.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa un código de captura';
      });
      return;
    }

    // Validar el código de captura
    if (captureCode == _validCaptureCode) {
      // Código válido - limpiar error y navegar
      setState(() {
        _errorMessage = null;
      });

      // Llamar al callback pasando el código de captura
      widget.onCaptureSelected(captureCode);
    } else {
      // Código inválido - mostrar error
      setState(() {
        _errorMessage = 'El codigo de captura ingresado no existe';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(       
      margin: EdgeInsets.symmetric(vertical: 35),
      width: 440,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE2E8F0),
            blurRadius: 1,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                // Icono de captura
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: AppTheme.bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 45,
                    color: AppTheme.primaryColor,
                  ),
                ),

                const SizedBox(height: 20),

                // Título principal
                const Text(
                  'Seleccionar Captura',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Descripción
                const Text(
                  'Ingresa el codigo de captura para comenzar a escanear productos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Label del campo
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Codigo de captura',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Campo de texto
                TextField(
                  controller: _captureCodeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ej: 00004',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _errorMessage != null
                            ? Colors.red
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _errorMessage != null
                            ? Colors.red
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _errorMessage != null
                            ? Colors.red
                            : AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    // Limpiar el error cuando el usuario empiece a escribir
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                  onSubmitted: (value) => _handleSelectCapture(),
                ),

                // Mensaje de error
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Botón de seleccionar captura
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSelectCapture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Seleccionar Captura',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
