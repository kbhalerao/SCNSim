//
//  Nematode.h
//  SCNModel
//
//  Created by Kaustubh Bhalerao on 8/3/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Simulation.h"
#import "Soybean.h"

// State Definitions
#define EMBRYO 0
#define J1 1 // inside the eggsac / cyst
#define UNHATCHEDJ2 2
#define J2 3 //hatched
#define J3 4
#define J4M 5
#define J4F 6
#define M 7
#define F 8
#define MATING 9
#define F_PRIME 10
#define EGGSAC 11
#define CYST 12
#define DEAD 13


// Life cycle times
#define HATCH_MIN_TEMP 61
#define HATCH_MAX_TEMP 97
#define SOY_HATCH_MIN 20
#define SOY_HATCH_MAX 100
#define J3_FEED 0.05
#define J4_FEED 0.05
#define F_FEED 0.05
#define MATING_FEED 0.05
#define F_PRIME_FEED 0.05
#define INCUBATE_TEMP 61


@interface Nematode : NSObject 

@property int State; // one of the integer defines above
@property int Age;
@property float Health; // max of 100
@property int NumZygotes;
@property (weak) Simulation* Sim;
@property (weak) Nematode * inContainer; // container =0 for eggsac, 1 for cyst.
@property int numContained;
@property NSMutableDictionary *Infection;
@property int generation;

// Infection is a dictionary that contains four viral parameters
// Burden  - Range 0-Health - corresponding to viral burden
// Virulence -  a multiplier to the burden
// Transmissibility - a probability for transmitting burden
// Durability - a probability that allows the viral burden to be reduced.


-(Nematode *) initWithSim: (Simulation *) sim;
-(void) incrementAge: (int) increment;
-(void) reproduceViruses;
-(void) growBy: (int) increment;
-(void) addInfection:(NSDictionary *) newInfection;
-(void) dealloc;
@end
