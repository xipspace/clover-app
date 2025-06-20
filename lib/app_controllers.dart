import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import 'app_models.dart';

class HomeController extends GetxController {
  RxString msg = 'welcome'.obs;
  RxString timeStamp = 'time'.obs;

  void setStamp() {
    timeStamp.value = DateTime.now().toString();
  }

  void setMessage(text) {
    msg.value = text;
  }

  @override
  void onInit() {
    super.onInit();
    setStamp();
  }

}

enum ViewMode { frequencyTable, frequencyRanking, groupRanking, sequenceTiers }
enum TimeFilter { allTime, oneMonth, sixMonths, oneYear, fiveYears }

class LottoController extends GetxController {
  RxString lottoBanner = 'void'.obs;
  RxList<LottoDraw> lottoData = <LottoDraw>[].obs;
  var currentView = ViewMode.frequencyTable.obs;
  var currentFilter = TimeFilter.allTime.obs;

  List<LottoDraw> _cachedFilteredData = [];
  TimeFilter? _lastUsedFilter;

  String frequencyTableOutput = '';
  String frequencyRankingOutput = '';
  String groupRankingOutput = '';
  String sequenceTiersOutput = '';

  @override
  void onReady() {
    super.onReady();
    loadLottoResults();
  }

  void updateLottoBanner(String text) {
    lottoBanner.value = text;
  }

  String get formattedLastDraw {
    if (lottoData.isEmpty) return 'last draw: void';

    final raw = lottoData.last.date;
    final parts = raw.split('_'); // ['2025', '05', '31']
    final formatted = '${parts[2]}-${parts[1]}-${parts[0]}'; // 31-05-2025
    return 'last draw: $formatted';
  }

  void updateView(ViewMode mode) {
    currentView.value = mode;
    switch (mode) {
      case ViewMode.frequencyTable:
        updateLottoBanner(frequencyTableOutput);
        break;
      case ViewMode.frequencyRanking:
        updateLottoBanner(frequencyRankingOutput);
        break;
      case ViewMode.groupRanking:
        updateLottoBanner(groupRankingOutput);
        break;
      case ViewMode.sequenceTiers:
        updateLottoBanner(sequenceTiersOutput);
        break;
    }
  }

  void updateFilter(TimeFilter filter) {
    currentFilter.value = filter;
    refreshStatistics();
    updateView(currentView.value);
  }

  List<LottoDraw> getFilteredData() {
    if (_lastUsedFilter != currentFilter.value || _cachedFilteredData.isEmpty) {
      _cachedFilteredData = _filterData();
      _lastUsedFilter = currentFilter.value;
    }
    return _cachedFilteredData;
  }

  List<LottoDraw> _filterData() {
    if (currentFilter.value == TimeFilter.allTime) return lottoData;

    final now = DateTime.now();
    DateTime cutoff;

    switch (currentFilter.value) {
      case TimeFilter.oneMonth:
        cutoff = DateTime(now.year, now.month - 1, now.day);
        break;
      case TimeFilter.sixMonths:
        cutoff = DateTime(now.year, now.month - 6, now.day);
        break;
      case TimeFilter.oneYear:
        cutoff = DateTime(now.year - 1, now.month, now.day);
        break;
      case TimeFilter.fiveYears:
        cutoff = DateTime(now.year - 5, now.month, now.day);
        break;
      default:
        return lottoData;
    }

    return lottoData.where((draw) {
      final parts = draw.date.split('_').map(int.parse).toList();
      final drawDate = DateTime(parts[0], parts[1], parts[2]);
      return drawDate.isAfter(cutoff);
    }).toList();
  }

  void refreshStatistics() {
    final filtered = getFilteredData();
    frequencyTableOutput = _generateFrequencyTable(filtered);
    frequencyRankingOutput = _generateFrequencyRanking(filtered);
    groupRankingOutput = _generateGroupRanking(filtered);
    sequenceTiersOutput = _generateSequenceTiers(filtered);
  }

  String _generateFrequencyTable(List<LottoDraw> draws) {
    Map<int, int> numberCounts = {};

    for (var draw in draws) {
      for (var number in draw.results) {
        numberCounts[number] = (numberCounts[number] ?? 0) + 1;
      }
    }

    StringBuffer output = StringBuffer();
    for (int i = 1; i <= 60; i++) {
      int count = numberCounts[i] ?? 0;
      output.write('[$i] appeared $count times');
      if (i < 60) output.writeln();
    }

    return output.toString();
  }

  String _generateFrequencyRanking(List<LottoDraw> draws) {
    Map<int, int> numberCounts = {};

    for (var draw in draws) {
      for (var number in draw.results) {
        numberCounts[number] = (numberCounts[number] ?? 0) + 1;
      }
    }

    List<LottoNumber> ranked = List.generate(60, (i) {
      int number = i + 1;
      return LottoNumber(number: number, frequency: numberCounts[number] ?? 0);
    });

    ranked.sort((a, b) {
      if (b.frequency != a.frequency) {
        return b.frequency.compareTo(a.frequency);
      }
      return a.number.compareTo(b.number);
    });

    StringBuffer output = StringBuffer();
    for (int i = 0; i < ranked.length; i++) {
      var item = ranked[i];
      output.write('[${item.number}] appeared ${item.frequency} times');
      if (i < ranked.length - 1) output.writeln();
    }

    return output.toString();
  }

  String _generateGroupRanking(List<LottoDraw> draws) {
    Map<int, int> numberCounts = {};

    for (var draw in draws) {
      for (var number in draw.results) {
        numberCounts[number] = (numberCounts[number] ?? 0) + 1;
      }
    }

    Map<String, int> groupCounts = {
      '1-9': 0,
      '10-19': 0,
      '20-29': 0,
      '30-39': 0,
      '40-49': 0,
      '50-59': 0,
      '60': 0,
    };

    numberCounts.forEach((number, count) {
      if (number <= 9) {
        groupCounts['1-9'] = groupCounts['1-9']! + count;
      } else if (number <= 19) {
        groupCounts['10-19'] = groupCounts['10-19']! + count;
      } else if (number <= 29) {
        groupCounts['20-29'] = groupCounts['20-29']! + count;
      } else if (number <= 39) {
        groupCounts['30-39'] = groupCounts['30-39']! + count;
      } else if (number <= 49) {
        groupCounts['40-49'] = groupCounts['40-49']! + count;
      } else if (number <= 59) {
        groupCounts['50-59'] = groupCounts['50-59']! + count;
      } else {
        groupCounts['60'] = groupCounts['60']! + count;
      }
    });

    final ranked = groupCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final output = StringBuffer();
    for (int i = 0; i < ranked.length; i++) {
      final entry = ranked[i];
      output.write('${entry.key} appeared ${entry.value} times');
      if (i < ranked.length - 1) output.writeln();
    }

    return output.toString();
  }

  String _generateSequenceTiers(List<LottoDraw> draws) {
    final Map<String, int> tierCounts = {
      't6': 0,
      't5': 0,
      't4': 0,
      't3': 0,
      't2': 0,
    };

    for (var draw in draws) {
      final list = draw.results;
      if (list.length < 2) continue;

      int maxStreak = 1;
      int currentStreak = 1;

      for (int i = 1; i < list.length; i++) {
        if (list[i] == list[i - 1] + 1) {
          currentStreak++;
          if (currentStreak > maxStreak) {
            maxStreak = currentStreak;
          }
        } else {
          currentStreak = 1;
        }
      }

      if (maxStreak >= 2) {
        final tier = maxStreak > 6 ? 't6' : 't$maxStreak';
        tierCounts[tier] = tierCounts[tier]! + 1;
      }
    }

    final output = StringBuffer();
    bool first = true;
    for (var tier in ['t6', 't5', 't4', 't3', 't2']) {
      final count = tierCounts[tier];
      if (count != null && count > 0) {
        if (!first) {
          output.write('\n');
        }
        output.write('$tier appeared $count times');
        first = false;
      }
    }

    return output.toString();
  }

  void loadLottoResults() async {
    try {
      String jsonData = await rootBundle.loadString('res/lotto.json');
      Map<String, dynamic> jsonMap = jsonDecode(jsonData);
      LottoHistory history = LottoHistory.fromJson(jsonMap);
      lottoData.value = history.draws;
      refreshStatistics();
      updateView(ViewMode.frequencyTable);
    } catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Warning!'),
          content: Text('Error loading lotto data: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class AppBindings implements Bindings {
  @override
  void dependencies() {
    Get.put(HomeController());
    Get.put(LottoController());
  }
}
