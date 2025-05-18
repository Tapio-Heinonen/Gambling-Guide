import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_logic_funcs.dart';
import 'database_helper.dart';

class QuizModeScreen extends StatefulWidget {
  @override
  _QuizModeScreenState createState() => _QuizModeScreenState();
}

String getRandomSuit() {
  final suits = ['♠', '♥', '♦', '♣'];
  return suits[Random().nextInt(suits.length)];
}

class _QuizModeScreenState extends State<QuizModeScreen> {
  String feedback = "";
  int score = 0;

  // Primary hand
  List<int> playerHand = [];

  // If split occurs, we store the split-off hand here
  List<int> splitHand = [];

  // Flag to say “we are done with this quiz/hand; disable further moves”
  bool quizOver = false;

  int dealerCardVal = 0;

  final Map<String, int> cardValues = {
    '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
    '10': 10, 'J': 10, 'Q': 10, 'K': 10, 'A': 11
  };

  // Load counter value from SharedPreferences
  Future<void> _loadScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      score = prefs.getInt('score') ?? 0;
    });
  }

  // Save counter value to SharedPreferences
  Future<void> _saveScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('score', score);
  }

  void _incrementScore() {
    setState(() {
      score++;
    });
    _saveScore();
  }

  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  int masteredHands = 0;
  int masteryLevel = 1;
  int masteryXP = 0;
  int xpToNextLevel = 10;

  Future<void> _loadMasteredHands() async {
    int count = await dbHelper.countMastered();
    setState(() {
      masteredHands = count;
      masteryLevel = 1;
      int remainingXP = masteredHands;

      // Determine mastery level and remaining XP
      while (remainingXP >= xpToNextLevel) {
        remainingXP -= xpToNextLevel;
        masteryLevel++;
        xpToNextLevel += 10; // XP needed increases per level
      }

      masteryXP = remainingXP;
    });
  }

  void _updateMastered(int handID) async {
    int count = await dbHelper.addMasteredAndGetCount(handID);
    setState(() {
      masteredHands = count;
      masteryLevel = 1;
      int xpToNextLevel = 10;
      int remainingXP = masteredHands;

      // Determine mastery level and remaining XP
      while (remainingXP >= xpToNextLevel) {
        remainingXP -= xpToNextLevel;
        masteryLevel++;
        xpToNextLevel += 10; // XP ToNextLevel increases per level
      }

      masteryXP = remainingXP;
    });
  }

  void _generateNewQuestion() {
    Random random = Random();
    List<String> cardKeys = cardValues.keys.toList();
    String playerCard1 = cardKeys[random.nextInt(cardKeys.length)];
    String playerCard2 = cardKeys[random.nextInt(cardKeys.length)];
    String dealerCardKey = cardKeys[random.nextInt(cardKeys.length)];

    playerHand = [cardValues[playerCard1]!, cardValues[playerCard2]!];
    dealerCardVal = cardValues[dealerCardKey]!;

    // Reset any split-hand stuff
    splitHand = [];
    quizOver = false;
    feedback = "";

    setState(() {});
  }

  void _hit() {
    if (quizOver) return; // If the quiz is over, ignore further hits
    Random random = Random();
    List<String> cardKeys = cardValues.keys.toList();
    String newCard = cardKeys[random.nextInt(cardKeys.length)];

    setState(() {
      // If we are showing a split, you might decide which hand you’re hitting. 
      // For simplicity, let’s always add to the main hand.
      playerHand.add(cardValues[newCard]!);
      _checkAnswer("Hit");
    });
  }

  int _calculateHandTotal(List<int> hand) {
    if (hand.isEmpty) return 0; // ✅ Prevents "Bad state: No element" error

    int total = hand.reduce((a, b) => a + b);
    int aceCount = hand.where((card) => card == 11).length;

    while (total > 21 && aceCount > 0) {
      total -= 10;
      aceCount--;
    }
    return total;
  }

  // Example of checking correctness. In a real game, you'd typically do this only
  // after the final decision (Stand / Double / etc.), but we’ll follow the existing pattern.
  void _checkAnswer(String choice) {
    if (quizOver) return; // If quiz is already over, do nothing
    String correctMove = getBlackjackMove(playerHand, dealerCardVal);
    setState(() {
      if (choice == "Hit" || choice == "Double") {
        correctMove = getBlackjackMove(playerHand.sublist(0, playerHand.length - 1), dealerCardVal);
        if (choice == correctMove && _calculateHandTotal(playerHand) > 21) {
          // Player hit/doubled correctly, but got unlucky and busted
          _updateMastered(handID(playerHand, dealerCardVal));
          feedback = "✅ Correct! But you got unlucky";
          _incrementScore();
          // Mark the quiz as over so no further hits/stands can happen
          quizOver = true;
        }
        else if (choice == correctMove) {
          // Player hit/doubled correctly and didn't bust
          _updateMastered(handID(playerHand, dealerCardVal));
          feedback = "✅ Correct!";

          if (choice == "Double") quizOver = true;
        }
        else {
          // Player hit incorrectly
          feedback = "❌ Wrong! Correct move: $correctMove";
          // Mark the quiz as over so no further hits/stands can happen
          quizOver = true;
        }
      } else {
        if (choice == correctMove) {
          _updateMastered(handID(playerHand, dealerCardVal));
          feedback = "✅ Correct!";
          _incrementScore();
          // Mark the quiz as over so no further hits/stands can happen
          quizOver = true;
        }
        else {
          feedback = "❌ Wrong! Correct move: $correctMove";
          // Mark the quiz as over so no further hits/stands can happen
          quizOver = true;
        }
      }
    });
  }

  // Double: Add a random card, then end the quiz right away
  void _doubleDown() {
    if (quizOver) return;
    Random random = Random();
    List<String> cardKeys = cardValues.keys.toList();
    String newCard = cardKeys[random.nextInt(cardKeys.length)];

    setState(() {
      playerHand.add(cardValues[newCard]!);

      // Check correctness against "Double"
      _checkAnswer("Double");
    });
  }

  // Split: move the second card to splitHand, then give each hand one new card
  // This is a *very* simplified version. In a real Blackjack scenario, you can only
  // split if the two cards are the same rank, and you'd then play each hand separately.
  void _splitHandAction() {
    if (quizOver || playerHand.length < 2) return;

    // Move second card to the new split
    splitHand = [playerHand.removeAt(1)];

    // Now give each hand 1 new card
    Random random = Random();
    List<String> cardKeys = cardValues.keys.toList();

    // Add a random card to the original (now single-card) hand
    String newCardMain = cardKeys[random.nextInt(cardKeys.length)];
    playerHand.add(cardValues[newCardMain]!);

    // Add a random card to the split hand
    String newCardSplit = cardKeys[random.nextInt(cardKeys.length)];
    splitHand.add(cardValues[newCardSplit]!);

    // At this point, you could require the user to play out each hand separately.
    // For demonstration, we immediately check correctness for "Split" 
    // and mark quiz as over. Adjust to your liking if you want interactive play 
    // on each hand.
    _checkAnswer("Split");
  }

  @override
  void initState() {
    super.initState();
    _loadScore();
    _loadMasteredHands();
    _generateNewQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Text("Quiz Mode - Score: $score"),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _generateNewQuestion),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16), // Add padding for better spacing
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20), // Add spacing at the top for better layout
            Text(
              "Mastery Level: $masteryLevel",
              key: ValueKey(masteryLevel),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              "EXP: $masteryXP / $xpToNextLevel",
              key: ValueKey(xpToNextLevel),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            // Progress Bar
            Stack(
              children: [
                Container(
                  height: 30,
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  height: 30,
                  width: 300 * (masteryXP / xpToNextLevel),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30), // Space between elements
            Container(
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.brown, width: 15)
              ),
              child: Column(
                children: [
                  SizedBox(height: 5),
                  Text(
                    "Dealer's Card",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  _buildCardRow([dealerCardVal]),
                  SizedBox(height: 20),
                  Text(
                    "Your Hand",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  _buildCardRow(playerHand),
                  // Split hand if available
                  if (splitHand.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Text(
                      "Split Hand",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    _buildCardRow(splitHand),
                  ],
                  SizedBox(height: 10),
                ]
              )
            ),
            SizedBox(height: 20),
            Text(
              feedback,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 20),
            // BUTTON LAYOUT
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: quizOver ? null : _hit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(130, 70),
                      ),
                      child: Text("Hit", style: TextStyle(fontSize: 24)),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: quizOver ? null : () => _checkAnswer("Stand"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(130, 70),
                      ),
                      child: Text("Stand", style: TextStyle(fontSize: 24)),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: quizOver ? null : _doubleDown,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow.shade800,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(130, 70),
                      ),
                      child: Text("Double", style: TextStyle(fontSize: 24)),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: quizOver ? null : _splitHandAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(130, 70),
                      ),
                      child: Text("Split", style: TextStyle(fontSize: 24)),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            if (quizOver)
              ElevatedButton(
                onPressed: _generateNewQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: Size(130, 70),
                ),
                child: Text("Next Hand", style: TextStyle(fontSize: 22)),
              ),
            SizedBox(height: 40), // Extra bottom spacing to prevent overflow
          ],
        ),
      ),
    );
  }

 // 👇 Replaces _buildCardRow and _buildCardBox in your code
Widget _buildCardRow(List<int> cards) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: cards.isEmpty
        ? [_buildCardBox("?", "")]
        : cards.map((cardValue) {
            final entry = cardValues.entries.firstWhere(
              (e) => e.value == cardValue,
              orElse: () => MapEntry("?", 0),
            );
            String cardLabel = entry.key;
            String suit = getRandomSuit();
            return _buildCardBox(cardLabel, suit);
          }).toList(),
  );
}

Widget _buildCardBox(String label, String suit) {
  final isRed = (suit == '♥' || suit == '♦');
  return Container(
    width: 60,
    height: 80,
    alignment: Alignment.center,
    margin: EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 4,
          offset: Offset(2, 2),
        ),
      ],
      border: Border.all(color: Colors.black, width: 1.5),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 4),
        Text(
          suit,
          style: TextStyle(
            fontSize: 20,
            color: isRed ? Colors.red : Colors.black,
          ),
        ),
      ],
    ),
  );
}


}
