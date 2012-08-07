//
//  Nematode.h
//  SCNModel
//
//  Created by Kaustubh Bhalerao on 8/3/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Virus.h"
#import "Simulation.h"
#import "Soybean.h"

// State Definitions
#define EMBRYO 0
#define J1 1
#define J2 2
#define J3 3
#define J4M 4
#define J4F 5
#define M 6
#define F 7
#define F_PRIME 8
#define EGGSAC 9
#define DEAD 10
#define MATING 11

// Life cycle times
#define HATCH_MIN_TEMP 61
#define HATCH_MAX_TEMP 97
#define SOY_HATCH_MIN 20
#define SOY_HATCH_MAX 100
#define J3_FEED 0.05
#define J4_FEED 0.05
#define F_FEED 0.1
#define F_PRIME_FEED 0.1
#define INCUBATE_TEMP 61


@interface Nematode : NSObject 

@property int State; // one of the integer defines above
@property NSMutableArray* Viruses; // array containing viruses
@property int Age;
@property float Health; // max of 100
@property int NumEggs;
@property (weak) Simulation* Sim;

-(Nematode*) initWithState: (int) state inSim: (Simulation*) sim;
-(void) incrementAge: (int) increment;
-(void) reproduceViruses;
-(void) growBy: (int) increment;
@end
