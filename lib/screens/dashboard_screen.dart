import 'package:flutter/material.dart';
import '../services/customer_service.dart';
import '../models/customer_data.dart';
import '../widgets/monthly_customer_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CustomerService _customerService = CustomerService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FutureBuilder<List<CustomerData>>(
              future: _customerService.getMonthlyCustomerData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Henüz müşteri verisi bulunmuyor'),
                  );
                }

                return MonthlyCustomerChart(data: snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
