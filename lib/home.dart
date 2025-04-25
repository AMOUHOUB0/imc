import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'bmi_calculator.dart';
import 'language_provider.dart';
import 'ImcChartpage.dart'; // adapte le chemin si besoin


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController controlWeight = TextEditingController();
  final TextEditingController controlHeight = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _info = "";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _info = AppLocalizations.of(context)!.reportData;
      });
    });
    
  }

  void _resetFields() {
    controlHeight.text = "";
    controlWeight.text = "";
    setState(() {
      _info = AppLocalizations.of(context)!.reportData;
    });
  }

  Future<void> _calculate() async {
    if (_formKey.currentState!.validate()) {
      double weight = double.parse(controlWeight.text);
      double height = double.parse(controlHeight.text) / 100;
      double imc = BMICalculator.calculateBMI(weight, height);
      String result =
          BMICalculator.getBMIResult(imc); // Pass context for translations

      setState(() {
        _info = result;
      });

      // Save the result to Firestore
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('bmiResults').add({
          'userId': user.uid,
          'bmi': imc,
          'result': result,
          'timestamp': DateTime.now(),
        });
      }
    }
  }

  void _signOut() async {
    try {
      await _auth.signOut();
      print("User signed out successfully");

      if (mounted) {
        context.pushReplacement('/sign-in');
      }
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    final localizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement('/sign-in');
      });
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.appTitle,
          style: TextStyle(fontFamily: "Segoe UI"),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetFields,
          ),
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () {
              _showLanguageDialog(context, languageProvider);
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.person,
                size: 120.0,
                color: Colors.green,
              ),
              TextFormField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: localizations.weight,
                  labelStyle: TextStyle(
                    color: Colors.green,
                    fontFamily: "Segoe UI",
                  ),
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 25.0,
                  fontFamily: "Segoe UI",
                ),
                controller: controlWeight,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.insertWeight;
                  }
                  return null;
                },
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: localizations.height,
                  labelStyle: TextStyle(
                    color: Colors.green,
                    fontFamily: "Segoe UI",
                  ),
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 25.0,
                  fontFamily: "Segoe UI",
                ),
                controller: controlHeight,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.insertHeight;
                  }
                  return null;
                },
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: SizedBox(
                  height: 50.0,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      textStyle: TextStyle(
                        fontSize: 25.0,
                        fontFamily: "Segoe UI",
                      ),
                    ),
                    child: Text(
                      localizations.calculate,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Text(
                _info,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 25.0,
                  fontFamily: "Segoe UI",
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/history');
                  },
                  child: Text(localizations.viewHistory),
                ),
              ),
              Padding(
  padding: EdgeInsets.only(top: 10.0),
  child: ElevatedButton.icon(
    onPressed: () {
      context.push('/graphique');
    },
    icon: Icon(Icons.show_chart),
    label: Text(AppLocalizations.of(context)!.viewGraph),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
    ),
  ),
),

            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.language),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languageProvider.languages.length,
              itemBuilder: (context, index) {
                final language = languageProvider.languages[index];
                return ListTile(
                  title: Text(language['name']),
                  onTap: () {
                    languageProvider.setLocale(language['locale']);
                    Navigator.pop(context);
                    // Reset the info text to update with new language
                    setState(() {
                      _info = AppLocalizations.of(context)!.reportData;
                    });
                  },
                  trailing: languageProvider.locale.languageCode ==
                          language['locale'].languageCode
                      ? Icon(Icons.check, color: Colors.green)
                      : null,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
