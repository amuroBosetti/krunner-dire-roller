import 'package:krunner/krunner.dart';
import 'package:test/test.dart';

import '../bin/roll_runner.dart';

void main(){
  test('When rolling any dice using the right syntax, the list of matches is not empty', () async{
    await expectLater(matchQuery('roll 1d20'), completion(isNotEmpty));
  });

  test('When rolling 1d1, the result is always 1', () async{
    await expectLater(matchQuery('roll 1d1'), completion(everyElement(predicate((QueryMatch match) => match.title == 'You rolled a 1!'))));
  });
}
    