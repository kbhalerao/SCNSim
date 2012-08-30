//
//  Environment.m
//  SCNModel_C
//
//  Created by Kaustubh Bhalerao on 8/3/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import "Environment.h"
#import "helpers.h"


@implementation Environment

@synthesize Age;
@synthesize Temperature;
@synthesize localEnvironment;

-(id) init {
    // Returns object with age initialized to zero
    @autoreleasepool {
        if (self = [super init]) {
            Age = 0;
            localEnvironment = nil;
        }
        return self;
    }
}

-(void) increment_age:(int)increment {
    // Increase age by given increment
    Age += increment;
    
    int month = ((Age % 365) / 30.4);
    // Avg days in a month = 365/12 = 30.4
    
    // temperature ranges for Champaign county, IL
    
    int max_temp = [localEnvironment[0][month] intValue];
    int min_temp = [localEnvironment[1][month] intValue];
    
    Temperature = 0.5*random_integer(min_temp, max_temp) + 0.5*Temperature;
    
}

@end
