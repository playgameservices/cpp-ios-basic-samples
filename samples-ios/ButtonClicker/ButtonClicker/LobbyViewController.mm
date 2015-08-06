//
//  LobbyViewController.mm
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

#import "LobbyViewController.h"
#import "ButtonClickerEngine.h"
#import "Constants.h"

@interface LobbyViewController ()<UIAlertViewDelegate, ButtonClickerGameDelegate, GIDSignInUIDelegate> {
  BOOL _currentlySigningIn;
}
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *signOutButton;
@property (weak, nonatomic) IBOutlet UIButton *incomingInvitesButton;
@property (weak, nonatomic) IBOutlet UIButton *quickMatchTwoPlayerButton;
@property (weak, nonatomic) IBOutlet UIButton *quickMatchFourPlayerButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteFriendsButton;
@end

@implementation LobbyViewController

#pragma mark - Multi-player stuff
/*
 * IB outlets for UI
 */
- (IBAction)quickFourPlayerWasPressed:(id)sender {
  [self startQuickMatchGameWithTotalPlayers:4];
}

- (IBAction)quickTwoPlayerWasPressed:(id)sender {
  [self startQuickMatchGameWithTotalPlayers:2];
}

- (IBAction)inviteFriendsWasPressed:(id)sender {
  ButtonClickerEngine::GetInstance().InviteFriend(MIN_PLAYERS, MAX_PLAYERS);
}

- (IBAction)viewIncomingInvitesWasPressed:(id)sender {
  ButtonClickerEngine::GetInstance().ShowRoomInbox();
}

/*
 * Start quick match game using ButtonClickerEngine methods
 */
- (void)startQuickMatchGameWithTotalPlayers:(int)totalPlayers {
  ButtonClickerEngine::GetInstance().QuickMatch(totalPlayers);
}

# pragma mark - ButtonClickerGameDelegate methods
/*
 * ButtonClickerGameDelegate callback invoked when the game is ready to start
 */
- (void)readyToStartMultiPlayerGame {
  dispatch_async(dispatch_get_main_queue(), ^{
    // I can still sometimes receive this if we're in the middle of a game
    if (![[self.navigationController.viewControllers lastObject] isEqual:self]) {
      return;
    }

    if (self.presentedViewController != nil) {
      [self dismissViewControllerAnimated:YES completion:^{
        [self performSegueWithIdentifier:@"SegueToGame" sender:self];
      }];
    } else {
      [self performSegueWithIdentifier:@"SegueToGame" sender:self];
    }
  });
}

# pragma mark - Sign in methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 0) {
    // Okay, chose not to sign in.
  } else {
    ButtonClickerEngine::GetInstance().GetGpgService()->StartAuthorizationUI();
  }
}

- (void)refreshButtons {
  dispatch_async(dispatch_get_main_queue(), ^{
    BOOL signedIn = ButtonClickerEngine::GetInstance().IsSignedIn();
    self.signInButton.hidden = signedIn;
    self.signOutButton.hidden = !signedIn;
    self.signInButton.enabled = !_currentlySigningIn;

    // Let's check out our incoming invites
    [self.incomingInvitesButton setTitle:@"Incoming Invites" forState:UIControlStateNormal];
    self.incomingInvitesButton.enabled = NO;
    if (signedIn) {
      ButtonClickerEngine::GetInstance().GetGpgService()->RealTimeMultiplayer()
      .FetchInvitations([self](gpg::RealTimeMultiplayerManager::FetchInvitationsResponse const& response) {
        dispatch_async(dispatch_get_main_queue(), ^{
          int32_t numberOfInvites = static_cast<int32_t>(response.invitations.size());
          [self.incomingInvitesButton setTitle:[NSString stringWithFormat:@"Incoming Invites (%d)", numberOfInvites] forState:UIControlStateNormal];
          self.incomingInvitesButton.enabled = (numberOfInvites > 0);
        });
      });
    }
    self.quickMatchTwoPlayerButton.enabled = signedIn;
    self.quickMatchFourPlayerButton.enabled = signedIn;
    self.inviteFriendsButton.enabled = signedIn;
  });
}

- (IBAction)signInButtonWasPressed:(id)sender {
  ButtonClickerEngine::GetInstance().GetGpgService()->StartAuthorizationUI();
}

- (IBAction)signOutButtonWasPressed:(id)sender {
  ButtonClickerEngine::GetInstance().GetGpgService()->SignOut();
}

# pragma mark -- GPGDelegate methods

- (void)signInStatusChanged
{
  NSLog(@"GooglePlayGames finished signing in!");

  _currentlySigningIn = NO;
  [self refreshButtons];
}

#pragma mark - Lifecycle methods

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  ButtonClickerEngine::GetInstance().SetGpgDelegate(self);
  [GIDSignIn sharedInstance].uiDelegate = self;

  [self refreshButtons];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  ButtonClickerEngine::GetInstance().SetGpgDelegate(self);

  _currentlySigningIn = YES;
  ButtonClickerEngine::GetInstance().GetGpgService()->StartAuthorizationUI();
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
