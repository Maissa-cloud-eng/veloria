import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClicksPage extends StatefulWidget {
  const ClicksPage({super.key});

  @override
  State<ClicksPage> createState() => _ClicksPageState();
}

class _ClicksPageState extends State<ClicksPage> {
  DateTimeRange selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 1)),
    end: DateTime.now(),
  );

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedRange,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      saveText: "Valider",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pink,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedRange) {
      setState(() {
        selectedRange = picked;
      });
    }
  }

  // --- NOUVELLE LOGIQUE DE COMPTAGE UNIQUE (ANTI-DÉPASSEMENT 100%) ---
  int _countUniqueAction(List<QueryDocumentSnapshot> docs, String eventName) {
    final Map<String, bool> uniqueActionMap = {};
    for (var d in docs) {
      final data = d.data() as Map<String, dynamic>;
      if (data['event'] == eventName) {
        final dynamic ts = data['timestamp'];
        if (ts == null || ts is! Timestamp) continue;

        DateTime date = ts.toDate();
        String visitorId = data['userId'] ?? data['deviceId'] ?? 'GUEST';
        // On crée une clé par utilisateur ET par jour pour cet événement
        String actionKey = "${visitorId}_${date.year}${date.month}${date.day}";
        uniqueActionMap[actionKey] = true;
      }
    }
    return uniqueActionMap.length;
  }

  String _calculateEngagement(int uniqueEventCount, int totalUsers) {
    if (totalUsers == 0) return "0%";
    // Le ratio ne peut plus dépasser 1 car uniqueEventCount <= totalUsers
    double pct = (uniqueEventCount / totalUsers) * 100;
    return "${pct.toStringAsFixed(1)}%";
  }

  @override
  Widget build(BuildContext context) {
    DateTime startDate = DateTime(
      selectedRange.start.year,
      selectedRange.start.month,
      selectedRange.start.day,
      0,
      0,
      0,
    );
    DateTime endDate = DateTime(
      selectedRange.end.year,
      selectedRange.end.month,
      selectedRange.end.day,
      23,
      59,
      59,
    );

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Performances Veloria",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              "Du ${DateFormat('dd/MM').format(startDate)} au ${DateFormat('dd/MM/yy').format(endDate)}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('analytics')
            .where('timestamp', isGreaterThanOrEqualTo: startDate)
            .where('timestamp', isLessThanOrEqualTo: endDate)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text("Erreur : ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            );
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text("Aucune donnée sur cette période"));

          // --- LOGIQUE UTILISATRICES GLOBALES ---
          final Map<String, bool> dailyUniqueMap = {};
          for (var d in docs) {
            final data = d.data() as Map<String, dynamic>;
            final dynamic ts = data['timestamp'];
            if (ts == null || ts is! Timestamp) continue;
            DateTime date = ts.toDate();
            String visitorId = data['userId'] ?? data['deviceId'] ?? 'GUEST';
            String dayKey = "${visitorId}_${date.year}${date.month}${date.day}";
            dailyUniqueMap[dayKey] = true;
          }

          int totalUsersCount = dailyUniqueMap.length;

          // --- CALCUL DES ACTIONS UNIQUES (1 action max / personne / jour) ---
          int chatOpens = _countUniqueAction(docs, 'chat_open');
          int forYouClicks = _countUniqueAction(docs, 'for_you_click');
          int productOpens = _countUniqueAction(docs, 'product_view');
          int addToCart = _countUniqueAction(docs, 'add_to_cart');
          int chatRegenerate = _countUniqueAction(
            docs,
            'chat_regenerate_click',
          );
          int shopScrollDeep = _countUniqueAction(docs, 'shop_scroll_deep');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeaderSummary(totalUsersCount, docs.length),
              const SizedBox(height: 24),
              _buildSectionTitle("Actions Fortes (Taux d'engagement)"),
              _buildStatCard(
                "Ajouts au Panier 🛒",
                addToCart.toString(),
                _calculateEngagement(addToCart, totalUsersCount),
                Colors.green,
              ),
              _buildStatCard(
                "Ouvertures Chatbot 🤖",
                chatOpens.toString(),
                _calculateEngagement(chatOpens, totalUsersCount),
                Colors.blue,
              ),
              _buildStatCard(
                "Autre produit (IA) 🔄",
                chatRegenerate.toString(),
                _calculateEngagement(chatRegenerate, totalUsersCount),
                Colors.purple,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Engagement Shop"),
              _buildStatCard(
                "Scroll Profond 📜",
                shopScrollDeep.toString(),
                _calculateEngagement(shopScrollDeep, totalUsersCount),
                Colors.teal,
              ),
              _buildStatCard(
                "Clics 'Pour Toi' ✨",
                forYouClicks.toString(),
                _calculateEngagement(forYouClicks, totalUsersCount),
                Colors.orange,
              ),
              _buildStatCard(
                "Fiches Produits 🧴",
                productOpens.toString(),
                _calculateEngagement(productOpens, totalUsersCount),
                Colors.pink,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Points de sortie (Répartition)"),
              _buildDropOffStats(docs),
              const SizedBox(height: 24),
              _buildSectionTitle("Temps de Session"),
              _buildTimeStats(docs, totalUsersCount),
              const SizedBox(height: 35),
            ],
          );
        },
      ),
    );
  }

  // --- DESIGN DES COMPOSANTS ---

  Widget _buildHeaderSummary(int users, int actions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryColumn("Visiteuses", users.toString(), Icons.people_outline),
          Container(width: 1, height: 40, color: Colors.pink.shade200),
          _summaryColumn(
            "Actions Totales",
            actions.toString(),
            Icons.touch_app_outlined,
          ),
        ],
      ),
    );
  }

  Widget _summaryColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.pink),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String percent,
    Color color,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          "Utilisatrices ayant cliqué : $percent",
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Text(
              "clics",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDropOffStats(List<QueryDocumentSnapshot> docs) {
    // 1. On identifie la DERNIÈRE sortie de chaque utilisatrice par jour
    // Map<DayKey, LastEventName>
    final Map<String, String> lastExitPerUserDay = {};

    for (var d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final String event = data['event'] ?? '';

      if ([
        'last_seen_home',
        'last_seen_chat',
        'last_seen_product',
      ].contains(event)) {
        final dynamic ts = data['timestamp'];
        if (ts == null || ts is! Timestamp) continue;

        DateTime date = ts.toDate();
        String visitorId = data['userId'] ?? data['deviceId'] ?? 'GUEST';
        String dayKey = "${visitorId}_${date.year}${date.month}${date.day}";

        // Comme on a fait un 'orderBy timestamp descending', le premier
        // event de sortie qu'on croise est mathématiquement le DERNIER dans le temps.
        if (!lastExitPerUserDay.containsKey(dayKey)) {
          lastExitPerUserDay[dayKey] = event;
        }
      }
    }

    final totalUniqueExits = lastExitPerUserDay.length;

    int homeExits = lastExitPerUserDay.values
        .where((e) => e == 'last_seen_home')
        .length;
    int chatExits = lastExitPerUserDay.values
        .where((e) => e == 'last_seen_chat')
        .length;
    int productExits = lastExitPerUserDay.values
        .where((e) => e == 'last_seen_product')
        .length;

    String getPct(int count) {
      if (totalUniqueExits == 0) return "0%";
      return "${((count / totalUniqueExits) * 100).toStringAsFixed(0)}%";
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildDropOffRow("Sur l'accueil", getPct(homeExits)),
          const Divider(height: 1),
          _buildDropOffRow("Après le Chat", getPct(chatExits)),
          const Divider(height: 1),
          _buildDropOffRow("Fiche Produit", getPct(productExits)),
        ],
      ),
    );
  }

  Widget _buildDropOffRow(String label, String percent) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        percent,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _buildTimeStats(List<QueryDocumentSnapshot> docs, int totalUsers) {
    Map<String, List<DateTime>> sessions = {};
    for (var doc in docs) {
      String uid =
          doc['userId']?.toString() ?? doc['deviceId']?.toString() ?? 'GUEST';
      Timestamp? ts = doc['timestamp'] as Timestamp?;
      if (ts != null) sessions.putIfAbsent(uid, () => []).add(ts.toDate());
    }
    int s = 0, m = 0, l = 0;
    sessions.forEach((uid, times) {
      if (times.length < 2)
        s++;
      else {
        times.sort();
        final diff = times.last.difference(times.first).inSeconds;
        if (diff < 30)
          s++;
        else if (diff < 120)
          m++;
        else
          l++;
      }
    });
    String pct(int val) => totalUsers == 0
        ? "0%"
        : "${((val / totalUsers) * 100).toStringAsFixed(0)}%";
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TimeLabel(label: "< 30s", value: pct(s)),
            _TimeLabel(label: "30s-2min", value: pct(m)),
            _TimeLabel(label: "+ 2min", value: pct(l)),
          ],
        ),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  final String label;
  final String value;
  const _TimeLabel({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.pink,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
