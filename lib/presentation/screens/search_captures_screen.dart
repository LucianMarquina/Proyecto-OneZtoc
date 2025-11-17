import 'package:flutter/material.dart';
import 'package:one_ztoc_app/config/theme/app_theme.dart';
import 'package:one_ztoc_app/services/api_service.dart';
import 'package:one_ztoc_app/models/faltante_item.dart';
import 'package:one_ztoc_app/presentation/widgets/faltante_list_item.dart';

class SearchCapturesScreen extends StatefulWidget {
  const SearchCapturesScreen({super.key});

  @override
  State<SearchCapturesScreen> createState() => _SearchCapturesScreenState();
}

enum SearchState { initial, loading, success, empty, error }

class _SearchCapturesScreenState extends State<SearchCapturesScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchState _currentState = SearchState.initial;
  List<FaltanteItem> _faltantes = [];
  CaptureInfo? _captureInfo;
  String _errorMessage = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCapture() async {
    // Validación de entrada
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un ID de captura'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Estado de carga
    setState(() {
      _currentState = SearchState.loading;
    });

    try {
      // Llamada a la API
      final response = await ApiService.getFaltantes(_searchController.text);

      if (!mounted) return;

      // Manejo de la respuesta
      if (response.success) {
        if (response.faltantes.isEmpty) {
          // Caso B: Éxito pero sin faltantes
          setState(() {
            _currentState = SearchState.empty;
            _faltantes = [];
            _captureInfo = response.captureInfo;
          });
        } else {
          // Caso A: Éxito con faltantes
          setState(() {
            _currentState = SearchState.success;
            _faltantes = response.faltantes;
            _captureInfo = response.captureInfo;
          });
        }
      } else {
        // Caso de error desde la API
        setState(() {
          _currentState = SearchState.error;
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      // Caso C: Error de red
      if (!mounted) return;
      setState(() {
        _currentState = SearchState.error;
        _errorMessage = 'Error de conexión: ${e.toString()}';
      });
    }
  }

  Widget _buildContent() {
    switch (_currentState) {
      case SearchState.initial:
        return _buildInitialState();
      case SearchState.loading:
        return _buildLoadingState();
      case SearchState.success:
        return _buildSuccessState();
      case SearchState.empty:
        return _buildEmptyState();
      case SearchState.error:
        return _buildErrorState();
    }
  }

  // Estado inicial: icono de lupa
  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppTheme.secondaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Busca una captura...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa un ID para ver los bienes faltantes',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Estado de carga
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 24),
          Text(
            'Buscando faltantes...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // Estado de éxito con faltantes
  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de la captura
        if (_captureInfo != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Captura: ${_captureInfo!.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _captureInfo!.ambito,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Contador de faltantes
        Text(
          'Se encontraron ${_faltantes.length} bienes faltantes',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),

        // Lista de faltantes
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: _faltantes.length,
              itemBuilder: (context, index) {
                return FaltanteListItem(item: _faltantes[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  // Estado vacío: no se encontraron faltantes
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppTheme.secondaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),         
          if (_captureInfo != null) ...[
            Text(
              'No se encontraron faltantes para la captura ${_captureInfo!.name}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const Text(
              'Captura no válida o sin faltantes',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // Estado de error
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Error al buscar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Buscar Capturas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white
          ),
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título y descripción
              const Text(
                'Buscar Faltantes por Captura',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa el ID de la captura para ver los bienes faltantes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
              ),
          
              const SizedBox(height: 24),
          
              // Barra de búsqueda
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ingresa el ID (00001)',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
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
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _currentState == SearchState.loading
                        ? null
                        : _searchCapture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _currentState == SearchState.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Buscar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
          
              const SizedBox(height: 24),

              // Contenido dinámico basado en el estado
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
