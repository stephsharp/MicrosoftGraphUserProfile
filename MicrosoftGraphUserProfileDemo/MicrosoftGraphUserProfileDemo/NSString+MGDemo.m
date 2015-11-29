//
//  NSString+MGDemo.m
//  MicrosoftGraphUserProfileDemo
//
//  Created by Steph Sharp on 30/11/2015.
//  Copyright © 2015 Stephanie Sharp. All rights reserved.
//

#import "NSString+MGDemo.h"

@implementation NSString (MGDemo)

- (NSString *)uppercaseInitial
{
    if (self.length > 0) {
        return [[self substringToIndex:1] uppercaseString];
    }

    return @"";
}

@end
