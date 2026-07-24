import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TambahPesananScreen extends StatefulWidget {
  // Parameter pintar untuk menampung data lama jika dalam mode EDIT
  final Map<String, dynamic>? pesanan;

  const TambahPesananScreen({super.key, this.pesanan});

  @override
  State<TambahPesananScreen> createState() => _TambahPesananScreenState();
}

class _TambahPesananScreenState extends State<TambahPesananScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. DEKLARASI CONTROLLER FORM
  final TextEditingController _namaKendaraanController = TextEditingController();
  final TextEditingController _merkKendaraanController = TextEditingController();
  final TextEditingController _namaCustomerController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _hargaAktualController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  // 2. DEKLARASI VARIABEL STATE
  String? _statusTerpilih = 'Booking';
  String? _jasaTerpilihId;
  DateTime? _tanggalMulai = DateTime.now();
  DateTime? _tanggalSelesai;

  List<Map<String, dynamic>> _daftarJasa = [];
  bool _isLoadingJasa = true;
  bool _isProsesSimpan = false;

  // Getter penanda apakah screen sedang dalam mode Edit atau Tambah Baru
  bool get _isEditMode => widget.pesanan != null;

  @override
  void initState() {
    super.initState();
    // Ambil data Master Jasa dulu, baru isi data lamanya jika mode edit
    _ambilDaftarJasa().then((_) {
      if (_isEditMode) {
        final p = widget.pesanan!;
        setState(() {
          _namaKendaraanController.text = p['nama_kendaraan'] ?? '';
          _merkKendaraanController.text = p['merk_kendaraan'] ?? '';
          _namaCustomerController.text = p['nama_customer'] ?? '';
          _noHpController.text = p['no_hp'] ?? '';
          _statusTerpilih = p['status'] ?? 'Booking';
          _jasaTerpilihId = p['jasa_id']?.toString();
          _catatanController.text = p['catatan'] ?? '';

          if (p['harga_aktual'] != null) {
            _hargaAktualController.text = p['harga_aktual']
                .toString()
                .replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');
          }
          if (p['tanggal_mulai'] != null) {
            _tanggalMulai = DateTime.parse(p['tanggal_mulai']);
          }
          if (p['tanggal_selesai'] != null) {
            _tanggalSelesai = DateTime.parse(p['tanggal_selesai']);
          }
        });
      }
    });
  }

  // 3. FUNGSI MENGAMBIL DATA MASTER JASA DARI SUPABASE
  Future<void> _ambilDaftarJasa() async {
    try {
      final data = await Supabase.instance.client.from('jasa').select();
      setState(() {
        _daftarJasa = List<Map<String, dynamic>>.from(data);
        _isLoadingJasa = false;
      });
    } catch (e) {
      setState(() => _isLoadingJasa = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil daftar jasa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 4. FUNGSI UTAMA: SIMPAN / PERBARUI TRANSAKSI (UPSERT LOGIC)
  Future<void> _simpanTransaksi() async {
    if (!_formKey.currentState!.validate()) return;
    if (_jasaTerpilihId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih jenis jasa terlebih dahulu!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProsesSimpan = true);

    try {
      final hargaBersih = int.parse(_hargaAktualController.text.replaceAll('.', ''));
      final supabase = Supabase.instance.client;

      // Kumpulkan data ke dalam satu wadah payload
      final dataPayload = {
        'nama_kendaraan': _namaKendaraanController.text,
        'merk_kendaraan': _merkKendaraanController.text,
        'harga_aktual': hargaBersih,
        'status': _statusTerpilih,
        'jasa_id': int.parse(_jasaTerpilihId!),
        'nama_customer': _namaCustomerController.text,
        'no_hp': _noHpController.text,
        'catatan': _catatanController.text,
        'tanggal_mulai': _tanggalMulai?.toIso8601String(),
        'tanggal_selesai': _tanggalSelesai?.toIso8601String(),
      };

      if (_isEditMode) {
        // Jika mode edit, jalankan fungsi UPDATE data berdasarkan ID transaksi
        await supabase.from('pesanan').update(dataPayload).eq('id', widget.pesanan!['id']);
      } else {
        // Jika mode baru, jalankan fungsi INSERT data
        await supabase.from('pesanan').insert(dataPayload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Transaksi sukses diperbarui!' : 'Transaksi sukses disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke dashboard riwayat
      }
    } catch (e) {
      setState(() => _isProsesSimpan = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 5. FUNGSI TAMBAHAN: HAPUS TRANSAKSI (DELETE LOGIC)
  // Future<void> _hapusDataPesanan() async {
  //   setState(() => _isProsesSimpan = true);
  //   try {
  //     final supabase = Supabase.instance.client;
  //     await supabase.from('pesanan').delete().eq('id', widget.pesanan!['id']);

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Transaksi sukses dihapus!'), backgroundColor: Colors.redAccent),
  //       );
  //       Navigator.pop(context); // Kembali ke dashboard
  //     }
  //   } catch (e) {
  //     setState(() => _isProsesSimpan = false);
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Gagal menghapus data: $e'), backgroundColor: Colors.red),
  //       );
  //     }
  //   }
  // }

  // Helper untuk memanggil DatePicker kalender
  Future<void> _pilihTanggalSelesai(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalSelesai ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xffFF9100),
              onPrimary: Colors.black,
              surface: Color(0xff1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tanggalSelesai = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A0A0A),
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Detail & Edit Transaksi' : 'Detail Transaksi',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff0A0A0A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoadingJasa
          ? const Center(child: CircularProgressIndicator(color: Color(0xffFF9100)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DROPDOWN STATUS TRANSAKSI
                    const Text('STATUS TRANSAKSI', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _statusTerpilih,
                      dropdownColor: const Color(0xff1E1E1E),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        fillColor: const Color(0xff1E1E1E),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: ['Booking', 'Sedang Dikerjakan', 'Selesai'].map((status) {
                        return DropdownMenuItem(value: status, child: Text(status));
                      }).toList(),
                      onChanged: (val) => setState(() => _statusTerpilih = val),
                    ),
                    const SizedBox(height: 20),

                    // DROPDOWN PILIH JASA LAYANAN
                    const Text('JENIS JASA LAYANAN', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _jasaTerpilihId,
                      hint: const Text('Pilih Jasa Bengkel', style: TextStyle(color: Colors.white30, fontSize: 14)),
                      dropdownColor: const Color(0xff1E1E1E),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        fillColor: const Color(0xff1E1E1E),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: _daftarJasa.isEmpty
                          ? []
                          : _daftarJasa.map((jasa) {
                              return DropdownMenuItem<String>(
                                value: jasa['id']?.toString() ?? '',
                                child: Text("${jasa['nama_jasa'] ?? 'Tanpa Nama'} (Rp ${jasa['harga']?.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.') ?? '0'})"),
                              );
                            }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _jasaTerpilihId = val;
                          final dataTerpilih = _daftarJasa.firstWhere((jasa) => jasa['id'].toString() == val);
                          _hargaAktualController.text = dataTerpilih['harga']
                              .toString()
                              .replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // INPUT DATA KENDARAAN & CUSTOMER
                    const Text('NAMA KENDARAAN / UNIT', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _namaKendaraanController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Aerox / Civic',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                        fillColor: const Color(0xff1E1E1E),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Nama kendaraan wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),

                    const Text('MERK & TAHUN KENDARAAN', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _merkKendaraanController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Honda 2020 / Yamaha',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                        fillColor: const Color(0xff1E1E1E),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('HARGA AKTUAL (Rp)', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _hargaAktualController,
                      style: const TextStyle(color: Color(0xffFF9100), fontWeight: FontWeight.bold),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(color: Color(0xffFF9100), fontWeight: FontWeight.bold),
                        fillColor: const Color(0xff1E1E1E),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('NAMA CUSTOMER', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _namaCustomerController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama pemilik',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                        fillColor: const Color(0xff1E1E1E),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('NOMOR HP / WHATSAPP', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noHpController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 08311...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                        fillColor: const Color(0xff1E1E1E),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // PILIH TANGGAL SELESAI
                    const Text('TANGGAL ESTIMASI SELESAI', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pilihTanggalSelesai(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(color: const Color(0xff1E1E1E), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _tanggalSelesai == null
                                  ? 'Pilih Tanggal Selesai'
                                  : "${_tanggalSelesai!.day}/${_tanggalSelesai!.month}/${_tanggalSelesai!.year}",
                              style: TextStyle(color: _tanggalSelesai == null ? Colors.white30 : Colors.white),
                            ),
                            const Icon(Icons.calendar_month, color: Color(0xffFF9100)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('CATATAN TRANSAKSI', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _catatanController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Masukkan catatan tambahan...',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                        fillColor: const Color(0xff1E1E1E),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // AREA TOMBOL AKSI DINAMIS (SIMPAN / UPDATE / DELETE)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isProsesSimpan ? null : _simpanTransaksi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffFF9100),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isProsesSimpan
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(
                                _isEditMode ? 'PERBARUI TRANSAKSI' : 'SIMPAN TRANSAKSI',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    // if (_isEditMode) ...[
                    //   const SizedBox(height: 12),
                    //   SizedBox(
                    //     width: double.infinity,
                    //     height: 48,
                    //     child: OutlinedButton(
                    //       onPressed: _isProsesSimpan ? null : _hapusDataPesanan,
                    //       style: OutlinedButton.styleFrom(
                    //         side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    //     ),
                    //       child: const Text('HAPUS TRANSAKSI', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    //   ),
                    //  ),
                      ],
                  // ],
                ),
              ),
            ),
    );
  }
}