# Trivial Quest 2 #
This sample demonstrates how to use the Event-and-Quest feature of Google
Play Game Services. In this sample, the game displays a sign-in button, along with four colored buttons. Clicking each button causes the application to send an event to Google Play Game Services ("GPGS"), enabling GPGS to track the player's progress toward a milestone.

When the player reaches a milestone specified in a Quest, the game receives a callback with an object describing the Quest reward.


## Code

Trivial Quest  Game  consists of a number of files that might be of interest to
you:

* `AppDelegate` contains a little code required to handle sign-in (but not
  much -- just the URL handler).

* `ViewController` is the ViewController for the game itself. It contains much
  of the logic to display the user interface.  

## Running the sample application

To run TrivialQuest on your own device, you will need to create your
own version of the game in the Play Console.  You will need to create 4 events one for each 
color monster (blue, green, red, and yellow).

1. Create your own application in the Play Console, as described in our [Developer
  Documentation](https://developers.google.com/games/services/console/enabling). Make
  sure you follow the "iOS" instructions for creating your client ID and linking
  your application.
    <strong>Note: Remember the Bundle ID, you will need to paste it 
         in a couple places in your app.</strong>
    You can leave your App Store ID blank for testing purposes.
2. Make a note of your client ID and application ID as described in the
  documentation.
3. Create the events which are referenced in the application code.
4. Create one or more quests.  These are viewed in the game, but do not need to have
direct reference to the quest IDs.

After you have configured the game on the Play Console, follow these steps:

4. In a terminal window, change directories to this directory and add the cocoapod project
to the workspace.  To do this run `pod update`.
5. Open the TrivialQuest2 workspace: `open TrivialQuest2.xcworkspace`.
6. Open project settings. Select the "TrivialQuest2" target and,
  on the "Summary" tab, change the Bundle Identifier to
  what you entered in the Play Console.
7. Click the "Info" tab and go down to the bottom where you see "URL Types". Expand
  this and change the "Identifier" and "URL Schemes" to the Bundle ID.
9. Once that's done, open up your `Constants.h` file, and replace the `CLIENT_ID` value
  with your own OAuth2.0 client ID, and set the event ID constants.

That's it! Your application should be ready to run! 

