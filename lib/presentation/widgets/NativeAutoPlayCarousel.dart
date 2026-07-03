import 'dart:async';
import 'package:flutter/material.dart';

class NativeAutoPlayCarousel extends StatefulWidget {
  final List<String> bannerImages;

  const NativeAutoPlayCarousel({super.key, required this.bannerImages});

  @override
  State<NativeAutoPlayCarousel> createState() => _NativeAutoPlayCarouselState();
}

class _NativeAutoPlayCarouselState extends State<NativeAutoPlayCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  StreamSubscription? _autoPlaySubscription;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    if (widget.bannerImages.length > 1) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _autoPlaySubscription = Stream.periodic(const Duration(seconds: 4)).listen((
      _,
    ) {
      if (_pageController.hasClients) {
        if (_currentPage < widget.bannerImages.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoPlaySubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bannerImages.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        // 1. Ton PageView existant (inchangé, sauf le setState ajouté)
        PageView.builder(
          controller: _pageController,
          itemCount: widget.bannerImages.length,
          onPageChanged: (int page) {
            setState(() {
              _currentPage =
                  page; // 🌟 Crucial pour mettre à jour l'affichage des points !
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              widget.bannerImages[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: 230,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 30,
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.pink,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        // 2. 🌟 LES INDICATEURS DE PAGES (DOTS) EN SUPERPOSITION
        if (widget.bannerImages.length >
            1) // On ne les affiche que s'il y a plus d'une bannière
          Positioned(
            bottom: 12, // Collé à 12 pixels du bas de la bannière
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.bannerImages.length, (index) {
                final bool isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: isActive
                      ? 14
                      : 6, // Effet pilule dynamique quand c'est actif
                  decoration: BoxDecoration(
                    // Rose vif si actif, blanc translucide si inactif pour passer sur toutes les couleurs de bannières
                    color: isActive
                        ? Colors.pink
                        : Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
