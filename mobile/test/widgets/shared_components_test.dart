import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/core/errors/app_exception.dart';
import 'package:rentra/core/theme/app_theme.dart';
import 'package:rentra/core/theme/app_tokens.dart';
import 'package:rentra/core/widgets/app_card.dart';
import 'package:rentra/core/widgets/async_body.dart';
import 'package:rentra/core/widgets/buttons.dart';
import 'package:rentra/core/widgets/copy_row.dart';
import 'package:rentra/core/widgets/display.dart';
import 'package:rentra/core/widgets/feedback.dart';
import 'package:rentra/core/widgets/sheets.dart';
import 'package:rentra/core/widgets/states.dart';
import 'package:rentra/core/widgets/status_chip.dart';
import 'package:rentra/core/widgets/text_fields.dart';

Future<void> pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpWithContext(
  WidgetTester tester,
  void Function(BuildContext context) onPressed,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => onPressed(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('buttons', () {
    testWidgets('primary button calls back and scales while pressed',
        (tester) async {
      var taps = 0;
      await pump(tester, PrimaryButton(label: 'Save', onPressed: () => taps++));

      final gesture = await tester.startGesture(tester.getCenter(find.text('Save')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        AppMotion.pressedScale,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });

    testWidgets('loading disables the button and keeps its label for screen readers',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: PrimaryButton(label: 'Save', isLoading: true, onPressed: () => taps++),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Save'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    });

    testWidgets('secondary, text and destructive buttons work', (tester) async {
      final pressed = <String>[];
      await pump(
        tester,
        Column(
          children: [
            SecondaryButton(label: 'Second', onPressed: () => pressed.add('s')),
            AppTextButton(label: 'Text', onPressed: () => pressed.add('t')),
            DestructiveButton(label: 'End', onPressed: () => pressed.add('d')),
          ],
        ),
      );
      await tester.tap(find.text('Second'));
      await tester.tap(find.text('Text'));
      await tester.tap(find.text('End'));
      expect(pressed, ['s', 't', 'd']);
      for (final finder in [
        find.byType(OutlinedButton).first,
        find.byType(TextButton),
        find.byType(OutlinedButton).last,
      ]) {
        expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
      }
    });
  });

  group('states', () {
    testWidgets('empty state explains and offers one action', (tester) async {
      var acted = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: EmptyState(
              icon: Icons.home_outlined,
              title: 'No buildings yet',
              message: 'Add one to start.',
              actionLabel: 'Add a building',
              onAction: () => acted = true,
            ),
          ),
        ),
      );
      expect(find.text('No buildings yet'), findsOneWidget);
      expect(find.text('Add one to start.'), findsOneWidget);
      await tester.tap(find.text('Add a building'));
      expect(acted, isTrue);
    });

    testWidgets('empty state without an action shows no button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: EmptyState(icon: Icons.home, title: 'Calm', message: 'Nothing to do.'),
          ),
        ),
      );
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('error state is specific to being offline and retries', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ErrorState(
              error: const NoConnectionException(),
              onRetry: () => retried++,
            ),
          ),
        ),
      );
      expect(find.text("You're offline"), findsOneWidget);
      expect(find.textContaining("couldn't connect to the internet"), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, 1);
    });

    testWidgets('error state never shows raw errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: ErrorState(error: StateError('null check'), onRetry: () {})),
        ),
      );
      expect(find.textContaining('null check'), findsNothing);
      expect(find.text("We couldn't load this"), findsOneWidget);
    });

    testWidgets('async body shows skeleton, then error, then data', (tester) async {
      Future<void> show(AsyncValue<int> value) => tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              home: Scaffold(
                body: AsyncBody<int>(
                  value: value,
                  onRetry: () {},
                  data: (n) => Text('Value $n'),
                ),
              ),
            ),
          );
      await show(const AsyncLoading());
      expect(find.byType(SkeletonList), findsOneWidget);
      await show(const AsyncError(ServerException(), StackTrace.empty));
      expect(find.text('Try again'), findsOneWidget);
      await show(const AsyncData(3));
      expect(find.text('Value 3'), findsOneWidget);
    });

    testWidgets('inline message pairs colour with an icon', (tester) async {
      await pump(tester, const InlineMessage(message: 'Saved', tone: InlineTone.success));
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
    });
  });

  group('display', () {
    testWidgets('status chips always show an icon with their text', (tester) async {
      await pump(
        tester,
        Column(
          children: [
            for (final tone in StatusTone.values)
              StatusChip(label: tone.name, tone: tone),
          ],
        ),
      );
      for (final tone in StatusTone.values) {
        expect(find.text(tone.name), findsOneWidget);
        expect(find.byIcon(tone.defaultIcon), findsWidgets);
      }
    });

    testWidgets('money text formats and reads out shillings', (tester) async {
      await pump(tester, const MoneyText(12500));
      expect(find.text('KES 12,500'), findsOneWidget);
      expect(find.bySemanticsLabel('Kenya shillings 12,500'), findsOneWidget);
    });

    testWidgets('stat tile is read as one label', (tester) async {
      await pump(
        tester,
        const StatTile(label: 'Buildings', value: '3', icon: Icons.apartment),
      );
      expect(find.bySemanticsLabel('Buildings: 3'), findsOneWidget);
    });

    testWidgets('list card is tappable and shows a chevron', (tester) async {
      var tapped = false;
      await pump(tester, ListCard(title: 'A1', subtitle: 'Vacant', onTap: () => tapped = true));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(find.text('A1'));
      expect(tapped, isTrue);
    });

    testWidgets('detail row wraps long values instead of overflowing', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 200,
          child: DetailRow(
            label: 'Notes',
            value: 'A very long note that cannot possibly fit on one line here',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('cards skip their entrance animation when animations are off',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: AppCard(child: Text('Card'))),
          ),
        ),
      );
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
      expect(find.text('Card'), findsOneWidget);
    });
  });

  group('fields', () {
    testWidgets('OTP field accepts digits only and reports completion once',
        (tester) async {
      final controller = TextEditingController();
      final completed = <String>[];
      await pump(tester, OtpField(controller: controller, onCompleted: completed.add));
      await tester.enterText(find.byType(TextField), '12a3456');
      await tester.pump();
      expect(controller.text, '123456');
      expect(completed, ['123456']);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('Kenyan phone field validates without changing the input',
        (tester) async {
      final key = GlobalKey<FormState>();
      final controller = TextEditingController();
      await pump(tester, Form(key: key, child: KenyanPhoneField(controller: controller)));
      await tester.enterText(find.byType(TextFormField), '12345');
      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.textContaining('Kenyan phone number'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '+254712345678');
      expect(key.currentState!.validate(), isTrue);
      expect(controller.text, '+254712345678');
    });

    testWidgets('money field shows KES and drops letters', (tester) async {
      final controller = TextEditingController();
      await pump(tester, MoneyField(label: 'Rent', controller: controller));
      expect(find.text('KES '), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '12a,500');
      expect(controller.text, '12,500');
    });

    testWidgets('password field can be revealed', (tester) async {
      await pump(tester, PasswordField(controller: TextEditingController()));
      expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText, isFalse);
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('date field shows the date in words', (tester) async {
      await pump(
        tester,
        AppDateField(
          label: 'Moved in',
          value: DateTime(2026, 10, 5),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          onChanged: (_) {},
        ),
      );
      expect(find.text('5 Oct 2026'), findsOneWidget);
    });

    testWidgets('dropdown shows options by label', (tester) async {
      String? chosen;
      await pump(
        tester,
        AppDropdownField<String>(
          label: 'Type',
          value: 'a',
          options: const [DropdownOption('a', 'Bedsitter'), DropdownOption('b', 'Shop')],
          onChanged: (v) => chosen = v,
        ),
      );
      await tester.tap(find.text('Bedsitter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shop').last);
      await tester.pumpAndSettle();
      expect(chosen, 'b');
    });
  });

  group('feedback', () {
    testWidgets('confirm dialog returns the choice', (tester) async {
      bool? result;
      await pumpWithContext(tester, (context) async {
        result = await showConfirmDialog(
          context: context,
          title: 'End this rental?',
          message: 'You can add another later.',
          confirmLabel: 'End rental',
          destructive: true,
        );
      });
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End rental'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('a sheet keeps a failure inline and closes on success',
        (tester) async {
      var attempts = 0;
      bool? result;
      await pumpWithContext(tester, (context) async {
        result = await showAmountSheet(
          context: context,
          title: 'Update rent',
          label: 'Monthly rent',
          initial: 7000,
          submitLabel: 'Save rent',
          onSubmit: (_) async {
            attempts++;
            if (attempts == 1) throw const NoConnectionException();
          },
        );
      });
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save rent'));
      await tester.pumpAndSettle();
      expect(find.textContaining("couldn't connect"), findsOneWidget);
      expect(find.text('Update rent'), findsOneWidget);

      await tester.tap(find.text('Save rent'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(find.text('Update rent'), findsNothing);
    });

    testWidgets('copy row copies and confirms', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      await pump(tester, const CopyRow(label: 'Paybill Number', value: '522522'));
      await tester.tap(find.byTooltip('Copy paybill number'));
      await tester.pumpAndSettle();
      expect(copied, '522522');
      expect(find.text('Paybill Number copied.'), findsOneWidget);
    });

    testWidgets('success snackbar pairs the message with an icon', (tester) async {
      await pumpWithContext(tester, (context) => showSuccessSnackBar(context, 'Payment recorded.'));
      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(find.text('Payment recorded.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });
}
