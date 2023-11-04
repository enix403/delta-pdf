import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vecm;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Root());
}

class Root extends StatelessWidget {
  const Root({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delta PDF Scratch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: SafeArea(child: Scaffold(body: Scratch())),
      //home: SafeArea(child: MyHomePage()),
    );
  }
}

Color _randomColor() =>
    Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

class Scratch extends StatefulWidget {
  @override
  State<Scratch> createState() => _ScratchState();
}

class _ScratchState extends State<Scratch> with SingleTickerProviderStateMixin {
  int n = 0;

  final scrollController = ScrollController();

  late final AnimationController animationController;
  late Simulation sim;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    animationController = AnimationController.unbounded(vsync: this);
    animationController.addListener(() {
      scrollController.jumpTo(animationController.value);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    animationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                animationController.stop();
                const physics = ClampingScrollPhysics();
                final simulation = physics.createBallisticSimulation(
                  scrollController.position,
                  5000.0,
                );
                if (simulation != null) {
                  sim = simulation;
                  animationController.animateWith(sim);
                }
              },
              child: const Text("Simulate"),
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              controller: scrollController,
              itemBuilder: (context, index) {
                return Container(
                  height: 116,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: _randomColor(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


