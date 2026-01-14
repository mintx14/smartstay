import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:smartstay/widgets/badge_widget.dart' as custom;

class LiquidNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int unreadMessagesCount;
  final int pendingBookingsCount;

  const LiquidNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadMessagesCount = 0,
    this.pendingBookingsCount = 0,
  });

  @override
  State<LiquidNavBar> createState() => _LiquidNavBarState();
}

class _LiquidNavBarState extends State<LiquidNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _prevIndex = 0;

  final List<IconData> _icons = [
    Icons.explore_outlined,
    Icons.favorite_border,
    Icons.chat_bubble_outline,
    Icons.person_outline,
  ];

  final List<String> _labels = [
    'Explore',
    'Favorites',
    'Messages',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Slightly faster
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastLinearToSlowEaseIn, // Sophisticated smooth slide
    );
    // Initialize animation to end state since we start at a specific index
    _controller.forward(from: 1.0);
  }

  @override
  void didUpdateWidget(LiquidNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _prevIndex = oldWidget.currentIndex;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns the badge count for a given tab index
  String? _getBadgeCount(int index) {
    switch (index) {
      case 2: // Messages tab
        return widget.unreadMessagesCount > 0
            ? widget.unreadMessagesCount.toString()
            : null;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double height =
        70 + bottomPadding; // Slightly taller for floating effect
    final double itemWidth = width / _icons.length;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Stack(
        children: [
          // Animated Sliding Pill Background
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(width, height),
                painter: SlidingPillPainter(
                  itemWidth: itemWidth,
                  currentIndex: widget.currentIndex.toDouble(),
                  prevIndex: _prevIndex.toDouble(),
                  progress: _animation.value,
                  usableHeight: 70, // Base height
                ),
              );
            },
          ),

          // Icons layer
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_icons.length, (index) {
                final isSelected = widget.currentIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onTap(index);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with badge support
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          padding: const EdgeInsets.all(8),
                          child: custom.Badge(
                            count: _getBadgeCount(index),
                            child: Icon(
                              isSelected ? _icons[index] : _icons[index],
                              color:
                                  isSelected ? Colors.white : Colors.grey[400],
                              size: 24,
                            ),
                          ),
                        ),
                        // Label
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isSelected ? 1.0 : 0.6,
                          child: Text(
                            _labels[index],
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[400],
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class SlidingPillPainter extends CustomPainter {
  final double itemWidth;
  final double currentIndex;
  final double prevIndex;
  final double progress;
  final double usableHeight;

  SlidingPillPainter({
    required this.itemWidth,
    required this.currentIndex,
    required this.prevIndex,
    required this.progress,
    required this.usableHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Current interpolated position
    final double currentPos = prevIndex + (currentIndex - prevIndex) * progress;
    final double centerX = (currentPos * itemWidth) + (itemWidth / 2);
    final double centerY = usableHeight / 2;

    // Pill Dimension
    final double pillWidth = 70.0;
    final double pillHeight = 50.0;

    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(centerX - pillWidth / 2, centerY), // Gradient moves with pill
        Offset(centerX + pillWidth / 2, centerY),
        [
          const Color(0xFF1E3A5F), // Dark Navy
          const Color(0xFF3D5A80), // Lighter Navy
        ],
      )
      ..style = PaintingStyle.fill;

    // Draw Drop Shadow
    final shadowPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(centerX, centerY + 4),
            width: pillWidth * 0.8,
            height: pillHeight * 0.8),
        const Radius.circular(20),
      ));

    canvas.drawShadow(shadowPath, const Color(0xFF1E3A5F), 8, true);

    // Draw Main Pill
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: pillWidth,
            height: pillHeight),
        const Radius.circular(25), // Fully rounded corners
      ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SlidingPillPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.currentIndex != currentIndex;
  }
}
