//
//  Soybean.m
//  SCNSim
//
//  Created by Kaustubh Bhalerao on 8/4/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import "Soybean.h"

@implementation Soybean
@synthesize GerminatedAge;
@synthesize AlternateYears;
@synthesize growThisYear;

-(Soybean*) init {
    @autoreleasepool {
        if (self = [super init]) {
            Age = 0;
            SoilTemp = [[NSMutableArray alloc] init];
            GerminatedAge = -1;
            PlantSize = 0;
            AlternateYears = NO;
            grewLastYear = NO;
            growThisYear = YES;
        }
        return self;
    }
}
-(void) growIncrement: (int) increment temp: (float) temperature {
    Age += increment;
    Age = Age % 365;

    if (AlternateYears && !grewLastYear && Age < 10) {
        // then don't grow this year
        growThisYear = YES;
    }
    
    if (AlternateYears && growThisYear && Age > 360) {
        grewLastYear = YES;
    }
    
    if (AlternateYears && !growThisYear && Age > 360) {
        grewLastYear = NO;
    }
    
    if (AlternateYears && grewLastYear && Age < 10) {
        // then don't grow this year
        growThisYear = NO;
    }
    
    if (!AlternateYears) growThisYear = YES;
    
    if (growThisYear) {
        
   
        if (GerminatedAge == -1) {
            [SoilTemp addObject:@(temperature)];
            if ([SoilTemp count] > 3) {
                [SoilTemp removeObjectAtIndex:0];
                float avgTemp = 0;
                for (int i=0; i<[SoilTemp count];  i++) {
                    @autoreleasepool {
                        avgTemp += [(NSNumber*)SoilTemp[i] floatValue];
                        //seriously dude? all this to add a float?
                    }
                }
                avgTemp = avgTemp / [SoilTemp count];
                if (avgTemp >= GERMINATETEMP) {
                    GerminatedAge = 0; // Age since germinated
                }
            }
        }
        
        if (GerminatedAge >= 0) {
            GerminatedAge++;
            if (temperature < OPTIMALGROWTH) {
                PlantSize += 1 - (OPTIMALGROWTH - temperature) / 60.0;
            }
            if (temperature >= OPTIMALGROWTH) {
                PlantSize += 1 - (temperature - OPTIMALGROWTH) / 40.0;
            }
        }
        
        if (Age > HARVESTDATE && GerminatedAge != -1) {
            PlantSize = 0;
            GerminatedAge = -1;
            grewLastYear = YES;
        }
    }
}

-(float) getFoodwithFeedRate: (float) feedrate {
    float food = MIN([self getHospitability], feedrate);
    PlantSize -= food;
    return food;
}
-(float) getHospitability {
    return MIN(5*PlantSize / SOYMAXSIZE, 1);
}
-(int) Age {
    return Age;
}
-(float) PlantSize {
    return PlantSize;
}
@end
