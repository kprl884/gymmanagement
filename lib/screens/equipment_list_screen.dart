import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../services/equipment_service.dart';
import '../utils/toast_helper.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({Key? key}) : super(key: key);

  @override
  _EquipmentListScreenState createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final EquipmentService _equipmentService = EquipmentService();
  List<Equipment> _equipmentList = [];
  List<Equipment> _filteredEquipmentList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  List<String> _categories = ['Tümü'];

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final equipmentList = await _equipmentService.getAllEquipment();

      // Kategorileri çıkar
      final categories = equipmentList.map((e) => e.category).toSet().toList();
      categories.sort();

      setState(() {
        _equipmentList = equipmentList;
        _filteredEquipmentList = equipmentList;
        _categories = ['Tümü', ...categories];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ekipmanlar yüklenirken hata: $e')),
      );
    }
  }

  void _filterEquipment() {
    setState(() {
      if (_searchQuery.isEmpty && _selectedCategory == 'Tümü') {
        _filteredEquipmentList = _equipmentList;
      } else {
        _filteredEquipmentList = _equipmentList.where((equipment) {
          final matchesSearch = _searchQuery.isEmpty ||
              equipment.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              equipment.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());

          final matchesCategory = _selectedCategory == 'Tümü' ||
              equipment.category == _selectedCategory;

          return matchesSearch && matchesCategory;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Arama ve filtreleme
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Arama çubuğu
                TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterEquipment();
                  },
                  decoration: InputDecoration(
                    labelText: 'Ekipman Ara',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _filterEquipment();
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 8),

                // Kategori filtresi
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category;
                                _filterEquipment();
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Ekipman listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEquipmentList.isEmpty
                    ? const Center(child: Text('Ekipman bulunamadı'))
                    : ListView.builder(
                        itemCount: _filteredEquipmentList.length,
                        itemBuilder: (context, index) {
                          final equipment = _filteredEquipmentList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            child: ListTile(
                              title: Text(
                                equipment.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    equipment.description.length > 50
                                        ? '${equipment.description.substring(0, 50)}...'
                                        : equipment.description,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(equipment.category),
                                        backgroundColor: Colors.blue[100],
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          equipment.isAvailable
                                              ? 'Kullanılabilir'
                                              : 'Kullanılamaz',
                                        ),
                                        backgroundColor: equipment.isAvailable
                                            ? Colors.green[100]
                                            : Colors.red[100],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(
                                  _getCategoryIcon(equipment.category),
                                  color: Colors.white,
                                ),
                              ),
                              onTap: () {
                                // Ekipman detayına git
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
          // Yeni ekipman ekleme ekranına git
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'strength':
        return Icons.fitness_center;
      case 'flexibility':
        return Icons.accessibility_new;
      default:
        return Icons.sports_gymnastics;
    }
  }
}
