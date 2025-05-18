import 'package:flutter/material.dart';

class HowToPlayScreen extends StatefulWidget {
  @override
  _HowToPlayScreenState createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  String _selectedTopic = '';
  final Map<String, String> _topicText = {
    "What's the goal?": "In blackjack, you play against the dealer. You must get as close to 21 points as possible, without going over. You both are dealt two cards, but only one of the dealer's cards is visible, and whoever is closer to 21 without going over wins. Number cards are worth their value, while picture cards are worth 10 points. Aces can be worth 11 or 1, whichever is advantageous. The dealer must hit if they have less than 17, and stand on 17 or above.",
    "What's the \"book\"?": "Like all finite games, there is always some optimal play that can be made in order to maximize your chances of winning. This is the goal of our app- we teach you which moves are best, and when. Images and screenshots are available online that also help with strategy.",
    "Basic intuition?": "In general, face cards and aces are scary if the dealer shows these. If the dealer shows a 5 or a 6, for example, then they are more likely to bust. A basic rule of thumb is to stand on 12 or above when the dealer shows a 2,3,4,5, or 6, and hit otherwise until you are above 17 points. The idea is that it is not worth the risk of busting yourself, when the dealer is likely to bust. Hitting on 16 is scary, but the book says to do it against a high dealer card.",
    "What about splitting?": "If you're dealt a pair, you can split them into two hands. Some pairs (like Aces or 8s) are great for splitting. The book says to never split 10s. You can split more aggresively when the dealer is showing a weaker card- since you are more likely to scoop both hands.",
    "What is doubling down?": "You can double your bet after the first two cards, before you've hit. Then you recieve one more card. This is ideal if you 11 or 10, for example, as then you have a high chance of making a 20 or 21. Always double on 11, and double more aggresively on weaker dealer upcards.",
    "What's a \"blackjack\"?": "A blackjack is when your first two cards total 21 — an Ace and a 10-value card. It usually pays 3:2. When the dealer gets a blackjack, the hand is over and you lose.",
    "\"Soft\" vs. \"Hard\" totals": "A soft total refers to when an Ace plays as 11 points instead of 1. It's called soft since there is no risk of busting - even if you're dealt a ten, then the ace will become worth less. Soft totals are generally good, since you allow the potential to make 20 or 21 without fear of busting. Many soft hands are doubled. A hard total is when you have an ace, but it must count as 1, since otherwise you would be over 21.",
    "Insurance?": "If the dealer shows an Ace, you can buy insurance — a side bet that pays if the dealer has a blackjack. Never buy insurance- our app does not even consider it an option.",
  };

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("How to Play"),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          ..._topicText.keys.map((topic) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 200, maxWidth: 300),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTopic = _selectedTopic == topic ? '' : topic;
                        });
                      },
                      child: Text(topic, textAlign: TextAlign.center),
                    ),
                  ),
                ),
                if (_selectedTopic == topic)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    child: Text(
                      _topicText[topic]!,
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: 12),
              ],
            );
          }).toList(),
        ],
      ),
    ),
  );
}
}