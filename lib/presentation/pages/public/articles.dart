import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloria/core/i18n/app_text.dart';
import 'package:veloria/presentation/pages/public/shop_page.dart';
import 'package:veloria/presentation/states/language_provider.dart';
import '../../../domain/entities/product.dart';

class ArticlePage extends StatelessWidget {
  final String articleId;

  const ArticlePage({super.key, required this.articleId});

  Stream<DocumentSnapshot> getArticleStream() {
    return FirebaseFirestore.instance
        .collection('articles')
        .doc(articleId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('article.title')),
        backgroundColor: Colors.pink,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: getArticleStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return Center(child: Text(context.t('article.notFound')));
          }

          final title = language.isAr
              ? (data['title_ar'] ?? data['title'] ?? '')
              : language.isEn
              ? (data['title_en'] ?? data['title'] ?? '')
              : (data['title'] ?? '');
          final content = language.isAr
              ? (data['content_ar'] ?? data['content'] ?? '')
              : language.isEn
              ? (data['content_en'] ?? data['content'] ?? '')
              : (data['content'] ?? '');
          final recommendedProducts = List<String>.from(
            data['recommendedProducts'] ?? [],
          );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                if (recommendedProducts.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('article.recommendedProducts'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('products')
                            .where(
                              FieldPath.documentId,
                              whereIn: recommendedProducts,
                            )
                            .snapshots(),
                        builder: (context, prodSnapshot) {
                          if (!prodSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final products = prodSnapshot.data!.docs
                              .map((doc) => Product.fromFirestore(doc))
                              .toList();

                          return SizedBox(
                            height: 340,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: products.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return SizedBox(
                                  width: 180,
                                  child: ProductCard(product: product),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
