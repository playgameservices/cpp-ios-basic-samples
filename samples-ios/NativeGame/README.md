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
2. Create an achievement named "Gone Native" (or a different name, but you will need
  to modify the code to match the name).
3. Create a leaderboard named "Native Leaders" (or a different name, but you will
  need to modify the code to match the name).

After you have configured the game on the Play Console, follow these steps:

4. In a terminal window, change directories to this directory and add the cocoapod project
to the workspace.  To do this run `pod update`.
5. Open the NativeGame workspace: `open NativeGame.xcworkspace`.
6. Open project settings. Select the "NativeGame" target and,
  on the "Summary" tab, change the Bundle Identifier to
  something appropriate for your Provisioning Profile. (It will probably look like
  com.<your_company>.NativeGame) and the package name in the play console.
7. Return to the Play Console, and in your game configuration, select Achievements.
  At the bottom of the list, click "Get Resources" and select Objective-C.
  Copy the definitions to the clipboard.  Then back in XCode, open the file
  GPGSIds.h and paste the resource definitions.
8. Click the "Info" tab and go down to the bottom where you see "URL Types".
  You need to add 2 URL types.  In one URL type, the Identifier needs to be
  a unique string such as com.google.ReverseClientId.  Specify your client ID
  in reversed order in the URL Schemas field. For example, if your client ID for iOS is
  YOUR_CLIENT_ID_CODE.apps.googleusercontent.com, then specify
  com.googleusercontent.apps.YOUR_CLIENT_ID in the URL Schemas field.
  In the other URL type, specify a unique string in the Identifier field,
  such as "BundleId".  Specify your app's bundle identifier in the URL Schemas field.

That's it! Your application should be ready to run!

