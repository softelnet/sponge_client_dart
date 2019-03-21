import 'package:sponge_client_dart/src/sub_action.dart';
import 'package:test/test.dart';

void main() {
  test('Sub-action specification - one mapping', () {
    var subAction = SubActionSpec.parse(
        'ContextAction(targetArg=sourceArg)', SubActionType.context);
    expect(subAction.actionName, 'ContextAction');
    expect(subAction.argSubstitutions.length, 1);
    expect(subAction.argSubstitutions[0].target, 'targetArg');
    expect(subAction.argSubstitutions[0].source, 'sourceArg');
  });
  test('Sub-action specification - two mappings', () {
    var subAction = SubActionSpec.parse(
        'ContextAction(targetArg1=sourceArg1, targetArg2=sourceArg2)',
        SubActionType.context);
    expect(subAction.actionName, 'ContextAction');
    expect(subAction.argSubstitutions.length, 2);
    expect(subAction.argSubstitutions[0].target, 'targetArg1');
    expect(subAction.argSubstitutions[0].source, 'sourceArg1');
    expect(subAction.argSubstitutions[1].target, 'targetArg2');
    expect(subAction.argSubstitutions[1].source, 'sourceArg2');
  });
  test('Sub-action specification - no mapping with parentheses', () {
    var subAction =
        SubActionSpec.parse('ContextAction()', SubActionType.context);
    expect(subAction.actionName, 'ContextAction');
    expect(subAction.argSubstitutions.length, 0);
  });
  test('Sub-action specification - no mapping without parentheses', () {
    var subAction = SubActionSpec.parse('ContextAction', SubActionType.context);
    expect(subAction.actionName, 'ContextAction');
    expect(subAction.argSubstitutions, isNull);
  });
  test('Sub-action specification - one arg default', () {
    var subAction =
        SubActionSpec.parse('ContextAction(sourceArg)', SubActionType.context);
    expect(subAction.actionName, 'ContextAction');
    expect(subAction.argSubstitutions.length, 1);
    expect(subAction.argSubstitutions[0].target, isNull);
    expect(subAction.argSubstitutions[0].source, 'sourceArg');
  });
  test('Sub-action specification - two args default', () {
    var subAction = SubActionSpec.parse(
        'ContextAction(sourceArg1,sourceArg2)', SubActionType.context);
    expect(subAction.actionName, 'ContextAction');
    expect(subAction.argSubstitutions.length, 2);
    expect(subAction.argSubstitutions[0].target, null);
    expect(subAction.argSubstitutions[0].source, 'sourceArg1');
    expect(subAction.argSubstitutions[1].target, null);
    expect(subAction.argSubstitutions[1].source, 'sourceArg2');
  });
  test('Sub-action specification - one mapping path', () {
    var subAction = SubActionSpec.parse(
        'ContextAction(targetArg=sourceArg.field)', SubActionType.context);
    expect(subAction.actionName, 'ContextAction');
    expect(subAction.argSubstitutions.length, 1);
    expect(subAction.argSubstitutions[0].target, 'targetArg');
    expect(subAction.argSubstitutions[0].source, 'sourceArg.field');
  });
  test('Sub-action specification - empty', () {
    expect(
        () => SubActionSpec.parse('', SubActionType.context),
        throwsA(
            predicate((e) => e.message == 'Invalid action specification: ')));
  });
  test('Sub-action specification - empty', () {
    expect(
        () => SubActionSpec.parse(
            'ContextAction(targetArg=)', SubActionType.context),
        throwsA(predicate((e) =>
            e.message ==
            'Invalid argument in the action specification: ContextAction(targetArg=)')));
  });
  test('Sub-action specification - incorrect mapping with path', () {
    expect(
        () => SubActionSpec.parse(
            'ContextAction(targetArg.incorrect=sourceArg)',
            SubActionType.context),
        throwsA(predicate((e) =>
            e.message ==
            'Invalid argument in the action specification: ContextAction(targetArg.incorrect=sourceArg)')));
  });
}
