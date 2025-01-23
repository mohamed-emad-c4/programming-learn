import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';

class LoginScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
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
                Icon(Icons.lock, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'اسم المستخدم',
                    prefixIcon: Icon(Icons.person, color: Colors.blue),
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
                    return null;
                  },
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/reset-password');
                    },
                    child: Text(
                      'نسيت كلمة المرور؟',
                      style: TextStyle(color: Colors.blue.shade800),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state is AuthSuccess) {
                      Navigator.pushReplacementNamed(context, '/home');
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
                          context.read<AuthCubit>().login(
                                username: _usernameController.text,
                                password: _passwordController.text,
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
                        'تسجيل الدخول',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/sign-up');
                  },
                  child: Text(
                    'ليس لديك حساب؟ سجل الآن',
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