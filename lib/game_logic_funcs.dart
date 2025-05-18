String getBlackjackMove(List<int> cards, int upcard) {
    // returns one of "Stand" "Hit" "Split" "Double"
    // input : list of cards (must contain at least 2 values)
    // rules: dealer hits soft 17, no surrenders, unlimited doubling and splitting allowed

    int total = cards.reduce((a, b) => a + b);
    int aceCount = cards.where((card) => card == 11).length;
    bool soft = aceCount > 0;
    while (total > 21 && aceCount > 0) { // change aces from 11 to 1 if total is above 21
      total -= 10;
      aceCount--; 
    } 
    soft = aceCount > 0; // if any aces still play as 11 then the total is soft
    if (cards.length == 2 && cards[0] == cards[1]){ 
      // check if pair and if we should split
      if (splitPair(cards[0], upcard)){
        return "Split";
      }
    }
    if (soft){ // soft total logic
      switch (total) {
          case 21:
            return "Stand";
          case 20:
            return "Stand";
          case 19:
            if (upcard == 6){ 
              if (cards.length == 2){ return "Double";} //double if able, otherwise stand
              else {return "Stand";}
            } else {return "Stand";}
          case 18:
            if (upcard <= 6){ 
              if (cards.length == 2){ return "Double";} //double if able, otherwise stand
              else {return "Stand";}
            } else if (upcard >= 9){ return "Hit";}
            else{ return "Stand";}
          case 17:
            if (upcard == 2 || upcard >= 7){ return "Hit";}
            else {
              if (cards.length == 2){ return "Double";} //double if able, otherwise hit
              else {return "Hit";}
            }
          case 16:
          case 15:
            if (upcard <= 3 || upcard >= 7){ return "Hit";}
            else {
              if (cards.length == 2){ return "Double";} //double if able, otherwise hit
              else {return "Hit";}
            }
          case 14:
          case 13:
            if (upcard <= 4 || upcard >= 7){ return "Hit";}
            else {
              if (cards.length == 2){ return "Double";} //double if able, otherwise hit
              else {return "Hit";}
            }
        }
    } else { // hard total logic
      switch (total) {
        case 21:
        case 20:
        case 19:
        case 18:
        case 17:
          return "Stand";
        case 16:
        case 15:
        case 14:
        case 13:
          if (upcard >= 7){ // hit except on dealer bust card
            return "Hit";
          } else {return "Stand";}
        case 12:
          if (upcard >= 7 || upcard <= 3){ // hit except on dealer bust card
            return "Hit";
          } else {return "Stand";}
        case 11:
          if (cards.length == 2){ return "Double";} //always double 11
          else {return "Hit";}
        case 10:
          if (cards.length == 2 && upcard <= 9){ return "Double";} // double 10 except on 10 or ace
          else {return "Hit";}
        case 9:
          if (cards.length == 2 && upcard <= 6 && upcard >= 3){ return "Double";} //double 9 on dealer 3-7
          else {return "Hit";}
        case 8:
        case 7:
        case 6:
        case 5:
        case 4:
          return "Hit";
      }
    }
    return "INCORRECT INPUT"; // all feasible inputs should have returned something

  }

bool splitPair(int cardval, int upcard) {
  // given paired card value and dealer upcard, returns true if we split the pair and false otherwise
  if (cardval == 8 || cardval == 11){
    return true;
  } else if ((cardval == 2 || cardval == 3 || cardval == 7) && upcard <= 7){
    return true;
  } else if (cardval == 6 && upcard <= 6){
    return true;
  } else if (cardval == 4 && (upcard == 5 || upcard == 6)){
    return true; 
  } else if (cardval == 9 && (upcard <= 6 || upcard == 8 || upcard == 9)){
    return true;
  } else{
    return false;
  }
}