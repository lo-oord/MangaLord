import 'package:flutter/material.dart';
import '../configs/developer_links.dart';
import '../configs/login.dart';
import '../configs/versions.dart';
import '../cross.dart';
import 'components/badged.dart';

const _releaseUrl = "https://github.com/lo-oord/MangaLord/releases/";
const _developerAccent = Color(0xFF3DDC97);
const _developerMuted = Color(0xFF8FA39C);

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AboutState();
  }
}

class _AboutState extends State<AboutScreen> {
  @override
  void initState() {
    loginEvent.subscribe(_l);
    super.initState();
  }

  @override
  void dispose() {
    loginEvent.unsubscribe(_l);
    super.dispose();
  }

  _l(_) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
      ),
      body: ListView(
        children: [
          const Divider(),
          _buildLogo(),
          const Divider(),
          _buildDeveloperSection(),
          const Divider(),
          _buildCurrentVersion(),
          const Divider(),
          _buildNewestVersion(),
          const Divider(),
          _buildGotoGithub(),
          const Divider(),
          _buildVersionText(),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double? width, height;
        if (constraints.maxWidth < constraints.maxHeight) {
          width = constraints.maxWidth / 2;
        } else {
          height = constraints.maxHeight / 2;
        }
        return Container(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: SizedBox(
              width: width,
              height: height,
              child: Image.asset('lib/assets/icon.png'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeveloperSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.code_rounded, color: _developerAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Developer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDeveloperCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCard() {
    final cardColor = Theme.of(context).colorScheme.surface.withOpacity(0.78);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _developerAccent.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: _developerAccent.withOpacity(0.08),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _developerAccent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _developerAccent.withOpacity(0.28),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 31,
                  backgroundImage: AssetImage('lib/assets/icon.png'),
                  backgroundColor: Colors.transparent,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Lord',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: _developerAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "Hello, I'm Lord, a new app designer. I hope you enjoy Manga Lord.",
            style: TextStyle(
              color: _developerMuted,
              height: 1.5,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Connect with me',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth > 430
                  ? (constraints.maxWidth - 24) / 4
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: developerLinks.keys
                    .map((name) => SizedBox(
                          width: itemWidth,
                          child: _buildSocialLink(name),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 15),
          const Center(
            child: Text(
              'Designed with passion for Manga Lord',
              style: TextStyle(
                color: _developerMuted,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLink(String name) {
    return Builder(
      builder: (context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: _developerAccent.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _developerAccent.withOpacity(0.15)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openDeveloperLink(context, name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_socialIcon(name), color: _developerAccent, size: 17),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDeveloperLink(BuildContext context, String name) {
    final url = developerLinks[name] ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add the $name link in developer_links.dart')),
      );
      return;
    }
    openUrl(url);
  }

  IconData _socialIcon(String name) {
    switch (name) {
      case 'GitHub':
        return Icons.code_rounded;
      case 'X':
        return Icons.alternate_email_rounded;
      case 'Facebook':
        return Icons.facebook;
      case 'Instagram':
        return Icons.camera_alt_outlined;
      case 'Threads':
        return Icons.forum_outlined;
      case 'TikTok':
        return Icons.music_note_rounded;
      case 'Pinterest':
        return Icons.push_pin_outlined;
      default:
        return Icons.link_rounded;
    }
  }

  Widget _buildCurrentVersion() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text("Current version: ${currentVersion()}"),
    );
  }

  Widget _buildNewestVersion() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text.rich(TextSpan(
        children: [
          const TextSpan(text: "Latest version: "),
          _buildNewestVersionSpan(),
          _buildCheckButton(),
        ],
      )),
    );
  }

  InlineSpan _buildNewestVersionSpan() {
    return WidgetSpan(
      child: Container(
        padding: const EdgeInsets.only(right: 20),
        child: VersionBadged(
          child: Text(
            "${latestVersion ?? "No new version found"}    ",
          ),
        ),
      ),
    );
  }

  InlineSpan _buildCheckButton() {
    return WidgetSpan(
      child: GestureDetector(
        child: const Text(
          "Check for updates",
          style: TextStyle(height: 1.3, color: Colors.blue),
          strutStyle: StrutStyle(height: 1.3),
        ),
        onTap: () {
          manualCheckNewVersion(context);
        },
      ),
    );
  }

  Widget _buildGotoGithub() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GestureDetector(
        child: const Text(
          "Open download page",
          style: TextStyle(color: Colors.blue),
        ),
        onTap: () {
          openUrl(_releaseUrl);
        },
      ),
    );
  }

  Widget _buildVersionText() {
    var info = latestVersionInfo();
    if (info != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: SelectableText("What is new\n\n$info"),
      );
    }
    return Container();
  }
}
