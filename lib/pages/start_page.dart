import 'package:animate_do/animate_do.dart';
import 'package:clutter_cut/pages/file_duplicate_remover_screen.dart';
import 'package:flutter/material.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {

  void navigateToScreen() {
     Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const FileDuplicateRemoverScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeIn;
            
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            
            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 5), () => navigateToScreen());
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark? Colors.white : Colors.black;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/open-folder.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.scaleDown,
                ),
                const SizedBox(width: 10),
                FadeInRight(
                  from: 200,
                  delay: Duration(milliseconds: 1500),
                  duration: const Duration(milliseconds: 1500),
                  child: Text(
                    'Cluttercut',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}