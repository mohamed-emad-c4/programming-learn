// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().checkTokenValidity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الصفحة الرئيسية'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings), // أيقونة الإعدادات
            onPressed: () {
              // في HomeScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value:
                        BlocProvider.of<AuthCubit>(context), // تمرير AuthCubit
                    child: SettingsScreen(),
                  ),
                ),
              ); // الانتقال إلى شاشة الإعدادات
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGridSection(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridSection(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildCard(
          icon: Icons.computer,
          title: 'أساسيات الكمبيوتر',
          description: 'تعلم أساسيات الهاردوير والسوفتوير.',
          onTap: () {
            Navigator.pushNamed(context, '/fundamentals');
          },
        ),
        _buildCard(
          icon: Icons.code,
          title: 'لغة البرمجة',
          description: 'تعلم بايثون، جافا، وغيرها.',
          onTap: () {
            Navigator.pushNamed(context, '/programming');
          },
        ),
        _buildCard(
          icon: Icons.lightbulb_outline,
          title: 'تعلم المهارات',
          description: 'طور التفكير النقدي والإبداع.',
          onTap: () {
            Navigator.pushNamed(context, '/skills');
          },
        ),
        _buildCard(
          icon: Icons.bug_report,
          title: 'حل المشكلات',
          description: 'تدرب على بناء المنطق والخوارزميات.',
          onTap: () {
            Navigator.pushNamed(context, '/problem-solving');
          },
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: Colors.blue.withOpacity(0.1),
        highlightColor: Colors.blue.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
