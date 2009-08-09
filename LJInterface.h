//
//  LJInterface.h
//  asLJFramework
//
//  Created by Isaac Greenspan on 7/17/09.
//

/*** BEGIN LICENSE TEXT ***
 
 Copyright (c) 2009, Isaac Greenspan
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 *** END LICENSE TEXT ***/

#import <Cocoa/Cocoa.h>


@interface LJInterface : NSObject {

}

#pragma mark -
#pragma mark initialization/confifguration

// set the name under which account keychain items are stored
+ (void)setKeychainItemName:(NSString *)theName;

// set the version string reported to the LJ-type site
+ (void)setClientVersion:(NSString *)theVersion;

// enable/disable verbose logging
+ (void)setVerboseLogging:(BOOL)verbose;


#pragma mark -
#pragma mark account-handling

+ (NSArray *)allAccounts;

+ (void)addAccountOnServer:(NSString *)server
			  withUsername:(NSString *)username
			  withPassword:(NSString *)password;

+ (void)deleteAccount:(NSString *)account;

+ (void)editAccount:(NSString *)account
		  setServer:(NSString *)server
		setUsername:(NSString *)username
		setPassword:(NSString *)password;


#pragma mark -
#pragma mark server interaction

+ (NSDictionary *)loginTo:(NSString *)account
					error:(NSError **)anError;
+ (NSDictionary *)loginTo:(NSString *)account;

+ (NSDictionary *)getDayCountsFor:(NSString *)account
					  withJournal:(NSString *)journal
							error:(NSError **)anError;
+ (NSDictionary *)getDayCountsFor:(NSString *)account
					  withJournal:(NSString *)journal;

+ (NSDictionary *)getEntriesFor:(NSString *)account
					withJournal:(NSString *)journal
						 onDate:(NSCalendarDate *)date
						  error:(NSError **)anError;
+ (NSDictionary *)getEntriesFor:(NSString *)account
					withJournal:(NSString *)journal
						 onDate:(NSCalendarDate *)date;

+ (NSArray *)getTagsFor:(NSString *)account
			withJournal:(NSString *)journal
				  error:(NSError **)anError;
+ (NSArray *)getTagsFor:(NSString *)account
			withJournal:(NSString *)journal;

+ (BOOL)deleteEntryFor:(NSString *)account
		   withJournal:(NSString *)journal
			withItemID:(NSString *)itemid
				 error:(NSError **)anError;
+ (void)deleteEntryFor:(NSString *)account
		   withJournal:(NSString *)journal
			withItemID:(NSString *)itemid;


#pragma mark -
#pragma mark moods

+ (NSArray *)getMoodStringsForServer:(NSString *)theServer;
+ (NSString *)getMoodIDForString:(NSString *)theMood
					  withServer:(NSString *)theServer;


@end
