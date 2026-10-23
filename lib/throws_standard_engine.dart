// lib/throws_standard_engine.dart

class ThrowsStandardEngine {
  /// Calculates the WMA Age-Graded Equivalent and Percentage score
  static Map<String, double> calculateWmaMetrics(
    String discipline,
    String division,
    double distance,
  ) {
    if (distance <= 0) {
      return {'openEquivalent': 0.0, 'percentage': 0.0};
    }

    final bool isMale = division.startsWith('M');
    final String ageStr = division.replaceAll(RegExp(r'[^0-9]'), '');
    final int age = int.tryParse(ageStr) ?? 35;

    double factor = 1.0;
    double baseRecord = isMale ? 74.08 : 76.80;

    if (isMale) {
      if (discipline == 'Discus') {
        baseRecord = 74.08;
        if (age >= 85) {
          factor = 1.8920;
        } else if (age >= 80) {
          factor = 1.6850;
        } else if (age >= 75) {
          factor = 1.5420;
        } else if (age >= 70) {
          factor = 1.4390;
        } else if (age >= 65) {
          factor = 1.3480;
        } else if (age >= 60) {
          factor = 1.2640;
        } else if (age >= 55) {
          factor = 1.1980;
        } else if (age >= 50) {
          factor = 1.1240;
        } else if (age >= 45) {
          factor = 1.0870;
        } else if (age >= 40) {
          factor = 1.0530;
        } else if (age >= 35) {
          factor = 1.0210;
        }
      } else if (discipline == 'Shot Put') {
        baseRecord = 23.12;
        if (age >= 85) {
          factor = 2.1200;
        } else if (age >= 80) {
          factor = 1.8450;
        } else if (age >= 75) {
          factor = 1.6650;
        } else if (age >= 70) {
          factor = 1.5240;
        } else if (age >= 65) {
          factor = 1.4180;
        } else if (age >= 60) {
          factor = 1.3250;
        } else if (age >= 55) {
          factor = 1.2340;
        } else if (age >= 50) {
          factor = 1.1560;
        } else if (age >= 45) {
          factor = 1.1040;
        } else if (age >= 40) {
          factor = 1.0620;
        } else if (age >= 35) {
          factor = 1.0250;
        }
      } else if (discipline == 'Javelin') {
        baseRecord = 98.48;
        if (age >= 85) {
          factor = 2.0540;
        } else if (age >= 80) {
          factor = 1.7820;
        } else if (age >= 75) {
          factor = 1.6140;
        } else if (age >= 70) {
          factor = 1.4880;
        } else if (age >= 65) {
          factor = 1.3480;
        } else if (age >= 60) {
          factor = 1.2980;
        } else if (age >= 55) {
          factor = 1.2160;
        } else if (age >= 50) {
          factor = 1.1480;
        } else if (age >= 45) {
          factor = 1.0920;
        } else if (age >= 40) {
          factor = 1.0480;
        } else if (age >= 35) {
          factor = 1.0190;
        }
      } else if (discipline == 'Hammer' || discipline == 'Weight') {
        baseRecord = 86.74;
        if (age >= 85) {
          factor = 2.2140;
        } else if (age >= 80) {
          factor = 1.8650;
        } else if (age >= 75) {
          factor = 1.6620;
        } else if (age >= 70) {
          factor = 1.5180;
        } else if (age >= 65) {
          factor = 1.4050;
        } else if (age >= 60) {
          factor = 1.3120;
        } else if (age >= 55) {
          factor = 1.2180;
        } else if (age >= 50) {
          factor = 1.1390;
        } else if (age >= 45) {
          factor = 1.0940;
        } else if (age >= 40) {
          factor = 1.0550;
        } else if (age >= 35) {
          factor = 1.0220;
        }
      }
    } else {
      if (discipline == 'Discus') {
        baseRecord = 76.80;
        if (age >= 75) {
          factor = 1.7450;
        } else if (age >= 70) {
          factor = 1.5720;
        } else if (age >= 65) {
          factor = 1.4420;
        } else if (age >= 60) {
          factor = 1.3340;
        } else if (age >= 55) {
          factor = 1.2420;
        } else if (age >= 50) {
          factor = 1.1620;
        } else if (age >= 45) {
          factor = 1.1080;
        } else if (age >= 40) {
          factor = 1.0610;
        } else if (age >= 35) {
          factor = 1.0240;
        }
      } else if (discipline == 'Shot Put') {
        baseRecord = 22.63;
        if (age >= 75) {
          factor = 1.8400;
        } else if (age >= 70) {
          factor = 1.6350;
        } else if (age >= 65) {
          factor = 1.4850;
        } else if (age >= 60) {
          factor = 1.3650;
        } else if (age >= 55) {
          factor = 1.2650;
        } else if (age >= 50) {
          factor = 1.1820;
        } else if (age >= 45) {
          factor = 1.1150;
        } else if (age >= 40) {
          factor = 1.0630;
        } else if (age >= 35) {
          factor = 1.0220;
        }
      } else if (discipline == 'Javelin') {
        baseRecord = 72.28;
        if (age >= 75) {
          factor = 1.9050;
        } else if (age >= 70) {
          factor = 1.6680;
        } else if (age >= 65) {
          factor = 1.5020;
        } else if (age >= 60) {
          factor = 1.3740;
        } else if (age >= 55) {
          factor = 1.2720;
        } else if (age >= 50) {
          factor = 1.1900;
        } else if (age >= 45) {
          factor = 1.1220;
        } else if (age >= 40) {
          factor = 1.0680;
        } else if (age >= 35) {
          factor = 1.0260;
        }
      } else if (discipline == 'Hammer' || discipline == 'Weight') {
        baseRecord = 82.98;
        if (age >= 75) {
          factor = 1.9820;
        } else if (age >= 70) {
          factor = 1.7140;
        } else if (age >= 65) {
          factor = 1.5360;
        } else if (age >= 60) {
          factor = 1.3980;
        } else if (age >= 55) {
          factor = 1.2880;
        } else if (age >= 50) {
          factor = 1.1980;
        } else if (age >= 45) {
          factor = 1.1280;
        } else if (age >= 40) {
          factor = 1.0720;
        } else if (age >= 35) {
          factor = 1.0280;
        }
      }
    }

    final double openEquivalent = distance * factor;
    final double scorePercentage = (openEquivalent / baseRecord) * 100;
    return {
      'openEquivalent': openEquivalent,
      'percentage': scorePercentage.clamp(0.0, 100.0),
    };
  }

  /// Fetches regulation implement weight constraints based on gender and division profiles
  static double getStandardWeight(String discipline, String division) {
    final bool isMale = division.startsWith('M');
    if (division.contains('35') || division.contains('40')) {
      if (discipline == 'Discus') {
        return isMale ? 2.0 : 1.0;
      }
      if (discipline == 'Shot Put') {
        return isMale ? 7.26 : 4.0;
      }
      if (discipline == 'Javelin') {
        return isMale ? 800.0 : 600.0;
      }
      if (discipline == 'Hammer') {
        return isMale ? 7.26 : 4.0;
      }
      return isMale ? 15.88 : 9.08;
    }
    if (division.contains('55') || division.contains('50')) {
      if (discipline == 'Discus') {
        return isMale ? 1.5 : 1.0;
      }
      if (discipline == 'Shot Put') {
        return isMale ? 6.0 : 3.0;
      }
      if (discipline == 'Javelin') {
        return isMale ? 700.0 : 500.0;
      }
      if (discipline == 'Hammer') {
        return isMale ? 6.0 : 3.0;
      }
      return isMale ? 11.34 : 7.26;
    }
    if (discipline == 'Discus') {
      return isMale ? 1.0 : 0.75;
    }
    if (discipline == 'Shot Put') {
      return isMale ? 4.0 : 2.0;
    }
    if (discipline == 'Javelin') {
      return isMale ? 500.0 : 400.0;
    }
    if (discipline == 'Hammer') {
      return isMale ? 4.0 : 2.0;
    }
    return isMale ? 7.26 : 5.45;
  }

  /// Linear-Inverse performance scaling calculation
  static double calculateProjectedDistance(
      double distance, double actualW, double standardW) {
    if (actualW == standardW || actualW <= 0) {
      return distance;
    }
    return distance * (actualW / standardW);
  }
}
