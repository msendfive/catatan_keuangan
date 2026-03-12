import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Catatan Keuangan",
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Catatan Keuangan Sendhy"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add_chart), text: "Input"),
              Tab(icon: Icon(Icons.history), text: "Riwayat"),
            ],
          ),
        ),
        body: const TabBarView(children: [FormKeuangan(), RiwayatKeuangan()]),
      ),
    );
  }
}

class FormKeuangan extends StatefulWidget {
  const FormKeuangan({super.key});

  @override
  State<FormKeuangan> createState() => _FormKeuanganState();
}

class _FormKeuanganState extends State<FormKeuangan> {
  final _itemController = TextEditingController();
  final _jumlahController = TextEditingController();

  bool _isLoading = false;

  String _kategori = "Pengeluaran";

  final String urlScript =
      "https://script.google.com/macros/s/AKfycbyP6PyWcT3OE-yX62vpaPtxxJGcQeMkjBOpZQ1J-t1Usb5lL0nk19y8lIAWfZnnKHti/exec";

  Future<void> simpanData() async {
    if (_itemController.text.isEmpty || _jumlahController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Isi semua data")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await http.post(
        Uri.parse(urlScript),
        body: {
          "item": _itemController.text,
          "jumlah": _jumlahController.text,
          "kategori": _kategori,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data berhasil disimpan"),
          backgroundColor: Colors.green,
        ),
      );

      _itemController.clear();
      _jumlahController.clear();
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 10),
              const Text(
                "Tambah Transaksi",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _itemController,
                decoration: InputDecoration(
                  labelText: "Nama Transaksi",
                  prefixIcon: const Icon(Icons.shopping_bag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Jumlah (Rp)",
                  prefixIcon: const Icon(Icons.payments),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: _kategori,
                decoration: InputDecoration(
                  labelText: "Kategori",
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                items: ["Pemasukan", "Pengeluaran"]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _kategori = val!;
                  });
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : simpanData,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Simpan Transaksi"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RiwayatKeuangan extends StatefulWidget {
  const RiwayatKeuangan({super.key});

  @override
  State<RiwayatKeuangan> createState() => _RiwayatKeuanganState();
}

class _RiwayatKeuanganState extends State<RiwayatKeuangan> {
  final String urlScript =
      "https://script.google.com/macros/s/AKfycbyP6PyWcT3OE-yX62vpaPtxxJGcQeMkjBOpZQ1J-t1Usb5lL0nk19y8lIAWfZnnKHti/exec";

  Future<List<dynamic>> fetchRawData() async {
    final response = await http.get(Uri.parse(urlScript));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Gagal mengambil data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: FutureBuilder<List<dynamic>>(
        future: fetchRawData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!.reversed.toList();

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];

              final isPengeluaran = item['kategori'] == "Pengeluaran";

              DateTime tanggal =
                  DateTime.tryParse(item['tanggal'].toString()) ??
                  DateTime.now();

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPengeluaran
                      ? Colors.red[50]
                      : Colors.green[50],
                  child: Icon(
                    isPengeluaran
                        ? Icons.upload_rounded
                        : Icons.download_rounded,
                    color: isPengeluaran ? Colors.red : Colors.green,
                  ),
                ),
                title: Text(item['item'].toString()),
                subtitle: Text(
                  "${tanggal.day}-${tanggal.month}-${tanggal.year}",
                ),
                trailing: Text(
                  "${isPengeluaran ? '-' : '+'} Rp ${item['jumlah']}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPengeluaran ? Colors.red : Colors.green,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
