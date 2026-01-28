import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Add this import
import '../controllers/auth_controller.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AuthController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  void handleLogin() async {
    setState(() {
      isLoading = true;
    });

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sila isi emel dan kata laluan.")),
      );
      return;
    }

    try {
      print("Logging in with email: $email");

      UserModel? user = await _authController.loginUser(email, password);

      if (user != null) {
        print("Login successful! Role: ${user.role}");

        // Subscribe to Firebase Cloud Messaging topic based on role
        FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

        // Example topic: "pusat_derma" (You can use a different topic depending on your logic)
        await _firebaseMessaging.subscribeToTopic('pusat_derma');
        print("Subscribed to pusat_derma topic");

        await _firebaseMessaging.subscribeToTopic('pengguna');
        print("Subscribed to pengguna topic");

        if (user.role == "pengguna") {
          print("Navigating to: /home");
          Navigator.pushReplacementNamed(context, "/home");
        } else if (user.role == "pusat_derma") {
          print("Navigating to: /homepusatderma");
          Navigator.pushReplacementNamed(context, "/homepusatderma");
        } else if (user.role == "pentadbir") {
          print("Navigating to: /homepentadbir");
          Navigator.pushReplacementNamed(context, "/homepentadbir");
        } else {
          print("Unknown role: ${user.role}");
        }
      } else {
        print("Login failed, user is null.");
      }
    } catch (e) {
      print("Login failed with error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Log masuk gagal: $e")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Important to handle keyboard
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/loginbackground.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // e-Derma Title
                Text(
                  "e-Derma",
                  style: TextStyle(
                    fontSize: 70,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFBB800),
                    fontFamily: "Lato",
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Email
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Emel",
                          labelStyle: TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontFamily: "Lato",
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFFBB800)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFFBB800)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Color(0xFFFBB800),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Password
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Kata laluan",
                          labelStyle: TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontFamily: "Lato",
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFFBB800)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFFBB800)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Color(0xFFFBB800),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Login Button
                      isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFBB800),
                                  foregroundColor: const Color(0xFF512D13),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "LOG MASUK",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "Lato",
                                  ),
                                ),
                              ),
                            ),

                      const SizedBox(height: 10),

                      // Register link
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "Tidak mempunyai akaun?",
                          style: TextStyle(
                            color: Color(0xFF007BFF),
                            fontSize: 14,
                            fontFamily: "Lato",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
