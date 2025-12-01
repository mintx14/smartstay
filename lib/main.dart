import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'register.dart';
import 'package:my_app/pages/tenant/home_page.dart';
import 'package:my_app/pages/owner/owner_page.dart'; // Add this import for owner page
import 'package:my_app/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Keep system status bar visible and ensure proper layout
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  
  // Set status bar style (dark icons on light background)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  final prefs = await SharedPreferences.getInstance();

  // Check login status
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Create user if logged in
  User? user;
  if (isLoggedIn) {
    user = User(
      // 💡 FIX 1: Change 'userId' to 'user_id'
      id: prefs.getString('user_id') ?? '',
      fullName: prefs.getString('fullName') ?? '',
      email: prefs.getString('email') ?? '',
      // 💡 FIX 2: Change 'phoneNum' to 'phoneNumber'
      phoneNumber: prefs.getString('phoneNumber') ?? '',
      userType: prefs.getString('userType') ?? '',
    );
  }

  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    user: user,
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final User? user;

  const MyApp({super.key, required this.isLoggedIn, this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartStay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.grey[500]),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
      home: _getInitialScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/tenant-home': (context) => HomePage(user: user!),
        '/owner-home': (context) => OwnerPage(user: user!), // Add owner route
      },
    );
  }

  Widget _getInitialScreen() {
    if (isLoggedIn && user != null) {
      // Auto-login based on user type
      if (user!.userType.toLowerCase() == 'owner') {
        // Use .toLowerCase() for safety
        return OwnerPage(user: user!);
      } else if (user!.userType.toLowerCase() == 'tenant') {
        // Use .toLowerCase() for safety
        return HomePage(user: user!);
      } else {
        // If userType is not recognized, go to login
        return const LoginPage(); // Direct to LoginPage instead of SplashScreen
      }
    } else {
      // Not logged in, show login page directly
      return const LoginPage(); // Direct to LoginPage instead of SplashScreen
    }
  }
}

// class SplashScreen extends StatelessWidget {
//   const SplashScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     Future.delayed(const Duration(seconds: 2), () {
//       Navigator.of(context).pushReplacementNamed('/login');
//     });

//     return const Scaffold(
//       backgroundColor: Color(0xFF190152),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.home,
//               size: 100,
//               color: Colors.white,
//             ),
//             SizedBox(height: 24),
//             Text(
//               'SmartStay',
//               style: TextStyle(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             SizedBox(height: 24),
//             CircularProgressIndicator(
//               color: Colors.white,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
