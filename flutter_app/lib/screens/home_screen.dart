import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/visa_provider.dart';
import '../widgets/check_tab.dart';
import '../widgets/embassies_tab.dart';
import '../widgets/irish_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisaProvider>().loadDashboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ireland Visa Checker'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Check Status'),
            Tab(icon: Icon(Icons.flag_outlined), text: 'Embassies'),
          ],
        ),
      ),
      body: IrishBackground(
        child: TabBarView(
          controller: _tabController,
          children: const [
            CheckTab(),
            EmbassiesTab(),
          ],
        ),
      ),
    );
  }
}
