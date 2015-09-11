//
//  ViewController.m
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

#import "GameData.h"
#import "GameViewController.h"
#import "LobbyViewController.h"

#import <GoogleSignIn.h>
//
// Constants
//
const int32_t MIN_PLAYERS = 1;
const int32_t MAX_PLAYERS = 3;


@interface LobbyViewController () <GIDSignInUIDelegate> {
  gpg::TurnBasedMatch matchToTransfer_;
  bool dismiss_;
  bool leave_;
  bool cancel_;
  bool rematch_;
}

@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *quickMatchButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteFriendsButton;
@property (weak, nonatomic) IBOutlet UIButton *viewMyMatchesButton;
@property BOOL authorizing;
@end

@implementation LobbyViewController

# pragma mark - Sign in stuff
/*
 * Initialize GooglePlayGameServices
 */
- (void)initializeGooglePlayGameServices
{
  gpg::IosPlatformConfiguration platform_configuration;
  platform_configuration.SetClientID([self readClientId].UTF8String)
  .SetOptionalViewControllerForPopups(self);

  [GIDSignIn sharedInstance].uiDelegate = self;

  if (service_ == nullptr) {
    // Game Services have not been initialized, create a new Game Services.
    gpg::GameServices::Builder builder;
    service_ = builder.SetOnAuthActionStarted([self](gpg::AuthOperation op) {
      [self OnAuthActionStarted:op];
    })
    .SetDefaultOnLog(gpg::LogLevel::VERBOSE)
    .SetOnAuthActionFinished(
                             [self](gpg::AuthOperation op, gpg::AuthStatus status) {
                               [self OnAuthActionFinished:op status:status];
                             })
    .SetOnTurnBasedMatchEvent(
                              [self](gpg::MultiplayerEvent event, std::string match_id,
                                     gpg::TurnBasedMatch match) {
                                NSLog(@"TurnBasedMultiplayerEvent callback");
                                //Show default inbox
                                [self updateInboxCount];
                                [self showMatchInbox];
                              })
    .SetOnMultiplayerInvitationEvent(
                                     [self](gpg::MultiplayerEvent event, std::string match_id,
                                            gpg::MultiplayerInvitation invitation) {
                                       NSLog(@"MultiplayerInvitationEvent callback");
                                       //Show default inbox
                                        [self updateInboxCount];
                                       [self showMatchInbox];
                                     }).Create(platform_configuration);
  }
}

/*
 * Callback: Authentication started
 */
- (void)OnAuthActionStarted:(gpg::AuthOperation) op
{
  [self refreshButtons:NO];
  self.authorizing = true;
}

/*
 * Callback: Authentication finishes
 */
- (void)OnAuthActionFinished:(gpg::AuthOperation) op status:(gpg::AuthStatus)status {
  self.authorizing = false;

    if(gpg::IsSuccess(status))
    {
      [self refreshButtons:YES];
      dispatch_async(dispatch_get_main_queue(), ^{
      [self.signInButton setTitle:@"Sign Out" forState:UIControlStateNormal];
      });
    }
    else
    {
      [self refreshButtons:NO];
      dispatch_async(dispatch_get_main_queue(), ^{
        self.signInButton.enabled = YES;
        [self.signInButton setTitle:@"Sign In" forState:UIControlStateNormal];
      });
    }
}

/*
 * Show match inbox
 */
-(void)showMatchInbox
{
  if (showingUI) {
    NSLog(@"Skipping inbox UI since the UI is already showing");
    return;
  }
  showingUI = YES;
  NSLog(@"Showing Inbox");
  service_->TurnBasedMultiplayer().ShowMatchInboxUI([self](
    gpg::TurnBasedMultiplayerManager::MatchInboxUIResponse const & response) {
    showingUI = NO;
    if (gpg::IsSuccess(response.status)) {
      //Show game based on the user's selection
      switch (response.match.Status()) {
        case gpg::MatchStatus::THEIR_TURN:
          //Manage match with dismiss, leave and cancel options
          [self playGame:response.match dismiss:true leave:true cancel:true rematch:false];
          break;
        case gpg::MatchStatus::MY_TURN:
          //Play selected game
          [self playGame:response.match dismiss:false leave:false cancel:false rematch:false];
          break;
        case gpg::MatchStatus::COMPLETED:
          //Manage match with dismiss, rematch options
          [self playGame:response.match dismiss:true leave:false cancel:false rematch:true];
          break;
        case gpg::MatchStatus::EXPIRED:
        default:
          //Manage match with dismiss option
          [self playGame:response.match dismiss:false leave:false cancel:false rematch:false];
          break;
      }
    } else if (response.status == gpg::UIStatus::ERROR_CANCELED) {
        NSLog(@"User canceled UI");
    } else {
      NSLog(@"Invalid response status: %d", response.status);
    }
  });
}

-(void)refreshButtons:(BOOL)b
{
  dispatch_async(dispatch_get_main_queue(), ^{
    self.signInButton.enabled = b;
    self.quickMatchButton.enabled = b;
    self.inviteFriendsButton.enabled = b;
    self.viewMyMatchesButton.enabled = b;

    [self updateInboxCount];

  });
}

- (IBAction)signInWasClicked:(id)sender {
  // Start authorization
  if (service_->IsAuthorized()) {
    service_->SignOut();
  } else {
    service_->StartAuthorizationUI();
  }
}

- (void) updateInboxCount {
  service_->TurnBasedMultiplayer().FetchMatches(
                                                [self](gpg::TurnBasedMultiplayerManager::TurnBasedMatchesResponse const&  resp)
                                                {
                                                  NSLog(@"rsp: status = %d", resp.status);
                                                  if(resp.status == gpg::MultiplayerStatus::VALID || resp.status == gpg::MultiplayerStatus::VALID_BUT_STALE) {
                                                    int ct = (int)(resp.data.invitations.size() + resp.data.my_turn_matches.size());
                                                    NSString* newTitle;
                                                    if (ct > 0) {
                                                      newTitle = [NSString stringWithFormat:@"All my matches (%d)", ct];
                                                    }
                                                    else {
                                                      newTitle = @"All my matches";
                                                    }

                                                    [self.viewMyMatchesButton setTitle:newTitle forState:UIControlStateNormal];


                                                  }
                                                  else {
                                                    NSLog(@"Error getting matches!");
                                                  }

                                                });
}

# pragma mark - Matchmaking methods
/*
 * Invite friends
 * - Show Player Select UI via ShowPlayerSelectUI,
 * - When the UI is finished, create match and show game UI
 */
- (IBAction)inviteMyFriends:(id)sender {
  service_->TurnBasedMultiplayer().
  ShowPlayerSelectUI(
                     MIN_PLAYERS, MAX_PLAYERS, true,
                     [self](gpg::TurnBasedMultiplayerManager::PlayerSelectUIResponse const &
                            response) {
                       NSLog(@"selected match %d", response.status);
                       if (gpg::IsSuccess(response.status)) {
                         // Create new match with the config
                         gpg::TurnBasedMatchConfig config = gpg::TurnBasedMatchConfig::Builder()
                         .SetMinimumAutomatchingPlayers(response.minimum_automatching_players)
                         .SetMaximumAutomatchingPlayers(response.maximum_automatching_players)
                         .AddAllPlayersToInvite(response.player_ids).Create();
                         [self refreshButtons:NO];
                         service_->TurnBasedMultiplayer().CreateTurnBasedMatch(config,
                                                                               [self](gpg::TurnBasedMultiplayerManager::TurnBasedMatchResponse const &matchResponse) {
                                                                                 [self refreshButtons:YES];
                                                                                 if (gpg::IsSuccess(matchResponse.status)) {
                                                                                   [self playGame:matchResponse.match dismiss:false leave:false cancel:false rematch:false];
                                                                                 }
                                                                               });
                       }
                     });
}

/*
 * Quick match
 * - Create a match with minimal setting and play the game
 */
- (IBAction)quickMatchWasPressed:(id)sender {
  gpg::TurnBasedMultiplayerManager& manager = service_->TurnBasedMultiplayer();
  gpg::TurnBasedMatchConfig config =
  gpg::TurnBasedMatchConfig::Builder().SetMinimumAutomatchingPlayers(1)
  .SetMaximumAutomatchingPlayers(2).Create();

  [self refreshButtons:NO];
  manager.CreateTurnBasedMatch(
                               config,
                               [self](gpg::TurnBasedMultiplayerManager::TurnBasedMatchResponse const &
                                      matchResponse) {
                                 [self refreshButtons:YES];
                                 if (gpg::IsSuccess(matchResponse.status)) {
                                   [self playGame:matchResponse.match dismiss:false leave:false
                                           cancel:false rematch:false];
                                 }
                               });
}


- (IBAction)seeMyMatches:(id)sender {
  [self showMatchInbox];
}

# pragma mark - Play game
- (void)playGame:(gpg::TurnBasedMatch const&)match
         dismiss:(bool)dismiss
           leave:(bool)leave
          cancel:(bool)cancel
         rematch:(bool)rematch
{
  dispatch_async(dispatch_get_main_queue(), ^{
    matchToTransfer_ = match;
    dismiss_ = dismiss;
    leave_ = leave;
    cancel_ = cancel;
    rematch_ = rematch;
    [self performSegueWithIdentifier:@"segueToGamePlay" sender:self];
  });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  //Pass GPG objects
  GameViewController *viewController = ((GameViewController *)[segue destinationViewController]);
  viewController.match = matchToTransfer_;
  viewController.manager = &service_->TurnBasedMultiplayer();
  viewController.dismissCurrentMatch = dismiss_;
  viewController.leaveCurrentMatch = leave_;
  viewController.cancelCurrentMatch = cancel_;
  viewController.rematchCurrent = rematch_;

  service_->Players().FetchSelf([viewController](gpg::PlayerManager::FetchSelfResponse response){
    viewController.localPlayerId = response.data.Id().c_str();
  });
}

# pragma mark - Lifecycle methods

- (void)viewDidLoad
{
  [super viewDidLoad];

  showingUI = NO;

  // Initialize TBMPGame object
  [self initializeGooglePlayGameServices];
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

/*
 Reads the client id by looking at the url types configured.  One of the url types is
 the client id reversed.  If it is not there, it is an error in configuration, so
 it will be fixed sooner vs. a cryptic runtime auth error.

 reverseClientUrlName is the key of the url type which contains the reversed client id.
 */
- (NSString*) readClientId {
    return [self readClientId: @"com.google.ReverseClientId"];
}
- (NSString*) readClientId: (NSString*) reverseClientUrlName {

    NSString *clientId = @"";
    NSDictionary *d = [NSBundle mainBundle].infoDictionary;

    // array of dictionaries of the url types;
    NSArray *urlTypes = [d objectForKey:@"CFBundleURLTypes"];

    for (NSDictionary* urlInfo in urlTypes)
    {
        NSString* name = [urlInfo objectForKey:@"CFBundleURLName"];
        if ([name isEqualToString:reverseClientUrlName]) {
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
    return clientId;
}
@end
