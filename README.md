Google Play Games C++ SDK Samples for iOS
=========================================

Copyright (C) 2014 Google Inc.

<h2>Contents</h2>

These samples illustrate how to use Google Play Game Services with your iOS game.

* **CollectAllTheStars**: Demonstrates how to use the Saved Games feature to save game data. The sample signs the player in, synchronizes their data from a named game save, and then updates the UI to reflect the saved game state.

* **NativeGame**: Demonstrates how to manage the signin process in C++ and display achievements and leaderboards.

* **TrivialQuest**: Demonstrates how to use the Events and Quests features of Google Play Game Services. The sample displays a sign-in button and four buttons to simulate killing monsters. Clicking a button generates an event, and sends it to Google Play Game Services to track what the player is doing in the game.

* **TbmpSkeleton**: A trivial, turn-based multiplayer game.  Many players can play together in this thrilling game, in which they send a shared gamestate string back and forth until someone finishes or cancels, or the second-to-last player leaves. Be the last one standing!

* **Button-Clicker**: Demonstrates real-time multiplayer using invites or quickmatch. The sample allows cross platform game play across iOS, Android

**Note:** In samples with corresponding counterparts for iOS and Web (particularly, CollectAllTheStars), the player can play a game seamlessly across phones of different platforms. For example, you can play some levels of CollectAllTheStars on your Android device, and then pick up your iOS device and continue where you left off! 

<h2>How to run a sample</h2>
The samples use [CocoaPods](https://cocoapods.org/) to manage the dependencies for the Google Play Game SDK.  You'll need to install CocoaPods before running the samples.

More information can be found in the  
[Getting Started](https://developers.google.com/games/services/cpp/GettingStartedNativeClient) guide.
