import 'dart:math' as math;
import 'package:flutter/material.dart';

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

  double _baseOffset = 0;
  double _basePointer = 0;
  //final _offset = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    animationController = AnimationController.unbounded(vsync: this);
    animationController.addListener(() {
      //scrollController.jumpTo(animationController.value
      //.clamp(0, scrollController.position.maxScrollExtent));
      _setScrollY(animationController.value);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    animationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _setScrollY(double value) {
    scrollController
        .jumpTo(value.clamp(0, scrollController.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {},
              child: const Text("Simulate"),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                animationController.stop();
                _baseOffset = scrollController.position.pixels;
                _basePointer = details.globalPosition.dy;
                //print("++++++++++++++++++${_baseOffset}");
              },
              onPanUpdate: (details) {
                final dst = details.globalPosition.dy - _basePointer;
                final delta = -dst;
                _setScrollY(_baseOffset + delta);
              },
              onPanEnd: (details) {
                animationController.stop();
                const physics = ClampingScrollPhysics();
                final simulation = physics.createBallisticSimulation(
                  scrollController.position,
                  -details.velocity.pixelsPerSecond.dy,
                );
                if (simulation != null) {
                  sim = simulation;
                  animationController.animateWith(sim);
                }
              },
              child: ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                controller: scrollController,
                //itemCount: ,
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
          ),
        ],
      ),
    );
  }
}
