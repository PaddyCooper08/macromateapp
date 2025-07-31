import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/macro_provider.dart';
import '../widgets/macro_summary_card.dart';
import '../widgets/meal_list.dart';
import '../widgets/add_meal_fab.dart';
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
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.blue[500],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentIndex == 0)
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red[600])),
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
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${macroProvider.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[600]),
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
        selectedItemColor: Colors.blue[500],
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
