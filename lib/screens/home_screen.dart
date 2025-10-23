import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pemrograman_mobile/screens/login_screen.dart';
import 'package:pemrograman_mobile/screens/todo_list_screen.dart';
import 'package:pemrograman_mobile/services/shopping_service.dart';
import 'package:pemrograman_mobile/screens/posts_home_screen.dart';

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
  
  // Permission status
  String cameraPermissionStatus = 'Mengecek...';
  String locationPermissionStatus = 'Mengecek...';
  bool isLoading = true;

  // Shopping Service
  final ShoppingService _shoppingService = ShoppingService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadStatistics();
    await _checkPermissions();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        username = prefs.getString('username') ?? 'user';
        email = prefs.getString('email') ?? 'user@example.com';
        fullName = prefs.getString('full_name') ?? 'User';
        joinDate = DateTime.now().subtract(const Duration(days: 45));
      });
    } catch (e) {
      setState(() {
        username = 'user';
        email = 'user@example.com';
        fullName = 'User';
        joinDate = DateTime.now();
      });
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final statistics = await _shoppingService.loadStatistics(username);
      setState(() {
        totalTransactions = statistics['totalTransactions'] ?? 0;
        totalSpending = statistics['totalSpending'] ?? 0.0;
      });
    } catch (e) {
      setState(() {
        totalTransactions = 0;
        totalSpending = 0.0;
      });
    }
  }

  Future<void> _checkPermissions() async {
    // Check camera permission
    final cameraStatus = await Permission.camera.status;
    setState(() {
      cameraPermissionStatus = _getStatusText(cameraStatus);
    });

    // Check location permission
    final locationStatus = await Permission.location.status;
    setState(() {
      locationPermissionStatus = _getStatusText(locationStatus);
    });
  }

  String _getStatusText(PermissionStatus status) {
    if (status.isGranted) return 'Diizinkan';
    if (status.isDenied) return 'Ditolak';
    if (status.isPermanentlyDenied) return 'Ditolak Permanen';
    if (status.isRestricted) return 'Dibatasi';
    if (status.isLimited) return 'Terbatas';
    return 'Tidak Diketahui';
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    
    setState(() {
      cameraPermissionStatus = _getStatusText(status);
    });

    if (status.isGranted) {
      _showSnackBar('Izin kamera diberikan!');
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(
        'Izin Kamera',
        'Aplikasi membutuhkan akses kamera untuk mengambil foto profil. Silakan aktifkan izin kamera di pengaturan.',
      );
    } else {
      _showSnackBar('Izin kamera ditolak');
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    
    setState(() {
      locationPermissionStatus = _getStatusText(status);
    });

    if (status.isGranted) {
      _showSnackBar('Izin lokasi diberikan!');
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(
        'Izin Lokasi',
        'Aplikasi membutuhkan akses lokasi untuk menampilkan toko terdekat. Silakan aktifkan izin lokasi di pengaturan.',
      );
    } else {
      _showSnackBar('Izin lokasi ditolak');
    }
  }

  void _showPermissionDeniedDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title Ditolak'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
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
          _showSnackBar('Logout gagal. Coba lagi.');
        }
      }
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
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
                  // Photo Profil
                  _buildProfileHeader(),
                  const SizedBox(height: 16),
                  
                  // Informasi Akun
                  _buildSectionTitle('Informasi Akun'),
                  _buildProfileItem('Nama Pengguna', username, Icons.person_outline),
                  _buildProfileItem('Email', email, Icons.email_outlined),
                  _buildProfileItem('Nama Lengkap', fullName, Icons.badge_outlined),
                  
                  const SizedBox(height: 8),
                  _buildSectionTitle('Status & Keanggotaan'),
                  _buildProfileItem('Status Akun', 'Aktif', Icons.verified_user_outlined, valueColor: Colors.green),
                  _buildProfileItem('Tingkat Keanggotaan', membershipLevel, Icons.workspace_premium_outlined, valueColor: Colors.amber),
                  _buildProfileItem('Tanggal Bergabung', _formatDate(joinDate), Icons.calendar_today_outlined),
                  
                  const SizedBox(height: 8),
                  _buildSectionTitle('Izin Aplikasi'),
                  _buildPermissionItemDialog(
                    'Kamera',
                    cameraPermissionStatus,
                    Icons.camera_alt,
                    () async {
                      Navigator.pop(context);
                      await _requestCameraPermission();
                    },
                    setDialogState,
                  ),
                  _buildPermissionItemDialog(
                    'Lokasi', 
                    locationPermissionStatus,
                    Icons.location_on,
                    () async {
                      Navigator.pop(context);
                      await _requestLocationPermission();
                    },
                    setDialogState,
                  ),
                  
                  const SizedBox(height: 8),
                  _buildSectionTitle('Statistik Belanja'),
                  _buildProfileItem('Total Transaksi', '$totalTransactions transaksi', Icons.receipt_long_outlined),
                  _buildProfileItem('Total Pengeluaran', _formatCurrency(totalSpending), Icons.attach_money_outlined, valueColor: Colors.red),
                  _buildProfileItem('Rata-rata Harian', _formatCurrency(totalSpending / 30), Icons.trending_up_outlined),
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
                        Navigator.pop(context);
                        _showEditProfileDialog();
                      },
                      child: const Text('Edit Profil'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
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
        const SizedBox(height: 12),
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          '@$username',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
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

  Widget _buildProfileItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
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
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItemDialog(
    String title, 
    String status, 
    IconData icon, 
    VoidCallback onRequest,
    StateSetter setDialogState,
  ) {
    final Color statusColor = status.contains('Ditolak') 
        ? Colors.red 
        : status.contains('Mengecek') 
            ? Colors.orange 
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          if (!status.contains('Diizinkan'))
            ElevatedButton(
              onPressed: onRequest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Minta Izin',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Fitur edit profil akan segera hadir!'),
            const SizedBox(height: 16),
            Icon(Icons.construction, size: 40, color: Colors.orange.shade400),
            const SizedBox(height: 8),
            const Text(
              'Fitur dalam pengembangan',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
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

  void _showPermissionsManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            SizedBox(width: 8),
            Text('Kelola Izin Aplikasi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPermissionManagementCard(
              'Kamera',
              cameraPermissionStatus,
              Icons.camera_alt,
              'Untuk mengambil foto profil',
              _requestCameraPermission,
            ),
            const SizedBox(height: 12),
            _buildPermissionManagementCard(
              'Lokasi',
              locationPermissionStatus,
              Icons.location_on,
              'Untuk menampilkan toko terdekat',
              _requestLocationPermission,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionManagementCard(
    String title, 
    String status, 
    IconData icon, 
    String description, 
    VoidCallback onRequest
  ) {
    final Color statusColor = status.contains('Ditolak') ? Colors.red : Colors.green;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            if (!status.contains('Diizinkan'))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Minta Izin',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Beranda', 
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: _showPermissionsManagement,
            icon: const Icon(Icons.security, size: 22),
            tooltip: 'Kelola Izin',
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, size: 22),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
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
                  style: const TextStyle(
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
              'Beranda',
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
                  builder: (context) => TodoListScreen(username: username),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.article, size: 20),
            title: const Text(
              'Posts API Demo',
              style: TextStyle(fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PostsHomeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, size: 20),
            title: const Text(
              'Profil Saya',
              style: TextStyle(fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
              _showProfileDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.security, size: 20),
            title: const Text(
              'Kelola Izin',
              style: TextStyle(fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
              _showPermissionsManagement();
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
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Halo, $username! Selamat datang kembali.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: [
                _buildDashboardCard(
                  'Profil Saya', 
                  Icons.person, 
                  Colors.green, 
                  () => _showProfileDialog()
                ),
                _buildDashboardCard(
                  'Daftar Belanja', 
                  Icons.shopping_cart, 
                  Colors.orange, 
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TodoListScreen(username: username),
                      ),
                    );
                  }
                ),
                _buildDashboardCard(
                  'Posts API', 
                  Icons.article, 
                  Colors.purple, 
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PostsHomeScreen()),
                    );
                  }
                ),
                _buildDashboardCard(
                  'Kelola Izin', 
                  Icons.security, 
                  Colors.blue, 
                  _showPermissionsManagement
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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