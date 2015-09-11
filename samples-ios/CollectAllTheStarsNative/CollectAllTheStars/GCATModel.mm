//
//  GCATModel.m
//  CollectAllTheStars
//
//  Created by Todd Kerpelman on 5/7/13.
//  Copyright (c) 2013 Google. All rights reserved.
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
//

#import "GCATModel.h"
#import "GCATStarInventory.h"
#import "GCATEngine.h"

#define DEFAULT_SAVE_NAME "snapshotTemp"

@interface GCATModel ()

@property (nonatomic, strong) NSNumber *starSaveSlot;
@property (nonatomic, copy) DataUpdatedHandler updatedHandler;
@property (nonatomic, strong) GCATStarInventory *inventory;
@end

@implementation GCATModel

- (id)init {
  self = [super init];
  if (self) {
    _starSaveSlot = [NSNumber numberWithInt:0];
    _inventory = [GCATStarInventory emptyInventory];
  }
  return self;
}

- (gpg::SnapshotManager&) snapshotManager {
  return GCATEngine::GetInstance().Snapshots();
}

/*
 * Read snapshot from cloud
 */
- (void) readCurrentSnapshot {
  NSLog(@"Reading snapshot");
  gpg::SnapshotManager::ReadResponse const &response = [self snapshotManager].ReadBlocking(self.currentSnapshot);
  if (gpg::IsSuccess(response.status)) {
    NSLog(@"Successfully read %zu blocks", response.data.size());
    NSData* data = [NSData dataWithBytes:reinterpret_cast<const void *>(response.data.data())
                                  length:response.data.size()];
    self.inventory = [GCATStarInventory starInventoryFromCloudData:data];
  }
  else {
    NSLog(@"Error while loading snapshot data: %d", response.status);
  }
}

/*
 * save snapshot
 */
- (void)saveSnapshotWithImage: (bool)newSave image:(UIImage *)snapshotImage completionHandler:(DataUpdatedHandler)handler {
  NSLog(@"Saving snapshot");

  std::string fileName;
  std::string description;
  if (self.currentSnapshot.Valid() == false || newSave) {
    NSString* newName = [self makeNewFileName];
    fileName = newName.UTF8String;
    description = [NSString stringWithFormat:@"Saved on iOS: %s",fileName.c_str()].UTF8String;
    NSLog(@"Creating new snapshot %s", fileName.c_str());
  } else {
    fileName = self.currentSnapshot.FileName();
    description = self.currentSnapshot.Description();
  }
  [self snapshotManager].Open(fileName,
                              gpg::SnapshotConflictPolicy::MANUAL,
                              [self, snapshotImage, handler,newSave, fileName, description](gpg::SnapshotManager::OpenResponse const & response) {

                                NSLog(@"Opened %s: status is %d conflict id: %s", fileName.c_str(), response.status, response.conflict_id.c_str());
                                if (IsSuccess(response.status)) {

                                  gpg::SnapshotMetadata metadata = response.data;
                                  if (response.conflict_id != "") {
                                    //Conflict detected
                                    NSLog(@"Snapshot conflict detected going to resolve that");
                                    gpg::ResponseStatus rsp = [self resolveSnapshotWithBaseMetadata:response.conflict_original
                                                           remoteMetadata:response.conflict_unmerged
                                                               conflictId:response.conflict_id];
                                    if(gpg::IsSuccess(rsp)) {
                                      // re-call save which needs to open the file again.
                                      [self saveSnapshotWithImage:newSave image:snapshotImage completionHandler:handler];
                                      return;

                                    }

                                  }

                                  // Save the snapshot.
                                  self.currentSnapshot = response.data;
                                  [self commitCurrentSnapshotWithImage:description image:snapshotImage completionHandler:handler];
                                }
                                else
                                {
                                  //Failed, just call handler
                                  handler();
                                }
                              });
}

/*
 * load snapshot
 */
- (void)loadSnapshot: (DataUpdatedHandler)handler
{
  if (self.currentSnapshot.Valid() == false)
  {
    handler();
    return;
  }

  [self snapshotManager].Open(_currentSnapshot.FileName(),
                              gpg::SnapshotConflictPolicy::MANUAL,
                              [self, handler](gpg::SnapshotManager::OpenResponse const & response) {
                                if (IsSuccess(response.status)) {
                                  gpg::SnapshotMetadata metadata = response.data;
                                  if (response.conflict_id != "") {
                                    //Conflict detected
                                    NSLog(@"Snapshot conflict detected going to resolve that");
                                    gpg::ResponseStatus rsp = [self resolveSnapshotWithBaseMetadata:response.conflict_original
                                                           remoteMetadata:response.conflict_unmerged
                                                               conflictId:response.conflict_id];
                                    if (gpg::IsSuccess(rsp)) {
                                      // call load again so that the resolved snapshot is opened.
                                      [self loadSnapshot:handler];
                                      return;
                                    }
                                    else {
                                      NSLog(@"Cannot resolve conflict: %d", rsp);
                                      return;
                                    }
                                  }

                                  // Save the snapshot.
                                  _currentSnapshot = response.data;
                                  [self readCurrentSnapshot];
                                  handler();
                                }
                              });
}


/**
 * Insert any resolution code here.
 *
 * In this sample, we just take the newer of the conflicting snapshots, an alternative would
 * be to merge the data.
 */
- (gpg::ResponseStatus)resolveSnapshotWithBaseMetadata :(const gpg::SnapshotMetadata&)conflictingSnapshotBase
                          remoteMetadata:(const gpg::SnapshotMetadata&)conflictingSnapshotRemote
                              conflictId:(std::string)conflictId {

  NSLog(@"Resolving snapshot conflicts: %s >> %s",
        conflictingSnapshotBase.Description().c_str(),
        conflictingSnapshotRemote.Description().c_str());

  gpg::SnapshotMetadata final = conflictingSnapshotBase; // The resolved snapshot.

  // For this sample, we use the snapshot with the latest timestamp. Alternatively, you could
  // take the union of the two snapshots as is demonstrated in the Android version.
  if (conflictingSnapshotRemote.LastModifiedTime() >
      conflictingSnapshotBase.LastModifiedTime()) {
    final = conflictingSnapshotRemote;
  }

  self.currentSnapshot = final;

  //Resolve conflict
  gpg::SnapshotMetadataChange::Builder builder;
  gpg::SnapshotMetadataChange metadata_change =
  builder.SetDescription(self.currentSnapshot.Description()).Create();

  //For now, we would just choose the newest version of snapshot
  gpg::SnapshotManager::CommitResponse commitResponse =
  [self snapshotManager].ResolveConflictBlocking(final,
                                                 metadata_change,
                                                 conflictId);

  if (gpg::IsSuccess(commitResponse.status)) {
    self.currentSnapshot = commitResponse.data;
  }
  return commitResponse.status;
}

/**
 * Saves the current Snapshot object stored in the
 */
- (void)commitCurrentSnapshotWithImage:(std::string) description image:(UIImage *)snapshotImage completionHandler:(DataUpdatedHandler)handler {
  if (self.currentSnapshot.Valid() == false) {
    NSLog(@"Error while committing snapshot, no current snapshot");
    handler();
    return;
  }

  //Convert UIImage to png stl::vector
  NSData *imageData = UIImagePNGRepresentation(snapshotImage);
  std::vector<uint8_t> vecImage;
  vecImage.assign(reinterpret_cast<const uint8_t*>([imageData bytes]),
                  reinterpret_cast<const uint8_t*>([imageData bytes]) + [imageData length]);

  //Played time
  std::chrono::minutes min(1);

  if(description.empty()) {
    description = "Saved via iOS NativClient";
  }
  // Create a snapshot change to be committed with a description, cover image, and play time.
  gpg::SnapshotMetadataChange::Builder builder;
  gpg::SnapshotMetadataChange metadata_change =
  builder.SetDescription(description)
  .SetPlayedTime(self.currentSnapshot.PlayedTime() + min)
  .SetCoverImageFromPngData(vecImage)
  .Create();

  //Convert NSData to stl::vector
  NSData* data = [self.inventory getCloudSaveData];
  std::vector<uint8_t> v;
  v.assign(reinterpret_cast<const uint8_t*>([data bytes]),
           reinterpret_cast<const uint8_t*>([data bytes]) + [data length]);

  // Save the snapshot.
  gpg::SnapshotManager::CommitResponse commitResponse =
  [self snapshotManager].CommitBlocking(self.currentSnapshot,
                                        metadata_change,
                                        v);

  if (IsSuccess(commitResponse.status)) {
    NSLog(@"Successfully saved %s", self.currentSnapshot.Description().c_str());
  } else {
    NSLog(@"Error while saving: %d", commitResponse.status);
  }
  handler();
}

// Setters / Getters
- (void)setStars:(int)stars forWorld:(int)world andLevel:(int)level {
  [self.inventory setStars:stars forWorld:world andLevel:level];
}

- (int)getStarsForWorld:(int)world andLevel:(int)level {
  return [self.inventory getStarsForWorld:world andLevel:level];
}

- (NSString *) makeNewFileName {
  NSDateFormatter *df = [[NSDateFormatter alloc] init];
  [df setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];

  NSDate *now = [[NSDate alloc] init];

  return [@"iOS Save_" stringByAppendingString:[df stringFromDate:now]];
}

@end
