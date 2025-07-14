import 'package:flutter/material.dart';

class NavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const NavigationBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  final List<String> icons = const [
    "assets/home.png", "assets/galerie.png",
    "assets/likes.png", "assets/statistik.png",
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40, left: 50, right: 50, top: 20),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFA8D5BA),
          borderRadius: BorderRadius.circular(100),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(icons.length, (index) {
            final bool isActive = selectedIndex == index;
            return GestureDetector(
              onTap: () => onIndexChanged(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isActive)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Image.asset(
                        icons[index],
                        width: 70, 
                        height: 30,
                        color: isActive ? Colors.black : Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}