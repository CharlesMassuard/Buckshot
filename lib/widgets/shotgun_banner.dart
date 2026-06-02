import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';

class ShotgunBanner extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String hours;
  final String imageUrl;

  final double height;
  final double? width;
  final VoidCallback? onTap;

  const ShotgunBanner({
    super.key,
    this.title = 'Événement à venir',
    this.description = 'Aucune description disponible pour le moment.',
    this.date = '--/--',
    this.hours = '--h--h',
    this.imageUrl = 'assets/evenement.png',
    this.height = 160.0,
    this.width,
    this.onTap,
  });

  Widget _buildImage() {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    if (imageUrl.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(imageUrl),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } catch (e) {
        return _buildPlaceholder();
      }
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      'assets/soiree.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: Colors.transparent),
                ),

                // 1. L'IMAGE DE FOND (Asset ou Base64)
                Positioned.fill(
                  child: _buildImage(),
                ),

                // 2. LA ZONE DE FLOU PROGRESSIVE
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: height * 0.6,
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                        ],
                        stops: [0.0, 0.2],
                      ).createShader(bounds);
                    },
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),

                // 3. LE CONTENU (TEXTES)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: 10.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(fontSize: 11, color: Colors.grey[200]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            date,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            hours,
                            style: TextStyle(fontSize: 12, color: Colors.grey[200]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}