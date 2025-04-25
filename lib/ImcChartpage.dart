import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'language_provider.dart';



class ImcChartPage extends StatefulWidget {
  @override
  _ImcChartPageState createState() => _ImcChartPageState();
}

class _ImcChartPageState extends State<ImcChartPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<FlSpot> _bmiSpots = [];
  double? _targetBMI = 22.0;
  DateTime? _firstDate;
  double _minY = 15;
  double _maxY = 30;
  double? _lastBMI;

  @override
  void initState() {
    super.initState();
    _loadBmiData();
  }

  Future<void> _loadBmiData() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("Aucun utilisateur connecté");
      return;
    }

    final snapshot = await _firestore
        .collection('bmiResults')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp')
        .get();

    List<FlSpot> spots = [];

    if (snapshot.docs.isNotEmpty) {
      _firstDate = (snapshot.docs.first['timestamp'] as Timestamp).toDate();
      double minBmi = 100;
      double maxBmi = 0;

      for (var doc in snapshot.docs) {
        double bmi = doc['bmi'];
        if (bmi < 10 || bmi > 50) continue;

        DateTime time = (doc['timestamp'] as Timestamp).toDate();
        double daysSinceFirst = time.difference(_firstDate!).inHours / 24;

        if (bmi < minBmi) minBmi = bmi;
        if (bmi > maxBmi) maxBmi = bmi;

        spots.add(FlSpot(daysSinceFirst, bmi));
      }

      _minY = (minBmi - 2).clamp(10, 40);
      _maxY = (maxBmi + 2).clamp(15, 45);

      if (spots.isNotEmpty) {
        _lastBMI = spots.last.y;
      }
    }

    setState(() {
      _bmiSpots = spots;
    });
  }

  double _calculateXInterval() {
    if (_bmiSpots.isEmpty) return 1;
    double totalDays = _bmiSpots.last.x;
    if (totalDays <= 7) return 1;
    if (totalDays <= 30) return 3;
    if (totalDays <= 90) return 7;
    return 14;
  }

  Widget _getDateLabel(double value) {
    if (_firstDate == null) return Text('');
    final date = _firstDate!.add(Duration(days: value.toInt()));
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        "${date.day}/${date.month}",
        style: TextStyle(fontSize: 10, color: Colors.black54),
      ),
    );
  }

 List<String> _getAdviceBasedOnBMI() {
  final loc = AppLocalizations.of(context)!;
  if (_lastBMI == null) return [loc.bmiNoData];

  if (_lastBMI! < 18.5) {
    return [loc.bmiUnderweight1, loc.bmiUnderweight2, loc.bmiUnderweight3];
  } else if (_lastBMI! < 25) {
    return [loc.bmiNormal1, loc.bmiNormal2, loc.bmiNormal3];
  } else if (_lastBMI! < 30) {
    return [loc.bmiOverweight1, loc.bmiOverweight2, loc.bmiOverweight3];
  } else {
    return [loc.bmiObese1, loc.bmiObese2, loc.bmiObese3];
  }
}


  void _showAdviceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.bmiAdviceTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _getAdviceBasedOnBMI().map((tip) => Text("• $tip")).toList(),
          ),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       title: Text(AppLocalizations.of(context)!.bmiEvolution),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline),
          tooltip: AppLocalizations.of(context)!.bmiTips,
            onPressed: _showAdviceDialog,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _bmiSpots.isEmpty
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                 Text(AppLocalizations.of(context)!.yourBmiEvolution),

                  SizedBox(height: 20),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: _bmiSpots,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.1),
                            ),
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.blue,
                                  strokeWidth: 1,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 5,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(color: Colors.black54, fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: _calculateXInterval(),
                              getTitlesWidget: (value, meta) => _getDateLabel(value),
                              reservedSize: 25,
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        minY: _minY,
                        maxY: _maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 5,
                          verticalInterval: _calculateXInterval(),
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey.withOpacity(0.5)),
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final date = _firstDate!.add(Duration(days: spot.x.toInt()));
                                return LineTooltipItem(
                                  "IMC: ${spot.y.toStringAsFixed(1)}\n${date.day}/${date.month}/${date.year}",
                                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                          ),
                          touchCallback: (_, __) {},
                          handleBuiltInTouches: true,
                        ),
                        extraLinesData: ExtraLinesData(horizontalLines: [
                          HorizontalLine(
                            y: _targetBMI!,
                            color: Colors.green,
                            strokeWidth: 2,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
      labelResolver: (_) => '${AppLocalizations.of(context)!.bmiTarget} ($_targetBMI)',
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: Colors.blue,
                          margin: EdgeInsets.only(right: 4),
                        ),
                       Text(AppLocalizations.of(context)!.yourBmi),
                        SizedBox(width: 20),
                        Container(
                          width: 12,
                          height: 2,
                          color: Colors.green,
                          margin: EdgeInsets.only(right: 4),
                        ),
                       Text(AppLocalizations.of(context)!.bmiTarget),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
