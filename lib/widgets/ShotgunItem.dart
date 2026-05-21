import 'dart:ui';
import 'package:flutter/material.dart';

class ShotgunItem extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String hours;
  final String imageUrl;

  final double height;
  final double? width;
  final VoidCallback? onTap; // Ajout du callback de clic

  const ShotgunItem({
    super.key,
    this.title = 'Événement à venir',
    this.description = 'Aucune description disponible pour le moment.',
    this.date = '--/--',
    this.hours = '--h--h',
    this.imageUrl = 'assets/evenement.png',
    this.height = 168.0,
    this.width = 118.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    List<String> hoursSplit = hours.split(' - ');
    String startHour = hoursSplit.isNotEmpty ? hoursSplit[0] : hours;
    String endHour = hoursSplit.length > 1 ? hoursSplit[1] : '';

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
            onTap: onTap, // Utilisation du onTap dynamique
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: Colors.transparent),
                ),

                // 1. L'IMAGE DE FOND
                Positioned.fill(
                  child: Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.grey[900]);
                    },
                  ),
                ),

                // 2. LA ZONE DE FLOU PROGRESSIVE
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: height * 0.60,
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                        stops: [0.0, 0.2],
                      ).createShader(bounds);
                    },
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                      child: Container(
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),

                // 3. LE TITRE
                Positioned(
                  left: 6.0,
                  right: 12.0,
                  bottom: 48.0,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 4. LES INFOS TOUT EN BAS
                Positioned(
                  left: 4.0,
                  right: 8.0,
                  bottom: 4.0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            startHour,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (endHour.isNotEmpty)
                            Text(
                              endHour,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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