import 'package:bluebubbles/database/sqlite/storage_state.dart';
import 'package:flutter/material.dart';

/// Shown while startup waits for the one-time copy of messages into the new
/// database (StorageStartup.start); Main replaces it once the copy is done.
class StorageCopyScreen extends StatelessWidget {
  const StorageCopyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? Colors.black : Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/icon/icon.png", width: 120, fit: BoxFit.contain),
              const SizedBox(height: 32),
              Text("Updating your messages",
                  style: TextStyle(fontSize: 18, color: dark ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
              Text("This happens once and takes about a minute.",
                  textAlign: TextAlign.center, style: TextStyle(color: dark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 24),
              ValueListenableBuilder<double>(
                valueListenable: StorageStartup.progress,
                builder: (_, value, _) => LinearProgressIndicator(value: value <= 0 ? null : value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
