import 'package:flutter/material.dart';
import 'package:ona_bottom_sheet/ona_bottom_sheet.dart';

void main() => runApp(const ExampleApp());

/// A tour of ona_bottom_sheet: every kind of sheet the package draws, in light and dark.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _mode = ThemeMode.light;
  bool _glass = false;
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

  /// `--dart-define=ONA_TOUR=true` walks through the demos on its own, printing `TOUR <name>` as each one shows:
  /// how the README's screenshots are taken.
  static const bool _tour = bool.fromEnvironment('ONA_TOUR');

  @override
  void initState() {
    super.initState();
    if (_tour) WidgetsBinding.instance.addPostFrameCallback((_) => _walk());
  }

  Future<void> _walk() async {
    Future<void> hold(String name) async {
      debugPrint('TOUR $name');
      await Future<void>.delayed(const Duration(seconds: 3));
    }

    for (final (bool dark, bool glass) in <(bool, bool)>[(false, false), (false, true), (true, false), (true, true)]) {
      setState(() {
        _mode = dark ? ThemeMode.dark : ThemeMode.light;
        _glass = glass;
      });
      await Future<void>.delayed(const Duration(seconds: 1));
      final String mode = '${dark ? 'dark' : 'light'}-${glass ? 'glass' : 'solid'}';
      showOnaBottomSheet<void>(context: _navigator.currentContext!, builder: (_) => const _TemplatesSheet());
      await hold('$mode-long');
      _navigator.currentState!.pop();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      showOnaBottomSheet<bool>(context: _navigator.currentContext!, builder: (_) => const _ConfirmSheet());
      await hold('$mode-confirm');
      _navigator.currentState!.pop();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      _navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const _MapScreen()));
      await hold('$mode-always-on');
      _navigator.currentState!.pop();
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
    debugPrint('TOUR done');
  }

  OnaSheetStyle get _style => _glass ? const OnaSheetStyle.glass() : OnaSheetStyle.solid;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigator,
      title: 'Ona sheets',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4D7BA7),
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        extensions: <ThemeExtension<dynamic>>[OnaBottomSheetTheme.light.copyWith(style: _style)],
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF4D7BA7),
        brightness: Brightness.dark,
        extensions: <ThemeExtension<dynamic>>[OnaBottomSheetTheme.dark.copyWith(style: _style)],
      ),
      home: _Tour(
        dark: _mode == ThemeMode.dark,
        onDark: (bool dark) => setState(() => _mode = dark ? ThemeMode.dark : ThemeMode.light),
        glass: _glass,
        onGlass: (bool glass) => setState(() => _glass = glass),
      ),
    );
  }
}

class _Tour extends StatelessWidget {
  const _Tour({required this.dark, required this.onDark, required this.glass, required this.onGlass});

  final bool dark;
  final ValueChanged<bool> onDark;
  final bool glass;
  final ValueChanged<bool> onGlass;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ona sheets')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Demo(
            title: 'Long list',
            subtitle: 'Opens at half, pulls to full; the list and the sheet share one drag.',
            onTap: () => showOnaBottomSheet<void>(context: context, builder: (_) => const _TemplatesSheet()),
          ),
          _Demo(
            title: 'Confirm',
            subtitle: 'Fits its content and rests there alone.',
            onTap: () async {
              final bool? deleted = await showOnaBottomSheet<bool>(
                context: context,
                builder: (_) => const _ConfirmSheet(),
              );
              if (context.mounted && deleted == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
              }
            },
          ),
          _Demo(
            title: 'Form',
            subtitle: 'Rises above the keyboard; a drag down puts the keyboard away.',
            onTap: () => showOnaBottomSheet<void>(context: context, builder: (_) => const _RenameSheet()),
          ),
          _Demo(
            title: 'Always on',
            subtitle: 'A Maps-style sheet that lives on a screen, with the page above still usable.',
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _MapScreen())),
          ),
          _Demo(
            title: 'Custom theme',
            subtitle: 'A warm surface, rounder corners and a softer spring, from one ThemeExtension.',
            onTap: () => showOnaBottomSheet<void>(
              context: context,
              builder: (BuildContext context) => Theme(
                data: Theme.of(context).copyWith(
                  extensions: <ThemeExtension<dynamic>>[
                    OnaBottomSheetTheme.of(context).copyWith(
                      backgroundColor: const Color(0xFFFFF8EC),
                      cornerRadius: 28,
                      motion: const OnaSheetMotion(settle: SpringDescription(mass: 1, stiffness: 180, damping: 22)),
                    ),
                  ],
                ),
                child: const _TemplatesSheet(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(title: const Text('Dark mode'), value: dark, onChanged: onDark),
          SwitchListTile.adaptive(
            title: const Text('Liquid glass'),
            subtitle: const Text('Every sheet in glass instead of solid: OnaBottomSheetTheme.style'),
            value: glass,
            onChanged: onGlass,
          ),
        ],
      ),
    );
  }
}

class _Demo extends StatelessWidget {
  const _Demo({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// The grabber and a centred title, the top of every sheet here.
class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 7),
        const OnaSheetGrabber(),
        SizedBox(
          height: 48,
          child: Center(
            child: Semantics(
              header: true,
              child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplatesSheet extends StatelessWidget {
  const _TemplatesSheet();

  @override
  Widget build(BuildContext context) {
    final OnaBottomSheetTheme theme = OnaBottomSheetTheme.of(context);
    return OnaBottomSheet(
      child: OnaSheetScaffold(
        header: const _Header('Templates'),
        footerVisibility: FooterVisibility.always(ignoreBottomInset: true, scrimColor: theme.backgroundColor),
        footer: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Use template'),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: 30,
          itemBuilder: (BuildContext context, int i) => ListTile(
            title: Text('Template ${i + 1}'),
            subtitle: const Text('Decisions, owners and dates'),
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet();

  @override
  Widget build(BuildContext context) {
    return OnaBottomSheet(
      child: OnaSheetScaffold(
        header: const _Header('Delete this conversation?'),
        body: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Its notes, transcript and to-dos go too. This cannot be undone.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD13A31),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ],
          ),
        ),
      ),
    );
  }
}

class _RenameSheet extends StatelessWidget {
  const _RenameSheet();

  @override
  Widget build(BuildContext context) {
    return OnaBottomSheet(
      child: OnaSheetScaffold(
        header: const _Header('Rename'),
        body: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: 'Weekly sync', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapScreen extends StatelessWidget {
  const _MapScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Always on')),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _FakeMap()),
          OnaSheetViewport(
            child: OnaBottomSheet(
              detents: const SheetDetents(
                snaps: <SheetOffset>[
                  SheetOffset.absolute(140),
                  SheetOffset.proportionalToViewport(0.5),
                  SheetOffset(1),
                ],
                flickProjection: 0.499,
              ),
              initialOffset: const SheetOffset.absolute(140),
              child: OnaSheetScaffold(
                header: const _Header('Places'),
                body: ListView.builder(
                  itemCount: 40,
                  itemBuilder: (BuildContext context, int i) => ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text('Place ${i + 1}'),
                    subtitle: Text('${(i + 1) * 120} m away'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FakeMap extends StatelessWidget {
  const _FakeMap();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFDDE8DF), Color(0xFFC9DCEB)],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, -0.6),
        child: FilledButton.tonal(
          onPressed: () =>
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The map is still usable'))),
          child: const Text('Tap the map'),
        ),
      ),
    );
  }
}
