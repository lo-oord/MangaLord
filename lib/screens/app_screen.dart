import 'package:flutter/material.dart';

const accentGreen = Color(0xFF3DDC97);
const deepGreen = Color(0xFF113C32);
const mutedText = Color(0xFF8FA39C);

class Manga {
  const Manga({required this.title, required this.author, required this.genre, required this.cover, required this.description, required this.chapters, this.status = 'Ongoing'});
  final String title, author, genre, cover, description, status;
  final int chapters;
}

const mockManga = <Manga>[
  Manga(title: 'The Beginning After the End', author: 'TurtleMe', genre: 'Fantasy', cover: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=700&q=80', description: 'King Grey has unrivaled strength, wealth and prestige in a world governed by martial ability.', chapters: 188),
  Manga(title: 'Omniscient Reader', author: 'Sing Shong', genre: 'Action', cover: 'https://images.unsplash.com/photo-1612036782180-6f0b6cd846fe?auto=format&fit=crop&w=700&q=80', description: 'An ordinary reader discovers that the novel he has followed for years is becoming reality.', chapters: 214),
  Manga(title: 'Solo Leveling', author: 'Chugong', genre: 'Adventure', cover: 'https://images.unsplash.com/photo-1607604276583-eef5b076f64f?auto=format&fit=crop&w=700&q=80', description: 'The weakest hunter finds a mysterious system that changes his fate.', chapters: 179, status: 'Completed'),
  Manga(title: 'Eleceed', author: 'Jeho Son', genre: 'Comedy', cover: 'https://images.unsplash.com/photo-1546525848-3ce03ca516f6?auto=format&fit=crop&w=700&q=80', description: 'A kind-hearted speedster and a powerful mentor in a cat find an unexpected friendship.', chapters: 321),
  Manga(title: 'Tower of God', author: 'SIU', genre: 'Mystery', cover: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=700&q=80', description: 'A boy enters a mysterious tower to find the only person who matters to him.', chapters: 625),
  Manga(title: 'Wind Breaker', author: 'Yongseok Jo', genre: 'Sports', cover: 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=700&q=80', description: 'A student discovers freedom, friendship and competition through street cycling.', chapters: 506),
];

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});
  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  int index = 0;
  String query = '';
  final favorites = <String>{'Solo Leveling'};
  final history = <Manga>[mockManga[2], mockManga[0]];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          HomePage(query: query, onQuery: (value) => setState(() => query = value), onOpen: openManga),
          HistoryPage(items: history, onOpen: openManga),
          SettingsPage(favorites: favorites, onOpen: openManga),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FloatingNavigation(index: index, onChanged: (value) => setState(() => index = value)),
        ),
      ),
    );
  }

  void openManga(Manga manga) {
    if (!history.any((item) => item.title == manga.title)) {
      history.insert(0, manga);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(manga: manga)));
  }
}

class FloatingNavigation extends StatelessWidget {
  const FloatingNavigation({required this.index, required this.onChanged, super.key});
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 22, offset: const Offset(0, 8))]),
      child: Row(children: [
        NavItem(icon: Icons.home_rounded, label: 'Home', active: index == 0, onTap: () => onChanged(0)),
        NavItem(icon: Icons.history_rounded, label: 'History', active: index == 1, onTap: () => onChanged(1)),
        NavItem(icon: Icons.settings_rounded, label: 'Settings', active: index == 2, onTap: () => onChanged(2)),
      ]),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({required this.icon, required this.label, required this.active, required this.onTap, super.key});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: AnimatedContainer(duration: const Duration(milliseconds: 220), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: active ? accentGreen.withOpacity(.16) : Colors.transparent, borderRadius: BorderRadius.circular(18)), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: active ? accentGreen : mutedText, size: 21), const SizedBox(height: 3), Text(label, style: TextStyle(color: active ? accentGreen : mutedText, fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500))]))));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.query, required this.onQuery, required this.onOpen, super.key});
  final String query;
  final ValueChanged<String> onQuery;
  final ValueChanged<Manga> onOpen;
  @override
  Widget build(BuildContext context) {
    final items = mockManga.where((manga) => manga.title.toLowerCase().contains(query.toLowerCase())).toList();
    final slivers = <Widget>[
      SliverAppBar(
        pinned: true,
        expandedHeight: 112,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: const FlexibleSpaceBar(
          titlePadding: EdgeInsetsDirectional.only(start: 20, bottom: 16),
          title: Text('Discover', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        sliver: SliverToBoxAdapter(
          child: TextField(
            onChanged: onQuery,
            decoration: InputDecoration(
              hintText: 'Search manga...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
        sliver: SliverToBoxAdapter(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Latest manga', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text('${items.length} titles', style: const TextStyle(color: mutedText, fontSize: 12)),
          ]),
        ),
      ),
    ];
    if (items.isEmpty) {
      slivers.add(const SliverFillRemaining(hasScrollBody: false, child: StateCard(icon: Icons.search_off_rounded, title: 'No manga found', message: 'Try another title or search again.')));
    } else {
      slivers.add(SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28), sliver: SliverGrid(delegate: SliverChildBuilderDelegate((context, i) => MangaCard(manga: items[i], onTap: () => onOpen(items[i])), childCount: items.length), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 190, mainAxisSpacing: 22, crossAxisSpacing: 16, childAspectRatio: .57))));
    }
    return CustomScrollView(slivers: slivers);
  }
}

class MangaCard extends StatelessWidget {
  const MangaCard({required this.manga, required this.onTap, super.key});
  final Manga manga;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final image = Image.network(manga.cover, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Container(color: deepGreen, child: const Icon(Icons.menu_book_rounded, color: accentGreen, size: 42)));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Hero(tag: manga.title, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: image))),
        const SizedBox(height: 9),
        Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 3),
        Text(manga.genre, style: const TextStyle(color: mutedText, fontSize: 12)),
      ]),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({required this.items, required this.onOpen, super.key});
  final List<Manga> items;
  final ValueChanged<Manga> onOpen;
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [SliverAppBar(pinned: true, backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent, title: const Text('Reading history', style: TextStyle(fontWeight: FontWeight.w800))), if (items.isEmpty) const SliverFillRemaining(hasScrollBody: false, child: StateCard(icon: Icons.history_rounded, title: 'Your history is empty', message: 'Open a manga and your reading journey will appear here.')) else SliverPadding(padding: const EdgeInsets.all(20), sliver: SliverList(delegate: SliverChildBuilderDelegate((context, i) => Padding(padding: const EdgeInsets.only(bottom: 14), child: HistoryTile(manga: items[i], onTap: () => onOpen(items[i]))), childCount: items.length))) ]);
  }
}

class HistoryTile extends StatelessWidget {
  const HistoryTile({required this.manga, required this.onTap, super.key});
  final Manga manga;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18)), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(manga.cover, width: 64, height: 82, fit: BoxFit.cover)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text('Chapter ${manga.chapters - 1}', style: const TextStyle(color: accentGreen, fontWeight: FontWeight.w600)), const SizedBox(height: 4), const Text('Opened recently', style: TextStyle(color: mutedText, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: mutedText)])));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.favorites, required this.onOpen, super.key});
  final Set<String> favorites;
  final ValueChanged<Manga> onOpen;
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [SliverAppBar(pinned: true, backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent, title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800))), SliverPadding(padding: const EdgeInsets.all(20), sliver: SliverList(delegate: SliverChildListDelegate([
      const Text('Your library', style: TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      SettingTile(title: 'Account', subtitle: 'Manage your profile', icon: Icons.person_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimplePage(title: 'Account', icon: Icons.person_rounded, message: 'Sign in to sync your library across devices.')))),
      SettingTile(title: 'Favorites', subtitle: '${favorites.length} saved manga', icon: Icons.favorite_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesPage(favorites: favorites, onOpen: onOpen)))),
      SettingTile(title: 'Downloads', subtitle: 'Offline reading queue', icon: Icons.download_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimplePage(title: 'Downloads', icon: Icons.download_rounded, message: 'Your downloaded chapters will be available offline here.', action: 'No downloads yet')))),
      SettingTile(title: 'Manga sources', subtitle: 'Manage future sources', icon: Icons.language_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimplePage(title: 'Manga sources', icon: Icons.language_rounded, message: 'Source connections are prepared for a future release.', action: 'Coming soon')))),
      SettingTile(title: 'More', subtitle: 'Appearance and preferences', icon: Icons.tune_rounded, onTap: () {}),
    ]))) ]);
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({required this.title, required this.subtitle, required this.icon, required this.onTap, super.key});
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(icon, color: accentGreen),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: mutedText, fontSize: 12))])),
              const Icon(Icons.chevron_right_rounded, color: mutedText),
            ]),
          ),
        ),
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  const DetailsPage({required this.manga, super.key});
  final Manga manga;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Manga details')), body: ListView(padding: const EdgeInsets.all(20), children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Hero(tag: manga.title, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(manga.cover, width: 130, height: 190, fit: BoxFit.cover))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(manga.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text('by ${manga.author}', style: const TextStyle(color: mutedText)), const SizedBox(height: 12), Text('${manga.chapters} chapters', style: const TextStyle(color: accentGreen, fontWeight: FontWeight.w700))]))]), const SizedBox(height: 28), const Text('Synopsis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(manga.description, style: const TextStyle(color: mutedText, height: 1.6)), const SizedBox(height: 24), FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(manga: manga))), icon: const Icon(Icons.menu_book_rounded), label: const Text('Start reading')), const SizedBox(height: 28), const Text('Chapters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 12), ...List.generate(8, (i) => ChapterTile(number: manga.chapters - i, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(manga: manga))))) ]));
}

class ChapterTile extends StatelessWidget {
  const ChapterTile({required this.number, required this.onTap, super.key});
  final int number;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(children: [
              const Icon(Icons.menu_book_outlined, color: accentGreen),
              const SizedBox(width: 12),
              Expanded(child: Text('Chapter $number', style: const TextStyle(fontWeight: FontWeight.w700))),
              const Icon(Icons.chevron_right_rounded, color: mutedText),
            ]),
          ),
        ),
      ),
    );
  }
}

class ReaderPage extends StatelessWidget {
  const ReaderPage({required this.manga, super.key});
  final Manga manga;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text('${manga.title} • Reader')),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: 5,
        itemBuilder: (_, i) => Center(child: Text('Page ${i + 1} of 5', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({required this.favorites, required this.onOpen, super.key});
  final Set<String> favorites;
  final ValueChanged<Manga> onOpen;
  @override
  Widget build(BuildContext context) {
    final items = mockManga.where((manga) => favorites.contains(manga.title)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 190, mainAxisSpacing: 22, crossAxisSpacing: 16, childAspectRatio: .57),
        itemBuilder: (_, i) => MangaCard(manga: items[i], onTap: () => onOpen(items[i])),
      ),
    );
  }
}

class SimplePage extends StatelessWidget {
  const SimplePage({required this.title, required this.icon, required this.message, this.action, super.key});
  final String title, message;
  final IconData icon;
  final String? action;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: StateCard(icon: icon, title: action ?? title, message: message));
}

class StateCard extends StatelessWidget {
  const StateCard({required this.icon, required this.title, required this.message, super.key});
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: accentGreen, size: 48), const SizedBox(height: 18), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: mutedText, height: 1.5))])));
}
