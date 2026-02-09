import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const TxApp());
}

class TxApp extends StatelessWidget {
  const TxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TX 3 Stops Alert (MVP)',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class Station {
  final String code;
  final String name;
  final int order;

  Station({required this.code, required this.name, required this.order});

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      code: json['code'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Station> _stations = [];
  Station? _destination;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    final text = await rootBundle.loadString('assets/tx_stations.json');
    final list = (jsonDecode(text) as List).cast<Map<String, dynamic>>();
    final stations = list.map(Station.fromJson).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    setState(() {
      _stations = stations;
      _destination = stations.isNotEmpty ? stations.first : null;
    });
  }

  Station? _threeStopsBefore(Station dest) {
    final targetOrder = dest.order - 3;
    if (targetOrder < 1) return null;
    return _stations.firstWhere(
      (s) => s.order == targetOrder,
      orElse: () => Station(code: '', name: '', order: -1),
    ).order == -1
        ? null
        : _stations.firstWhere((s) => s.order == targetOrder);
  }

  @override
  Widget build(BuildContext context) {
    final dest = _destination;
    final before = (dest == null) ? null : _threeStopsBefore(dest);

    return Scaffold(
      appBar: AppBar(title: const Text('TX 3 Stops Alert (MVP)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _stations.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('目的地駅を選んでください', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  DropdownButton<Station>(
                    isExpanded: true,
                    value: dest,
                    items: _stations
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s.name}（${s.code}）'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _destination = v),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    dest == null
                        ? '目的地：未選択'
                        : '目的地：${dest.name}（${dest.code}）',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    before == null
                        ? '3駅前：存在しません（秋葉原に近すぎます）'
                        : '3駅前：${before.name}（${before.code}）',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: before == null ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '※このMVPは「3駅前を計算して表示」まで。\n'
                    '次に、位置情報＋通知（バイブ）を追加します。',
                  ),
                ],
              ),
      ),
    );
  }
}
