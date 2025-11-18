import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:one_ztoc_app/config/theme/app_theme.dart';
import 'package:one_ztoc_app/presentation/widgets/manual_code.dart';
import 'package:one_ztoc_app/presentation/widgets/capture_selection_view.dart';
import 'package:one_ztoc_app/presentation/widgets/active_capture_info.dart';
import 'package:one_ztoc_app/presentation/widgets/user_info_widget.dart';
import 'package:one_ztoc_app/services/database_service.dart';
import 'package:one_ztoc_app/services/auth_service.dart';

class EscanearView extends StatefulWidget {
  final VoidCallback? onScanCompleted; // Callback para notificar al padre

  const EscanearView({super.key, this.onScanCompleted});

  @override
  State<EscanearView> createState() => _EscanearViewState();
}

class _EscanearViewState extends State<EscanearView> with AutomaticKeepAliveClientMixin {
  bool _captureSelected = false; // Nueva variable para controlar si se seleccionó captura
  String _activeCaptureCode = ''; // Código de captura activo
  Map<String, dynamic>? _activeCaptureData; // Datos completos de la captura
  bool _showManualInput = false;
  bool _cameraActive = false;
  MobileScannerController? _scannerController;
  Barcode? _lastBarcode;
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  String _userName = 'Usuario';
  String _userRole = 'Empleado';

  @override
  bool get wantKeepAlive => true; // Mantener el estado al cambiar de pestañas

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _userName = userData['name'];
        _userRole = userData['job_title'];
      });
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _toggleManualInput() {
    setState(() {
      _showManualInput = !_showManualInput;
      // Si se abre el ingreso manual, cerrar la cámara
      if (_showManualInput && _cameraActive) {
        _deactivateCamera();
      }
    });
  }

  void _activateCamera() {
    setState(() {
      _cameraActive = true;
      _scannerController = MobileScannerController();
    });
  }

  void _deactivateCamera() {
    _scannerController?.dispose();
    setState(() {
      _cameraActive = false;
      _scannerController = null;
      _lastBarcode = null;
    });
  }

  void _onBarcodeDetect(BarcodeCapture capture) async {
    if (!mounted) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final String? code = barcode.rawValue;

      // Evitar múltiples detecciones del mismo código
      if (code != null && code != _lastBarcode?.rawValue) {
        setState(() {
          _lastBarcode = barcode;
        });

        // Detener el escáner
        _deactivateCamera();

        // Guardar el código en la base de datos local como PENDING con la captura activa
        try {
          await _dbService.insertScanItem(
            code,
            captureCode: _activeCaptureCode,
            captureName: _activeCaptureCode,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ Código guardado: $code'),
                backgroundColor: AppTheme.primaryColor,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          // Notificar al padre que se completó un escaneo
          widget.onScanCompleted?.call();

          debugPrint('Código guardado en BD local: $code (Captura: $_activeCaptureCode)');
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
          debugPrint('Error al guardar en BD: $e');
        }
      }
    }
  }

  void _onCaptureSelected(String captureCode, Map<String, dynamic> captureData) async {
    // Registrar la captura validada inmediatamente en la base de datos
    await _dbService.registerValidatedCapture(captureCode);

    setState(() {
      _captureSelected = true;
      _activeCaptureCode = captureCode;
      _activeCaptureData = captureData;
    });

    // Mostrar mensaje de éxito
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Captura validada: $captureCode'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onChangeCapture() {
    setState(() {
      _captureSelected = false;
      _activeCaptureCode = '';
      _activeCaptureData = null;
      // También cerrar la cámara si está activa
      if (_cameraActive) {
        _deactivateCamera();
      }
      // Cerrar el ingreso manual si está abierto
      if (_showManualInput) {
        _showManualInput = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin

    // Si no se ha seleccionado captura, mostrar la vista de selección con info de usuario
    if (!_captureSelected) {
      return Column(
        children: [
          const SizedBox(height: 35),
          // Widget de información del usuario
          UserInfoWidget(
            userName: _userName,
            userRole: _userRole,
          ),
          const SizedBox(height: 0),
          // Vista de selección de captura
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 40),
                child: CaptureSelectionView(
                  onCaptureSelected: _onCaptureSelected,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Si ya se seleccionó captura, mostrar la info de captura activa y la vista de escaneo
    return Column(
      children: [
        const SizedBox(height: 35),
        // Widget de información de captura activa
        ActiveCaptureInfo(
          captureCode: _activeCaptureCode,
          onChangeCapture: _onChangeCapture,
        ),
        const SizedBox(height: 0),
        // Vista de escaneo
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 35),
              child: Container(
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
                child: _cameraActive
                    ? _buildCameraView()
                    : (_showManualInput
                        ? ManualCodeInputView(
                            onClose: _toggleManualInput,
                            onCodeSubmitted: widget.onScanCompleted,
                            captureCode: _activeCaptureCode,
                          )
                        : _buildScanView()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraView() {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetect,
          ),
          // Overlay con instrucciones
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Apunta la cámara al código de barras',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Botón de cerrar cámara
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _deactivateCamera,
                icon: const Icon(Icons.close, size: 20),
                label: const Text(
                  'Cerrar Cámara',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Círculo con icono de escaneo
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: AppTheme.bgColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.document_scanner_outlined,
            size: 50,
            color: AppTheme.primaryColor,
          ),
        ),

        const SizedBox(height: 24),

        // Título
        const Text(
          'Escanea un código de barras',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Subtítulo
        const Text(
          'Coloca el código dentro del recuadro de\nescaneo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Activar Cámara
        SizedBox(
          width: 300,
          child: ElevatedButton.icon(
            onPressed: _activateCamera,
            icon: const Icon(Icons.camera_alt, size: 20),
            label: const Text(
              'Activar Cámara',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Ingresar Manualmente
        SizedBox(
          width: 300,
          child: OutlinedButton.icon(
            onPressed: _toggleManualInput,
            icon: const Icon(Icons.keyboard, size: 20),
            label: const Text(
              'Ingresar Manualmente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

}
