//
//  Soybean.h
//  SCNSim
//
//  Created by Kaustubh Bhalerao on 8/4/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GERMINATEDATE 115
#define HARVESTDATE 240
#define OPTIMALGROWTH 80 //F
#define SOYMAXSIZE 100
#define GERMINATETEMP 55

@interface Soybean : NSObject {
    int Age;
    float PlantSize;
    NSMutableArray* SoilTemp;
    int grewLastYear;
}
@property (readonly) int GerminatedAge; // -1 if not germinated, Days since germination if germinated
@property int AlternateYears;

-(Soybean*) init;
-(void) growIncrement: (int) increment temp: (float) temperature;
-(float) getFoodwithFeedRate: (float) feedrate;
-(float) getHospitability;
-(int) Age;
-(float) PlantSize;

@end
