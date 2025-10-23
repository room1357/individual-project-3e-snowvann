import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pemrograman_mobile/screens/login_screen.dart';
import 'package:pemrograman_mobile/screens/todo_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = '';
  String email = '';
  String fullName = '';
  DateTime? joinDate;
  int totalTransactions = 0;
  double totalSpending = 0.0;
  String membershipLevel = 'Basic';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        username = prefs.getString('username') ?? 'user';
        email = prefs.getString('email') ?? 'user@example.com';
        fullName = prefs.getString('full_name') ?? 'User';
        
        // Simulasi data untuk demo
        joinDate = DateTime.now().subtract(const Duration(days: 45));
        totalTransactions = 15;
        totalSpending = 1250000.0;
        membershipLevel = 'Basic';
      });
    } catch (e) {
      setState(() {
        username = 'user';
        email = 'user@example.com';
        fullName = 'User';
        joinDate = DateTime.now();
        totalTransactions = 0;
        totalSpending = 0.0;
        membershipLevel = 'Basic';
      });
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logout gagal. Coba lagi.')),
          );
        }
      }
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text(
              'Informasi Profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Profil dan Info Dasar
              _buildProfileHeader(),
              const SizedBox(height: 16),
              
              // Informasi Akun
              _buildSectionTitle('Informasi Akun'),
              _buildProfileItemWithIcon(
                Icons.person_outline,
                'Nama Pengguna',
                username,
              ),
              _buildProfileItemWithIcon(
                Icons.email_outlined,
                'Email',
                email,
              ),
              _buildProfileItemWithIcon(
                Icons.badge_outlined,
                'Nama Lengkap',
                fullName,
              ),
              
              const SizedBox(height: 8),
              _buildSectionTitle('Status & Keanggotaan'),
              _buildProfileItemWithIcon(
                Icons.verified_user_outlined,
                'Status Akun',
                'Aktif',
                valueColor: Colors.green,
              ),
              _buildProfileItemWithIcon(
                Icons.workspace_premium_outlined,
                'Tingkat Keanggotaan',
                membershipLevel,
                valueColor: Colors.amber[700],
              ),
              _buildProfileItemWithIcon(
                Icons.calendar_today_outlined,
                'Tanggal Bergabung',
                _formatDate(joinDate),
              ),
              
              const SizedBox(height: 8),
              _buildSectionTitle('Statistik Belanja'),
              _buildProfileItemWithIcon(
                Icons.receipt_long_outlined,
                'Total Transaksi',
                '$totalTransactions transaksi',
              ),
              _buildProfileItemWithIcon(
                Icons.attach_money_outlined,
                'Total Pengeluaran',
                _formatCurrency(totalSpending),
                valueColor: Colors.red,
              ),
              _buildProfileItemWithIcon(
                Icons.trending_up_outlined,
                'Rata-rata Harian',
                _formatCurrency(totalSpending / 30),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement edit profile
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur edit profil akan segera hadir!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Edit Profil'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: username.isNotEmpty
                  ? Text(
                      username[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : const Icon(Icons.person, size: 40, color: Colors.blue),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '@$username',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.blue[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // PERBAIKAN: Ganti parameter Color dengan dynamic
  Widget _buildProfileItemWithIcon(IconData icon, String label, String value, {dynamic valueColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor is MaterialColor ? valueColor : (valueColor ?? Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur $feature akan segera hadir!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home', 
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, size: 22),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 30, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Halo, $username!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${username.toLowerCase()}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      membershipLevel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, size: 20),
              title: const Text(
                'Home',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, size: 20),
              title: const Text(
                'Daftar Belanja',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TodoListScreen(username: username), // Kirim username
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, size: 20),
              title: const Text(
                'Profil',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                _showProfileDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, size: 20),
              title: const Text(
                'Pengaturan',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Pengaturan');
              },
            ),
            const Divider(height: 20),
            ListTile(
              leading: const Icon(Icons.logout, size: 20),
              title: const Text(
                'Logout',
                style: TextStyle(fontSize: 14),
              ),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Halo, $username! Selamat datang kembali.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                padding: const EdgeInsets.all(4),
                children: [
                  _buildDashboardCard('Profil', Icons.person, Colors.green, () {
                    _showProfileDialog();
                  }),
                  _buildDashboardCard('Daftar Belanja', Icons.shopping_cart, Colors.orange, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TodoListScreen(username: username), // Kirim username
                      ),
                    );
                  }),
                  _buildDashboardCard('Statistik', Icons.analytics_outlined, Colors.purple, () {
                    _showComingSoon('Statistik');
                  }),
                  _buildDashboardCard('Bantuan', Icons.help, Colors.red, () {
                    _showComingSoon('Bantuan');
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, MaterialColor color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}