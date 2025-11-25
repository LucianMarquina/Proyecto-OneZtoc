import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyEmployeeId = 'employee_id';
  static const String _keyEmployeeName = 'employee_name';
  static const String _keyEmployeeJobTitle = 'employee_job_title';

  // Guardar token de acceso
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, token);
  }

  // Obtener token de acceso
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  // Guardar ID del empleado
  Future<void> saveEmployeeId(int employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEmployeeId, employeeId);
  }

  // Obtener ID del empleado
  Future<int?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyEmployeeId);
  }

  // Guardar nombre del empleado
  Future<void> saveEmployeeName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmployeeName, name);
  }

  // Obtener nombre del empleado
  Future<String?> getEmployeeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmployeeName);
  }

  // Guardar título del empleado
  Future<void> saveEmployeeJobTitle(String jobTitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmployeeJobTitle, jobTitle);
  }

  // Obtener título del empleado
  Future<String?> getEmployeeJobTitle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmployeeJobTitle);
  }

  // Guardar toda la información del usuario
  Future<void> saveUserData({
    required String accessToken,
    required int employeeId,
    required String employeeName,
    required String employeeJobTitle,
  }) async {
    await saveAccessToken(accessToken);
    await saveEmployeeId(employeeId);
    await saveEmployeeName(employeeName);
    await saveEmployeeJobTitle(employeeJobTitle);
  }

  // Limpiar todos los datos del usuario
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyEmployeeId);
    await prefs.remove(_keyEmployeeName);
    await prefs.remove(_keyEmployeeJobTitle);
  }

  // Verificar si hay un token guardado
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
