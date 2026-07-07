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

  String _visitorKey(Map<String, dynamic> data, String docId) {
    for (final key in [
      'userId',
      'deviceId',
      'visitorId',
      'sessionId',
      'clientId',
    ]) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return '$key:$value';
      }
    }
    return 'doc:$docId';
  }

  String _sessionKey(Map<String, dynamic> data, String docId) {
    final sessionId = data['sessionId']?.toString().trim();
    if (sessionId != null &&
        sessionId.isNotEmpty &&
        sessionId.toLowerCase() != 'null') {
      return 'session:$sessionId';
    }
    return _visitorKey(data, docId);
  }

  int _countSessionsWithEvent(
    List<QueryDocumentSnapshot> docs,
    String eventName,
  ) {
    final Set<String> sessions = {};
    for (var d in docs) {
      final data = d.data() as Map<String, dynamic>;
      if (data['event'] == eventName) {
        sessions.add(_sessionKey(data, d.id));
      }
    }
    return sessions.length;
  }

  String _calculateRate(int sessionCount, int totalSessions) {
    if (totalSessions == 0) return "0%";
    final pct = (sessionCount / totalSessions) * 100;
    return "${pct.clamp(0, 100).toStringAsFixed(1)}%";
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

          final Set<String> uniqueVisitors = {};
          final Set<String> sessions = {};
          for (var d in docs) {
            final data = d.data() as Map<String, dynamic>;
            uniqueVisitors.add(_visitorKey(data, d.id));
            sessions.add(_sessionKey(data, d.id));
          }

          int totalUsersCount = uniqueVisitors.length;
          int totalSessionsCount = sessions.length;

          int chatOpens = _countSessionsWithEvent(docs, 'chat_open');
          int forYouClicks = _countSessionsWithEvent(docs, 'for_you_click');
          int productOpens = _countSessionsWithEvent(docs, 'product_view');
          int addToCart = _countSessionsWithEvent(docs, 'add_to_cart');
          int reachedCheckout = _countSessionsWithEvent(
            docs,
            'reached_checkout',
          );
          int purchases = _countSessionsWithEvent(docs, 'purchase_completed');
          int chatRegenerate = _countSessionsWithEvent(
            docs,
            'chat_regenerate_click',
          );
          int shopScrollDeep = _countSessionsWithEvent(
            docs,
            'shop_scroll_deep',
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeaderSummary(
                totalUsersCount,
                totalSessionsCount,
                docs.length,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Actions Fortes (Taux d'engagement)"),
              _buildStatCard(
                "Ajouts au Panier 🛒",
                addToCart.toString(),
                _calculateRate(addToCart, totalSessionsCount),
                Colors.green,
              ),
              _buildStatCard(
                "Ouvertures Chatbot 🤖",
                chatOpens.toString(),
                _calculateRate(chatOpens, totalSessionsCount),
                Colors.blue,
              ),
              _buildStatCard(
                "Autre produit (IA) 🔄",
                chatRegenerate.toString(),
                _calculateRate(chatRegenerate, totalSessionsCount),
                Colors.purple,
              ),
              _buildStatCard(
                "Arrivées Checkout 💳",
                reachedCheckout.toString(),
                _calculateRate(reachedCheckout, totalSessionsCount),
                Colors.indigo,
              ),
              _buildStatCard(
                "Achats confirmés ✅",
                purchases.toString(),
                _calculateRate(purchases, totalSessionsCount),
                Colors.green.shade700,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Engagement Shop"),
              _buildStatCard(
                "Scroll Profond 📜",
                shopScrollDeep.toString(),
                _calculateRate(shopScrollDeep, totalSessionsCount),
                Colors.teal,
              ),
              _buildStatCard(
                "Clics 'Pour Toi' ✨",
                forYouClicks.toString(),
                _calculateRate(forYouClicks, totalSessionsCount),
                Colors.orange,
              ),
              _buildStatCard(
                "Fiches Produits 🧴",
                productOpens.toString(),
                _calculateRate(productOpens, totalSessionsCount),
                Colors.pink,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Points de sortie (Répartition)"),
              _buildDropOffStats(docs),
              const SizedBox(height: 24),
              _buildSectionTitle("Temps de Session"),
              _buildTimeStats(docs, totalSessionsCount),
              const SizedBox(height: 35),
            ],
          );
        },
      ),
    );
  }

  // --- DESIGN DES COMPOSANTS ---

  Widget _buildHeaderSummary(int users, int sessions, int actions) {
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
          Expanded(
            child: _summaryColumn(
              "Sessions",
              sessions.toString(),
              Icons.timeline_outlined,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.pink.shade200),
          Expanded(
            child: _summaryColumn(
              "Visiteuses",
              users.toString(),
              Icons.people_outline,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.pink.shade200),
          Expanded(
            child: _summaryColumn(
              "Actions",
              actions.toString(),
              Icons.touch_app_outlined,
            ),
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
          "Sessions avec action : $percent",
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
              "sessions",
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
    // 1. On identifie la DERNIÈRE sortie de chaque session sur la période
    final Map<String, String> lastExitPerSession = {};

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

        final sessionKey = _sessionKey(data, d.id);

        // Comme on a fait un 'orderBy timestamp descending', le premier
        // event de sortie qu'on croise est mathématiquement le DERNIER dans le temps.
        if (!lastExitPerSession.containsKey(sessionKey)) {
          lastExitPerSession[sessionKey] = event;
        }
      }
    }

    final totalUniqueExits = lastExitPerSession.length;

    int homeExits = lastExitPerSession.values
        .where((e) => e == 'last_seen_home')
        .length;
    int chatExits = lastExitPerSession.values
        .where((e) => e == 'last_seen_chat')
        .length;
    int productExits = lastExitPerSession.values
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
      final data = doc.data() as Map<String, dynamic>;
      final uid = _sessionKey(data, doc.id);
      final ts = data['timestamp'];
      if (ts is Timestamp) sessions.putIfAbsent(uid, () => []).add(ts.toDate());
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
