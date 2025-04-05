import '../widgets/monthly_customer_chart.dart';
import '../services/customer_service.dart';

class DashboardScreen extends StatelessWidget {
  final CustomerService _customerService = CustomerService();

  @override
  Widget build(BuildContext context) {
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Veri yüklenirken bir hata oluştu'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Veri bulunamadı'));
                }

                return MonthlyCustomerChart(data: snapshot.data!);
              },
            ),
            // Diğer widget'lar...
          ],
        ),
      ),
    );
  }
}
