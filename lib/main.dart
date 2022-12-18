import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBaseUri = 'http://lucky.anakint.com:8888';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lucky drawer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isWon = false;
  bool isLost = false;
  int count = 0;
  late int key;
  late String seed;

  @override
  void initState() {
    super.initState();
    reseed();
  }

  void reseed() {
    seed = randomHexString(16);
    key = 0;
    for (int i = 0; i < seed.length; i++) {
      key += int.parse(seed[i], radix: 16);
    }
    key %= 9;
  }

  final Random _random = Random();

  String randomHexString(int length) {
    StringBuffer sb = StringBuffer();
    for (var i = 0; i < length; i++) {
      sb.write(_random.nextInt(16).toRadixString(16));
    }
    return sb.toString();
  }

  void handlePlay(int number) {
    if (isWon || isLost) return;
    count += 1;
    if (number == key) {
      setState(() => isWon = true);
    } else if (count == 3) {
      setState(() => isLost = true);
    }
  }

  void handleTryAgain() {
    setState(() {
      isWon = false;
      isLost = false;
      count = 0;
      reseed();
    });
  }

  void handleClaim() {
    http
        .get(Uri.parse(apiBaseUri + '/claim?seed=$seed&num=$num'))
        .then((response) {
          if (response.statusCode != 200) {
            _showMyDialog('Unknown error occurred');
          } else {
            _showMyDialog('Success');
          }
        });
  }

  Future<void> _showMyDialog(text) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(text),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Find the cat hidden behind these boxes within 3 tries to win our prize!'),
            ),
            Board(seed: seed, onPlay: handlePlay),
            isWon ? Won(onPressed: handleClaim) : Container(),
            isLost ? Lost(onPressed: handleTryAgain) : Container()
          ]
        )
      )
    );
  }
}

class Board extends StatefulWidget {
  const Board({ Key? key, required this.seed, required this.onPlay }) : super(key: key);
  final String seed;
  final Function(int) onPlay;

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> {
  late int key;
  late List<Widget> boxes;
  List<bool> openStatus = [false, false, false, false, false, false, false, false, false];

  List<Widget> getBoxes(s) {
    key = 0;
    for (int i = 0; i < s.length; i++) {
      key += int.parse(s[i], radix: 16);
    }
    key %= 9;
    List<Widget> widgets = List<int>.generate(9, (i) => i)
        .map((i) => Pic(
              path: 'assets/troll.png',
              onTap: handlePlay,
              number: i,
              isOpened: openStatus[i],
            ))
        .toList();
    widgets[key] = Pic(
        path: 'assets/cat.jpg',
        onTap: handlePlay,
        number: key,
        isOpened: openStatus[key]);
    return widgets;
  }

  void handlePlay(int number) {
    if (openStatus[number] == false) {
      setState(() {
        openStatus[number] = true;
        boxes = getBoxes(widget.seed);
        widget.onPlay(number);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    boxes = getBoxes(widget.seed);
  }

  @override
  void didUpdateWidget(covariant Board oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      openStatus = [
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false
      ];
      boxes = getBoxes(widget.seed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(children: boxes);
  }
}

class Pic extends StatelessWidget {
  const Pic(
      {Key? key,
      required this.path,
      required this.onTap,
      required this.number,
      required this.isOpened})
      : super(key: key);
  final String path;
  final Function(int) onTap;
  final int number;
  final bool isOpened;

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.all(10),
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: Colors.blue[900]!)
          ),
          clipBehavior: Clip.hardEdge,
          child: Material(
            child: InkWell(
              onTap: () => onTap(number),
              splashColor: Colors.blue[200],
              child: isOpened ?
                Image.asset(path) : const Center(child: Text('?')),
            ),
          )
        );
  }
}

class Won extends StatelessWidget {
  const Won({ Key? key, required this.onPressed }) : super(key: key);
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Congratulations!!! Claim your 1,000,000BTC below'),
        ),
        ElevatedButton(
          onPressed: onPressed,
          child: const Text('Claim')
        )
      ],
    );
  }
}

class Lost extends StatelessWidget {
  const Lost({Key? key, required this.onPressed}) : super(key: key);
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Bad luck!'),
        ),
        ElevatedButton(onPressed: onPressed, child: const Text('Try again'))
      ],
    );
  }
}
