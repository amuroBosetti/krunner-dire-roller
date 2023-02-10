import 'dart:io';
import 'dart:math';

import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:krunner/krunner.dart';

Future<void> main(List<String> arguments) async {
  // Check if already running.
  await checkIfAlreadyRunning();

  // Instantiate the plugin, provider identifiers and callback functions.
  final runner = KRunnerPlugin(
    identifier: 'com.example.roll_runner',
    name: '/roll_runner',
    matchQuery: matchQuery,
    retrieveActions: retrieveActions,
    runAction: runAction,
  );

  // Start the plugin and enter the event loop.
  await runner.init();
}

/// Check if an instance of this plugin is already running.
///
/// If we don't check KRunner will just launch a new instance every time.
Future<void> checkIfAlreadyRunning() async {
  final result = await Process.run('pidof', ['roll_runner']);
  final hasError = result.stderr != '';
  if (hasError) {
    print('Issue checking for existing process: ${result.stderr}');
    return;
  }
  final output = result.stdout as String;
  final runningInstanceCount = output
      .trim()
      .split(' ')
      .length;
  if (runningInstanceCount != 1) {
    print('An instance of roll_runner appears to already be running. '
        'Aborting run of new instance.');
    exit(0);
  }
}

Future<List<QueryMatch>> matchQuery(String query) async {
  // We want to match anything that has the pattern 'roll ndnn'
  RegExp regex = RegExp(r'^roll\s\d+d\d+');
  if (!regex.hasMatch(query)) return const [];
  final matches = <QueryMatch>[];
  final result = DiceQuery.from(query).roll();
  matches.add(QueryMatch(
    icon: 'clock',
    id: result.value().toString(),
    rating: QueryMatchRating.exact,
    relevance: 1.0,
    title: 'You rolled a ${result.value()}!',
    properties: QueryMatchProperties(subtitle: result.termsRepresentation()),
  ));
  return matches;
}

int rollDice(String query) => Random().nextInt(20);

Future<List<SecondaryAction>> retrieveActions() async {
  return [
    SecondaryAction(id: 'notify', text: 'Notify', icon: 'notifications'),
  ];
}

Future<void> runAction({
  required String matchId,
  String? actionId,
}) async {
  // if (actionId == 'notify') {
  //   // Secondary action: Notification with local timezone.
  //   final timezone = DateTime.now().timeZoneName;
  //   await sendNotification('Current timezone is: $timezone');
  // } else {
  //   // Primary action: Notification with current time.
  //   await sendNotification('Current time is: $matchId');
  // }
}

/// Send a desktop notification containing [value].

Future<void> sendNotification(String value) async {
  final client = NotificationsClient();
  await client.notify(value);
  await client.close();
}

class DiceQuery {
  late int diceAmount;
  late int diceType;

  DiceQuery(String diceAmount, String diceType) {
    this.diceAmount = int.parse(diceAmount);
    this.diceType = int.parse(diceType);
  }


  static DiceQuery from(String query) {
    RegExp regex = RegExp(r'(\d*)d(\d*)');
    final match = regex.firstMatch(query);
    final diceAmount = match!.group(1);
    final diceType = match.group(2);
    return DiceQuery(diceAmount!, diceType!);
  }

  roll() {
    final diceList = <Dice>[];
    for(var i = 0; i < diceAmount; i++) {
      diceList.add(Dice(diceType));
    }
    return RollResult(diceList);
  }
}

class RollResult {
  List<Dice> diceList;
  RollResult(this.diceList);

  value() {
    return diceList.fold(0, (int previousValue, element) => previousValue + element.result);
  }

  termsRepresentation() {
    return diceList.fold<String>('', (previousValue, element) => previousValue + ' + ${element.result}');
  }
}

class Dice {
  int diceType;
  late int result;
  Dice(this.diceType) {
    result = Random().nextInt(diceType) + 1;
  }
}
