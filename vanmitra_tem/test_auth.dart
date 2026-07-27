import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyCHumxWKKMNwi9NCElr6WgIHD40QXbwLSQ';
  final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=$apiKey');
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'phoneNumber': '+918999880619',
      'recaptchaToken': 'dummy_token'
    }),
  );
  
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
