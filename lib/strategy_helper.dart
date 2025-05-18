import 'package:flutter/material.dart';
import 'dart:math';

class StrategyHelperScreen extends StatefulWidget {
  @override
  _StrategyHelperScreenState createState() => _StrategyHelperScreenState();
}

String getRandomSuit() {
  final suits = ['♠', '♥', '♦', '♣'];
  return suits[Random().nextInt(suits.length)];
}

class _StrategyHelperScreenState extends State<StrategyHelperScreen> with SingleTickerProviderStateMixin {
  List<int> playerHand = [];
  List<String> playerHandString = [];
  List<int>? splitHand;
  List<String>? splitHandString;
  int? dealerCard;
  String? dealerCardString;
  String instructionText = "Enter your first two cards";
  String suggestion = "";
  bool isSplit = false;
  bool isPlayingSplitHand = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true); // Makes it pulse forever

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  final Map<String, int> cardValues = {
    '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
    '10': 10, 'J': 10, 'Q': 10, 'K': 10, 'A': 11
  };

  void _addPlayerCard(String card) {
    setState(() {
      if (playerHand.length < 2) {
        playerHand.add(cardValues[card]!);
        playerHandString.add(card);
        if (playerHand.length == 2) {
          instructionText = "Enter the dealer's card";
        }
      } else if (dealerCard != null && suggestion == "Hit") {
        playerHand.add(cardValues[card]!);
        playerHandString.add(card);
      }
      _updateSuggestion();
    });
  }

  void _setDealerCard(String card) {
    setState(() {
      if (dealerCard == null && playerHand.length == 2) {
        dealerCard = cardValues[card]!;
        dealerCardString = card;
        instructionText = "";
        _updateSuggestion();
      }
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

  void _updateSuggestion() {
    if (dealerCard == null || playerHand.length < 2) return;

    int playerTotal = _calculateHandTotal(playerHand);

    if (playerTotal > 21) {
      suggestion = "Bust! You Lose";
    } else if (_shouldSplit()) {
      _splitHandAction();
    } else if (_shouldDoubleDown(playerTotal)) {
      _doubleDownAction();
    } else {
      suggestion = _getBlackjackMove(playerTotal, dealerCard!);
    }

    if (suggestion == "Stand") {
      instructionText = "Final Decision: Stand";
    }
  }

    bool _shouldSplit() {
    if (playerHand.length != 2 || playerHand[0] != playerHand[1]) return false;

    int cardValue = playerHand[0];
    if (cardValue == 8 || cardValue == 11) return true; // Always split 8s and Aces
    if (cardValue == 9 && (dealerCard! != 7 && dealerCard! < 10)) return true;
    if (cardValue == 7 && dealerCard! <= 7) return true;
    if (cardValue == 6 && dealerCard! <= 6) return true;
    if (cardValue == 4 && (dealerCard! == 5 || dealerCard! == 6)) return true;
    if (cardValue == 2 || cardValue == 3) return dealerCard! <= 7;

    return false;
  }



  bool _shouldDoubleDown(int total) {
  return playerHand.length == 2 && (
      (total == 9 && dealerCard! >= 3 && dealerCard! <= 6) ||
      (total == 10 && dealerCard! <= 9) ||
      (total == 11) ||
      (playerHand.contains(11) && (total == 18 && dealerCard! >= 3 && dealerCard! <= 6)) ||
      (playerHand.contains(11) && (total == 17 && dealerCard! >= 3 && dealerCard! <= 6)) ||
      (playerHand.contains(11) && ((total == 16 || total == 15) && dealerCard! >= 4 && dealerCard! <= 6)) ||
      (playerHand.contains(11) && ((total == 14 || total == 13) && dealerCard! >= 5 && dealerCard! <= 6))
  );
}

  String _getBlackjackMove(int player, int dealer) {
    // Hard Hands (No Aces treated as 11)
    if (!playerHand.contains(11)) {
      if (player <= 8) return "Hit";
      if (player == 9 && (dealer >= 3 && dealer <= 6)) return playerHand.length == 2 ? "Double Down" : "Hit";
      if (player == 9) return "Hit";
      if (player == 10 && dealer <= 9) return playerHand.length == 2 ? "Double Down" : "Hit";
      if (player == 10) return "Hit";
      if (player == 11) return playerHand.length == 2 ? "Double Down" : "Hit";
      if (player == 12 && (dealer == 4 || dealer == 5 || dealer == 6)) return "Stand";
      if (player == 12) return "Hit";
      if (player >= 13 && player <= 16 && dealer <= 6) return "Stand";
      if (player >= 13 && player <= 16) return "Hit";
      if (player >= 17) return "Stand";
    }

    // Soft Hands (Contains Ace)
    if (playerHand.contains(11)) {
      if (player <= 17) return "Hit";
      if (player == 18 && (dealer >= 3 && dealer <= 6)) return playerHand.length == 2 ? "Double Down" : "Hit";
      if (player == 18 && (dealer == 2 || dealer == 7 || dealer == 8)) return "Stand";
      if (player == 18) return "Hit";
      if (player >= 19) return "Stand";
    }
    return "Hit"; // Default to Hit if no specific condition is met
  }
  
  void _splitHandAction() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Split Hand Detected"),
          content: Text("You need to play each hand separately. Please reset and play them individually."),
          actions: [
            TextButton(
              onPressed: () {
                _resetGame();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Reset Hand"),
            ),
          ],
        );
      },
    );
  }

  void _doubleDownAction() {
    setState(() {
      instructionText = "Double Down - Receive One Card";
      suggestion = "Final Decision: Double Down";
    });
  }

  void _resetGame() {
    setState(() {
      playerHand.clear();
      playerHandString.clear();
      splitHand = null;
      splitHandString = null;
      dealerCard = null;
      dealerCardString = null;
      instructionText = "Enter your first two cards";
      suggestion = "";
      isSplit = false;
      isPlayingSplitHand = false;
    });
  }

  Color _getSuggestionColor() {
    if (suggestion.contains("Stand")) return Colors.red;
    if (suggestion.contains("Double Down")) return Colors.yellow;
    if (suggestion.contains("Hit")) return Colors.green;
    if (suggestion.contains("Bust")) return Colors.red;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    //double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Text("Strategy"),
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _resetGame)],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Text(
                  instructionText,
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.brown, width: 15)
            ),
            child: Column(
              children: [
                SizedBox(height: 15),
                _buildCardRow(
                  "Dealer's Hand", 
                  dealerCard != null ? [dealerCardString!] : [], 
                  highlightNextCard: playerHand.length == 2,
                  totalSlots: 1 // Only show 1 card for dealer
                ),
                SizedBox(height: 15),
                _buildCardRow(
                  "Your Hand - Total Score: ${_calculateHandTotal(playerHand)}",
                  playerHandString, 
                  highlightNextCard: playerHand.length < 2 || suggestion == "Hit", 
                  totalSlots: (playerHand.length + (suggestion == "Hit" ? 1 : 0)).clamp(2, 10) // Ensure minimum 2 slots
                ),
                if (isSplit) _buildCardRow("Split Hand", splitHandString ?? [], highlightNextCard: isPlayingSplitHand),
                SizedBox(height: 15)
              ]
            )
          ),

          SizedBox(height: 15),
          Text(
            suggestion,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _getSuggestionColor()),
          ),
          SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 4)
            ),
            padding: EdgeInsets.all(8),
            child: _buildCardKeyboard()
          ),
          SizedBox(height: 15),
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: Size(140, 60),
          ),
          child: Text("New Game", style: TextStyle(fontSize: 24))),
        ],
      ),
    );
  }

  Widget _buildCardRow(String title, List<String> cards, {bool highlightNextCard = false, int totalSlots = 2}) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < totalSlots; i++)
              _buildCardBox(
                i < cards.length ? cards[i] : "?",
                isCurrent: highlightNextCard && i == cards.length,
              ),
          ],
        ),
      ],
    );
  }
Widget _buildCardBox(String text, {bool isCurrent = false}) {
  final bool isUnknown = text == "?";
  final String suit = isUnknown ? "?" : getRandomSuit();
  final bool isRed = (suit == '♥' || suit == '♦');

  return Container(
    width: 60,
    height: 80,
    alignment: Alignment.center,
    margin: EdgeInsets.symmetric(horizontal: 5),
    decoration: BoxDecoration(
      color: isCurrent ? Colors.yellow : Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.black, width: 2),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
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

  Widget _buildCardKeyboard() {
    return SingleChildScrollView(
      child: Center(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: cardValues.keys.map((card) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade900,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: Size(70, 60)
              ),
              onPressed: () {
                if (playerHand.length < 2) {
                  _addPlayerCard(card);
                } else if (dealerCard == null) {
                  _setDealerCard(card);
                } else {
                  _addPlayerCard(card);
                }
              },
              child: Text(card, style: TextStyle(fontSize: 24)),
            );
          }).toList(),
        )
      ),
    );
  }
}