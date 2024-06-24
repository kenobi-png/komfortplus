import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({Key? key}) : super(key: key);
  static const String phoneNumber = '+79281307878';
  static const String emailAddress = '9281307878@mail.ru';

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      final snackBar = SnackBar(
        content: Text('Скопировано в буфер обмена: $text'),
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void _openPhoneDialer(BuildContext context, String phoneNumber) async {
    final uri = 'tel://$phoneNumber';
    if (await canLaunchUrlString(uri)) {
      await launchUrlString(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось открыть приложение набора номера'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Контакты'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Телефон'),
              subtitle: Text(phoneNumber),
              onTap: () {
                _openPhoneDialer(context, phoneNumber);
              },
            ),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Электронная почта'),
              subtitle: Text(emailAddress),
              onTap: () {
                _copyToClipboard(context, emailAddress);
              },
            ),
          ],
        ),
      ),
    );
  }
}
