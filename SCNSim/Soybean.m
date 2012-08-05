//
//  Soybean.m
//  SCNSim
//
//  Created by Kaustubh Bhalerao on 8/4/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import "Soybean.h"

@implementation Soybean
-(Soybean*) init {
    if (self = [super init]) {
        Age = 0;
        SoilTemp = [[NSMutableArray alloc] init];
        Germinated = 0;
        PlantSize = 0;
    }
    return self;
}
-(void) growIncrement: (float) increment temp: (float) temperature {
    Age += increment;
    Age = Age % 365;
    if (Germinated == 0 && Age <= GERMINATEDATE) {
        [SoilTemp addObject:[NSNumber numberWithFloat:temperature]];
        if ([SoilTemp count] > 3) {
            [SoilTemp removeObjectAtIndex:0];
            float avgTemp = 0;
            for (int i=0; i<[SoilTemp count];  i++) {
                avgTemp += [(NSNumber*)[SoilTemp objectAtIndex:i] floatValue];
                //seriously dude? all this to add a float?
            }
            avgTemp = avgTemp / [SoilTemp count];
            if (avgTemp >= GERMINATETEMP) {
                Germinated = 1;
            }
        }
    }
    
    if (Germinated==1) {
        if (temperature < OPTIMALGROWTH) {
            PlantSize += 1 - (OPTIMALGROWTH - temperature) / 60.0;
        }
        if (temperature >= OPTIMALGROWTH) {
            PlantSize += 1 - (temperature - OPTIMALGROWTH) / 40.0;
        }
    }
    
    if (Age > HARVESTDATE && Germinated == 1) {
        PlantSize = 0;
        Germinated = 0;
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
-(int) PlantSize {
    return PlantSize;
}
@end
