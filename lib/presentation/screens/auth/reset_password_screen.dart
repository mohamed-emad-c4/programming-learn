import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_reset, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'استعادة كلمة المرور',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                    if (!value.contains('@')) return 'صيغة البريد الإلكتروني غير صحيحة';
                    return null;
                  },
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم إرسال رابط الاستعادة إلى بريدك الإلكتروني.')),
                      );
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'إرسال الرابط',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text(
                    'العودة لتسجيل الدخول',
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}