import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🔴 PENTING: Untuk mendeteksi kIsWeb (HP vs Laptop)
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // 🔴 PENTING: Untuk logo resmi WhatsApp
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'tambah_pesanan_screen.dart';

class DaftarPesananScreen extends StatefulWidget {
  const DaftarPesananScreen({super.key});

  @override
  State<DaftarPesananScreen> createState() => _DaftarPesananScreenState();
}

class _DaftarPesananScreenState extends State<DaftarPesananScreen> {
  List<Map<String, dynamic>> _daftarPesanan = [];
  bool _isLoading = true;
  int _totalOmsetSelesai = 0;
  String _statusFilterTerpilih = 'Semua'; 

  final TextEditingController _searchController = TextEditingController();
  String _kataKunciPencarian = '';

  @override
  void initState() {
    super.initState();
    _ambilDataPesanan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ambilDataPesanan() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('pesanan')
          .select('*, jasa(nama_jasa)')
          .order('id', ascending: false);

      final listData = List<Map<String, dynamic>>.from(data);

      int hitungOmset = 0;
      for (var item in listData) {
        if (item['status'] == 'Selesai' && item['harga_aktual'] != null) {
          hitungOmset += int.parse(item['harga_aktual'].toString());
        }
      }

      setState(() {
        _daftarPesanan = listData;
        _totalOmsetSelesai = hitungOmset;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _hapusDataPesananLangsung(dynamic id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('pesanan').delete().eq('id', id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi sukses dihapus!'), backgroundColor: Colors.redAccent),
        );
      }
      _ambilDataPesanan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🔴 PENJELASAN LOGIKA PINTAR WHATSAPP
  Future<void> _kirimWhatsApp(String noHp, String namaCust, String namaKendaraan, String status) async {
    if (noHp == '-' || noHp.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal kirim, nomor HP Pelanggan kosong!'), backgroundColor: Colors.orange),
      );
      return;
    }

    // 1. Bersihkan Format Nomor HP
    String nomorBersih = noHp.trim().replaceAll(' ', '').replaceAll('-', '');
    if (nomorBersih.startsWith('0')) {
      nomorBersih = '62${nomorBersih.substring(1)}';
    }

    // 2. Draf Pesan Otomatis Beserta Emoji
    String templatePesan = "";
    if (status == 'Selesai') {
      templatePesan = "Halo Kak $namaCust, pengerjaan skotlet/wrapping untuk kendaraan *($namaKendaraan)* sudah *SELESAI RAPI* di bengkel *DantieWrap* dan siap diambil ya kak. Terima kasih banyak atas kepercayaannya! 🙏";
    } else if (status == 'Sedang Dikerjakan') {
      templatePesan = "Halo Kak $namaCust, menginfokan bahwa kendaraan *($namaKendaraan)* saat ini *SEDANG DIKERJAKAN* oleh tim *DantieWrap*. Progres terbaik sedang kami berikan, mohon ditunggu ya kak! 💪";
    } else {
      templatePesan = "Halo Kak $namaCust, data *BOOKING* untuk kendaraan *($namaKendaraan)* sudah tercatat di sistem *DantieWrap*. Silakan datang sesuai jadwal ya kak. Terima kasih! 😊";
    }

    // 3. Gunakan Link Universal api.whatsapp.com
    // Format ini aman untuk Emoji & Menampilkan Halaman Pilihan (Open App / WA Web)
    final String urlString = "https://api.whatsapp.com/send?phone=$nomorBersih&text=${Uri.encodeComponent(templatePesan)}";
    final Uri urlWa = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(urlWa)) {
        await launchUrl(urlWa, mode: LaunchMode.externalApplication);
      } else {
        throw 'Aplikasi/Browser WhatsApp tidak dapat dibuka';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka WhatsApp: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _tampilkanDialogKonfirmasiHapus(dynamic id, String namaKendaraan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xff1E1E1E),
          title: const Text('Konfirmasi Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text('Apakah Anda yakin ingin menghapus transaksi data "$namaKendaraan"?', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATAL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(context);
                _hapusDataPesananLangsung(id);
              },
              child: const Text('YA, HAPUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        );
      },
    );
  }

  Color _dapatkanWarnaStatus(String status) {
    switch (status) {
      case 'Booking':
        return const Color(0xffFF9100);
      case 'Sedang Dikerjakan':
        return Colors.blueAccent;
      case 'Selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final omsetFormat = _totalOmsetSelesai.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');

    final listTersaring = _daftarPesanan.where((item) {
      bool cocokStatus = _statusFilterTerpilih == 'Semua' || item['status'] == _statusFilterTerpilih;
      
      final keyword = _kataKunciPencarian.toLowerCase();
      final namaMobil = (item['nama_kendaraan'] ?? '').toString().toLowerCase();
      final merkMobil = (item['merk_kendaraan'] ?? '').toString().toLowerCase();
      final namaOrang = (item['nama_customer'] ?? '').toString().toLowerCase();

      bool cocokSearch = namaMobil.contains(keyword) || 
                          merkMobil.contains(keyword) || 
                          namaOrang.contains(keyword);

      return cocokStatus && cocokSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xff0A0A0A),
      appBar: AppBar(
        title: const Text(
          'DantieWrap Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xff0A0A0A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: _ambilDataPesanan,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xffFF9100)))
          : Column(
              children: [
                // TOTAL OMSET
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xff1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffFF9100), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL PENDAPATAN (SELESAI RILL)', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      const SizedBox(height: 8),
                      Text(
                        'Rp $omsetFormat',
                        style: const TextStyle(color: Color(0xffFF9100), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                ),

                // SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Cari nama kendaraan, merk, atau pelanggan...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 15),
                      prefixIcon: const Icon(Icons.search, color: Color(0xffFF9100), size: 24),
                      suffixIcon: _kataKunciPencarian.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white54),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _kataKunciPencarian = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xff1E1E1E),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xffFF9100), width: 1.5),
                      ),
                    ),
                    onChanged: (nilai) {
                      setState(() {
                        _kataKunciPencarian = nilai;
                      });
                    },
                  ),
                ),
                
                // FILTER TAB HORIZONTAL
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 12),
                  child: Row(
                    children: ['Semua', 'Booking', 'Sedang Dikerjakan', 'Selesai'].map((status) {
                      final bool isTerpilih = _statusFilterTerpilih == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _statusFilterTerpilih = status;
                            });
                          },
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isTerpilih ? const Color(0xffFF9100) : const Color(0xff1E1E1E),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isTerpilih ? const Color(0xffFF9100) : Colors.white10,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: isTerpilih ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                // DAFTAR CARD TRANSAKSI
                Expanded(
                  child: listTersaring.isEmpty
                      ? Center(
                          child: Text(
                            _kataKunciPencarian.isEmpty
                                ? 'Tidak ada data status "$_statusFilterTerpilih"'
                                : 'Data tidak ditemukan...',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xffFF9100),
                          onRefresh: _ambilDataPesanan,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: listTersaring.length,
                            itemBuilder: (context, index) {
                              final item = listTersaring[index];
                              final namaJasa = item['jasa'] != null ? item['jasa']['nama_jasa'] : 'Jasa tidak terikat';
                              final hargaFormat = item['harga_aktual'].toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');
                              
                              final namaCust = (item['nama_customer'] == null || item['nama_customer'].toString().trim().isEmpty) ? 'Tanpa Nama' : item['nama_customer'];
                              final noHp = (item['no_hp'] == null || item['no_hp'].toString().trim().isEmpty) ? '-' : item['no_hp'];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Card(
                                  color: const Color(0xff1E1E1E),
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Colors.white10, width: 1),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item['nama_kendaraan'] ?? 'Tanpa Nama',
                                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // 🔴 LOGO RESMI WHATSAPP PAKAI FaIcon
                                                if (noHp != '-') ...[
                                                  IconButton(
                                                    icon: const FaIcon(
                                                      FontAwesomeIcons.whatsapp, 
                                                      color: Color(0xff25D366), // Warna hijau asli WA
                                                      size: 24,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    tooltip: 'Kirim Pesan WhatsApp',
                                                    onPressed: () => _kirimWhatsApp(
                                                      noHp, 
                                                      namaCust, 
                                                      item['nama_kendaraan'] ?? 'Unit', 
                                                      item['status'] ?? 'Booking'
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                ],
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _dapatkanWarnaStatus(item['status'] ?? '').withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: _dapatkanWarnaStatus(item['status'] ?? '')),
                                                  ),
                                                  child: Text(
                                                    item['status'] ?? 'Status',
                                                    style: TextStyle(color: _dapatkanWarnaStatus(item['status'] ?? ''), fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(item['merk_kendaraan'] ?? '-', style: const TextStyle(color: Colors.white54, fontSize: 15)),
                                        const Divider(color: Colors.white10, height: 24),
                                        
                                        Row(
                                          children: [
                                            const Icon(Icons.build_circle_outlined, size: 18, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(namaJasa, style: const TextStyle(color: Colors.white70, fontSize: 15), overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text("$namaCust ($noHp)", style: const TextStyle(color: Colors.white70, fontSize: 15), overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                        
                                        const Divider(color: Colors.white10, height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Total Pendapatan:', style: TextStyle(color: Colors.white30, fontSize: 14)),
                                            Text('Rp $hargaFormat', style: const TextStyle(color: Color(0xffFF9100), fontSize: 18, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                height: 42,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xffFF9100),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  onPressed: () async {
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (context) => TambahPesananScreen(pesanan: item)),
                                                    );
                                                    _ambilDataPesanan();
                                                  },
                                                  child: const Text('EDIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.1)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: SizedBox(
                                                height: 42,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.redAccent,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  onPressed: () => _tampilkanDialogKonfirmasiHapus(item['id'], item['nama_kendaraan'] ?? 'Unit'),
                                                  child: const Text('HAPUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.1)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xffFF9100),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahPesananScreen()),
          );
          _ambilDataPesanan();
        },
      ),
    );
  }
}