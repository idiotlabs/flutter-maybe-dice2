import 'dart:math';

import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  Crashlytics.instance.enableInDevMode = true;

  FlutterError.onError = Crashlytics.instance.recordFlutterError;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maybe Dice',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorObservers: <NavigatorObserver>[observer],
      home: MyHomePage(
        title: '주사위 굴리기겠지...2',
        analytics: analytics,
        observer: observer,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.analytics, this.observer}) : super(key: key);

  final String title;
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  _MyHomePageState createState() => _MyHomePageState(analytics, observer);
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  _MyHomePageState(this.analytics, this.observer);

  int diceNumber1 = 1;
  int diceNumber2 = 1;

  String _gesture = "";
  TapPosition _position = TapPosition(Offset.zero, Offset.zero);

  AnimationController dice1AnimationController;
  AnimationController dice2AnimationController;

  final FirebaseAnalyticsObserver observer;
  final FirebaseAnalytics analytics;
  String _message = '';

  BannerAd myBanner = BannerAd(
    // Replace the testAdUnitId with an ad unit id from the AdMob dash.
    // https://developers.google.com/admob/android/test-ads
    // https://developers.google.com/admob/ios/test-ads
    adUnitId: 'ca-app-pub-8206166796422159/2005131170',
    size: AdSize.smartBanner,
    listener: (MobileAdEvent event) {
      print("BannerAd event is $event");
    },
  );

  InterstitialAd myInterstitial = InterstitialAd(
    // Replace the testAdUnitId with an ad unit id from the AdMob dash.
    // https://developers.google.com/admob/android/test-ads
    // https://developers.google.com/admob/ios/test-ads
    adUnitId: 'ca-app-pub-8206166796422159/7840777752',
    listener: (MobileAdEvent event) {
      print("InterstitialAd event is $event");
    },
  );

  @override
  void initState() {
    super.initState();

    dice1AnimationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    dice2AnimationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);

    FirebaseAdMob.instance.initialize(appId: 'ca-app-pub-8206166796422159~9735092165');

    myBanner
    // typically this happens well before the ad is shown
      ..load()
      ..show(
        // Positions the banner ad 60 pixels from the bottom of the screen
        anchorOffset: 40.0,
        // Positions the banner ad 10 pixels from the center of the screen to the right
        horizontalCenterOffset: 0.0,
        // Banner Position
        anchorType: AnchorType.bottom,
      );

    RewardedVideoAd.instance.listener = (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
      print("RewardedVideoAd event $event");
      if (event == RewardedVideoAdEvent.rewarded) {
        setState(() {

        });
      }
      else if (event == RewardedVideoAdEvent.closed) {
        RewardedVideoAd.instance
            .load(adUnitId: 'ca-app-pub-8206166796422159/8379833800')
            .catchError((e) => print("error in loading again"));
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            UserAccountsDrawerHeader(
                accountName: new Text("Created by idiotLabs"),
                accountEmail: null,
            ),
            ListTile(
              title: Text("광고 봐주기"),
              onTap: () {
                myInterstitial
                  ..load()
                  ..show(
                    anchorType: AnchorType.bottom,
                    anchorOffset: 0.0,
                    horizontalCenterOffset: 0.0,
                  );
              },
            ),
            ListTile(
              title: Text("광고 봐주기 (video)"),
              onTap: () {
                RewardedVideoAd.instance
                    .load(adUnitId: 'ca-app-pub-8206166796422159/8379833800')
                    .catchError((e) => print("error in loading 1st time"));

                RewardedVideoAd.instance
                    .show()
                    .catchError((e) {
                      print("error in showing ad: ${e.toString()}");
                      _showDialog();
                    });
              },
            ),
            ListTile(
              title: Text("건의하기 (google form)"),
              onTap: () async {
                const url = 'https://forms.gle/2TyztqwYqEscbEkT8';
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              AnimatedBuilder(
                animation: dice1AnimationController,
                child: Image.asset('images/dice' + diceNumber1.toString() + '.png'),
                builder: (BuildContext context, Widget _widget) {
                  diceNumber1 = Random().nextInt(5) + 1;

                  if (dice1AnimationController.value == 1) {
                    if (_position.relative.dx < 30 && _position.relative.dy < 30)
                      diceNumber1 = Random().nextInt(2) + 4;
                    else if (_position.relative.dx > 285 && _position.relative.dy > 50)
                      diceNumber1 = Random().nextInt(2) + 1;
                  }

                  return Image.asset('images/dice' + diceNumber1.toString() + '.png');
                },
              ),
              Padding(padding: EdgeInsets.all(10.0)),
              AnimatedBuilder(
                animation: dice2AnimationController,
                builder: (BuildContext context, Widget _widget) {
                  diceNumber2 = Random().nextInt(5) + 1;

                  if (dice2AnimationController.value == 1) {
                    if (_position.relative.dx < 30 && _position.relative.dy < 30)
                      diceNumber2 = Random().nextInt(3) + 4;
                    else if (_position.relative.dx > 285 && _position.relative.dy > 50)
                      diceNumber2 = Random().nextInt(3) + 1;
                  }

                  return Image.asset('images/dice' + diceNumber2.toString() + '.png');
                },
              ),
            ]),
            const SizedBox(height: 40),
            PositionedTapDetector(
              onTap: _onTap,
              onDoubleTap: _onDoubleTap,
              onLongPress: _onLongPress,
              child: Container(
                width: 315.0,
                height: 80.0,
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black38,
                        spreadRadius: 2,
                        blurRadius: 2.0,
                        offset: Offset(1, 2)),
                  ],
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '굴러라!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 41,
                        ),
                      )
                    ]),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    dice1AnimationController.dispose();
    dice2AnimationController.dispose();

    myBanner.dispose();

    super.dispose();
  }

  void _onTap(TapPosition position) => _updateState('single tap', position);

  void _onDoubleTap(TapPosition position) => _updateState('double tap', position);

  void _onLongPress(TapPosition position) => _updateState('long press', position);

  void _updateState(String gesture, TapPosition position) {
    _clickRollDice();

    setState(() {
      _gesture = gesture;
      _position = position;
    });

    dice1AnimationController.forward(from: 0.0);
    dice2AnimationController.forward(from: 0.0);
  }

  void setMessage(String message) {
    setState(() {
      _message = message;
    });
  }

  Future<void> _clickRollDice() async {
    await analytics.logEvent(
      name: 'clickRollDice',
      parameters: <String, dynamic>{
      },
    );
    setMessage('logEvent succeeded');
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          content: new Text("아직은 때가 아닌가봐요 :')\n눌러주셔서 감사합니다."),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

}
