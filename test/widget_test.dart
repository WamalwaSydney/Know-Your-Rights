// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legal_ai/widgets/chat_bubble.dart';
import 'package:legal_ai/core/constants.dart';

void main() {
  group('ChatBubble Widget Tests', () {
    testWidgets('displays user message correctly', (WidgetTester tester) async {
      const testMessage = 'Hello, this is a test message';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: testMessage,
              isUser: true,
            ),
          ),
        ),
      );

      expect(find.text(testMessage), findsOneWidget);
      expect(find.byType(ChatBubble), findsOneWidget);
    });

    testWidgets('displays AI message correctly', (WidgetTester tester) async {
      const testMessage = 'AI response message';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: testMessage,
              isUser: false,
            ),
          ),
        ),
      );

      expect(find.text(testMessage), findsOneWidget);
      expect(find.byType(ChatBubble), findsOneWidget);
    });

    testWidgets('user message aligns to the right', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: 'User message',
              isUser: true,
            ),
          ),
        ),
      );

      final alignWidget = tester.widget<Align>(find.byType(Align));
      expect(alignWidget.alignment, Alignment.centerRight);
    });

    testWidgets('AI message aligns to the left', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: 'AI message',
              isUser: false,
            ),
          ),
        ),
      );

      final alignWidget = tester.widget<Align>(find.byType(Align));
      expect(alignWidget.alignment, Alignment.centerLeft);
    });

    testWidgets('user message has correct background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: 'User message',
              isUser: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, kUserChatBubbleColor);
    });

    testWidgets('AI message has correct background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: 'AI message',
              isUser: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, kAIChatBubbleColor);
    });

    testWidgets('user message has correct text color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: 'User message',
              isUser: true,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('User message'));
      expect(textWidget.style?.color, kUserChatTextColor);
    });

    testWidgets('AI message has correct text color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: 'AI message',
              isUser: false,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('AI message'));
      expect(textWidget.style?.color, kAIChatTextColor);
    });
  });
}