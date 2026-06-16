class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://92.38.48.187:5000/api',
  );

  static const String authUrl = '$baseUrl/auth';
  static const String usersUrl = '$baseUrl/users';
  static const String productsUrl = '$baseUrl/products';
  static const String cartUrl = '$baseUrl/cart';
  static const String ordersUrl = '$baseUrl/orders';
  static const String reportsUrl = '$baseUrl/reports';
  static const String bookingsUrl = '$baseUrl/bookings';
}
