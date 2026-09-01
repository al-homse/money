import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  // 1. الدخول عبر البريد الإلكتروني وكلمة المرور
  Future<void> _submitEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      _showError('يرجى إدخال بريد صحيح وكلمة مرور من 6 أحرف على الأقل.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'حدث خطأ أثناء عملية المصادقة.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. الدخول عبر Google
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      if (googleAuth != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      _showError('لم يتم إكمال تسجيل الدخول عبر Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. الدخول عبر Facebook
  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential =
            FacebookAuthProvider.credential(result.accessToken!.tokenString);
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      _showError('خدمة Facebook غير مفعّلة حالياً أو حدث خطأ.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 4. الدخول عبر Apple
  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final OAuthProvider oauthProvider = OAuthProvider('apple.com');
      final credential = oauthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      _showError('خدمة Apple غير مفعّلة حالياً أو حدث خطأ.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 5. الدخول كـ زائر (Anonymous)
  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      _showError('فشل الدخول كزائر، يرجى المحاولة لاحقاً.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isLogin ? 'تسجيل الدخول' : 'حساب جديد'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitEmailAuth,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(_isLogin ? 'دخول بالبريد' : 'إنشاء حساب'),
                    ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? 'ليس لديك حساب؟ سجل الآن'
                      : 'لديك حساب بالفعل؟ سجل الدخول',
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.horizontal(8.0),
                      child: Text('أو عبر'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              // أزرار منصات التواصل والزائر
              OutlinedButton.icon(
                icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                label: const Text('المتابعة باستخدام Google'),
                onPressed: _signInWithGoogle,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.facebook, color: Colors.blue),
                label: const Text('المتابعة باستخدام Facebook'),
                onPressed: _signInWithFacebook,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.apple, color: Colors.black),
                label: const Text('المتابعة باستخدام Apple'),
                onPressed: _signInWithApple,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.person_outline, color: Colors.grey),
                label: const Text(
                  'الدخول كـ زائر (تصفح سريع)',
                  style: TextStyle(color: Colors.grey),
                ),
                onPressed: _signInAsGuest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
