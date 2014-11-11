Google Play Games C++ SDK Samples for iOS
=========================================

Copyright (C) 2014 Google Inc.

<h2>Contents</h2>

These samples illustrate how to use Google Play Game Services with your iOS game.

* **CollectAllTheStars**: Demonstrates how to use the Saved Games feature to save game data. The sample signs the player in, synchronizes their data from a named game save, and then updates the UI to reflect the saved game state.

* **TrivialQuest**: Demonstrates how to use the Events and Quests features of Google Play Game Services. The sample displays a sign-in button and four buttons to simulate killing monsters. Clicking a button generates an event, and sends it to Google Play Game Services to track what the player is doing in the game.

* **TypeANumber**: Shows leaderboards and achievements. In this exciting game, the player decides and enters his or her "deserved" score. But, wait--there's a twist! Playing the game in "easy" mode gets the player the requested score. But, in "hard" mode, he or she only gets half! Can you handle the challenge?

* **TbmpSkeleton**: A trivial, turn-based multiplayer game.  Many players can play together in this thrilling game, in which they send a shared gamestate string back and forth until someone finishes or cancels, or the second-to-last player leaves. Be the last one standing!

* **Button-Clicker**: Demonstrates real-time multiplayer using invites or quickmatch. The sample allows cross platform game play across iOS, Android

**Note:** In samples with corresponding counterparts for iOS and Web (particularly, CollectAllTheStars and TypeANumber), the player can play a game seamlessly across phones of different platforms. For example, you can play some levels of CollectAllTheStars on your Android device, and then pick up your iOS device and continue where you left off! TypeANumber shows your achievements and leaderboards on all platforms; when you make progress on one platform, that progress is reflected on the other devices, as well.

<h2>How to run a sample</h2>
To use these samples, you need the Google Play Game Services C++ SDK, which you
can [download from here](https://developers.google.com/games/services/downloads/).

After downloading the archive, unzip it to the  `./gpg-cpp-sdk` directory. Then, follow [these directions](https://developers.google.com/games/services/cpp/GettingStartedNativeClient).

<h2>Acknowledgment</h2>
Some of these samples use the following open-source project:
JASONCPP: https://github.com/open-source-parsers/jsoncpp

