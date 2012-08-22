//
//  Simulation.h
//  SCNSim
//
//  Created by Kaustubh Bhalerao on 8/4/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Soybean.h"
#import "Environment.h"

@interface Simulation : NSObject {
    int maxTicks;
    NSFileHandle *logfile;
    NSMutableDictionary *report_dict;
    NSArray *columns;
    int Done;
}

@property (readonly) Soybean* soybean;
@property (readonly) Environment *environment;
@property NSMutableArray *nematodes;
@property (readonly) int simTicks;
@property int reportInterval;
@property int breakIfNoViruses;
@property int numMales;
@property NSMutableArray *potentialMates;
@property NSMutableArray *deadNematodes;

-(Simulation*) initForMaxTicks: (int) ticks withCysts: (int) cysts;
-(void) installNewNematodes: (NSMutableArray*) new_nematodes;
-(void) setLogFile: (NSString*) logfilename;
-(void) infectCystsAtRate: (float) infectionRate
                  atLoads: (int) viralLoads
            withVirluence: (float) Virulence
     withTransmissibility: (float) Transmissibility
            withBurstSize: (int) BurstSize
           withDurability: (float) Durability;
-(int) run;
-(void) convertEggSacsToCysts;
-(void) dealloc;

@end
