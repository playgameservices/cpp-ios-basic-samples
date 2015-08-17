# Button Clicker

A native client sample application that demonstrates some simple real-time multiplayer using both
invites and matchmaking with strangers. It's also compatible with the Android version
for some cross-platform button-clicking excitement!

## Code

Button Clicker consists of a number of files that might be of interest to you:

* `AppDelegate` contains some of the code required to handle incoming notifications

* `ButtonClickerPlayer` contains a very simple class that represents our player in
the game.

* `GameModel` is the game's model. It supplies information about all the players
in the game for your ViewController.

* `GameViewController` is the ViewController for the game itself. This contains the
gameplay elements, a scoreboard, and some debug buttons to leave the game early and
simulate a crash.

* `ButtonClickerEngine` is a singleton class that handles all of the multiplayer logic.
It contains all of the gpg::IRealTimeEventListener methods and also has delegates that
point to the lobby and game view controllers, so that it can alert them when important
messages are received from the network

* `LobbyViewController` contains methods that handle sign-in and create real-time
mutliplayer games, either through invites or through automatching.

* `Main.storyboard` is the main storyboard used by the application. We currently
use the same storyboard for both iPhone and iPad games

## Running the sample application

To run Button Clicker on your own device, you will need to create
your own version of the game in the Play Console and copy over some information to
your Xcode project. To follow this process, perform the following steps:

1, In a terminal window, change directories to this directory and add the cocoapod project
    to the workspace.  To do this run `pod update`.
2. Open the ButtonClicker workspace: `open ButtonClicker.xcworkspace`.
3. Open project settings. Select the "Button Clicker" target and,
  on the "Summary" tab, change the Bundle Identifier from `com.example.ButtonClicker` to
  something appropriate for your Provisioning Profile. (It will probably look like
  `com.<your_company>.ButtonClicker`)
4. Create your own application in the Play Console, as described in our [Developer
  Documentation](https://developers.google.com/games/services/console/enabling). Make
  sure you follow the "iOS" instructions for creating your client ID and linking
  your application.
    * If you have already created an application (because you tested the Android version,
  for instance), you can use that application, and just add a new linked iOS client to the same
  application.
    * Again, you will be using the Bundle ID that you created in Step 1.
    * You can leave your App Store ID blank for testing purposes.
    * Don't forget to turn on the "Real-time multiplayer" switch!
5. If you want to try out receiving invites, you will need to get an APNS certificate
  from iTunes Connect and upload it to the developer console as well. Please review our
  documentation for how to do this.
6. Make a note of your client ID and application ID as described in the
  documentation
7. Click the "Info" tab and go down to the bottom where you see "URL Types".
  You need to add 2 URL types.  In one URL type, the Identifier needs to be
  the unique string `com.google.ReverseClientId`. Specify your client ID
  in reversed order in the URL Schemas field. For example, if your client ID
  for iOS is `YOUR_CLIENT_ID.apps.googleusercontent.com`, then specify
  `com.googleusercontent.apps.YOUR_CLIENT_ID` in the URL Schemas field.
  In the other URL type, specify a unique string in the Identifier field,
  `com.google.BundleId`.  Specify your app's bundle identifier in the
  URL Schemas field.

That's it! Your application should be ready to run!  Give it a try, and add some button-clicking
excitement to your evening!

## Known issues

* We should probably add some icons and other supporting graphics. Any artists out there?
