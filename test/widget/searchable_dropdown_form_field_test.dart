import 'package:codewalk/presentation/widgets/searchable_dropdown_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filters items and applies the selected value', (
    WidgetTester tester,
  ) async {
    String? selectedValue = 'alpha';

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: SearchableDropdownFormField<String>(
                  key: const ValueKey<String>('searchable_dropdown'),
                  value: selectedValue,
                  searchHintText: 'Search option',
                  searchTermsBuilder: (value) => switch (value) {
                    'alpha' => <String>['Alpha', 'one'],
                    'beta' => <String>['Beta', 'two'],
                    _ => <String>[value],
                  },
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'alpha',
                      child: Text('Alpha'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'beta',
                      child: Text('Beta'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedValue = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Choice',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('searchable_dropdown')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'two');
    await tester.pumpAndSettle();

    expect(find.text('Beta'), findsOneWidget);

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(selectedValue, 'beta');
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('shows an empty state when no items match', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SearchableDropdownFormField<String>(
              key: const ValueKey<String>('searchable_dropdown_empty'),
              value: 'alpha',
              emptyText: 'Nothing available',
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'alpha', child: Text('Alpha')),
              ],
              onChanged: _noop,
              decoration: const InputDecoration(
                labelText: 'Choice',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('searchable_dropdown_empty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();

    expect(find.text('Nothing available'), findsOneWidget);
  });

  testWidgets('stays closed when disabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SearchableDropdownFormField<String>(
              key: const ValueKey<String>('searchable_dropdown_disabled'),
              value: 'alpha',
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'alpha', child: Text('Alpha')),
              ],
              onChanged: null,
              decoration: const InputDecoration(
                labelText: 'Choice',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('searchable_dropdown_disabled')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('supports rollback through FormFieldState.didChange', (
    WidgetTester tester,
  ) async {
    final fieldKey = GlobalKey<FormFieldState<String>>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SearchableDropdownFormField<String>(
              key: fieldKey,
              initialValue: 'alpha',
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'alpha', child: Text('Alpha')),
                DropdownMenuItem<String>(value: 'beta', child: Text('Beta')),
              ],
              onChanged: (value) {
                if (value == 'beta') {
                  fieldKey.currentState?.didChange('alpha');
                }
              },
              decoration: const InputDecoration(
                labelText: 'Choice',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(fieldKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
  });
}

void _noop(String? _) {}
