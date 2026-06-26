import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';

void main() {
  // [ProviderScope] is Riverpod's root container: it holds the state of every
  // provider in the app. It must sit above everything that reads a provider,
  // so we wrap the entire app in it.
  runApp(const ProviderScope(child: TickrApp()));
}
