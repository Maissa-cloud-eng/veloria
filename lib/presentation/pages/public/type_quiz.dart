import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veloria/presentation/states/language_provider.dart';

class SkinQuizPage extends StatefulWidget {
  const SkinQuizPage({super.key});

  @override
  State<SkinQuizPage> createState() => _SkinQuizPageState();
}

class _SkinQuizPageState extends State<SkinQuizPage> {
  int _currentQuestionIndex = 0;

  final Map<String, int> _scores = {
    'Sèche': 0,
    'Mixte': 0,
    'Grasse': 0,
    'Normale': 0,
  };

  final Map<String, Map<String, String>> _localizedText = {
    'title': {'FR': 'Mon Diagnostic Peau', 'EN': 'My Skin Diagnosis'},
    'question_count': {'FR': 'Question', 'EN': 'Question'},
    'of': {'FR': 'sur', 'EN': 'of'},
    'result_intro': {
      'FR': 'Votre type de peau dominant est :',
      'EN': 'Your dominant skin type is:',
    },
    'save_btn': {
      'FR': 'Enregistrer dans mon profil',
      'EN': 'Save to my profile',
    },
    'Sèche': {'FR': 'Peau Sèche', 'EN': 'Dry Skin'},
    'Mixte': {'FR': 'Peau Mixte', 'EN': 'Combination Skin'},
    'Grasse': {'FR': 'Peau Grasse', 'EN': 'Oily Skin'},
    'Normale': {'FR': 'Peau Normale', 'EN': 'Normal Skin'},
  };

  // Questions reformulées pour être sensorielles et moins prévisibles
  final List<Map<String, dynamic>> _questions = [
    {
      'question': {
        'FR':
            '1️⃣ Comment décririez-vous votre peau environ 15 minutes après le lavage ?',
        'EN':
            '1️⃣ How would you describe your skin about 15 minutes after washing?',
      },
      'answers': [
        {
          'text': {
            'FR': 'Inconfortable, elle me tiraille et manque de souplesse',
            'EN': 'Uncomfortable, tight, and lacks suppleness',
          },
          'icon': Icons.waves, // Évoque la déshydratation / tiraillement
          'type': 'Sèche',
        },
        {
          'text': {
            'FR': 'Fraîche sur les joues, mais déjà un peu luisante sur le nez',
            'EN': 'Fresh on cheeks, but already a bit shiny on the nose',
          },
          'icon': Icons.gradient,
          'type': 'Mixte',
        },
        {
          'text': {
            'FR':
                'Complètement soulagée, mais elle commence déjà à briller partout',
            'EN':
                'Completely relieved, but already starting to look shiny all over',
          },
          'icon': Icons.opacity, // Évoque l'excès de sébum
          'type': 'Grasse',
        },
        {
          'text': {
            'FR': 'Parfaitement équilibrée, ni trop sèche ni trop luisante',
            'EN': 'Perfectly balanced, neither too dry nor too shiny',
          },
          'icon': Icons.check_circle_outline,
          'type': 'Normale',
        },
      ],
    },
    {
      'question': {
        'FR':
            '2️⃣ Vers 16h en fin de journée, quel est votre réflexe ou constat principal ?',
        'EN': '2️⃣ Around 4 PM, what is your main observation or reflex?',
      },
      'answers': [
        {
          'text': {
            'FR':
                'Ma peau picote, rougit ou réagit aux variations de température',
            'EN': 'My skin tingles, flushes, or reacts to temperature changes',
          },
          'icon': Icons.error_outline,
          'type': 'sèche',
        },
        {
          'text': {
            'FR': 'Je dois poudrer ou éponger uniquement mon front et mon nez',
            'EN': 'I need to powder or blot only my forehead and nose',
          },
          'icon': Icons.face,
          'type': 'Mixte',
        },
        {
          'text': {
            'FR': 'Le maquillage ne tient pas, toute ma zone faciale brille',
            'EN': 'Makeup doesn\'t stay put, my entire face is shiny',
          },
          'icon': Icons.blur_on,
          'type': 'Grasse',
        },
        {
          'text': {
            'FR': 'Rien à signaler, mon teint reste net et confortable',
            'EN':
                'Nothing to report, my complexion remains clear and comfortable',
          },
          'icon': Icons.sentiment_satisfied_alt,
          'type': 'Normale',
        },
      ],
    },
    {
      'question': {
        'FR':
            '3️⃣ Si vous observez votre grain de peau de près dans un miroir :',
        'EN': '3️⃣ If you look closely at your skin texture in a mirror:',
      },
      'answers': [
        {
          'text': {
            'FR':
                'Les pores sont invisibles, mais j\'ai de petites ridules ou squames',
            'EN': 'Pores are invisible, but I have fine lines or dry patches',
          },
          'icon': Icons.texture,
          'type': 'Sèche',
        },
        {
          'text': {
            'FR': 'Les pores sont dilatés uniquement sur le nez et le menton',
            'EN': 'Pores are enlarged only on the nose and chin',
          },
          'icon': Icons.grain,
          'type': 'Mixte',
        },
        {
          'text': {
            'FR':
                'Le relief est irrégulier avec des pores visibles sur tout le visage',
            'EN': 'Texture is uneven with visible pores across the whole face',
          },
          'icon': Icons.apps,
          'type': 'Grasse',
        },
      ],
    },
  ];

  void _answerQuestion(String type) {
    setState(() {
      _scores[type] = (_scores[type] ?? 0) + 1;
      _currentQuestionIndex++;
    });
  }

  String _getResult() {
    var sortedEntries = _scores.entries.toList()
      ..sort((e1, e2) => e2.value.compareTo(e1.value));
    return sortedEntries.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final String lang =
        Provider.of<LanguageProvider>(context).selectedLanguage == "Anglais"
        ? "EN"
        : "FR";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          _localizedText['title']![lang]!,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _currentQuestionIndex < _questions.length
              ? _buildQuiz(lang)
              : _buildResult(lang),
        ),
      ),
    );
  }

  Widget _buildQuiz(String lang) {
    final question = _questions[_currentQuestionIndex];
    double targetProgress = (_currentQuestionIndex + 1) / _questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barre de progression élégante
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            tween: Tween<double>(begin: 0, end: targetProgress),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.pink.shade50,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
                minHeight: 6,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "${_localizedText['question_count']![lang]} ${_currentQuestionIndex + 1} ${_localizedText['of']![lang]} ${_questions.length}",
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          question['question'][lang],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.builder(
            itemCount: (question['answers'] as List).length,
            itemBuilder: (context, index) {
              final ans = question['answers'][index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _answerQuestion(ans['type']),
                  child: Row(
                    children: [
                      // Icône intégrée pour rendre le choix visuel et intuitif
                      Icon(ans['icon'], color: Colors.pink.shade300, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          ans['text'][lang],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResult(String lang) {
    String finalTypeFR = _getResult();
    String displayResult = _localizedText[finalTypeFR]![lang]!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.pink, size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            _localizedText['result_intro']![lang]!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayResult,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context, finalTypeFR),
              child: Text(
                _localizedText['save_btn']![lang]!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
