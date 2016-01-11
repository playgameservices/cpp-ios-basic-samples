//
//  GameModel.h
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

#import <Foundation/Foundation.h>
#import <gpg/gpg.h>

typedef NS_ENUM(NSInteger, BCGameState) {
  BCGameStateWaitingToStart,
  BCGameStatePlaying,
  BCGameStateWaitingToFinish,
  BCGameStateDone
};

@interface GameModel : NSObject
@property (nonatomic, readonly) CFTimeInterval timeLeft;
@property (nonatomic, readonly) BCGameState gameState;

/**
 * Get ready to start a new game! Reset our score to zero, and get ourselves into a
 * "Ready to start" phase
 */
- (void)prepareToStart;

/**
 * Actually start a game!
 */
- (void)startGame;

/**
 * The player clicked the button. Update the score and send it out, if applicable
 */
- (void)playerDidClick;

/**
 * We received word that an opponent has reached a particular score
 *
 * @param participantId The random string corresponding to this player in the match
 * @param newScore The new player's reported score
 * @param isFinal Is this the player's final score?
 */
- (void)playerWithId:(NSString *)participantId reportedScore:(int)newScore isFinal:(BOOL)isFinal;

/**
 * Get an array of ButtonClickerPlayer objects, sorted by their score
 *
 * @return An array of ButtonClickerPlayers, highest score first
 */
- (NSArray *)getListOfPlayersSortedByScore;

/**
 * Tell the model to check its state and update it if necessary
 */
- (void)updateStateIfNeeded;

/**
 * The list of connected players might have changed, so we might need to mark scores as final
 * for players that have left, add new players, and so on
 */
- (void)refreshPlayerSet;

@end
