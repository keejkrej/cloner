import 'package:flutter/material.dart';
import '../../deck/models/slide.dart';
import '../../themes/deck_theme.dart';

class SlideRenderer extends StatelessWidget {
  final Slide slide;
  final DeckTheme theme;
  final bool isInteractive;

  const SlideRenderer({
    super.key,
    required this.slide,
    required this.theme,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          gradient: theme.backgroundGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: _buildLayoutContent(context),
        ),
      ),
    );
  }

  Widget _buildLayoutContent(BuildContext context) {
    switch (slide.layoutType) {
      case SlideLayout.title:
        return _buildTitleLayout(context);
      case SlideLayout.bullets:
        return _buildBulletsLayout(context);
      case SlideLayout.twoColumn:
        return _buildTwoColumnLayout(context);
      case SlideLayout.imageText:
        return _buildImageTextLayout(context);
      case SlideLayout.bigNumber:
        return _buildBigNumberLayout(context);
      case SlideLayout.quote:
        return _buildQuoteLayout(context);
    }
  }

  // 1. Title Slide
  Widget _buildTitleLayout(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.accentColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              'PRESENTATION',
              style: TextStyle(
                color: theme.accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.titleFont(
              textStyle: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: theme.primaryTextColor,
                height: 1.15,
                letterSpacing: -1.0,
              ),
            ),
          ),
          if (slide.subtitle != null && slide.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 700,
              child: Text(
                slide.subtitle!,
                textAlign: TextAlign.center,
                style: theme.bodyFont(
                  textStyle: TextStyle(
                    fontSize: 20,
                    color: theme.secondaryTextColor,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 2. Bullets Slide
  Widget _buildBulletsLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: slide.bullets.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final bullet = entry.value;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardBackground.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.primaryTextColor.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.accentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$idx',
                        style: TextStyle(
                          color: theme.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        bullet,
                        style: theme.bodyFont(
                          textStyle: TextStyle(
                            fontSize: 16,
                            color: theme.primaryTextColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 3. Two-Column Slide
  Widget _buildTwoColumnLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Column
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardBackground.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.primaryTextColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.remove_circle_outline, color: theme.secondaryTextColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            slide.leftColumnTitle ?? 'Left Column',
                            style: theme.titleFont(
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: Text(
                          slide.leftColumnText ?? '',
                          style: theme.bodyFont(
                            textStyle: TextStyle(
                              fontSize: 15,
                              color: theme.secondaryTextColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Right Column
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardBackground.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.accentColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: theme.accentColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            slide.rightColumnTitle ?? 'Right Column',
                            style: theme.titleFont(
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: Text(
                          slide.rightColumnText ?? '',
                          style: theme.bodyFont(
                            textStyle: TextStyle(
                              fontSize: 15,
                              color: theme.primaryTextColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Image + Text Slide
  Widget _buildImageTextLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image container
              Expanded(
                flex: 48,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: theme.cardBackground,
                    border: Border.all(color: theme.primaryTextColor.withValues(alpha: 0.1)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: slide.imageUrl != null
                      ? Image.network(
                          slide.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackImageVisual(),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                    : null,
                                color: theme.accentColor,
                              ),
                            );
                          },
                        )
                      : _buildFallbackImageVisual(),
                ),
              ),
              const SizedBox(width: 24),
              // Text Content
              Expanded(
                flex: 52,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardBackground.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      slide.leftColumnText ?? slide.subtitle ?? 'Content details for this section.',
                      style: theme.bodyFont(
                        textStyle: TextStyle(
                          fontSize: 16,
                          color: theme.primaryTextColor,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Big Number Slide
  Widget _buildBigNumberLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slide.statNumber ?? '10x',
                  style: theme.titleFont(
                    textStyle: TextStyle(
                      fontSize: 88,
                      fontWeight: FontWeight.w900,
                      color: theme.accentColor,
                      letterSpacing: -2.0,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 650,
                  child: Text(
                    slide.statLabel ?? 'Measurable performance benchmark achieved across modern workflows.',
                    textAlign: TextAlign.center,
                    style: theme.bodyFont(
                      textStyle: TextStyle(
                        fontSize: 22,
                        color: theme.primaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 6. Quote Slide
  Widget _buildQuoteLayout(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '“',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: theme.accentColor,
              height: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 750,
            child: Text(
              slide.quoteText ?? 'Great architecture is not about what we can add, but what is impossible to strip away.',
              textAlign: TextAlign.center,
              style: theme.bodyFont(
                textStyle: TextStyle(
                  fontSize: 26,
                  fontStyle: FontStyle.italic,
                  color: theme.primaryTextColor,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (slide.quoteAuthor != null && slide.quoteAuthor!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.accentColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                '— ${slide.quoteAuthor}',
                style: theme.titleFont(
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.accentColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slide.title,
          style: theme.titleFont(
            textStyle: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: theme.primaryTextColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (slide.subtitle != null && slide.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            slide.subtitle!,
            style: theme.bodyFont(
              textStyle: TextStyle(
                fontSize: 16,
                color: theme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackImageVisual() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.cardBackground, theme.accentColor.withValues(alpha: 0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 48, color: theme.accentColor),
            const SizedBox(height: 12),
            Text(
              slide.imagePrompt ?? 'Thematic Visual',
              style: TextStyle(color: theme.secondaryTextColor, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
