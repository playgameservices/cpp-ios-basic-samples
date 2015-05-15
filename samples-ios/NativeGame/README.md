# NativeGame Sample

A sample application that demonstrates leaderboard and achievement calls from a native
C++ application. 
This sample is using C++ NativeClient SDK with conjunction of ObjectiveC++.

## Code

Native Game  consists of a number of files that might be of interest to
you:

* `AppDelegate` contains a little code required to handle sign-in (but not
  much -- just the URL handler).

* `StateManager` contains the code to manage the signin state, and make the
   API calls to interact with the game services.

* `ViewController` is the ViewController for the game itself. It contains much
  of the logic to display the user interface.  ViewController.mm also has the constants
  used to reference the achievement and leaderboard.

## Running the sample application

To run NativeGame on your own device, you will need to create your
own version of the game in the Play Console.  You will need to create at least one
achievement and one leaderboard.
1. Create your own application in the Play Console, as described in our [Developer
  Documentation](https://developers.google.com/games/services/console/enabling). Make
  sure you follow the "iOS" instructions for creating your client ID and linking
  your application.
    <strong>Note: Remember the Bundle ID, you will need to paste it 
         in a couple places in your app.</strong>
    You can leave your App Store ID blank for testing purposes.
2. Make a note of your client ID and application ID as described in the
  documentation.
3. Create an achievement (or more if you want) and a leaderboard.

After you have configured the game on the Play Console, follow these steps:

4. In a terminal window, change directories to this directory and add the cocoapod project
to the workspace.  To do this run `pod update`.
5. Open the NativeGame workspace: `open NativeGame.xcworkspace`.
6. Open project settings. Select the "NativeGame" target and,
  on the "Summary" tab, change the Bundle Identifier to
  something appropriate for your Provisioning Profile. (It will probably look like
  com.<your_company>.CollectAllTheStars) and the package name in the play console.
7. Click the "Info" tab and go down to the bottom where you see "URL Types". Expand
  this and change the "Identifier" and "URL Schemes" from the default package name to
  whatever you used in Step 3.
8. If you have already created this application in the Play Console (because you
  have created the Android or web version of the game, for example), you can
  skip steps 4 and 5 below. All you will need to do is...
    * Link the iOS version of your game, as described in the "Link Your Platform-
      Specific Apps" section of the console documentation
    * Create a separate client ID for the iOS version of the game, as described in
      the "Create a client ID" section of the [Console Documentation](https://developers.google.com/games/services/console/enabling).
        * Use the Bundle ID that you created in Step 1.
9. Once that's done, open up your `ViewController.mm` file, and replace the `CLIENT_ID` value
  with your own OAuth2.0 client ID, Achievement ID and Leaderboard ID.

That's it! Your application should be ready to run! 

