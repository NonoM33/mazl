import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

/// The reading direction of text written by a member (a message, a bio):
/// its own, from its words, not the interface's. A French message stays
/// left-to-right in the Hebrew interface, and the other way round. Text with
/// no strong direction (an emoji, a number) follows [context].
TextDirection contentDirection(BuildContext context, String text) =>
    switch (intl.Bidi.estimateDirectionOfText(text)) {
      intl.TextDirection.RTL => TextDirection.rtl,
      intl.TextDirection.LTR => TextDirection.ltr,
      _ => Directionality.of(context),
    };

/// Where a member's text lines up in the layout: on the interface's start
/// side (the right in Hebrew), even when the text itself reads the other way.
TextAlign interfaceStart(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
    ? TextAlign.right
    : TextAlign.left;
