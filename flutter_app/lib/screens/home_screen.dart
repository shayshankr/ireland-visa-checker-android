import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/saved_numbers_provider.dart';
import '../providers/visa_provider.dart';
import '../widgets/about_sheet.dart';
import '../widgets/check_tab.dart';
import '../widgets/embassies_tab.dart';
import '../widgets/irish_background.dart';
import '../widgets/saved_numbers_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisaProvider>().loadDashboard();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sync My Numbers with any updates the background watcher made while the
    // app was in the background.
    if (state == AppLifecycleState.resumed) {
      context.read<SavedNumbersProvider>().reload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedNumbersProvider>(
      builder: (context, savedProvider, _) {
        final watchedCount =
            savedProvider.numbers.where((n) => n.watchEnabled).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ireland Visa Checker'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'About',
                onPressed: () => showAboutSheet(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              tabs: [
                const Tab(
                    icon: Icon(Icons.search), text: 'Check Status'),
                Tab(
                  text: 'My Numbers',
                  icon: Badge(
                    isLabelVisible: watchedCount > 0,
                    label: Text('$watchedCount'),
                    child:
                        const Icon(Icons.bookmarks_outlined),
                  ),
                ),
                const Tab(
                    icon: Icon(Icons.flag_outlined),
                    text: 'Embassies'),
              ],
            ),
          ),
          body: IrishBackground(
            child: TabBarView(
              controller: _tabController,
              children: const [
                CheckTab(),
                SavedNumbersTab(),
                EmbassiesTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}
