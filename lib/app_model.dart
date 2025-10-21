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
  final String drawNumber;
  final String date;
  final List<int> results;

  LottoDraw({required this.drawNumber, required this.date, required this.results});

  factory LottoDraw.fromJson(String drawNumber, Map<String, dynamic> json) {
    return LottoDraw(drawNumber: drawNumber, date: json['date'], results: List<int>.from(json['result']));
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'result': results};
  }
}

class LottoHistory {
  final List<LottoDraw> draws;

  LottoHistory({required this.draws});

  factory LottoHistory.fromJson(Map<String, dynamic> json) {
    List<LottoDraw> draws = [];
    json.forEach((key, value) {
      draws.add(LottoDraw.fromJson(key, value));
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

class UserProfile {
  String userName;
  List<UserGame> games;

  UserProfile({required this.userName, required this.games});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userName: json['userName'],
      games:
          (json['games'] as List)
              .map((gameJson) => UserGame.fromJson(gameJson))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'games': games.map((g) => g.toJson()).toList(),
  };
}

class UserGame {
  final String name;
  final List<int> numbers;
  final String createdAt;

  UserGame({required this.name, required this.numbers, required this.createdAt})
    : assert(numbers.length <= 60),
      assert(numbers.toSet().length == numbers.length); // no duplicates

  factory UserGame.fromJson(Map<String, dynamic> json) {
    return UserGame(
      name: json['name'],
      numbers: List<int>.from(json['numbers']),
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'numbers': numbers,
    'createdAt': createdAt,
  };
}
