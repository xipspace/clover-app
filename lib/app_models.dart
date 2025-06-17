class LottoNumber {
  final int number;
  int frequency;

  LottoNumber({required this.number, this.frequency = 0});

  void incrementFrequency() {
    frequency++;
  }

  factory LottoNumber.fromJson(Map<String, dynamic> json) {
    return LottoNumber(
      number: json['number'],
      frequency: json['frequency'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'frequency': frequency,
      };
}

class LottoDraw {
  final String date;
  final List<int> results;

  LottoDraw({required this.date, required this.results});

  factory LottoDraw.fromJson(Map<String, dynamic> json) {
    List<dynamic> resultsJson = json['result'] ?? [];
    var sortedResults = List<int>.from(resultsJson);
    sortedResults.sort();
    return LottoDraw(
      date: json['date'],
      results: sortedResults,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'result': results,
      };
}

class LottoHistory {
  final List<LottoDraw> draws;

  LottoHistory({required this.draws});

  factory LottoHistory.fromJson(Map<String, dynamic> json) {
    List<LottoDraw> draws = [];
    json.forEach((key, value) {
      draws.add(LottoDraw.fromJson(value));
    });
    return LottoHistory(draws: draws);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    for (int i = 0; i < draws.length; i++) {
      map[(i + 1).toString()] = draws[i].toJson();
    }
    return map;
  }
}