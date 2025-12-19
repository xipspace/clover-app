import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_controller.dart';
// import 'app_model.dart';

enum AppScreen { home, info, user }

class ScreenFactory {
  static Widget create(AppScreen screen) {
    switch (screen) {
      case AppScreen.home:
        return const HomeScreen();
      case AppScreen.info:
        return const InfoScreen();
      case AppScreen.user:
        return const UserScreen();
    }
  }
}

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'cloverApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/',
      initialBinding: AppBindings(),
      home: const SafeArea(child: HomeScreen()),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('@xipspace'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: const Icon(Icons.dark_mode_outlined), onPressed: () {}),
          // IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(controller.msg.value),
                Text(controller.timeStamp.value),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Get.offAll(() => ScreenFactory.create(AppScreen.info)),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 640),
                    child: Image.asset('res/clover_banner.png', fit: BoxFit.contain,)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final lotto = Get.find<LottoController>();
    controller.setStamp();
    if (controller.msg.value != 'user') {
      controller.setMessage('lotto');
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(child: const Text('@xipspace'), onTap: () => Get.offAll(() => const HomeScreen())),
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Get.to(() => const UserScreen())),
          IconButton(icon: const Icon(Icons.dark_mode_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Obx(() => Text(controller.msg.value)),
                Obx(() => Text(controller.timeStamp.value)),
                const SizedBox(height: 10),
                Text('draws: ${lotto.lottoData.length.toString()}'),
                Text(lotto.formattedLastDraw),
                Text('last result: ${lotto.lottoData.last.results.toString()}'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 10),
                    Obx(() {
                      final current = lotto.currentFilter.value;

                      return DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<TimeFilter>(
                            value: current,
                            icon: const Icon(Icons.arrow_drop_down),
                            dropdownColor: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: TimeFilter.allTime,
                                child: Text('All Time'),
                              ),
                              DropdownMenuItem(
                                value: TimeFilter.fiveYears,
                                child: Text('5 Years'),
                              ),
                              DropdownMenuItem(
                                value: TimeFilter.oneYear,
                                child: Text('1 Year'),
                              ),
                              DropdownMenuItem(
                                value: TimeFilter.sixMonths,
                                child: Text('6 Months'),
                              ),
                              DropdownMenuItem(
                                value: TimeFilter.oneMonth,
                                child: Text('1 Month'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                lotto.updateFilter(value);
                              }
                            },
                          ),
                        ),
                      );
                    }),

                    const SizedBox(width: 10),

                    Obx(() {
                      final current = lotto.currentView.value;

                      return DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<ViewMode>(
                            value: current,
                            icon: const Icon(Icons.arrow_drop_down),
                            dropdownColor: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: ViewMode.drawResults,
                                child: Text('Draw Results'),
                              ),
                              DropdownMenuItem(
                                value: ViewMode.frequencyTable,
                                child: Text('Frequency by Number'),
                              ),
                              DropdownMenuItem(
                                value: ViewMode.frequencyRanking,
                                child: Text('Frequency Ranking'),
                              ),
                              DropdownMenuItem(
                                value: ViewMode.groupRanking,
                                child: Text('Group Ranking'),
                              ),
                              DropdownMenuItem(
                                value: ViewMode.sequenceTiers,
                                child: Text('Sequence Tiers'),
                              ),
                              DropdownMenuItem(
                                value: ViewMode.repeatedDraws,
                                child: Text('Repeated Draws'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                lotto.updateView(value);
                              }
                            },
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 640),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
                        child: Center(
                          child: Column(
                            children: [
                              Obx(() => Text(lotto.lottoBanner.value, textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final user = Get.find<UserController>();
    // final lotto = Get.find<LottoController>();
    final MediaQueryData mediaQueryData = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        // title: GestureDetector(child: const Text('@xipspace'), onTap: () => Get.offAll(() => const HomeScreen())),
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
          IconButton(icon: const Icon(Icons.dark_mode_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Obx(() => Text(controller.userState.value.toString())),
                Obx(() => Text(controller.msg.value)),
                Obx(() => Text(controller.timeStamp.value)),

                // Obx(() => Text('isLogged: ${controller.isLogged}')),
                // Obx(() => Text(controller.userIsLogged.value.toString())),
                const SizedBox(height: 10),
                const Text('device info'),
                const SizedBox(height: 10),
                Text('Screen Size: ${mediaQueryData.size.width} x ${mediaQueryData.size.height}'),
                Text('Orientation: ${mediaQueryData.orientation}'),
                Text('Device Pixel Ratio: ${mediaQueryData.devicePixelRatio}'),
                Text('Device Theme: ${mediaQueryData.platformBrightness}'),

                Text('GetX isDarkMode: ${Get.isDarkMode}'),

                // Obx(() => Text('isLight: ${controller.isLight}')),
                // width: Get.width * 0.95,
                // height: Get.height * 0.95,
                // Obx(() => Text('username: ${user.profile.value.userName.toString()}')),
                const SizedBox(height: 20),
                Obx(() => Text('username: ${user.profile.value.userName}')),
                Obx(() => Text('games: ${user.profile.value.games.length.toString()}')),
                const SizedBox(height: 20),
              
                Obx(() {
                  final games = user.profile.value.games;

                  return Column(
                    children:
                        games.map((game) {
                          return Card(
                            child: Container(
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                              constraints: const BoxConstraints(maxWidth: 680.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(game.name),
                                        Spacer(),
                                        Tooltip(
                                          message: 'delete',
                                          child: IconButton(
                                            iconSize: 15.0,
                                            icon: Icon(Icons.close),
                                            onPressed: () => user.deleteGame(game),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(),
                                    const SizedBox(height: 5),
                                    Text('size: ${game.length}'),
                                    Text('numbers: ${game.numbers.join(', ')}'),
                                    Text('created: ${game.createdAt.toIso8601String()}'),
                                    Text('statistics: [tbd]'),
                                    const SizedBox(height: 5),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          controller.setStamp();
          // controller.isLogged.toggle();
          // controller.isLogged.value ? controller.setMsg('user') : controller.setMsg('guest');
          // controller.setMessage('user');
          /*
          user.profile.value.userName.isNotEmpty && user.profile.value.userName != 'guest'
              ? controller.setMessage('user')
              : controller.setMessage('guest');
          */

          // TODO > persist user games
          user.addGameDialog();
        },
      ),
    );
  }
}
