import 'package:flutter/material.dart';

class SelesaiFields extends StatelessWidget {
  final DateTime? tanggalSelesai;
  final VoidCallback onPickTanggal;
  final TextEditingController catatanController;

  const SelesaiFields({
    super.key,
    required this.tanggalSelesai,
    required this.onPickTanggal,
    required this.catatanController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white10, height: 32),
        const Text('TANGGAL SELESAI', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.white10)),
          tileColor: const Color(0xff1E1E1E),
          title: Text(
            tanggalSelesai == null 
                ? 'Pilih tanggal selesai...' 
                : '${tanggalSelesai!.day}/${tanggalSelesai!.month}/${tanggalSelesai!.year}',
            style: TextStyle(color: tanggalSelesai == null ? Colors.white30 : Colors.white),
          ),
          trailing: const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
          onTap: onPickTanggal,
        ),
        const SizedBox(height: 16),
        const Text('CATATAN / REVIEW PELANGGAN (EVALUASI)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: catatanController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tulis tanggapan positif/negatif di sini...',
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
            filled: true,
            fillColor: const Color(0xff1E1E1E),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xffFF9100))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
          ),
        ),
      ],
    );
  }
}