import 'dart:math';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnim;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();

    // 3.0s total: dramatic spin-in → 4 decaying swings → settles pointing up
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _rotationAnim = _CompassSettleAnimation().animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache the image so there's zero blank frame when it first paints
    precacheImage(
      const AssetImage('assets/icons/app_logo.png'),
      context,
    ).then((_) {
      if (mounted) {
        setState(() => _imageLoaded = true);
        // Start animation only after image is guaranteed ready
        _controller.forward();
        _controller.addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            Future.delayed(const Duration(milliseconds: 350), _navigateToApp);
          }
        });
      }
    });
  }

  void _navigateToApp() {
    final user = SupabaseService().getCurrentUser();
    Navigator.of(context).pushReplacementNamed(
      user != null ? '/home' : '/login',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Compass needle with visible rotating ring ──
          Center(
            child: _imageLoaded
                ? AnimatedBuilder(
                    animation: _rotationAnim,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnim.value,
                        child: child,
                      );
                    },
                    child: _CompassWidget(),
                  )
                : _CompassWidget(), // show static while precaching
          ),

          // ── Tagline bottom ──
          const Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Just plan and GO!',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compass widget: just the logo, no ring
class _CompassWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/app_logo.png',
      width: 80,
      height: 80,
      fit: BoxFit.contain,
    );
  }
}

/// Compass physics animation:
///   Phase 1 (0–30%): fast 1.5-turn spin from 120° offset
///   Phase 2 (30–100%): 4 strongly damped oscillations that decay to 0° (pointing up)
class _CompassSettleAnimation extends Animatable<double> {
  @override
  double transform(double t) {
    if (t <= 0.0) return pi * 0.67; // start ~120° off axis

    // Phase 1 – fast spin in: sweeps through ~1.5 full rotations
    if (t < 0.30) {
      final p = t / 0.30;
      // goes from +120° → −360° (total ~480° rotation)
      return pi * 0.67 * (1.0 - p) - 2.67 * pi * p;
    }

    // Phase 2 – damped oscillation settling to 0 (north / pointing up)
    final p = (t - 0.30) / 0.70; // 0..1
    // Exponential decay envelope × sine gives natural compass needle feel
    final decay = exp(-4.5 * p);
    return pi * 1.1 * decay * sin(4.0 * p * pi);
  }
}
