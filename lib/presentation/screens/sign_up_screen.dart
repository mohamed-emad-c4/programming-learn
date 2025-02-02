import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

class SignUpScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _countryController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
                Icon(Icons.person_add, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'تسجيل حساب جديد',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: Icon(Icons.person, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return 'يرجى إدخال الاسم الكامل';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: 'اسم المستخدم',
                    prefixIcon: Icon(Icons.person_outline, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return 'يرجى إدخال اسم المستخدم';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _countryController,
                  decoration: InputDecoration(
                    labelText: 'البلد',
                    prefixIcon: Icon(Icons.location_on, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) return 'يرجى إدخال البلد';
                    return null;
                  },
                ),
                SizedBox(height: 16),
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
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty) return 'يرجى إدخال كلمة المرور';
                    if (value.length < 6) return 'كلمة المرور يجب أن تكون على الأقل 6 أحرف';
                    return null;
                  },
                ),
                SizedBox(height: 24),
                BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state is AuthSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم تسجيل الحساب بنجاح!')),
                      );
                      Navigator.pushReplacementNamed(context, '/login');
                    } else if (state is AuthFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.error)),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is AuthLoading) {
                      return CircularProgressIndicator();
                    }
                    return ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<AuthCubit>().register(
                                name: _nameController.text,
                                nickname: _nicknameController.text,
                                country: _countryController.text,
                                email: _emailController.text,
                                password: _passwordController.text,
                                role: 'user',
                              );
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
                        'تسجيل الحساب',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text(
                    'لديك حساب بالفعل؟ تسجيل الدخول',
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