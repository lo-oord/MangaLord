import 'package:flutter/material.dart';

const accentGreen = Color(0xFF3DDC97);
const deepGreen = Color(0xFF113C32);
const mutedText = Color(0xFF8FA39C);

class Manga {
  const Manga({required this.title, required this.author, required this.genre, required this.cover, required this.description, required this.chapters, this.status = 'Ongoing'});
  final String title;
  final String author;
  final String genre;
  final String cover;
  final String description;
  final int chapters;
  final String status;
}

const mockManga = <Manga>[
  Manga(title: 'The Beginning After the End', author: 'TurtleMe', genre: 'Fantasy', cover: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=700&q=80', description: 'King Grey has unrivaled strength, wealth and prestige in a world governed by martial ability. Yet solitude lingers closely behind those with great power.', chapters: 188),
  Manga(title: 'Omniscient Reader', author: 'Sing Shong', genre: 'Action', cover: 'https://images.unsplash.com/photo-1612036782180-6f0b6cd846fe?auto=format&fit=crop&w=700&q=80', description: 'An ordinary reader discovers that the novel he has followed for years is suddenly becoming reality.', chapters: 214),
  Manga(title: 'Solo Leveling', author: 'Chugong', genre: 'Adventure', cover: 'https://images.unsplash.com/photo-1607604276583-eef5b076f64f?auto=format&fit=crop&w=700&q=80', description: 'In a world where hunters battle monsters, the weakest hunter finds a mysterious system that changes his fate.', chapters: 179, status: 'Completed'),
  Manga(title: 'Eleceed', author: 'Jeho Son', genre: 'Comedy', cover: 'https://images.unsplash.com/photo-1546525848-3ce03ca516f6?auto=format&fit=crop&w=700&q=80', description: 'A kind-hearted speedster and a powerful mentor in a cat find an unexpected friendship.', chapters: 321),
  Manga(title: 'Tower of God', author: 'SIU', genre: 'Mystery', cover: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=700&q=80', description: 'A boy enters a mysterious tower to find the only person who matters to him.', chapters: 625),
  Manga(title: 'Wind Breaker', author: 'Yongseok Jo', genre: 'Sports', cover: 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=700&q=80', description: 'A student discovers freedom, friendship and competition through the world of street cycling.', chapters: 506),
];

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});
  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  int selectedIndex = 0;
  String searchQuery = '';
  final favorites = <String>{'Solo Leveling'};
  final history = <Manga>[mockManga[2], mockManga[0]];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(query: searchQuery, onQueryChanged: (value) => setState(() => searchQuery = value), onOpen: openManga),
      HistoryPage(items: history, onOpen: openManga),
      SettingsPage(favorites: favorites, onOpen: openManga, onThemeTap: () => showThemePicker(context)),
    ];
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FloatingNavigation(index: selectedIndex, onChanged: (value) => setState(() => selectedIndex = value)),
        ),
      ),
    );
  }

  void openManga(Manga manga) {
    if (!history.any((item) => item.title == manga.title)) {
      setState(() => history.insert(0, manga));
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(manga: manga, isFavorite: favorites.contains(manga.title), onFavorite: () => setState(() {
        if (favorites.contains(manga.title)) {
          favorites.remove(manga.title);
        } else {
          favorites.add(manga.title);
        }
      }), onRead: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(manga: manga))))));
  }

  Future<void> showThemePicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.brightness_auto_rounded), title: const Text('Follow system'), onTap: () => Navigator.pop(sheetContext)),
          ListTile(leading: const Icon(Icons.light_mode_rounded), title: const Text('Light mode'), onTap: () => Navigator.pop(sheetContext)),
          ListTile(leading: const Icon(Icons.dark_mode_rounded), title: const Text('Dark mode'), onTap: () => Navigator.pop(sheetContext)),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}

class FloatingNavigation extends StatelessWidget {
  const FloatingNavigation({required this.index, required this.onChanged, super.key});
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), blurRadius: 22, offset: const Offset(0, 8))]),
        child: Row(children: [NavItem(icon: Icons.home_rounded, label: 'Home', active: index == 0, onTap: () => onChanged(0)), NavItem(icon: Icons.history_rounded, label: 'History', active: index == 1, onTap: () => onChanged(1)), NavItem(icon: Icons.settings_rounded, label: 'Settings', active: index == 2, onTap: () => onChanged(2))]),
      );
}

class NavItem extends StatelessWidget {
  const NavItem({required this.icon, required this.label, required this.active, required this.onTap, super.key});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 220), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: active ? accentGreen.withOpacity(.16) : Colors.transparent, borderRadius: BorderRadius.circular(18)), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: active ? accentGreen : mutedText, size: 21), const SizedBox(height: 3), Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? accentGreen : mutedText))]))));
}

class HomePage extends StatelessWidget {
  const HomePage({required this.query, required this.onQueryChanged, required this.onOpen, super.key});
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Manga> onOpen;
  @override
  Widget build(BuildContext context) {
    final items = mockManga.where((manga) => manga.title.toLowerCase().contains(query.toLowerCase())).toList();
    return CustomScrollView(slivers: [
      SliverAppBar(pinned: true, expandedHeight: 112, backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent, flexibleSpace: FlexibleSpaceBar(titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16), title: const Text('Discover', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)), background: const Align(alignment: Alignment.topRight, child: Padding(padding: EdgeInsets.only(top: 52, right: 20), child: CircleAvatar(backgroundColor: deepGreen, child: Icon(Icons.auto_awesome_rounded, color: accentGreen, size: 20))))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), sliver: SliverToBoxAdapter(child: TextField(onChanged: onQueryChanged, decoration: InputDecoration(hintText: 'Search manga...', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: query.isEmpty ? null : IconButton(onPressed: () => onQueryChanged(''), icon: const Icon(Icons.close_rounded)), filled: true, fillColor: Theme.of(context).colorScheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: accentGreen, width: 1.5))))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 28, 20, 14), sliver: SliverToBoxAdapter(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Latest manga', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('${items.length} titles', style: const TextStyle(color: mutedText, fontSize: 12))]))),
      if (items.isEmpty) const SliverFillRemaining(hasScrollBody: false, child: StateCard(icon: Icons.search_off_rounded, title: 'No manga found', message: 'Try another title or search again.')) else SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28), sliver: SliverGrid(delegate: SliverChildBuilderDelegate((context, index) => MangaCard(manga: items[index], onTap: () => onOpen(items[index])), childCount: items.length), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 190, mainAxisSpacing: 22, crossAxisSpacing: 16, childAspectRatio: .57))),
    ]);
  }
}

class MangaCard extends StatelessWidget {
  const MangaCard({required this.manga, required this.onTap, super.key});
  final Manga manga;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Hero(tag: manga.title, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(manga.cover, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => Container(color: deepGreen, child: const Icon(Icons.menu_book_rounded, color: accentGreen, size: 42))))), const SizedBox(height: 9), Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)), const SizedBox(height: 3), Text(manga.genre, style: const TextStyle(color: mutedText, fontSize: 12))]));
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({required this.items, required this.onOpen, super.key});
  final List<Manga> items;
  final ValueChanged<Manga> onOpen;
  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [SliverAppBar(pinned: true, backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent, title: const Text('Reading history', style: TextStyle(fontWeight: FontWeight.w800))), if (items.isEmpty) const SliverFillRemaining(hasScrollBody: false, child: StateCard(icon: Icons.history_rounded, title: 'Your history is empty', message: 'Open a manga and your reading journey will appear here.')) else SliverPadding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 30), sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) => Padding(padding: const EdgeInsets.only(bottom: 14), child: HistoryTile(manga: items[index], onTap: () => onOpen(items[index]))), childCount: items.length))) ]);
}

class HistoryTile extends StatelessWidget {
  const HistoryTile({required this.manga, required this.onTap, super.key});
  final Manga manga;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18)), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(manga.cover, width: 64, height: 82, fit: BoxFit.cover)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 7), Text('Chapter ${manga.chapters - 1}', style: const TextStyle(color: accentGreen, fontWeight: FontWeight.w600)), const SizedBox(height: 4), const Text('Opened recently', style: TextStyle(color: mutedText, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: mutedText)])));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.favorites, required this.onOpen, required this.onThemeTap, super.key});
  final Set<String> favorites;
  final ValueChanged<Manga> onOpen;
  final VoidCallback onThemeTap;
  @override
  Widget build(BuildContext context) {
    final options = <({String title, String subtitle, IconData icon, VoidCallback action})>[
      (title: 'Account', subtitle: 'Manage your profile', icon: Icons.person_rounded, action: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimplePage(title: 'Account', icon: Icons.person_rounded, message: 'Sign in to sync your library across devices.')))),
      (title: 'Favorites', subtitle: '${favorites.length} saved manga', icon: Icons.favorite_rounded, action: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesPage(favorites: favorites, onOpen: onOpen)))),
      (title: 'Downloads', subtitle: 'Offline reading queue', icon: Icons.download_rounded, action: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimplePage(title: 'Downloads', icon: Icons.download_rounded, message: 'Your downloaded chapters will be available offline here.', action: 'No downloads yet')))),
      (title: 'Manga sources', subtitle: 'Manage future sources', icon: Icons.language_rounded, action: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimplePage(title: 'Manga sources', icon: Icons.language_rounded, message: 'Source connections are prepared for a future release.', action: 'Coming soon')))),
      (title: 'More', subtitle: 'Appearance and preferences', icon: Icons.tune_rounded, action: onThemeTap),
    ];
    return CustomScrollView(slivers: [SliverAppBar(pinned: true, backgroundColor: Theme.of(context).scaffoldBackgroundColor, surfaceTintColor: Colors.transparent, title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800))), SliverPadding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 32), sliver: SliverList(delegate: SliverChildListDelegate([Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [deepGreen, Color(0xFF1E5949)]), borderRadius: BorderRadius.circular(22)), child: const Row(children: [CircleAvatar(radius: 25, backgroundColor: Color(0x333DDC97), child: Icon(Icons.person_outline_rounded, color: accentGreen, size: 28)), SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Welcome to MangaLord', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Your personal reading space', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12))])])), const SizedBox(height: 24), ...options.map((option) => Padding(padding: const EdgeInsets.only(bottom: 12), child: SettingTile(title: option.title, subtitle: option.subtitle, icon: option.icon, onTap: option.action))), const Center(child: Text('MangaLord 0.0.22  •  Built for readers', style: TextStyle(color: mutedText, fontSize: 11))) ]))) ]);
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({required this.title, required this.subtitle, required this.icon, required this.onTap, super.key});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: accentGreen.withOpacity(.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: accentGreen, size: 21)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: mutedText, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: mutedText)])));
}

class DetailsPage extends StatelessWidget {
  const DetailsPage({required this.manga, required this.isFavorite, required this.onFavorite, required this.onRead, super.key});
  final Manga manga;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onRead;
  @override
  Widget build(BuildContext context) => Scaffold(body: CustomScrollView(slivers: [SliverAppBar(expandedHeight: 340, pinned: true, backgroundColor: deepGreen, leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)), actions: [IconButton(onPressed: onFavorite, icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFavorite ? accentGreen : Colors.white))], flexibleSpace: FlexibleSpaceBar(background: Stack(fit: StackFit.expand, children: [Hero(tag: manga.title, child: Image.network(manga.cover, fit: BoxFit.cover)), DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(.1), Colors.black.withOpacity(.9)]))), Positioned(left: 20, right: 20, bottom: 24, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(manga.genre.toUpperCase(), style: const TextStyle(color: accentGreen, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(manga.title, style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text('by ${manga.author}', style: const TextStyle(color: Color(0xCCFFFFFF))) ]))]))), SliverPadding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 32), sliver: SliverList(delegate: SliverChildListDelegate([Row(children: [InfoPill(label: 'Chapters', value: '${manga.chapters}'), InfoPill(label: 'Status', value: manga.status), InfoPill(label: 'Type', value: 'Manhwa')]), const SizedBox(height: 26), const Text('Synopsis', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 9), Text(manga.description, style: const TextStyle(color: mutedText, height: 1.6)), const SizedBox(height: 26), SizedBox(height: 52, child: FilledButton.icon(onPressed: onRead, icon: const Icon(Icons.menu_book_rounded), label: const Text('Start reading', style: TextStyle(fontWeight: FontWeight.w800)))), const SizedBox(height: 30), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Chapters', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), Text('${manga.chapters} total', style: const TextStyle(color: mutedText, fontSize: 12))]), const SizedBox(height: 12), ...List.generate(8, (index) => ChapterTile(number: manga.chapters - index, onTap: onRead))]))) ]));
}

class InfoPill extends StatelessWidget {
  const InfoPill({required this.label, required this.value, super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14)), child: Column(children: [Text(label, style: const TextStyle(color: mutedText, fontSize: 11)), const SizedBox(height: 5), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))])));
}

class ChapterTile extends StatelessWidget {
  const ChapterTile({required this.number, required this.onTap, super.key});
  final int number;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15), child: Row(children: [Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: accentGreen.withOpacity(.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.menu_book_outlined, size: 17, color: accentGreen)), const SizedBox(width: 12), Expanded(child: Text('Chapter $number', style: const TextStyle(fontWeight: FontWeight.w700))), const Text('›', style: TextStyle(color: mutedText, fontSize: 24))]))));
}

class ReaderPage extends StatelessWidget {
  const ReaderPage({required this.manga, super.key});
  final Manga manga;
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text('${manga.title} • Chapter ${manga.chapters}')), body: PageView.builder(scrollDirection: Axis.vertical, itemCount: 5, itemBuilder: (_, index) => Column(children: [Expanded(child: Image.network('https://images.unsplash.com/photo-${index.isEven ? '1543002588-bfa74002ed7e' : '1516979187457-637abb4f9353'}?auto=format&fit=crop&w=1200&q=85', fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.white, size: 48)))), Padding(padding: const EdgeInsets.all(12), child: Text('Page ${index + 1} of 5', style: const TextStyle(color: Colors.white54))) ])));
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({required this.favorites, required this.onOpen, super.key});
  final Set<String> favorites;
  final ValueChanged<Manga> onOpen;
  @override
  Widget build(BuildContext context) { final items = mockManga.where((manga) => favorites.contains(manga.title)).toList(); return Scaffold(appBar: AppBar(title: const Text('Favorites', style: TextStyle(fontWeight: FontWeight.w800))), body: items.isEmpty ? const StateCard(icon: Icons.favorite_border_rounded, title: 'No favorites yet', message: 'Save a manga from its details page to see it here.') : GridView.builder(padding: const EdgeInsets.all(20), itemCount: items.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 190, mainAxisSpacing: 22, crossAxisSpacing: 16, childAspectRatio: .57), itemBuilder: (_, index) => MangaCard(manga: items[index], onTap: () => onOpen(items[index])))); }
}

class SimplePage extends StatelessWidget {
  const SimplePage({required this.title, required this.icon, required this.message, this.action, super.key});
  final String title;
  final IconData icon;
  final String message;
  final String? action;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))), body: StateCard(icon: icon, title: action ?? title, message: message));
}

class StateCard extends StatelessWidget {
  const StateCard({required this.icon, required this.title, required this.message, super.key});
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: accentGreen.withOpacity(.12), shape: BoxShape.circle), child: Icon(icon, color: accentGreen, size: 38)), const SizedBox(height: 18), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: mutedText, height: 1.5))])));
}
