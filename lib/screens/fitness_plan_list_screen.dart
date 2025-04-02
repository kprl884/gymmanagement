import 'package:flutter/material.dart';
import '../models/fitness_plan.dart';
import '../services/fitness_plan_service.dart';

class FitnessPlanListScreen extends StatefulWidget {
  const FitnessPlanListScreen({Key? key}) : super(key: key);

  @override
  _FitnessPlanListScreenState createState() => _FitnessPlanListScreenState();
}

class _FitnessPlanListScreenState extends State<FitnessPlanListScreen> {
  final FitnessPlanService _planService = FitnessPlanService();
  List<FitnessPlan> _plans = [];
  List<FitnessPlan> _filteredPlans = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final plans = await _planService.getAllPlans();
      setState(() {
        _plans = plans;
        _filteredPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Planlar yüklenirken hata: $e')),
      );
    }
  }

  void _filterPlans(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPlans = _plans;
      } else {
        _filteredPlans = _plans
            .where((plan) =>
                plan.name.toLowerCase().contains(query.toLowerCase()) ||
                plan.description.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterPlans,
              decoration: InputDecoration(
                labelText: 'Fitness Planı Ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _filterPlans(''),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          // Plan listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPlans.isEmpty
                    ? const Center(child: Text('Fitness planı bulunamadı'))
                    : ListView.builder(
                        itemCount: _filteredPlans.length,
                        itemBuilder: (context, index) {
                          final plan = _filteredPlans[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            child: ListTile(
                              title: Text(
                                plan.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                plan.description.length > 50
                                    ? '${plan.description.substring(0, 50)}...'
                                    : plan.description,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getDifficultyColor(plan.difficulty),
                                child: Text(
                                  _getDifficultyShort(plan.difficulty),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${plan.durationWeeks} hafta'),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                              onTap: () {
                                // Plan detayına git
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yeni plan ekleme ekranına git
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getDifficultyShort(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 'B';
      case 'intermediate':
        return 'I';
      case 'advanced':
        return 'A';
      default:
        return '?';
    }
  }
}
