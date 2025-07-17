import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _logoController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutSine,
    ));

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoController.forward();
    _shimmerController.repeat();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, 'login');
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFffffff),
              Color(0xFFf8fafc),
              Color(0xFFf1f5f9),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _logoAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7dd3fc), // sky-300
                        Color(0xFF38bdf8), // sky-400
                        Color(0xFF0ea5e9), // sky-500
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38bdf8).withOpacity(0.4),
                        blurRadius: 25,
                        spreadRadius: 8,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: const Color(0xFF7dd3fc).withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 3,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [
                          Color(0xFF64748b), // slate-500
                          Color(0xFF3b82f6), // blue-500
                          Color(0xFF06b6d4), // cyan-500
                          Color(0xFF0ea5e9), // sky-500
                          Color(0xFF3b82f6), // blue-500
                          Color(0xFF8b5cf6), // violet-500
                          Color(0xFF64748b), // slate-500
                        ],
                        stops: const [0.0, 0.15, 0.3, 0.5, 0.7, 0.85, 1.0],
                        transform: GradientRotation(0),
                        tileMode: TileMode.mirror,
                      ).createShader(
                        Rect.fromLTWH(
                          _shimmerAnimation.value * bounds.width,
                          0,
                          bounds.width,
                          bounds.height,
                        ),
                      );
                    },
                    child: const Text(
                      'GoPox',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black12,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              Text(
                'Health Monitoring App',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF64748b).withOpacity(0.8),
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 60),

              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF0ea5e9).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0ea5e9)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}