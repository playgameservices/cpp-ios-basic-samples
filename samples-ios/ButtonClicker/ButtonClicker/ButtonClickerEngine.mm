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

/*
 * This file demonstrates,
 * - How to use RTMP features in C++ code with gpg native client, including
 *   - Sign in to gpg service
 *   - How to handle RTMP callbacks
 *   - How to initiate RTMP matchs via several ways (QuickMatch, Invitation etc)
 *   - How to send reliable/unreliable packets to peers
 * - Setup management UI and game UI
 */

/*
 * Include files
 */
#include "ButtonClickerEngine.h"

/*
 * Retrieve Singleton instance
 */
ButtonClickerEngine& ButtonClickerEngine::GetInstance()
{
  static ButtonClickerEngine engine;
  return engine;
}

/*
 * Constructor
 */
ButtonClickerEngine::ButtonClickerEngine(): gpg_delegate_(nil)
{

}

/*
 * Destructor
 */
ButtonClickerEngine::~ButtonClickerEngine()
{

}

/*
 * Retrieve Gpg service
 */
std::unique_ptr<gpg::GameServices>& ButtonClickerEngine::GetGpgService()
{
  return service_;
}

/*
 * Set delegate interface
 */
void ButtonClickerEngine::SetGpgDelegate(id<ButtonClickerGameDelegate>  delegate)
{
  gpg_delegate_ = delegate;
}

/*
 * Initialize GooglePlayGameServices via gpg::GameServices::Builder
 * In the build, it's setting several callbacks such as auth status changes,
 * receiving invitations etc.
 */
void ButtonClickerEngine::InitGooglePlayGameServices() {
  if (service_ != nullptr) {
    return;
  }

  // Game Services have not been initialized, create a new Game Services.
  gpg::IosPlatformConfiguration platform_configuration;
  platform_configuration.SetClientID(ReadClientId());

  gpg::GameServices::Builder builder;
  service_ = builder.SetOnAuthActionStarted([this](gpg::AuthOperation op) {
      // This callback is invoked when auth action started
      // While auth action is going on, disable auth and related UI
      OnAuthActionStarted(op);
    })
    .SetOnAuthActionFinished([this](gpg::AuthOperation op,
                                    gpg::AuthStatus status) {
      // This callback is invoked when auth action finished
      // Check status code and update UI to signed-in state
      OnAuthActionFinished(op, status);
    })
    .SetOnMultiplayerInvitationEvent([this](
         gpg::MultiplayerEvent event, std::string match_id,
         gpg::MultiplayerInvitation invitation) {
      // Invoked when the invitation has been received from the Play Game
      // app or a notification center.
      LOGI("MultiplayerInvitationEvent callback");

      if (event == gpg::TurnBasedMultiplayerEvent::UPDATED_FROM_APP_LAUNCH) {
        // In this case, an invitation has been accepted already
        // in notification or in Play game app
        gpg::RealTimeMultiplayerManager::RealTimeRoomResponse result =
            service_->RealTimeMultiplayer().AcceptInvitationBlocking(
                invitation, this);
        if (gpg::IsSuccess(result.status)) {
          room_ = result.room;
          service_->RealTimeMultiplayer().ShowWaitingRoomUI(
              room_, MIN_PLAYERS,
              [this](gpg::RealTimeMultiplayerManager::
                        WaitingRoomUIResponse const &waitResult) {
                if (gpg::IsSuccess(waitResult.status)) {
                  PlayGame();
                }
              });
        } else {
          LeaveGame();
        }
      } else {
        // Otherwise, show default inbox and let players to accept an
        // invitation
        ShowRoomInbox();
      }
    })
    .Create(platform_configuration);
}

/*
 * Callback: Authentication action started
 *
 * gpg::AuthOperation op : SIGN_IN = 1, SIGN_OUT = 2
 *
 */
void ButtonClickerEngine::OnAuthActionStarted(gpg::AuthOperation op) {
  authorizing_ = true;
  if (op == gpg::AuthOperation::SIGN_IN) {
    LOGI("Signing in to GPG");
  } else {
    LOGI("Signing out from GPG");
  }
}

/*
 * Callback: Authentication action finishes
 *
 * gpg::AuthOperation op : SIGN_IN = 1, SIGN_OUT = 2
 * gpg::AuthStatus status : VALID, or ERROR_* indicating error reasons
 *
 */
void ButtonClickerEngine::OnAuthActionFinished(gpg::AuthOperation op,
                                  gpg::AuthStatus status) {
  if (gpg::IsSuccess(status)) {
    service_->Players().FetchSelf([this](
        gpg::PlayerManager::FetchSelfResponse const &response) {
      if (gpg::IsSuccess(response.status)) {
        self_id_ = response.data.Id();
      }

      if ([gpg_delegate_ respondsToSelector:@selector(signInStatusChanged)])
      {
        // Invoke delegate
        [gpg_delegate_ signInStatusChanged];
      }
    });
  } else {
    if ([gpg_delegate_ respondsToSelector:@selector(signInStatusChanged)])
    {
      // Invoke delegate
      [gpg_delegate_ signInStatusChanged];
    }
  }
}

/*
 * Check if it's signed in to gpg services
 */
bool ButtonClickerEngine::IsSignedIn()
{
  if (service_ == nullptr)
    return false;
  return service_->IsAuthorized();
}

/*
 * Show room inbox
 */
void ButtonClickerEngine::ShowRoomInbox() {
  service_->RealTimeMultiplayer().ShowRoomInboxUI([this](
      gpg::RealTimeMultiplayerManager::RoomInboxUIResponse const &response) {
    if (gpg::IsSuccess(response.status)) {
      gpg::RealTimeMultiplayerManager::RealTimeRoomResponse result =
          service_->RealTimeMultiplayer().AcceptInvitationBlocking(
              response.invitation, this);
      if (gpg::IsSuccess(result.status)) {
        room_ = result.room;
        ShowWaitingRoomAndPlayGame(MIN_PLAYERS);
      }
    } else {
      LOGI("Invalid response status %d", response.status);
    }
  });
}

/*
 * Create a match with minimal setting and play the game
 * numPlayers: Number of players in a creating match
 */
void ButtonClickerEngine::QuickMatch(const int32_t numPlayers) {
  gpg::RealTimeRoomConfig config =
      gpg::RealTimeRoomConfig::Builder()
          .SetMinimumAutomatchingPlayers(MIN_PLAYERS)
          .SetMaximumAutomatchingPlayers(numPlayers)
          .Create();

  service_->RealTimeMultiplayer().CreateRealTimeRoom(
      config, this,
      [this](gpg::RealTimeMultiplayerManager::RealTimeRoomResponse const &
                 response) {
        LOGI("created a room %d", response.status);
        if (gpg::IsSuccess(response.status)) {
          room_ = response.room;
          ShowWaitingRoomAndPlayGame(MIN_PLAYERS);
        }
      });
}

/*
 * Show Player Select UI via ShowPlayerSelectUI,
 * When the UI is finished, create match and show game UI
 * min_players: Minimum # of players allowed in the match
 * max_players: Maximum # of players allowed in the match
 */
void ButtonClickerEngine::InviteFriend(const int32_t min_players, const int32_t max_players) {
  service_->RealTimeMultiplayer().ShowPlayerSelectUI(
      min_players, max_players, true,
      [this, min_players](gpg::RealTimeMultiplayerManager::PlayerSelectUIResponse const &
                 response) {
        LOGI("inviting friends %d", response.status);
        if (gpg::IsSuccess(response.status)) {
          // Create room
          gpg::RealTimeRoomConfig config =
              gpg::RealTimeRoomConfig::Builder()
                  .PopulateFromPlayerSelectUIResponse(response)
                  .Create();

          auto roomResponse =
              service_->RealTimeMultiplayer().CreateRealTimeRoomBlocking(config,
                                                                         this);
          if (gpg::IsSuccess(roomResponse.status)) {
            room_ = roomResponse.room;
            ShowWaitingRoomAndPlayGame(min_players);
          }
        }
      });
}

/*
 * Broadcast my score to peers
 * score: Score to post
 * bFinal: Indicate if the score is final score. Final score is sent via reliable protocol.
 */
void ButtonClickerEngine::BroadcastScore(int32_t score, bool bFinal) {
  std::vector<uint8_t> v;
  if (!bFinal) {
    v.push_back('U');
    v.push_back(static_cast<uint8_t>(score));
    service_->RealTimeMultiplayer().SendUnreliableMessageToOthers(room_, v);
  } else {
    v.push_back('F');
    v.push_back(static_cast<uint8_t>(score));

    const std::vector<gpg::MultiplayerParticipant> participants =
        room_.Participants();
    for (gpg::MultiplayerParticipant participant : participants) {
      service_->RealTimeMultiplayer().SendReliableMessage(
          room_, participant, v, [](gpg::MultiplayerStatus const &) {});
    }
  }
}

/*
 * Got message from peers
 * room : The room which from_participant is in.
 * from_participant : The participant who sent the data.
 * data : The received data.
 * is_reliable : Whether the data was sent using the unreliable or
 *                    reliable mechanism.
 * In this app, packet format is defined as:
 * 1 byte: indicate score type 'F': final score 'U' updating score
 * 1 byte: score
 */
void ButtonClickerEngine::OnDataReceived(gpg::RealTimeRoom const &room,
                            gpg::MultiplayerParticipant const &from_participant,
                            std::vector<uint8_t> data, bool is_reliable) {
  if (data[0] == 'F' && is_reliable) {
    // Got final score
    LOGI("Got final data from Dispname:%s ID:%s",
         from_participant.DisplayName().c_str(), from_participant.Id().c_str());
    if ([gpg_delegate_ respondsToSelector:@selector(playerWithId:reportedScore:isFinal:)])
    {
      [gpg_delegate_ playerWithId:[NSString stringWithUTF8String:from_participant.Id().c_str()]
                    reportedScore:data[1]
                          isFinal:true];
    }

  } else if (data[0] == 'U' && !is_reliable) {
    // Got current score
    LOGI("Got data from Dispname:%s ID:%s",
      from_participant.DisplayName().c_str(), from_participant.Id().c_str());
    if ([gpg_delegate_ respondsToSelector:@selector(playerWithId:reportedScore:isFinal:)])
    {
      [gpg_delegate_ playerWithId:[NSString stringWithUTF8String:from_participant.Id().c_str()]
                    reportedScore:data[1]
                          isFinal:false];
    }
  }
}

/*
 * Room status change callback
 * room : RealTimeRoom object of the room that had status update.
 */
void ButtonClickerEngine::OnRoomStatusChanged(gpg::RealTimeRoom const &room) {
  room_ = room;

  // Check participant ID
  std::vector < gpg::MultiplayerParticipant > participants =
  room_.Participants();
  for (gpg::MultiplayerParticipant participant : participants) {
    if (participant.HasPlayer()
        && participant.Player().Id().compare(self_id_) == 0)
      self_participant_id_ = participant.Id(); // Skip local player
  }

  if ([gpg_delegate_ respondsToSelector:@selector(playerSetMayHaveChanged)])
  {
    [gpg_delegate_ playerSetMayHaveChanged];
  }
}

/*
 * Helper to show waitingRoom and play game
 * min_players : minimum # of players in the match
 */
void ButtonClickerEngine::ShowWaitingRoomAndPlayGame(const int32_t min_players)
{
  service_->RealTimeMultiplayer().ShowWaitingRoomUI(
    room_, min_players,
    [this](gpg::RealTimeMultiplayerManager::WaitingRoomUIResponse const &
           waitResult) {
      if (gpg::IsSuccess(waitResult.status)) {
        PlayGame();
      }
    });
}

/*
 * Retrieve current room
 */
gpg::RealTimeRoom ButtonClickerEngine::GetCurrentRoom()
{
  return room_;
}

/*
 * Retrieve local player's Id
 */
std::string ButtonClickerEngine::GetLocalPlayerParticipantId()
{
  return self_participant_id_;
}

/*
 * Invoked when participant status changed
 * room : RealTimeRoom object of current room
 * participant : MultiplayerParticipant object of a player that had status change
 */
void ButtonClickerEngine::OnParticipantStatusChanged(
    gpg::RealTimeRoom const &room,
    gpg::MultiplayerParticipant const &participant) {

  // Update participant status
  LOGI("Participant %s status changed: %d", participant.Id().c_str(),
       participant.Status());

  if ([gpg_delegate_ respondsToSelector:@selector(playerSetMayHaveChanged)])
  {
    [gpg_delegate_ playerSetMayHaveChanged];
  }
}

/*
 * Play games UI that is in your turn
 */
void ButtonClickerEngine::PlayGame() {
  LOGI("Playing match");

  //Tell delegate call back that it's ready to start a match
  if ([gpg_delegate_ respondsToSelector:@selector(readyToStartMultiPlayerGame)])
  {
    [gpg_delegate_ readyToStartMultiPlayerGame];
  }
}

/*
 * Leave game
 */
void ButtonClickerEngine::LeaveGame() {
  service_->RealTimeMultiplayer().LeaveRoom(
      room_, [](gpg::ResponseStatus const &status) {});

  LOGI("Game is over");
}

/*
 Reads the client id by looking at the url types configured.  One of the url types is
 the client id reversed.  If it is not there, it is an error in configuration, so
 it will be fixed sooner vs. a cryptic runtime auth error.

 reverseClientUrlName is the key of the url type which contains the reversed client id.
 */
const char* ButtonClickerEngine::ReadClientId(const char* reverseClientUrlName) {

    NSString *clientId = @"";
    NSDictionary *d = [NSBundle mainBundle].infoDictionary;

    // array of dictionaries of the url types;
    NSArray *urlTypes = [d objectForKey:@"CFBundleURLTypes"];

    for (NSDictionary* urlInfo in urlTypes)
    {
        NSString* name = [urlInfo objectForKey:@"CFBundleURLName"];
        if ([name isEqualToString:[NSString stringWithUTF8String:reverseClientUrlName]]) {
            NSArray* vals = [urlInfo objectForKey:@"CFBundleURLSchemes"];
            // only use  the first
            NSArray *parts = [(NSString*)[vals objectAtIndex:0] componentsSeparatedByString:@"."];
            for (int i= (int)[parts count] -1;i>=0;i--) {
                clientId = [clientId stringByAppendingString:[parts objectAtIndex:i]];
                clientId = [clientId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if ( i > 0) {
                    clientId = [clientId stringByAppendingString:@"."];
                }
            }
            break;
        }
    }
    if ([clientId length] <= 1) {
        [NSException raise:@"Invalid configuration" format:@"Client ID based URL Type not configured!"];
    }
    return (const char*)[clientId UTF8String];
}



