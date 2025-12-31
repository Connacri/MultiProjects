import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    List<Container> cards = [
      _cardCustom(img: '100'),
      _cardCustom(img: '101'),
      _cardCustom(img: '102'),
    ];
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10.0),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '추천 드릴 친구들을 준비 중이에요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                ),
                Text('매일 새로운 친구들을 소개시켜드려요'),
              ],
            ),
          ),
        ),
        CardSwiper(
          cardsCount: cards.length,
          isLoop: false,
          cardBuilder: (context, index, percentThresholdX, percentThresholdY) =>
              Center(child: cards[index]),
        ),
      ],
    );
  }

  Container _cardCustom({required String img}) {
    const double widthHeight = 460;

    return Container(
      width: kIsWeb ? widthHeight : double.infinity,
      height: kIsWeb ? widthHeight : double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0)),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Image.asset(
            'assets/$img.png',
            fit: BoxFit.cover,
            width: kIsWeb ? widthHeight : double.infinity,
            height: kIsWeb ? widthHeight : double.infinity,
          ),
          Container(
            width: kIsWeb ? widthHeight : double.infinity,
            height: kIsWeb ? widthHeight : double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                gradient: const LinearGradient(colors: [
                  Colors.transparent,
                  Color.fromARGB(182, 0, 0, 0),
                ], transform: GradientRotation(360))),
          ),
          Positioned(
            bottom: 130.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1000.0),
                  color: Colors.black,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.grey.shade800,
                      ),
                      const Text('29,930'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                children: [
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '잭과분홍콩나물 25',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20.0),
                      ),
                      Text('서울·2km 거리에 있음'),
                    ],
                  ),
                  const SizedBox(
                    width: 80.0,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(177, 0, 0, 0),
                      border: Border.all(
                        color: Colors.blueAccent,
                      ),
                      borderRadius: BorderRadius.circular(1000.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset('assets/heart.png'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ],
      ),
    );
  }
}
