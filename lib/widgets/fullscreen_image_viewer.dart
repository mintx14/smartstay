import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

enum MediaType { image, video }

class MediaItem {
  final String url;
  final MediaType type;

  MediaItem({required this.url, required this.type});

  factory MediaItem.fromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.avi') ||
        lowerUrl.endsWith('.mkv') ||
        lowerUrl.endsWith('.webm')) {
      return MediaItem(url: url, type: MediaType.video);
    }
    return MediaItem(url: url, type: MediaType.image);
  }
}

class FullScreenMediaViewer extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;
  final String propertyTitle;

  const FullScreenMediaViewer({
    super.key,
    required this.mediaUrls,
    this.initialIndex = 0,
    required this.propertyTitle,
  });

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late ScrollController _thumbnailScrollController;
  late int _currentIndex;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late List<MediaItem> _mediaItems;
  final Map<int, VideoPlayerController> _videoControllers = {};
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _thumbnailScrollController = ScrollController();

    // Convert URLs to MediaItems
    _mediaItems =
        widget.mediaUrls.map((url) => MediaItem.fromUrl(url)).toList();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Initialize video controller for current item if it's a video
    _initializeCurrentVideo();

    // Scroll to the initial thumbnail
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToThumbnail(_currentIndex);
    });

    // Auto-hide controls after 3 seconds
    _startControlsTimer();
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _initializeCurrentVideo() {
    final currentItem = _mediaItems[_currentIndex];
    if (currentItem.type == MediaType.video &&
        !_videoControllers.containsKey(_currentIndex)) {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(currentItem.url));
      _videoControllers[_currentIndex] = controller;
      controller.initialize().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailScrollController.dispose();
    _fadeController.dispose();

    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _scrollToThumbnail(int index) {
    if (_thumbnailScrollController.hasClients) {
      final double position = index * 80.0; // 64 width + 16 margin
      _thumbnailScrollController.animateTo(
        position - (MediaQuery.of(context).size.width / 2) + 40,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    // Pause previous video if it was playing
    final previousItem = _mediaItems[_currentIndex];
    if (previousItem.type == MediaType.video &&
        _videoControllers.containsKey(_currentIndex)) {
      _videoControllers[_currentIndex]?.pause();
    }

    setState(() {
      _currentIndex = index;
      _showControls = true;
    });

    _scrollToThumbnail(index);
    _initializeCurrentVideo();
    _startControlsTimer();
  }

  void _goToMedia(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  void _toggleVideoPlayback() {
    final controller = _videoControllers[_currentIndex];
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
      setState(() {});
    }
  }

  Widget _buildMainMedia(MediaItem mediaItem, int index) {
    if (mediaItem.type == MediaType.video) {
      final controller = _videoControllers[index];

      if (controller == null || !controller.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        );
      }

      return GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            if (_showControls)
              Center(
                child: GestureDetector(
                  onTap: _toggleVideoPlayback,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            if (_showControls && controller.value.isInitialized)
              Positioned(
                bottom: 50,
                left: 20,
                right: 20,
                child: _buildVideoProgressBar(controller),
              ),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: _toggleControls,
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: Image.network(
              mediaItem.url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white.withOpacity(0.7),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }
  }

  Widget _buildVideoProgressBar(VideoPlayerController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            _formatDuration(controller.value.position),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(controller.value.duration),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildThumbnail(MediaItem mediaItem, int index) {
    final isSelected = index == _currentIndex;

    return GestureDetector(
      onTap: () => _goToMedia(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64,
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.6,
            child: Stack(
              children: [
                if (mediaItem.type == MediaType.image)
                  Image.network(
                    mediaItem.url,
                    fit: BoxFit.cover,
                    width: 64,
                    height: 64,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.image,
                          color: Colors.white30,
                          size: 24,
                        ),
                      );
                    },
                  )
                else
                  Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white70,
                      size: 32,
                    ),
                  ),
                if (mediaItem.type == MediaType.video)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Main media viewer
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _mediaItems.length,
              itemBuilder: (context, index) {
                return _buildMainMedia(_mediaItems[index], index);
              },
            ),

            // Top bar with counter and close button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Media counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _mediaItems[_currentIndex].type ==
                                        MediaType.video
                                    ? Icons.videocam
                                    : Icons.image,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_currentIndex + 1} / ${_mediaItems.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Close button
                        IconButton(
                          onPressed: () {
                            _fadeController.reverse().then((_) {
                              Navigator.of(context).pop();
                            });
                          },
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Navigation arrows
            if (_mediaItems.length > 1) ...[
              // Left arrow
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                left: _showControls ? 16 : -60,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _currentIndex > 0 ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: _currentIndex > 0
                          ? () => _goToMedia(_currentIndex - 1)
                          : null,
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 40,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),

              // Right arrow
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                right: _showControls ? 16 : -60,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _currentIndex < _mediaItems.length - 1 ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: _currentIndex < _mediaItems.length - 1
                          ? () => _goToMedia(_currentIndex + 1)
                          : null,
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 40,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Bottom section with thumbnails and indicators
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showControls ? 0 : -160,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page indicators
                      SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _mediaItems.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _currentIndex == index ? 8 : 6,
                              height: _currentIndex == index ? 8 : 6,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentIndex == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Thumbnail strip
                      Container(
                        height: 80,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListView.builder(
                          controller: _thumbnailScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _mediaItems.length,
                          itemBuilder: (context, index) {
                            return _buildThumbnail(_mediaItems[index], index);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to open the media viewer
void openFullScreenMediaViewer(
  BuildContext context,
  List<String> mediaUrls,
  int initialIndex,
  String propertyTitle,
) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FullScreenMediaViewer(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
          propertyTitle: propertyTitle,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  );
}
