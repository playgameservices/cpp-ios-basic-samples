//  Copyright (c) 2015 Google. All rights reserved.
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

#include "GCATEngine.h"

GCATEngine::GCATEngine() {

}

GCATEngine::~GCATEngine() {
}

/*
 * Retrieve Singleton instance
 */
GCATEngine& GCATEngine::GetInstance()
{
  static GCATEngine engine;
  return engine;
}

/*
 * Initialize GooglePlayGameServices via gpg::GameServices::Builder
 * In the build, it's setting several callbacks such as auth status changes,
 * receiving invitations etc.
 */
void GCATEngine::InitGooglePlayGameServices(id<GCATEngineDelegate> signInDelegate, UIViewController* view) {

  gpg_delegate_ = signInDelegate;

  if (service_ != nullptr) {
    return;
  }

  // Game Services have not been initialized, create a new Game Services.
  gpg::IosPlatformConfiguration platform_configuration;
  platform_configuration.SetClientID(ReadClientId())
  .SetOptionalViewControllerForPopups(view);

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
  .SetDefaultOnLog(gpg::LogLevel::VERBOSE)  //For debugging log
  .EnableSnapshots()                        //Enable Snapshot
  .Create(platform_configuration);

  [GIDSignIn sharedInstance].uiDelegate = signInDelegate;
}


# pragma mark - Sign-in functions
void GCATEngine::StartSignIn() {

  if (service_ != nullptr) {
    service_->StartAuthorizationUI();
  }
  else {
    [NSException raise:@"GPGS not initialized" format:@"Need to call InitGooglePlayGameServices first"];
  }
}

bool GCATEngine::IsSignedIn() {
  return service_ != nullptr && service_->IsAuthorized();
}

void GCATEngine::SignOut(){
  if (service_ != nullptr) {
    service_->SignOut();
  }
  else {
    [NSException raise:@"GPGS not initialized" format:@"Need to call InitGooglePlayGameServices first"];
  }
}
void GCATEngine::OnAuthActionStarted(gpg::AuthOperation op) {
  LOGI("OnAuthStarted called: op: %d", op);
  [gpg_delegate_ authStarted: op];
}

gpg::SnapshotManager& GCATEngine::Snapshots() {

  if (service_ != nullptr) {
    return service_->Snapshots();
  }
  else {
    [NSException raise:@"GPGS not initialized" format:@"Need to call InitGooglePlayGameServices first"];
  }

  return service_->Snapshots();
}

void GCATEngine::OnAuthActionFinished(gpg::AuthOperation op, gpg::AuthStatus status) {
  LOGI("OnAuthActionFinished called: op: %d status: %d", op, status);
  // Invoke delegate
  [gpg_delegate_ authFinished: op status:status];
}

/*
 * Reads the client id by looking at the url types configured.  One of the url types is
 * the client id reversed.  If it is not there, it is an error in configuration, so
 * it will be fixed sooner vs. a cryptic runtime auth error.
 *
 * reverseClientUrlName is the key of the url type which contains the reversed client id.
 */
const char* GCATEngine::ReadClientId(const char* reverseClientUrlName) {
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

