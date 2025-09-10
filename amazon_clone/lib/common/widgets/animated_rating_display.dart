import 'package:amazon_clone/providers/rating_provider.dart';
import 'package:amazon_clone/models/rating.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnimatedRatingDisplay extends StatefulWidget {
  final String productId;
  final List<Rating>? fallbackRatings;
  final double? size;
  final bool showCount;
  final TextStyle? textStyle;
  final Color? starColor;

  const AnimatedRatingDisplay({
    super.key,
    required this.productId,
    this.fallbackRatings,
    this.size = 16.0,
    this.showCount = true,
    this.textStyle,
    this.starColor,
  });

  @override
  State<AnimatedRatingDisplay> createState() => _AnimatedRatingDisplayState();
}

class _AnimatedRatingDisplayState extends State<AnimatedRatingDisplay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  double _lastRating = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerPulseAnimation(double newRating) {
    if (newRating != _lastRating && newRating > 0) {
      _pulseController.reset();
      _pulseController.forward().then((_) {
        _pulseController.reverse();
      });
    }
    _lastRating = newRating;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RatingProvider>(
      builder: (context, ratingProvider, child) {
        final currentRating = ratingProvider.getAverageRating(
          widget.productId,
          widget.fallbackRatings,
        );
        final ratingCount = ratingProvider.getRatingCount(
          widget.productId,
          widget.fallbackRatings,
        );

        // Trigger animation when rating changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _triggerPulseAnimation(currentRating);
        });

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Star rating display
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      if (index < currentRating.floor()) {
                        return Icon(
                          Icons.star,
                          size: widget.size,
                          color: widget.starColor ?? Colors.orange,
                        );
                      } else if (index < currentRating) {
                        return Icon(
                          Icons.star_half,
                          size: widget.size,
                          color: widget.starColor ?? Colors.orange,
                        );
                      } else {
                        return Icon(
                          Icons.star_border,
                          size: widget.size,
                          color: Colors.grey[400],
                        );
                      }
                    }),
                  ),

                  if (widget.showCount && currentRating > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${currentRating.toStringAsFixed(1)}',
                      style:
                          widget.textStyle ??
                          TextStyle(
                            fontSize: (widget.size! * 0.8),
                            fontWeight: FontWeight.w600,
                            color: widget.starColor ?? Colors.orange,
                          ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '($ratingCount)',
                      style:
                          widget.textStyle?.copyWith(
                            fontSize: (widget.size! * 0.7),
                            color: Colors.grey[600],
                          ) ??
                          TextStyle(
                            fontSize: (widget.size! * 0.7),
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class QuickRatingButton extends StatefulWidget {
  final String productId;
  final double currentUserRating;
  final Function(double) onRatingUpdate;
  final double? size;

  const QuickRatingButton({
    super.key,
    required this.productId,
    required this.currentUserRating,
    required this.onRatingUpdate,
    this.size = 24.0,
  });

  @override
  State<QuickRatingButton> createState() => _QuickRatingButtonState();
}

class _QuickRatingButtonState extends State<QuickRatingButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _showQuickRating(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickRatingSheet(
        productId: widget.productId,
        currentRating: widget.currentUserRating,
        onRatingUpdate: widget.onRatingUpdate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _scaleController.forward(),
            onTapUp: (_) {
              _scaleController.reverse();
              _showQuickRating(context);
            },
            onTapCancel: () => _scaleController.reverse(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rate,
                    size: widget.size,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Rate',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class QuickRatingSheet extends StatefulWidget {
  final String productId;
  final double currentRating;
  final Function(double) onRatingUpdate;

  const QuickRatingSheet({
    super.key,
    required this.productId,
    required this.currentRating,
    required this.onRatingUpdate,
  });

  @override
  State<QuickRatingSheet> createState() => _QuickRatingSheetState();
}

class _QuickRatingSheetState extends State<QuickRatingSheet> {
  double _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.currentRating;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Rate this product',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = index + 1.0;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _selectedRating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: index < _selectedRating
                        ? Colors.orange
                        : Colors.grey[400],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          if (_selectedRating > 0)
            Text(
              '${_selectedRating.toStringAsFixed(0)} star${_selectedRating > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedRating > 0
                  ? () {
                      widget.onRatingUpdate(_selectedRating);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Rating',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
