import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/macromate_logo.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AppBar(
      leading: showBackButton
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: MacroMateLogo(
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () => themeProvider.toggleTheme(),
          icon: Icon(
            themeProvider.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          tooltip: themeProvider.isDarkMode
              ? 'Switch to Light Mode'
              : 'Switch to Dark Mode',
        ),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
