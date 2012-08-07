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

-(id) init {
    // Returns object with age initialized to zero
    if (self = [super init]) {
        Age = 0;
    }
    return self;
}

-(void) increment_age:(int)increment {
    // Increase age by given increment
    Age += increment;
}

-(float) temperature {
    // returns a uniformly distributed temperature in F
    // for the 'age' of the environment in hours.
    @autoreleasepool {
    
        int days = Age / 24;
        
        int month = ((days % 365) / 30.4);
        // Avg days in a month = 365/12 = 30.4
        static int min_t[] = {17, 20, 30, 41, 52, 62, 65, 63, 54, 43, 32, 21};
        static int max_t[] = {33, 38, 50, 63, 73, 83, 85, 84, 78, 64, 51, 37};
        // temperature ranges for Champaign county, IL
        
        int max_temp = max_t[month];
        int min_temp = min_t[month];
        
        int temp = random_integer(min_temp, max_temp);
        return temp; // in Fahrenheit
    }
}
@end
