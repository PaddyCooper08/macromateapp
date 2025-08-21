import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/macro_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/macro_summary_card.dart';
import '../widgets/meal_list.dart';
import '../widgets/add_meal_fab.dart';
import '../widgets/custom_app_bar.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _TodayTab(),
    const FavoritesScreen(),
    const HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Refresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MacroProvider>(context, listen: false).loadTodaysMacros();
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<MacroProvider>(context, listen: false).logout();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _getAppBarTitle(),
        actions: [
          if (_currentIndex == 0) ...[
            // Gemini usage counter
            Consumer<MacroProvider>(
              builder: (context, macroProvider, child) {
                if (macroProvider.adFree) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Center(
                      child: Text(
                        'AD-FREE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Text(
                      'Gemini: ${macroProvider.geminiUses}/3',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              onPressed: () {
                Provider.of<MacroProvider>(
                  context,
                  listen: false,
                ).loadTodaysMacros();
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                _logout();
              } else if (value == 'toggle_ad_free') {
                final macroProvider = Provider.of<MacroProvider>(
                  context,
                  listen: false,
                );
                await macroProvider.setAdFree(!macroProvider.adFree);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        macroProvider.adFree
                            ? 'Ad-free mode enabled (Testing)'
                            : 'Ad-free mode disabled (Testing)',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'toggle_ad_free',
                child: Consumer<MacroProvider>(
                  builder: (context, macroProvider, child) => Row(
                    children: [
                      Icon(
                        macroProvider.adFree ? Icons.block : Icons.local_offer,
                        color: macroProvider.adFree
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        macroProvider.adFree
                            ? 'Disable Ad-Free (Testing)'
                            : 'Enable Ad-Free (Testing)',
                        style: TextStyle(
                          color: macroProvider.adFree
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).getErrorColor(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).getErrorColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<MacroProvider>(
        builder: (context, macroProvider, child) {
          if (macroProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).getErrorColor(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${macroProvider.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).getErrorColor(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      macroProvider.clearError();
                      if (_currentIndex == 0) {
                        macroProvider.loadTodaysMacros();
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return _screens[_currentIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Provider.of<ThemeProvider>(
          context,
          listen: false,
        ).getAccentColor(context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? const AddMealFab() : null,
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Today\'s Macros';
      case 1:
        return 'Favorites';
      case 2:
        return 'History';
      default:
        return 'MacroMate';
    }
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<MacroProvider>(
      builder: (context, macroProvider, child) {
        if (macroProvider.isLoading && macroProvider.todaysMeals.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => macroProvider.loadTodaysMacros(),
          child: CustomScrollView(
            slivers: [
              // Macro Summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MacroSummaryCard(
                    totalProtein: macroProvider.totalProtein,
                    totalCarbs: macroProvider.totalCarbs,
                    totalFats: macroProvider.totalFats,
                    totalCalories: macroProvider.totalCalories,
                  ),
                ),
              ),

              // Meals Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Today\'s Meals',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${macroProvider.todaysMeals.length} meals',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Meals List
              MealList(meals: macroProvider.todaysMeals),
            ],
          ),
        );
      },
    );
  }
}
