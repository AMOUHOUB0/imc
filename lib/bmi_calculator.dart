import 'dart:ui';

import 'package:flutter/material.dart';

class BMICalculator {
  static double calculateBMI(double weight, double height) {
    return weight / (height * height);
  }

  static String getBMIResult(double bmi) {
    if (bmi < 18.5) {
      return "Underweight";
    } else if (bmi >= 18.5 && bmi < 25) {
      return "Normal";
    } else if (bmi >= 25 && bmi < 30) {
      return "Overweight";
    } else {
      return "Obese";
    }
  }
  Color getBMIColor(double bmi) {
    if (bmi < 18.5) {
      return Colors.orange; // Underweight
    } else if (bmi >= 18.5 && bmi < 25) {
      return Colors.green; // Normal
    } else if (bmi >= 25 && bmi < 30) {
      return Colors.orange; // Overweight
    } else {
      return Colors.red; // Obese
    }
  }
}
