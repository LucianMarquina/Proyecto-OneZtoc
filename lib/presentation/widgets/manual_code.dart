import 'package:flutter/material.dart';
import 'package:one_ztoc_app/config/theme/app_theme.dart';
import 'package:one_ztoc_app/services/database_service.dart';

class ManualCodeInputView extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onCodeSubmitted;
  final String? captureCode; // Código de captura activo

  const ManualCodeInputView({
    super.key,
    required this.onClose,
    this.onCodeSubmitted,
    this.captureCode,
  });

  @override
  State<ManualCodeInputView> createState() => _ManualCodeInputViewState();
}

class _ManualCodeInputViewState extends State<ManualCodeInputView> {
  final TextEditingController _codeController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _searchProduct() async {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un código'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final code = _codeController.text.trim();

      // Guardar el código en la base de datos local como PENDING con la captura activa
      await _dbService.insertScanItem(
        code,
        captureCode: widget.captureCode,
        captureName: widget.captureCode,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Código guardado: $code'),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );

        // Notificar al padre
        widget.onCodeSubmitted?.call();

        // Limpiar el campo
        _codeController.clear();
      }

      debugPrint('Código manual guardado en BD local: $code (Captura: ${widget.captureCode})');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar código: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Error al guardar código manual: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ingresar código manualmente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.arrow_back),
                color: const Color(0xFF64748B),
                iconSize: 25,
              ),
            ],
          ),
          SizedBox(height: 30),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppTheme.bgColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.manage_search_outlined,
              size: 55,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 20),          
          TextField(            
            controller: _codeController,
            keyboardType: TextInputType.number,                       
            decoration: InputDecoration(
              labelText: 'Ejemplo: 7347384125', 
              labelStyle: TextStyle(
                color: Colors.blueGrey
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),          
          // Search button
          ElevatedButton(
            onPressed: _isLoading ? null : _searchProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Guardar Código',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),

          const SizedBox(height: 32),         
        ],
      ),
    );
  }
}
