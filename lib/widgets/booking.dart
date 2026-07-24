import 'package:flutter/material.dart';

class BookingFields extends StatelessWidget {
  final TextEditingController namaController;
  final TextEditingController noHpController;
  final DateTime? tanggalMulai;
  final VoidCallback onPickTanggal;
  final String labelTanggal; // Menampung label dinamis (Booking / Pengerjaan)

  const BookingFields({
    super.key,
    required this.namaController,
    required this.noHpController,
    required this.tanggalMulai,
    required this.onPickTanggal,
    required this.labelTanggal,
  });

  Widget _buildField(String label, TextEditingController controller, String hint, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
            filled: true,
            fillColor: const Color(0xff1E1E1E),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xffFF9100))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white10, height: 32),
        
        // FIELD TANGGAL DINAMIS (Bisa jadi Tanggal Booking atau Tanggal Pengerjaan)
        Text(labelTanggal.toUpperCase(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.white10)),
          tileColor: const Color(0xff1E1E1E),
          title: Text(
            tanggalMulai == null 
                ? 'Pilih tanggal...' 
                : '${tanggalMulai!.day}/${tanggalMulai!.month}/${tanggalMulai!.year}',
            style: TextStyle(color: tanggalMulai == null ? Colors.white30 : Colors.white),
          ),
          trailing: const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
          onTap: onPickTanggal,
        ),
        const SizedBox(height: 16),

        _buildField('NAMA CUSTOMER', namaController, 'Contoh: Pak Budi', TextInputType.text),
        _buildField('NO. HANDPHONE', noHpController, 'Contoh: 0812345678', TextInputType.phone),
      ],
    );
  }
}