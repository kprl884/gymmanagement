// Yardım butonu
TextButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yardım'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Giriş yaparken sorun mu yaşıyorsunuz?'),
            const SizedBox(height: 8),
            const Text('Lütfen yönetici ile iletişime geçin:'),
            const SizedBox(height: 4),
            Text('E-posta: ${AppConstants.adminEmail}'),
            Text('Telefon: ${AppConstants.supportPhone}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  },
  child: const Text('Yardım'),
), 

Future<void> _signIn() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
      
      // Kullanıcı verilerini al
      final userData = await _userService.getCurrentUserData();
      
      if (userData != null) {
        // Rol kontrolü yap ve uygun ekrana yönlendir
        if (userData.role == UserRole.admin) {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else if (userData.role == UserRole.staff) {
          Navigator.pushReplacementNamed(context, '/staff_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/customer_dashboard');
        }
      } else {
        ToastHelper.showErrorToast(
            context, 'Kullanıcı bilgileri alınamadı.');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showErrorToast(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 