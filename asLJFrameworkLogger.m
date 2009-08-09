//
//  asLJFrameworkLogger.m
//  asLJFramework
//
//  Created by Isaac Greenspan on 8/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "asLJFrameworkLogger.h"


@implementation asLJFrameworkLogger

static BOOL verboseLogging = NO;

+ (void)setVerboseLogging:(BOOL)verbose
{
	verboseLogging = verbose;
}

+(void)log:(NSString*)format, ...
{
	va_list ap;
	NSString *print;
	va_start(ap,format);
	print=[[NSString alloc] initWithFormat:format arguments:ap];
	va_end(ap);
	NSLog(@"%@",print);
	[print release];
}

@end
