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

#ifndef __CollectAllTheStars__GCATEngine__
#define __CollectAllTheStars__GCATEngine__

/*
 * Include files
 */

// iOS include files
#include <CoreFoundation/CoreFoundation.h>
#include <objc/NSObjCRuntime.h>

//GPG
#include <gpg/gpg.h>
#include <GoogleSignIn.h>

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
 * Delegate definitions for ObjC bridge
 */
@protocol GCATEngineDelegate<GIDSignInUIDelegate>

- (void)authStarted: (gpg::AuthOperation) op;
- (void)authFinished:(gpg::AuthOperation) op status:(gpg::AuthStatus)status;
@end


class GCATEngine
{
public:
  static GCATEngine& GetInstance();

  ~GCATEngine();

  // GPG-related methods
  void InitGooglePlayGameServices(id<GCATEngineDelegate> signInDelegate, UIViewController* view);

  // Sign-in/out and status check for GPG services
  void StartSignIn();
  bool IsSignedIn();
  void SignOut();

  //Snapshot Manager
  gpg::SnapshotManager& Snapshots();

private:
  GCATEngine();

  //Gpg service instance
  std::unique_ptr<gpg::GameServices> service_;
  id<GCATEngineDelegate> gpg_delegate_;

  // Callbacks for GPG authentication.
  void OnAuthActionStarted(gpg::AuthOperation op);
  void OnAuthActionFinished(gpg::AuthOperation op, gpg::AuthStatus status);

  // Helper to read the client id from the info plist where the reverse client id is configured.
  const char* ReadClientId(const char* reverseClientUrlName="com.google.ReverseClientId");

};

#endif /* defined(__CollectAllTheStars__GCATEngine__) */
