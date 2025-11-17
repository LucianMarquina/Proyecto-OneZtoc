import 'package:flutter/material.dart';
import 'package:one_ztoc_app/config/theme/app_theme.dart';
import 'package:one_ztoc_app/presentation/widgets/scan_view.dart';
import 'package:one_ztoc_app/presentation/widgets/historial_view.dart';
import 'package:one_ztoc_app/presentation/widgets/configuration_view.dart';
import 'package:one_ztoc_app/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _totalCount = 0;
  final GlobalKey<State> _historialKey = GlobalKey();
  final AuthService _authService = AuthService();
  String _userInitial = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserInitial();
  }

  Future<void> _loadUserInitial() async {
    final userData = await _authService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _userInitial = userData['name'].toString().isNotEmpty
            ? userData['name'].toString()[0].toUpperCase()
            : 'U';
      });
    }
  }

  void _updateTotalCount(int count) {
    setState(() {
      _totalCount = count;
    });
  }

  void _onScanCompleted() {
    // Recargar el historial cuando se completa un escaneo
    final historialState = _historialKey.currentState;
    if (historialState != null) {
      // Llamar al método refresh si existe
      try {
        (historialState as dynamic).refresh();
      } catch (e) {
        debugPrint('Error al refrescar historial: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        toolbarHeight: 120,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: IconButton(onPressed: () {}, icon: const Icon(Icons.document_scanner_outlined), iconSize: 50),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Align(alignment: Alignment.centerLeft, child: const Text('Escáner de Productos',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18)
                ),
              ),
              Align(alignment: Alignment.bottomLeft, child: const Text('Escanea código de barras',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Colors.white70,
                  ),
                )
              )
            ],
          ),
        ),
        actions: [
          if (_userInitial.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _userInitial,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
        
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50), 
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorColor: Colors.black,              
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,              
              ),
              unselectedLabelStyle: const TextStyle(                
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),              
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.document_scanner_outlined, size: 23),
                      SizedBox(width: 4),
                      Text('Escanear', style: TextStyle(
                        fontSize: 16
                      ),),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 23),
                      const SizedBox(width: 4),
                      Text('Historial ($_totalCount)', style: TextStyle(
                        fontSize: 16
                      ),),
                     
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.settings, size: 23),
                      SizedBox(width: 4),
                      Text('Configuración', style: TextStyle(
                        fontSize: 16
                      ),),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EscanearView(onScanCompleted: _onScanCompleted),
          HistorialView(
            key: _historialKey,
            onTotalCountChanged: _updateTotalCount,
          ),
          const ConfigScreen(),
        ],
      ),
    );
  }
}
