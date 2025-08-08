class AppSounds {
  // Background Music
  static const String backgroundMusic = 'sounds/background_music.mp3';
  
  // Game Sounds
  static const String correctAnswer = 'sounds/correct.mp3';
  static const String incorrectAnswer = 'sounds/incorrect.mp3';
  static const String gameComplete = 'sounds/game_complete.mp3';
  static const String levelUp = 'sounds/level_up.mp3';
  static const String celebration = 'sounds/celebration.mp3';
  
  // UI Sounds
  static const String buttonClick = 'sounds/click.mp3';
  static const String buttonHover = 'sounds/hover.mp3';
  static const String pageTransition = 'sounds/transition.mp3';
  
  // Character Sounds
  static const String mascotWelcome = 'sounds/mascot_welcome.mp3';
  static const String mascotEncouragement = 'sounds/mascot_encouragement.mp3';
  static const String mascotCelebration = 'sounds/mascot_celebration.mp3';
  static const String mascotTryAgain = 'sounds/mascot_try_again.mp3';
  
  // Number Sounds (Arabic)
  static const String number1 = 'sounds/numbers/one.mp3';
  static const String number2 = 'sounds/numbers/two.mp3';
  static const String number3 = 'sounds/numbers/three.mp3';
  static const String number4 = 'sounds/numbers/four.mp3';
  static const String number5 = 'sounds/numbers/five.mp3';
  static const String number6 = 'sounds/numbers/six.mp3';
  static const String number7 = 'sounds/numbers/seven.mp3';
  static const String number8 = 'sounds/numbers/eight.mp3';
  static const String number9 = 'sounds/numbers/nine.mp3';
  static const String number10 = 'sounds/numbers/ten.mp3';
  static const String number11 = 'sounds/numbers/eleven.mp3';
  static const String number12 = 'sounds/numbers/twelve.mp3';
  static const String number13 = 'sounds/numbers/thirteen.mp3';
  static const String number14 = 'sounds/numbers/fourteen.mp3';
  static const String number15 = 'sounds/numbers/fifteen.mp3';
  static const String number16 = 'sounds/numbers/sixteen.mp3';
  static const String number17 = 'sounds/numbers/seventeen.mp3';
  static const String number18 = 'sounds/numbers/eighteen.mp3';
  static const String number19 = 'sounds/numbers/nineteen.mp3';
  static const String number20 = 'sounds/numbers/twenty.mp3';
  
  // Shape Sounds (Arabic)
  static const String circle = 'sounds/shapes/circle.mp3';
  static const String square = 'sounds/shapes/square.mp3';
  static const String triangle = 'sounds/shapes/triangle.mp3';
  static const String rectangle = 'sounds/shapes/rectangle.mp3';
  static const String star = 'sounds/shapes/star.mp3';
  
  // Color Sounds (Arabic)
  static const String red = 'sounds/colors/red.mp3';
  static const String blue = 'sounds/colors/blue.mp3';
  static const String yellow = 'sounds/colors/yellow.mp3';
  static const String green = 'sounds/colors/green.mp3';
  static const String orange = 'sounds/colors/orange.mp3';
  static const String purple = 'sounds/colors/purple.mp3';
  
  // Encouragement Phrases (Arabic)
  static const List<String> encouragementSounds = [
    'sounds/phrases/great_job.mp3',
    'sounds/phrases/excellent.mp3',
    'sounds/phrases/well_done.mp3',
    'sounds/phrases/fantastic.mp3',
    'sounds/phrases/amazing.mp3',
  ];
  
  static const List<String> tryAgainSounds = [
    'sounds/phrases/try_again.mp3',
    'sounds/phrases/almost_there.mp3',
    'sounds/phrases/keep_trying.mp3',
    'sounds/phrases/you_can_do_it.mp3',
  ];
  
  // Helper Methods
  static String getNumberSound(int number) {
    const Map<int, String> numberSounds = {
      1: number1,
      2: number2,
      3: number3,
      4: number4,
      5: number5,
      6: number6,
      7: number7,
      8: number8,
      9: number9,
      10: number10,
      11: number11,
      12: number12,
      13: number13,
      14: number14,
      15: number15,
      16: number16,
      17: number17,
      18: number18,
      19: number19,
      20: number20,
    };
    return numberSounds[number] ?? '';
  }
  
  static String getShapeSound(String shape) {
    const Map<String, String> shapeSounds = {
      'circle': circle,
      'square': square,
      'triangle': triangle,
      'rectangle': rectangle,
      'star': star,
    };
    return shapeSounds[shape] ?? '';
  }
  
  static String getColorSound(String color) {
    const Map<String, String> colorSounds = {
      'red': red,
      'blue': blue,
      'yellow': yellow,
      'green': green,
      'orange': orange,
      'purple': purple,
    };
    return colorSounds[color] ?? '';
  }
}

