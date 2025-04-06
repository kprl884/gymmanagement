import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  // Örnek SSS verileri
  final List<Map<String, String>> faqs = [
    {
      'question': 'Spor salonunda başlamak için ne yapmalıyım?',
      'answer':
          'deneme 1 İlk olarak üyelik kaydınızı yaptırıp, sağlık durumunuzu değerlendirmek için form doldurmanız gerekiyor. Ardından size uygun bir program belirlenecek.',
    },
    {
      'question': 'Hangi sıklıkta antrenman yapmalıyım?',
      'answer':
          'Başlangıçta haftada 3-4 gün antrenman yapmanız önerilir. Vücudunuzun adaptasyonuna göre bu süre artırılabilir.',
    },
    {
      'question': 'Antrenman öncesi ne yemeliyim?',
      'answer':
          'Antrenmandan 2-3 saat önce protein ve karbonhidrat içeren hafif bir öğün tüketebilirsiniz. Örneğin: yulaf, muz ve protein tozu.',
    },
    {
      'question': 'Kas ağrılarını nasıl azaltabilirim?',
      'answer':
          'Düzenli stretching yaparak, yeterli su tüketerek ve dinlenmeye özen göstererek kas ağrılarını minimize edebilirsiniz.',
    },
  ];

  void _addNewFaq() {
    setState(() {
      faqs.add({
        'question': 'Yeni Soru',
        'answer': 'Cevabınızı buraya ekleyin...',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sık Sorulan Sorular',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Template Header
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spor Salonu SSS',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Spor salonu hakkında sık sorulan soruları ve cevaplarını burada bulabilirsiniz.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // FAQ Items
                  ...List.generate(
                    faqs.length,
                    (index) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.question,
                                size: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  faqs[index]['question']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  faqs[index]['answer']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
