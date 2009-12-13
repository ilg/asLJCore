//
//  asLJCore.m
//  asLJCore
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

#import "asLJCore.h"
#import "LJxmlrpc.h"
#import "LJMoods.h"
#import "asLJCoreKeychain.h"

@implementation asLJCore

#pragma mark -
#pragma mark initialization/confifguration

static NSString *keychainItemName;

// set the name under which account keychain items are stored
+ (void)setKeychainItemName:(NSString *)theName
{
	[keychainItemName release];
	keychainItemName = [[theName copy] retain];
	[LJxmlrpc setKeychainItemName:theName];
}

// set the version string reported to the LJ-type site
+ (void)setClientVersion:(NSString *)theVersion
{
	[LJxmlrpc setClientVersion:theVersion];
}

// enable/disable verbose logging
+ (void)setVerboseLogging:(BOOL)verbose
{
	[asLJCoreLogger setVerboseLogging:verbose];
}


#pragma mark -
#pragma mark internal utility

// turn a@b into @"username" => a, @"server" => b
+ (NSDictionary *)splitAccountString:(NSString *)account
{
	NSArray *parts = [account componentsSeparatedByString:@"@"];
	if ([parts count] == 2) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[parts objectAtIndex:0],@"username",
				[parts objectAtIndex:1],@"server",
				nil];
	} else {
		return nil;
	}
}


#pragma mark -
#pragma mark account-handling

+ (NSArray *)allAccounts
{
	NSArray *accountArray = [asLJCoreKeychain getKeysByLabel:keychainItemName];
	return [NSArray arrayWithArray:accountArray];
}

+ (void)addAccountOnServer:(NSString *)server
			  withUsername:(NSString *)username
			  withPassword:(NSString *)password
{
	[asLJCoreKeychain makeNewInternetKeyWithLabel:keychainItemName
										   withAccount:username
											withServer:server
										  withPassword:password];
}

+ (void)deleteAccount:(NSString *)account
{
	NSDictionary *accountInfo = [self splitAccountString:account];
	[asLJCoreKeychain deleteKeychainItemByLabel:keychainItemName
										 withAccount:[accountInfo objectForKey:@"username"]
										  withServer:[accountInfo objectForKey:@"server"]];
}

+ (void)editAccount:(NSString *)account
		  setServer:(NSString *)server
		setUsername:(NSString *)username
		setPassword:(NSString *)password
{
	NSDictionary *accountInfo = [self splitAccountString:account];
	[asLJCoreKeychain editKeychainItemByLabel:keychainItemName
									   withAccount:[accountInfo objectForKey:@"username"]
										withServer:[accountInfo objectForKey:@"server"]
										setAccount:username
										 setServer:server
									   setPassword:password];
}


#pragma mark -
#pragma mark server interaction

+ (NSDictionary *)loginTo:(NSString *)account
					error:(NSError **)anError
{
	NSDictionary *theResult;
	NSDictionary *accountInfo = [self splitAccountString:account];
	LJxmlrpc *loginCall = [[LJxmlrpc alloc] init];
	NSError *myError;
	if (![loginCall call:@"login"
			  withParams:[NSDictionary dictionaryWithObjectsAndKeys:// (value,key), nil to end
						  @"1",@"getpickws",
						  @"1",@"getpickwurls",
						  [LJMoods getHighestMoodIDForServer:[accountInfo objectForKey:@"server"]],@"getmoods",
						  nil]
				   atURL:SERVER2URL([accountInfo objectForKey:@"server"])
				 forUser:[accountInfo objectForKey:@"username"]
				   error:&myError]) {
		// call failed
		VLOG(@"Fault (%d): %@", [myError code], [[myError userInfo] objectForKey:NSLocalizedDescriptionKey]);
		theResult = nil;
		if (anError != NULL) *anError = [[myError copy] autorelease];
	} else {
		// call succeded
		VLOG(@"... logged in.");
		
		// store new moods
		NSArray *newMoods = [loginCall objectForKey:@"moods"];
		NSMutableArray *newMoodStrings = [NSMutableArray arrayWithCapacity:[newMoods count]];
		NSMutableArray *newMoodIDs = [NSMutableArray arrayWithCapacity:[newMoods count]];
		for (id theNewMood in newMoods) {
			[newMoodStrings addObject:[theNewMood objectForKey:@"name"]];
			[newMoodIDs addObject:[theNewMood objectForKey:@"id"]];
		}
		[LJMoods addNewMoods:newMoodStrings
					 withIDs:newMoodIDs
				   forServer:[accountInfo objectForKey:@"server"]];
		theResult = [loginCall getResultDictionary];
	}
	[loginCall release];
	return theResult;
}

+ (NSDictionary *)loginTo:(NSString *)account
{
	return [self loginTo:account error:NULL];
}

+ (NSDictionary *)getDayCountsFor:(NSString *)account
					  withJournal:(NSString *)journal
							error:(NSError **)anError
{
	NSDictionary *theResult;
	NSError *myError;
	NSDictionary *accountInfo = [self splitAccountString:account];
	LJxmlrpc *theCall = [[LJxmlrpc alloc] init];
	if (![theCall call:@"getdaycounts"
			withParams:[NSDictionary dictionaryWithObjectsAndKeys:// (value,key), nil to end
						journal,@"usejournal",
						nil]
				 atURL:SERVER2URL([accountInfo objectForKey:@"server"])
			   forUser:[accountInfo objectForKey:@"username"]
				 error:&myError]) {
		// call failed
		VLOG(@"Fault (%d): %@", [myError code], [[myError userInfo] objectForKey:NSLocalizedDescriptionKey]);
		theResult = nil;
		if (anError != NULL) *anError = [[myError copy] autorelease];
	} else {
		// call succeded
		NSArray *dayCountArray = [theCall objectForKey:@"daycounts"];
		VLOG(@"Got counts for %d days",[dayCountArray count]);
		NSMutableDictionary *temporaryResults = [NSMutableDictionary dictionaryWithCapacity:[dayCountArray count]];
		for (id theDayCount in dayCountArray) {
			[temporaryResults setObject:[theDayCount objectForKey:@"count"]
								 forKey:[theDayCount objectForKey:@"date"]];
		}
		theResult = [NSDictionary dictionaryWithDictionary:temporaryResults];
	}
	[theCall release];
	return theResult;
}

+ (NSDictionary *)getDayCountsFor:(NSString *)account
					  withJournal:(NSString *)journal
{
	return [self getDayCountsFor:account withJournal:journal error:NULL];
}

+ (NSDictionary *)getEntriesFor:(NSString *)account
					withJournal:(NSString *)journal
						 onDate:(NSCalendarDate *)date
						  error:(NSError **)anError
{
	NSDictionary *theResult;
	NSError *myError;
	NSDictionary *accountInfo = [self splitAccountString:account];
	LJxmlrpc *theCall = [[LJxmlrpc alloc] init];
	if (![theCall call:@"getevents"
			withParams:[NSDictionary dictionaryWithObjectsAndKeys:// (value,key), nil to end
						journal,@"usejournal",
						@"day",@"selecttype",
						[NSString stringWithFormat:@"%d",[date yearOfCommonEra]],@"year",
						[NSString stringWithFormat:@"%d",[date monthOfYear]],@"month",
						[NSString stringWithFormat:@"%d",[date dayOfMonth]],@"day",
						@"mac",@"linenedings",
						@"1",@"noprops",
						@"1",@"prefersubject",
						@"200",@"truncate",
						nil]
				 atURL:SERVER2URL([accountInfo objectForKey:@"server"])
			   forUser:[accountInfo objectForKey:@"username"]
				 error:&myError]) {
		// call failed
		VLOG(@"Fault (%d): %@", [myError code], [[myError userInfo] objectForKey:NSLocalizedDescriptionKey]);
		theResult = nil;
		if (anError != NULL) *anError = [[myError copy] autorelease];
	} else {
		// call succeded
		NSArray *eventArray = [theCall objectForKey:@"events"];
		VLOG(@"Got %d events",[eventArray count]);
		NSMutableDictionary *temporaryResults = [NSMutableDictionary dictionaryWithCapacity:[eventArray count]];
		for (id anEvent in eventArray) {
			[temporaryResults setObject:[NSDictionary dictionaryWithObjectsAndKeys:
										 [NSString stringWithFormat:@"[%@] %@",
										  [[[anEvent objectForKey:@"eventtime"] 
											componentsSeparatedByString:@" "] lastObject],
										  [anEvent objectForKey:@"event"]],
										 @"title",
										 [anEvent objectForKey:@"url"],@"url",
										 nil]
								 forKey:[anEvent objectForKey:@"itemid"]];
		}
		theResult = [NSDictionary dictionaryWithDictionary:temporaryResults];
	}
	[theCall release];
	return theResult;
}

+ (NSDictionary *)getEntriesFor:(NSString *)account
					withJournal:(NSString *)journal
						 onDate:(NSCalendarDate *)date
{
	return [self getEntriesFor:account withJournal:journal onDate:date error:NULL];
}

+ (NSArray *)getTagsFor:(NSString *)account
			withJournal:(NSString *)journal
				  error:(NSError **)anError
{
	NSArray *theResult;
	NSError *myError;
	NSDictionary *accountInfo = [self splitAccountString:account];
	LJxmlrpc *theCall = [[LJxmlrpc alloc] init];
	if (![theCall call:@"getusertags"
			withParams:[NSDictionary dictionaryWithObjectsAndKeys:// (value,key), nil to end
						journal,@"usejournal",
						nil]
				 atURL:SERVER2URL([accountInfo objectForKey:@"server"])
			   forUser:[accountInfo objectForKey:@"username"]
				 error:&myError]) {
		// call failed
		VLOG(@"Fault (%d): %@", [myError code], [[myError userInfo] objectForKey:NSLocalizedDescriptionKey]);
		theResult = nil;
		if (anError != NULL) *anError = [[myError copy] autorelease];
	} else {
		// call succeded
		NSArray *tagsArray = [theCall objectForKey:@"tags"];
		VLOG(@"Got %d tags",[tagsArray count]);
		NSMutableArray *temporaryResults = [NSMutableArray arrayWithCapacity:[tagsArray count]];
		for (id aTag in tagsArray) {
			[temporaryResults addObject:[aTag objectForKey:@"name"]];
		}
		theResult = [NSArray arrayWithArray:temporaryResults];
	}
	[theCall release];
	return theResult;
}

+ (NSArray *)getTagsFor:(NSString *)account
			withJournal:(NSString *)journal
{
	return [self getTagsFor:account withJournal:journal error:NULL];
}

+ (BOOL)deleteEntryFor:(NSString *)account
		   withJournal:(NSString *)journal
			withItemID:(NSString *)itemid
				 error:(NSError **)anError
{
	BOOL theResult;
	NSError *myError;
	NSDictionary *accountInfo = [self splitAccountString:account];
	LJxmlrpc *theCall = [[LJxmlrpc alloc] init];
	if (![theCall call:@"editevent"
			withParams:[NSDictionary dictionaryWithObjectsAndKeys:// (value,key), nil to end
						journal,@"usejournal",
						itemid,@"itemid",
						@"",@"event",
						@"",@"subject",
						@"mac",@"linenedings",
						nil]
				 atURL:SERVER2URL([accountInfo objectForKey:@"server"])
			   forUser:[accountInfo objectForKey:@"username"]
				 error:&myError]) {
		// call failed
		VLOG(@"Fault (%d): %@", [myError code], [[myError userInfo] objectForKey:NSLocalizedDescriptionKey]);
		theResult = NO;
		if (anError != NULL) *anError = [[myError copy] autorelease];
	} else {
		// call succeded
		VLOG(@"Deleted entry with itemid=%@",itemid);
		theResult = YES;
	}
	[theCall release];
	return theResult;
}

+ (void)deleteEntryFor:(NSString *)account
		   withJournal:(NSString *)journal
			withItemID:(NSString *)itemid
{
	[self deleteEntryFor:account withJournal:journal withItemID:itemid error:NULL];
}

+ (NSString *)getSessionCookieFor:(NSString *)account
							error:(NSError **)anError
{
	NSString *theResult;
	NSDictionary *accountInfo = [self splitAccountString:account];
	LJxmlrpc *theCall = [[LJxmlrpc alloc] init];
	NSError *myError;
	if (![theCall call:@"sessiongenerate"
			  withParams:[NSDictionary dictionaryWithObjectsAndKeys:// (value,key), nil to end
						  nil]
				   atURL:SERVER2URL([accountInfo objectForKey:@"server"])
				 forUser:[accountInfo objectForKey:@"username"]
				   error:&myError]) {
		// call failed
		VLOG(@"Fault (%d): %@", [myError code], [[myError userInfo] objectForKey:NSLocalizedDescriptionKey]);
		theResult = nil;
		if (anError != NULL) *anError = [[myError copy] autorelease];
	} else {
		// call succeded
		VLOG(@"Got session cookie.");
		theResult = [NSString stringWithString:[theCall objectForKey:@"ljsession"]];
	}
	[theCall release];
	return theResult;
}

+ (NSString *)getSessionCookieFor:(NSString *)account
{
	return [self getSessionCookieFor:account error:NULL];
}




#pragma mark -
#pragma mark moods

+ (NSArray *)getMoodStringsForServer:(NSString *)theServer
{
	return [LJMoods getMoodStringsForServer:theServer];
}

+ (NSString *)getMoodIDForString:(NSString *)theMood
					  withServer:(NSString *)theServer
{
	return [LJMoods getMoodIDForString:theMood withServer:theServer];
}

@end