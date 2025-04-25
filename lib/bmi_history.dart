import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class BMIHistoryScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mapping of BMI result keys to translation keys
  final Map<String, String> bmiResultKeys = {
    'Underweight': 'underweight',
    'Normal': 'normal',
    'Overweight': 'overweight',
    'Obese': 'obese',
  };

  Future<List<Map<String, dynamic>>> _fetchBMIResults() async {
    User? user = _auth.currentUser;
    if (user == null) {
      print("User is not logged in");
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('bmiResults')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        print("No BMI results found for user: ${user.uid}");
        return [];
      }

      print("Fetched ${snapshot.docs.length} BMI results");
      return snapshot.docs.map((doc) {
        print("Document data: ${doc.data()}");
        return doc.data();
      }).toList();
    } catch (e) {
      print("Error fetching BMI results: $e");
      return [];
    }
  }

  // Get the translated BMI result using the app localizations
  String getTranslatedBmiResult(BuildContext context, String result) {
    final l10n = AppLocalizations.of(context)!;
    
    // Map the result to the corresponding localization key
    switch (result) {
      case 'Underweight':
        return l10n.underweight;
      case 'Normal':
        return l10n.normal;
      case 'Overweight':
        return l10n.overweight;
      case 'Obese':
        return l10n.obese;
      default:
        return result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bmiHistory),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBMIResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("FutureBuilder error: ${snapshot.error}");
            return Center(child: Text(l10n.errorLoadingData));
          }

          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return Center(child: Text(l10n.noBmiResults));
          }
          var bmiResults = snapshot.data!;

          return ListView.builder(
            itemCount: bmiResults.length,
            itemBuilder: (context, index) {
              var data = bmiResults[index];
              DateTime timestamp = data['timestamp'].toDate();
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${l10n.bmi}: ${data['bmi'].toStringAsFixed(2)}",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            DateFormat.yMd(Localizations.localeOf(context).languageCode).format(timestamp),
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "${l10n.result}: ${getTranslatedBmiResult(context, data['result'])}",
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${l10n.date}: ${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).add_Hm().format(timestamp)}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
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