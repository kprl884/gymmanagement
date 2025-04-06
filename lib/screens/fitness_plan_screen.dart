import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FitnessPlanScreen extends StatefulWidget {
  const FitnessPlanScreen({Key? key}) : super(key: key);

  @override
  State<FitnessPlanScreen> createState() => _FitnessPlanScreenState();
}

class _FitnessPlanScreenState extends State<FitnessPlanScreen> {
  int selectedProgramIndex = 0;

  final List<Map<String, dynamic>> programTypes = [
    {
      'icon': FontAwesomeIcons.dumbbell,
      'label': 'Fitness',
    },
    {
      'icon': FontAwesomeIcons.appleWhole,
      'label': 'Beslenme',
    },
    {
      'icon': FontAwesomeIcons.personRunning,
      'label': 'Kardiyo',
    },
    {
      'icon': FontAwesomeIcons.weightHanging,
      'label': 'Güç',
    },
    {
      'icon': FontAwesomeIcons.handHoldingHeart,
      'label': 'Yoga',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Program Oluştur'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Program Tipleri Yatay Liste
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Program Tipleri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: programTypes.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedProgramIndex = index;
                      });
                    },
                    child: _buildProgramTypeCard(
                      icon: programTypes[index]['icon'],
                      label: programTypes[index]['label'],
                      isSelected: selectedProgramIndex == index,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Popüler Şablonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popüler Şablonlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Şablon Kartları
            _buildTemplateCard(
              icon: FontAwesomeIcons.personRunning,
              color: Colors.blue,
              title: 'Başlangıç Antrenman Planı',
              duration: '12 haftalık program',
              users: '2.5k kullanıcı',
            ),
            const SizedBox(height: 12),
            _buildTemplateCard(
              icon: FontAwesomeIcons.fire,
              color: Colors.purple,
              title: 'HIIT Antrenmanı',
              duration: '8 haftalık program',
              users: '1.8k kullanıcı',
            ),

            // Özel Program Oluştur Butonu
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const FaIcon(FontAwesomeIcons.plus),
                label: const Text('Özel Program Oluştur'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.fileLines),
            label: 'Şablonlar',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.folder),
            label: 'Dosyalar',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.user),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildProgramTypeCard({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              icon,
              size: 24,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard({
    required IconData icon,
    required Color color,
    required String title,
    required String duration,
    required String users,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(icon, size: 24, color: color),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  users,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const FaIcon(
            FontAwesomeIcons.chevronRight,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
