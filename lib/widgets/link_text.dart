import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/link_launcher.dart';

final _urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);

/// Текстовый виджет, автоматически делающий URL кликабельными.
///
/// Stateful, потому что [TapGestureRecognizer] нужно диспозить: созданный в
/// `build` и брошенный, он течёт на каждой перерисовке. Держим по одному
/// распознавателю на ссылку и пересоздаём их только когда текст изменился.
class LinkText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const LinkText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  final _recognizers = <String, TapGestureRecognizer>{};

  @override
  void didUpdateWidget(LinkText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _disposeRecognizers();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final linkColor = Theme.of(context).colorScheme.primary;
    final spans = <InlineSpan>[];
    int last = 0;

    for (final match in _urlRegex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        ),
        recognizer: _recognizers.putIfAbsent(
          url,
          () => TapGestureRecognizer()
            ..onTap = () => openExternal(context, url),
        ),
      ));
      last = match.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return RichText(
      text: TextSpan(
          style: widget.style ?? DefaultTextStyle.of(context).style,
          children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow ?? TextOverflow.clip,
    );
  }
}
