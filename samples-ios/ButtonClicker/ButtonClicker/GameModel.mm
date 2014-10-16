//
//  GameModel.mm
//  ButtonClicker
//
//  Copyright (c) 2014 Google. All rights reserved.
//
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

#import "GameModel.h"
#import "ButtonClickerEngine.h"
#import "ButtonClickerPlayer.h"

@interface GameModel () {
  CFTimeInterval _startTime;
  NSString *_localPlayerId;
  CFTimeInterval _gameOverTimeoutTime;
}
@property (atomic) NSMutableDictionary *allPlayers;
@end

static const double kTotalGameTime = 20.0;


@implementation GameModel

/*
 * init the instance
 */
- (id)init
{
  self = [super init];
  if (self) {
    // Custom intiialization here
  }
  return self;
}

/*
 * prepare the game
 */
- (void)prepareToStart {
  gpg::RealTimeRoom room = ButtonClickerEngine::GetInstance().GetCurrentRoom();
  std::vector<gpg::MultiplayerParticipant> participants = room.Participants();
  NSInteger numPlayers = participants.size() + 1;
  _allPlayers = [[NSMutableDictionary alloc] initWithCapacity:numPlayers];

  // Let's populate our player list from the room. This now includes the local player
  for (gpg::MultiplayerParticipant player : participants)
  {
    ButtonClickerPlayer *nextPlayer = [[ButtonClickerPlayer alloc] init];
    nextPlayer.participantId = [NSString stringWithUTF8String:player.Id().c_str()];
    nextPlayer.displayName = [NSString stringWithUTF8String:player.DisplayName().c_str()];
    [self.allPlayers setObject:nextPlayer forKey:nextPlayer.participantId];
    NSLog(@"Adding player %@ -- %@", nextPlayer.displayName, nextPlayer.participantId);
  }

  _localPlayerId = [NSString stringWithUTF8String:
    ButtonClickerEngine::GetInstance().GetLocalPlayerParticipantId().c_str()];
  _gameState = BCGameStateWaitingToStart;
}

/*
 * start the game which is ready
 */
- (void)startGame {
  if (_gameState == BCGameStateWaitingToStart) {
    _gameState = BCGameStatePlaying;
    _startTime = CACurrentMediaTime();
  }
}

/*
 * ButtonClickerGameDelegate callback invoked when other players score is received
 * participantId : participantId of a player posted the score
 * reportedScore : updated score
 * isFinal : indicates whether the score is final one
 */
- (void)playerWithId:(NSString *)participantId reportedScore:(int)newScore isFinal:(BOOL)isFinal {
  if ([self.allPlayers objectForKey:participantId]) {
    ButtonClickerPlayer *opponent =
        (ButtonClickerPlayer *)[self.allPlayers objectForKey:participantId];
    // Some commands could arrive out of order, so we can probably ignore any case where the
    // score has gone down.
    if (newScore > opponent.score) {
      opponent.score = newScore;
    }
    if (isFinal) {
      opponent.scoreIsFinal = YES;
    }
  } else {
    NSLog(@"This is odd. Received a score updated for a player not on my list?!");
  }
}

/*
 * Sort players in descending order
 */
- (NSArray *)getListOfPlayersSortedByScore {
  NSArray *sortedPlayers = [[self.allPlayers allValues]
    sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    if ([(ButtonClickerPlayer *)obj1 score] < [(ButtonClickerPlayer *)obj2 score]) {
      return NSOrderedDescending;
    } else if ([(ButtonClickerPlayer *)obj1 score] > [(ButtonClickerPlayer *)obj2 score]) {
      return NSOrderedAscending;
    } else {
      return NSOrderedSame;
    }
  }];

  return sortedPlayers;
}

/*
 * returns time left for the game
 */
- (CFTimeInterval)timeLeft {
  CFTimeInterval timeLeft = MAX(0, kTotalGameTime - (CACurrentMediaTime() - _startTime));
  return timeLeft;
}

/*
 * update player set
 */
- (void)refreshPlayerSet {
  gpg::RealTimeRoom room = ButtonClickerEngine::GetInstance().GetCurrentRoom();
  std::vector<gpg::MultiplayerParticipant> participants = room.Participants();

  for (gpg::MultiplayerParticipant nextPlayer : participants)
  {
    NSLog(@"I have participant %s with status %d", nextPlayer.DisplayName().c_str(), nextPlayer.Status());
    if (nextPlayer.Status() == gpg::ParticipantStatus::LEFT) {
      ((ButtonClickerPlayer *)[self.allPlayers objectForKey:[NSString stringWithUTF8String:nextPlayer.Id().c_str()]])
      .scoreIsFinal = YES;
    } else if (nextPlayer.Status() == gpg::ParticipantStatus::JOINED
      && [self.allPlayers objectForKey:[NSString stringWithUTF8String:nextPlayer.Id().c_str()]] == nil) {
      NSLog(@"Looks like we added a player late.");
      ButtonClickerPlayer *newlyJoinedPlayer = [[ButtonClickerPlayer alloc] init];
      newlyJoinedPlayer.participantId = [NSString stringWithUTF8String:nextPlayer.Id().c_str()];
      newlyJoinedPlayer.displayName = [NSString stringWithUTF8String:nextPlayer.DisplayName().c_str()];
      [self.allPlayers setObject:newlyJoinedPlayer forKey:newlyJoinedPlayer.participantId];
    }
  }

  [self updateStateIfNeeded];
}

/*
 * update game state
 */
- (void)updateStateIfNeeded {
  if (_gameState == BCGameStatePlaying) {
    if (self.timeLeft <= 0) {
      ButtonClickerPlayer *me =
        (ButtonClickerPlayer *)[self.allPlayers objectForKey:_localPlayerId];
      me.scoreIsFinal = YES;
      ButtonClickerEngine::GetInstance().BroadcastScore(me.score, true);
      _gameState = BCGameStateWaitingToFinish;
      // We could probably be more sophisticated here
      _gameOverTimeoutTime = CACurrentMediaTime() + 10.0;
    }
  } else if (_gameState == BCGameStateWaitingToFinish) {
    // Timed out! Let's mark everybody else as finished
    if (CACurrentMediaTime() >= _gameOverTimeoutTime) {
      for (ButtonClickerPlayer *nextPlayer in [self.allPlayers allValues]) {
        nextPlayer.scoreIsFinal = YES;
        NSLog(@"Marking score as final");
      }
    }

    BOOL allFinished = YES;
    for (ButtonClickerPlayer *nextPlayer in [self.allPlayers allValues]) {
      if (!nextPlayer.scoreIsFinal) {
        allFinished = NO;
      }
    }
    if (allFinished) {
      _gameState = BCGameStateDone;
    }
  }

}

/*
 * Selector connected to the clicker button
 */
- (void)playerDidClick {
  [self updateStateIfNeeded];
  if (_gameState != BCGameStatePlaying)
    return;
  ButtonClickerPlayer *me = (ButtonClickerPlayer *)[self.allPlayers objectForKey:_localPlayerId];
  me.score++;

  ButtonClickerEngine::GetInstance().BroadcastScore(me.score, false);
}


@end
