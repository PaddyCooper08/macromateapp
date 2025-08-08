import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/macro_provider.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _telegramIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _telegramIdController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final macroProvider = Provider.of<MacroProvider>(context, listen: false);
    final success = await macroProvider.login(
      _telegramIdController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use themed background so dark mode stays black/white only
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Provider.of<ThemeProvider>(context).isDarkMode
                        ? Colors.black
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Provider.of<ThemeProvider>(context).isDarkMode
                          ? Colors.white24
                          : Colors.black12,
                    ),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 60,
                    color: Provider.of<ThemeProvider>(context).isDarkMode
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'MacroMate',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your macros with ease',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),

                // Login Form
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Login',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Telegram ID Field
                          TextFormField(
                            controller: _telegramIdController,
                            decoration: InputDecoration(
                              labelText: 'Telegram ID',
                              hintText: 'Enter your Telegram ID',
                              prefixIcon: const Icon(Icons.telegram),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              helperText:
                                  'Find your ID by messaging @userinfobot on Telegram',
                              helperMaxLines: 2,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your Telegram ID';
                              }
                              if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                                return 'Telegram ID should only contain numbers';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          Consumer<MacroProvider>(
                            builder: (context, macroProvider, child) {
                              return ElevatedButton(
                                onPressed: macroProvider.isLoading
                                    ? null
                                    : _login,
                                // Colors come from elevatedButtonTheme
                                child: macroProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              );
                            },
                          ),

                          // Error Message
                          Consumer<MacroProvider>(
                            builder: (context, macroProvider, child) {
                              if (macroProvider.error != null) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          Provider.of<ThemeProvider>(
                                            context,
                                          ).isDarkMode
                                          ? Colors.white10
                                          : Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            Provider.of<ThemeProvider>(
                                              context,
                                            ).isDarkMode
                                            ? Colors.white24
                                            : Colors.red[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color:
                                              Provider.of<ThemeProvider>(
                                                context,
                                              ).isDarkMode
                                              ? Colors.white
                                              : Colors.red[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            macroProvider.error!,
                                            style: TextStyle(
                                              color:
                                                  Provider.of<ThemeProvider>(
                                                    context,
                                                  ).isDarkMode
                                                  ? Colors.white
                                                  : Colors.red[700],
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: macroProvider.clearError,
                                          icon: Icon(
                                            Icons.close,
                                            color:
                                                Provider.of<ThemeProvider>(
                                                  context,
                                                ).isDarkMode
                                                ? Colors.white
                                                : Colors.red[700],
                                          ),
                                          iconSize: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info Card
                Card(
                  color: Provider.of<ThemeProvider>(context).isDarkMode
                      ? Colors.black
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Provider.of<ThemeProvider>(context).isDarkMode
                          ? Colors.white24
                          : Colors.black12,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Provider.of<ThemeProvider>(context).isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How to find your Telegram ID:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                Provider.of<ThemeProvider>(context).isDarkMode
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '1. Open Telegram\n2. Search for @userinfobot\n3. Start a chat and it will show your ID',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
