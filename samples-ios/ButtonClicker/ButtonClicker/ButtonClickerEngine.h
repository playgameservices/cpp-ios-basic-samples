//  Copyright (c) 2014 Google. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#ifndef BUTTONCLICKERENGINE_H_
#define BUTTONCLICKERENGINE_H_

/*
 * Include files
 */
#include <errno.h>
#include <sstream>
#include <algorithm>
#include <thread>
#include <unordered_map>

// iOS include files
#include <CoreFoundation/CoreFoundation.h>
#include <objc/NSObjCRuntime.h>

// For GPGS
#include <gpg/gpg.h>
#include "Constants.h"

/*
 * Delegate definitions for ObjC bridge
 */
@protocol ButtonClickerGameDelegate<NSObject>
@optional
- (void)readyToStartMultiPlayerGame;
- (void)playerWithId:(NSString *)playerId reportedScore:(int)score isFinal:(BOOL)final;
- (void)playerSetMayHaveChanged;
- (void)signInStatusChanged;
@end

//
//Logging for CoreFoundation
//
const int32_t BUFFER_SIZE = 256;
#define LOGI(...) {\
  char c[BUFFER_SIZE];\
  snprintf(c,BUFFER_SIZE,__VA_ARGS__);\
  NSString* str = [NSString stringWithUTF8String:c];\
  NSLog(str, nil);\
}

/*
 * Preprocessors
 */
const int32_t MIN_PLAYERS = 1;
const int32_t MAX_PLAYERS = 3;
const double GAME_DURATION = 20.0;

enum NEXT_PARTICIPANT {
  NEXT_PARTICIPANT_AUTOMATCH = -1,
  NEXT_PARTICIPANT_NONE = -2,
};

struct PLAYER_STATUS {
  int32_t score;
  bool finished;
};

/*
 * Engine class of the sample
 */
class ButtonClickerEngine : public gpg::IRealTimeEventListener {
 public:
  // Retreive Singleton
  static ButtonClickerEngine& GetInstance();

  // Engine life cycles
  ButtonClickerEngine();
  ~ButtonClickerEngine();

  //Gpg service instance
  std::unique_ptr<gpg::GameServices>& GetGpgService();

  void SetGpgDelegate(id<ButtonClickerGameDelegate>);

  // GPG-related methods
  void InitGooglePlayGameServices();
  void InviteFriend(const int32_t min_players = MIN_PLAYERS,
                    const int32_t max_players = MAX_PLAYERS);
  void ShowRoomInbox();

  void PlayGame();
  void LeaveGame();
  void QuickMatch(const int32_t numPlayers = MAX_PLAYERS);

  // Sign-in/out and status check for GPG services
  bool IsSignedIn();

  // Retrieve current room object
  gpg::RealTimeRoom GetCurrentRoom();

  // Local player's ID
  std::string GetLocalPlayerParticipantId();

  void BroadcastScore(int32_t score, bool bFinal);

  // IRealTimeEventListener members
  virtual void OnRoomStatusChanged(gpg::RealTimeRoom const &room);

  virtual void OnParticipantStatusChanged(
      gpg::RealTimeRoom const &room,
      gpg::MultiplayerParticipant const &participant);

  virtual void OnDataReceived(
      gpg::RealTimeRoom const &room,
      gpg::MultiplayerParticipant const &from_participant,
      std::vector<uint8_t> data, bool is_reliable);

  // We are not using these callbacks below
  // because the app just waits for the room to become active,
  // no need to inspect individual changes
  virtual void OnConnectedSetChanged(gpg::RealTimeRoom const &room) {}

  virtual void OnP2PConnected(gpg::RealTimeRoom const &room,
                              gpg::MultiplayerParticipant const &participant) {}
  virtual void OnP2PDisconnected(
      gpg::RealTimeRoom const &room,
      gpg::MultiplayerParticipant const &participant) {}

 private:
  // Callbacks for GPG authentication.
  void OnAuthActionStarted(gpg::AuthOperation op);
  void OnAuthActionFinished(gpg::AuthOperation op, gpg::AuthStatus status);

  // Helper function for waiting room & game play
  void ShowWaitingRoomAndPlayGame(const int32_t min_players);

  std::unique_ptr<gpg::GameServices> service_;  // gpg service instance
  gpg::RealTimeRoom room_;  // room status. This variable is updated each time
                            // the room status is updated in OnRoomStatusChanged()
  bool authorizing_;        // Am I signing in to gpg service?
  std::string self_id_;     // Local player's ID
  std::string self_participant_id_;     // Local player's Participant ID

  id<ButtonClickerGameDelegate> gpg_delegate_;

};

#endif  // BUTTONCLICKERENGINE_H_
