import 'package:sponge_client_dart/src/exception.dart';
import 'package:sponge_client_dart/src/type_value.dart';
import 'package:sponge_client_dart/src/util/type_utils.dart';
import 'package:test/test.dart';

void main() {
  test('getPathElements', () {
    expect(DataTypeUtils.getPathElements('a.b.c'), equals(['a', 'b', 'c']));
    expect(DataTypeUtils.getPathElements('a'), equals(['a']));
    expect(DataTypeUtils.getPathElements('this'), equals([]));
    expect(DataTypeUtils.getPathElements(null), equals([]));
  });
  test('getSubValue', () {
    expect(
        DataTypeUtils.getSubValue({
          'a': {
            'b': {'c': 'test'}
          }
        }, 'a.b.c'),
        equals('test'));

    expect(
        DataTypeUtils.getSubValue({
          'a': {
            'b': {'c': 'test'}
          }
        }, 'a.b'),
        equals({'c': 'test'}));

    expect(
        DataTypeUtils.getSubValue({
          'a': {
            'b': {'c': 'test'}
          }
        }, 'a'),
        equals({
          'b': {'c': 'test'}
        }));

    expect(
        DataTypeUtils.getSubValue({
          'a': {
            'b': {'c': 'test'}
          }
        }, 'this'),
        equals({
          'a': {
            'b': {'c': 'test'}
          }
        }));

    expect(DataTypeUtils.getSubValue(null, 'a'), isNull);
  });
  test('getSubValue - AnnotatedValue', () {
    expect(
        DataTypeUtils.getSubValue(
            AnnotatedValue({
              'a': {
                'b': {'c': 'test'}
              }
            }),
            'a.b.c'),
        equals('test'));

    expect(
        DataTypeUtils.getSubValue(
            AnnotatedValue({
              'a': {
                'b': {'c': 'test'}
              }
            }),
            'a.b'),
        equals({'c': 'test'}));

    expect(
        DataTypeUtils.getSubValue(
            AnnotatedValue({
              'a': {
                'b': {'c': 'test'}
              }
            }),
            'a'),
        equals({
          'b': {'c': 'test'}
        }));
    expect(
        DataTypeUtils.getSubValue(
            AnnotatedValue({
              'a': {
                'b': {'c': 'test'}
              }
            }),
            'this'),
        equals({
          'a': {
            'b': {'c': 'test'}
          }
        }));

    expect(DataTypeUtils.getSubValue(AnnotatedValue(null), 'a'), isNull);
  });
  test('getSubValue - return annotated', () {
    expect(
        DataTypeUtils.getSubValue({
          'a': {
            'b': {'c': AnnotatedValue('test')}
          }
        }, 'a.b.c', returnAnnotatedTarget: true)
            .value,
        equals('test'));

    expect(
        DataTypeUtils.getSubValue(
                AnnotatedValue({
                  'a': {
                    'b': AnnotatedValue({'c': 'test'})
                  }
                }),
                'a.b',
                returnAnnotatedTarget: true)
            .value,
        equals({'c': 'test'}));

    expect(
        DataTypeUtils.getSubValue(
                AnnotatedValue({
                  'a': AnnotatedValue({
                    'b': {'c': 'test'}
                  })
                }),
                'a',
                returnAnnotatedTarget: true)
            .value,
        equals({
          'b': {'c': 'test'}
        }));
    expect(
        DataTypeUtils.getSubValue(
                AnnotatedValue({
                  'a': {
                    'b': {'c': 'test'}
                  }
                }),
                'this',
                returnAnnotatedTarget: true)
            .value,
        equals({
          'a': {
            'b': {'c': 'test'}
          }
        }));

    expect(
        DataTypeUtils.getSubValue(AnnotatedValue(null), 'this',
                returnAnnotatedTarget: true)
            .value,
        isNull);

    // Annotated values in the path are skipped.
    expect(
        DataTypeUtils.getSubValue(AnnotatedValue(null), 'a',
            returnAnnotatedTarget: true),
        isNull);
  });
  test('setSubValue', () {
    var value = {
      'a': {
        'b': {'c': 'test'}
      }
    };
    DataTypeUtils.setSubValue(value, 'a.b.c', 'test2');
    expect(value['a']['b']['c'], equals('test2'));

    value = {
      'a': {
        'b': {'c': 'test'}
      }
    };
    DataTypeUtils.setSubValue(value, 'a.b', {'c': 'test3'});
    expect(value['a']['b'], equals({'c': 'test3'}));

    value = {
      'a': {
        'b': {'c': 'test'}
      }
    };
    DataTypeUtils.setSubValue(value, 'a', {
      'b': {'c': 'test4'}
    });
    expect(
        value['a'],
        equals({
          'b': {'c': 'test4'}
        }));

    value = {
      'a': {
        'b': {'c': 'test'}
      }
    };

    expect(
        () => DataTypeUtils.setSubValue(value, 'this', {
              'a': {
                'b': {'c': 'test5'}
              }
            }),
        throwsA(predicate((e) =>
            e is SpongeException &&
            e.message ==
                'The path \'this\' is empty or points to the same value')));

    expect(
        () => DataTypeUtils.setSubValue({
              'a': {'b': null}
            }, 'a.b.c', 'test6'),
        throwsA(predicate((e) =>
            e is SpongeException &&
            e.message == 'The parent value of a.b.c is null')));
  });
}
