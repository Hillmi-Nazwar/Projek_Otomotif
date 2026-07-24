import 'package:flutter/material.dart';
import 'package:project_automotive/daftar_pesanan_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';// Import screen tambah pesanan

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:'https://narjjynkiubsjtwlffig.supabase.co',
    publishableKey:'sb_publishable_ZjZhmcSz15y_DwGAzBc35w_3_S8AxfK',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DantieWrap',
      debugShowCheckedModeBanner: false, // Menghilangkan pita debug merah di kanan atas
      theme: ThemeData.dark(), // Mengatur tema dasar dark mode
      home: const DaftarPesananScreen(), 
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 1. Tempat menyimpan daftar jasa yang diambil dari Supabase nanti
  List<dynamic> _daftarJasa = [];
  
  // 2. Status untuk menampilkan indikator loading muter-muter
  bool _isLoading = true;

  // 3. Fungsi bawaan Flutter yang otomatis berjalan pertama kali saat halaman dibuka
  @override
  void initState() {
    super.initState();
    _ambilDataDariSupabase(); // Langsung suruh aplikasi ambil data
  }

  // 4. Otak pemroses data (Async karena menembak data lewat internet ke Singapore)
  Future<void> _ambilDataDariSupabase() async {
    try {
      // Perintah resmi Supabase untuk: "Ambil semua data dari tabel bernama 'jasa'"
      final response = await Supabase.instance.client
          .from('jasa')
          .select();

      // Perbarui tampilan UI dengan data yang baru didapat
      setState(() {
        _daftarJasa = response;
        _isLoading = false; // Loading dimatikan karena data sudah sampai
      });
    } catch (e) {
      // Jika terjadi error (misal internet mati), infonya akan muncul di terminal debug
      print('Waduh, ada error pas ambil data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      // 5. Kondisi UI: Jika masih loading tampilkan lingkaran muter, jika selesai tampilkan list
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _daftarJasa.isEmpty
              ? const Center(child: Text('Data jasa masih kosong melongpong.'))
              : ListView.builder(
                  itemCount: _daftarJasa.length,
                  itemBuilder: (context, index) {
                    final item = _daftarJasa[index];
                    return ListTile(
                      leading: const Icon(Icons.build_circle, color: Colors.deepPurple),
                      title: Text(item['nama_jasa'] ?? 'Tanpa Nama'),
                      subtitle: Text('Harga: Rp ${item['harga'] ?? 0}'),
                    );
                  },
                ),
    );
  }
}