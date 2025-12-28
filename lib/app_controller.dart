import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

import 'app_model.dart';

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



enum ViewMode { drawResults, frequencyTable, frequencyRanking, groupRanking, sequenceTiers, repeatedDraws }
enum TimeFilter { allTime, oneMonth, sixMonths, oneYear, fiveYears }

// TODO > add helper to iterate for same draws (and their number/date)
class LottoController extends GetxController {
  RxString lottoBanner = 'void'.obs;
  RxList<LottoDraw> lottoData = <LottoDraw>[].obs;
  var currentView = ViewMode.drawResults.obs;
  var currentFilter = TimeFilter.allTime.obs;

  List<LottoDraw> _cachedFilteredData = [];
  TimeFilter? _lastUsedFilter;

  String drawResultsOutput = '';
  String frequencyTableOutput = '';
  String frequencyRankingOutput = '';
  String groupRankingOutput = '';
  String sequenceTiersOutput = '';
  String repeatedDrawsOutput = '';

  @override
  void onReady() {
    super.onReady();
    loadLottoResults();
  }

  String get formattedLastDraw {
    if (lottoData.isEmpty) return 'last draw: void';

    final raw = lottoData.last.date;
    return 'last draw: ${_formatDate(raw)}';
  }

  String get formattedLastSingleTierDraw {
    final draws = getFilteredData().reversed;
    for (var draw in draws) {
      final result = _generateTiersInDraw(draw.results);
      if (result['count'] == 1) {
        return 'last single tier draw: ${_formatDate(draw.date)}';
      }
    }
    return 'last single tier draw: none';
  }

  String get formattedLastMultiTierDraw {
    final draws = getFilteredData().reversed;
    for (var draw in draws) {
      final result = _generateTiersInDraw(draw.results);
      if (result['count'] > 1) {
        return 'last multi tier draw: ${_formatDate(draw.date)}';
      }
    }
    return 'last multi tier draw: none';
  }

  Map<String, String> get formattedLastSeenByTier {
    final draws = getFilteredData().reversed;

    final Map<String, String> lastSeen = {
      't6': 'last t6: none',
      't5': 'last t5: none',
      't4': 'last t4: none',
      't3': 'last t3: none',
      't2': 'last t2: none',
    };

    final found = <String>{};

    for (var draw in draws) {
      final result = _generateTiersInDraw(draw.results);
      final Set<String> tierSet = result['tierSet'];

      for (var tier in tierSet) {
        if (!found.contains(tier)) {
          lastSeen[tier] = 'last $tier: ${_formatDate(draw.date)}';
          found.add(tier);
        }
      }

      if (found.length == 5) break;
    }

    return lastSeen;
  }

  void updateView(ViewMode mode) {
    currentView.value = mode;
    switch (mode) {
      case ViewMode.drawResults:
        lottoBanner.value = drawResultsOutput;
        break;
      case ViewMode.frequencyTable:
        lottoBanner.value = frequencyTableOutput;
        break;
      case ViewMode.frequencyRanking:
        lottoBanner.value = frequencyRankingOutput;
        break;
      case ViewMode.groupRanking:
        lottoBanner.value = groupRankingOutput;
        break;
      case ViewMode.sequenceTiers:
        lottoBanner.value = sequenceTiersOutput;
        break;
      case ViewMode.repeatedDraws:
        lottoBanner.value = repeatedDrawsOutput;
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

    // generate all outputs once
    drawResultsOutput = _generateDrawResults(filtered);
    frequencyTableOutput = _generateFrequencyTable(filtered);
    frequencyRankingOutput = _generateFrequencyRanking(filtered);
    groupRankingOutput = _generateGroupRanking(filtered);
    sequenceTiersOutput = _generateTierOutput(filtered);
    repeatedDrawsOutput = _generateRepeatedDraws(filtered);
  }

  String _generateDrawResults(List<LottoDraw> draws) {
    if (draws.isEmpty) return 'no draw results available';

    // sort descending by drawNumber
    final sorted = List<LottoDraw>.from(draws)..sort((a, b) => int.parse(b.drawNumber).compareTo(int.parse(a.drawNumber)));

    final buffer = StringBuffer();

    for (final draw in sorted) {
      final formattedDate = _formatDate(draw.date);
      final numbers = draw.results.map((n) => n.toString().padLeft(2, '0')).join(', ');

      buffer.writeln('[$formattedDate] draw ${draw.drawNumber}: [$numbers]');
    }

    return buffer.toString().trim();
  }

  String _generateTierOutput(List<LottoDraw> draws) {
    final highest = _generateHighestTierSummary(draws);
    final total = _generateTotalTierFrequency(draws);
    final sequenceStats = _generateSequenceCountSummary(draws);

    final lines = <String>[];

    if (highest.isNotEmpty) lines.addAll(highest.split('\n'));
    if (total.isNotEmpty) lines.addAll(total.split('\n'));
    if (sequenceStats.isNotEmpty) lines.addAll(sequenceStats.split('\n'));

    lines.add(formattedLastSingleTierDraw);
    lines.add(formattedLastMultiTierDraw);
    lines.addAll(formattedLastSeenByTier.values);

    return lines.join('\n');
  }

  String _generateHighestTierSummary(List<LottoDraw> draws) {
    final tierCounts = {'t2': 0, 't3': 0, 't4': 0, 't5': 0, 't6': 0};

    for (var draw in draws) {
      final result = _generateTiersInDraw(draw.results);
      final String? tier = result['highest'];
      if (tier != null) {
        tierCounts[tier] = tierCounts[tier]! + 1;
      }
    }

    final buffer = StringBuffer();
    for (var tier in ['t6', 't5', 't4', 't3', 't2']) {
      final count = tierCounts[tier]!;
      if (count > 0) {
        buffer.write('$tier is highest in $count draws');
        if (tier != 't2') buffer.write('\n');
      }
    }

    return buffer.toString();
  }

  String _generateTotalTierFrequency(List<LottoDraw> draws) {
    final tierCounts = {'t2': 0, 't3': 0, 't4': 0, 't5': 0, 't6': 0};

    for (var draw in draws) {
      final result = _generateTiersInDraw(draw.results);
      final List<String> tiers = result['tiers'];
      for (var tier in tiers) {
        tierCounts[tier] = tierCounts[tier]! + 1;
      }
    }

    final buffer = StringBuffer();
    for (var tier in ['t6', 't5', 't4', 't3', 't2']) {
      final count = tierCounts[tier]!;
      if (count > 0) {
        buffer.write('$tier occurred $count times');
        if (tier != 't2') buffer.write('\n');
      }
    }

    return buffer.toString();
  }

  String _generateSequenceCountSummary(List<LottoDraw> draws) {
    int single = 0;
    int multi = 0;

    for (var draw in draws) {
      final result = _generateTiersInDraw(draw.results);
      final int count = result['count'];
      if (count == 1) single++;
      if (count > 1) multi++;
    }

    final lines = <String>[];
    if (single > 0) lines.add('single tier draws: $single');
    if (multi > 0) lines.add('multi tier draws: $multi');

    return lines.join('\n');
  }

  String _generateFrequencyTable(List<LottoDraw> draws) {
    final Map<int, int> numberCounts = {};

    for (var draw in draws) {
      for (var number in draw.results) {
        numberCounts[number] = (numberCounts[number] ?? 0) + 1;
      }
    }

    final buffer = StringBuffer();
    for (int i = 1; i <= 60; i++) {
      int count = numberCounts[i] ?? 0;
      buffer.write('[$i] appeared $count times');
      if (i < 60) buffer.writeln();
    }

    return buffer.toString();
  }

  String _generateFrequencyRanking(List<LottoDraw> draws) {
    final Map<int, int> numberCounts = {};

    for (var draw in draws) {
      for (var number in draw.results) {
        numberCounts[number] = (numberCounts[number] ?? 0) + 1;
      }
    }

    final ranked = List.generate(60, (i) {
      int number = i + 1;
      return LottoNumber(number: number, frequency: numberCounts[number] ?? 0);
    });

    ranked.sort((a, b) {
      if (b.frequency != a.frequency) {
        return b.frequency.compareTo(a.frequency);
      }
      return a.number.compareTo(b.number);
    });

    final buffer = StringBuffer();
    for (int i = 0; i < ranked.length; i++) {
      var item = ranked[i];
      buffer.write('[${item.number}] appeared ${item.frequency} times');
      if (i < ranked.length - 1) buffer.writeln();
    }

    return buffer.toString();
  }

  String _generateGroupRanking(List<LottoDraw> draws) {
    final Map<int, int> numberCounts = {};

    for (var draw in draws) {
      for (var number in draw.results) {
        numberCounts[number] = (numberCounts[number] ?? 0) + 1;
      }
    }

    final Map<String, int> groupCounts = {
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

    final buffer = StringBuffer();
    for (int i = 0; i < ranked.length; i++) {
      final entry = ranked[i];
      buffer.write('${entry.key} appeared ${entry.value} times');
      if (i < ranked.length - 1) buffer.writeln();
    }

    return buffer.toString();
  }

  String _generateRepeatedDraws(List<LottoDraw> draws) {
    if (draws.isEmpty) return 'no draw data available';

    final Map<String, List<LottoDraw>> groups = {};

    for (final draw in draws) {
      final key = (List<int>.from(draw.results)..sort()).join(',');
      groups.putIfAbsent(key, () => []).add(draw);
    }

    final repeated = groups.values.where((g) => g.length > 1).toList();

    if (repeated.isEmpty) {
      return 'no repeated draw results found';
    }

    final buffer = StringBuffer();

    for (final group in repeated) {
      final numbers = group.first.results.map((n) => n.toString().padLeft(2, '0')).join(', ');

      buffer.writeln('numbers: [$numbers]');

      for (final draw in group) {
        buffer.writeln('  - draw ${draw.drawNumber} (${_formatDate(draw.date)})');
      }

      buffer.writeln(); // group separator
    }

    return buffer.toString().trim();
  }

  Map<String, dynamic> _generateTiersInDraw(Iterable<int> results) {
    // final sorted = List<int>.from(results)..sort();
    final sorted = results.toList()..sort();
    final streaks = <int>[];

    int currentStreak = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == sorted[i - 1] + 1) {
        currentStreak++;
      } else {
        if (currentStreak >= 2) streaks.add(currentStreak);
        currentStreak = 1;
      }
    }
    if (currentStreak >= 2) streaks.add(currentStreak);

    final tiers = streaks
        .map((streak) => 't${streak > 6 ? 6 : streak}')
        .toList();

    final highest = tiers.isEmpty ? null : tiers.reduce((a, b) {
      return int.parse(a.substring(1)) > int.parse(b.substring(1)) ? a : b;
    });

    return {
      'tiers': tiers,
      'highest': highest,
      'tierSet': tiers.toSet(),
      'count': tiers.length,
    };
  }

  String _formatDate(String raw) {
    final parts = raw.split('_'); // ['2025', '05', '31']
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  void loadLottoResults() async {
    try {
      String jsonData = await rootBundle.loadString('res/lotto.json');
      Map<String, dynamic> jsonMap = jsonDecode(jsonData);
      LottoHistory history = LottoHistory.fromJson(jsonMap);
      lottoData.value = history.draws;
      refreshStatistics();
      updateView(ViewMode.drawResults);
    } catch (e) {
      Get.dialog(
        AlertDialog(
          title: const Text('Warning!'),
          content: Text('Error loading lotto data: $e'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}


// TODO > extend helper that iterate for same draws (and their number/date) with user selection
class UserController extends GetxController {
  // add user object to factory game with combinations of numbers to be compared with lotto data
  final Rx<UserProfile> profile = UserProfile(userName: 'guest', games: []).obs;

  // update user name from profile
  void setName(String text) {
    profile.update((p) {
      if (p != null) {
        p.userName = text;
      }
    });
  }

  // create a game object on profile
  void addGame(UserGame userGame) {
    profile.update((p) {
      if (p == null) return;
      p.games.add(userGame);
    });
  }

  // delete a game object on profile
  void deleteGame(UserGame game) {
    profile.update((p) {
      if (p == null) return;
      p.games.remove(game);
    });
  }

  // get dialog to provide pattern input
  void addGameDialog() {
    final nameController = TextEditingController(text: 'Lotto Game');

    final RxInt tempLength = 6.obs;
    final RxSet<int> tempNumbers = <int>{1, 2, 3, 4, 5, 6}.obs;

    void syncNumbers() {
      // If we decrease the size, we need to trim the set
      if (tempNumbers.length > tempLength.value) {
        final List<int> currentList = tempNumbers.toList();
        tempNumbers.assignAll(currentList.take(tempLength.value).toSet());
      }
    }

    void clearSelection() {
      tempNumbers.clear();
    }

    clearSelection();

    Get.dialog(
      AlertDialog(
        // title: const Text('Add New Game'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10.0, width: 360.0),
            Text('Add New Game'),
            // Divider(),
            TextField(decoration: const InputDecoration(labelText: 'Title'), controller: nameController),

            const SizedBox(height: 10.0),

            // Game Size Selector
            Obx(() {
              return Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Game size'),
                  Spacer(),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed:
                            tempLength.value > 6
                                ? () {
                                  tempLength.value--;
                                  syncNumbers();
                                }
                                : null,
                      ),
                      SizedBox(width: 40, child: Text(tempLength.value.toString(), textAlign: TextAlign.center)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed:
                            tempLength.value < 20
                                ? () {
                                  tempLength.value++;
                                }
                                : null,
                      ),
                    ],
                  ),
                ],
              );
            }),

            // const SizedBox(height: 20.0),

            // Selection Progress
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected: ${tempNumbers.length} / ${tempLength.value}',
                    // style: TextStyle(color: tempNumbers.length == tempLength.value ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: tempNumbers.isNotEmpty ? clearSelection : null,
                    icon: const Icon(Icons.restart_alt_rounded, size: 20.0),
                    label: const Text('Restart'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20.0),

            // Toggable Grid
            SizedBox(
              width: 500.0,
              height: 300.0,
              child: GridView.builder(
                itemCount: 60,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final number = index + 1;
                  return Obx(() {
                    final isSelected = tempNumbers.contains(number);
                    return InkWell(
                      // circular splash effect to match the container
                      customBorder: const CircleBorder(),
                      onTap: () {
                        if (isSelected) {
                          tempNumbers.remove(number);
                        } else if (tempNumbers.length < tempLength.value) {
                          tempNumbers.add(number);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.yellow.shade500 : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? Colors.grey.shade300 : Colors.white, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            number.toString().padLeft(2, '0'),
                            style: TextStyle(
                              // color: isSelected ? Colors.white : Colors.black,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(
            () => TextButton(
              // Only allow "OK" if the set is exactly the right size
              onPressed:
                  tempNumbers.length == tempLength.value
                      ? () {
                        final userGame = UserGame(
                          name: nameController.text,
                          length: tempLength.value,
                          numbers: tempNumbers,
                          createdAt: DateTime.now(),
                        );
                        addGame(userGame);
                        Get.back();
                      }
                      : null,
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
  
}

class AppBindings implements Bindings {
  @override
  void dependencies() {
    Get.put(HomeController());
    Get.put(LottoController());
    Get.put(UserController());
  }
}
