import 'package:cloud_firestore/cloud_firestore.dart';

class Quiz {
  final String id;
  final String title;
  final List<QuizQuestion> questions;

  Quiz({required this.id, required this.title, required this.questions});

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final questionsData = List<Map<String, dynamic>>.from(
      data['questions'] ?? [],
    );

    return Quiz(
      id: doc.id,
      title: data['title'] ?? '',
      questions: questionsData.map((q) => QuizQuestion.fromMap(q)).toList(),
    );
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final bool saveToProfile;
  final String? profileField;
  final List<List<String>> recommendations;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.saveToProfile,
    this.profileField,
    required this.recommendations,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    final options = List<String>.from(map['options'] ?? []);
    final recommendationsData = List<List<String>>.from(
      (map['recommendations'] ?? []).map<List<String>>(
        (recList) => List<String>.from(recList),
      ),
    );

    return QuizQuestion(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      options: options,
      saveToProfile: map['saveToProfile'] ?? false,
      profileField: map['profileField'],
      recommendations: recommendationsData,
    );
  }
}
