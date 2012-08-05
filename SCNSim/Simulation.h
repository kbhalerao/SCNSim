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
    NSMutableArray *nematodes;
    Soybean *soybean;
    Environment *environment;
    int simTicks;
    int maxTicks;
    NSFileHandle *logfile;
    NSMutableDictionary *report_dict;
    NSArray *columns;
    int reportInterval;
}
-(Simulation*) initForMaxTicks: (int) ticks withCysts: (int) cysts;
-(void) installNewNematodes: (NSArray*) new_ematodes;
-(Soybean*) soybean;
-(Environment*) environment;
-(NSMutableArray*) nematodes;
-(void) setLogFile: (NSString*) logfilename;
-(void) infectCystsAtRate: (float) infectionRate
                  atLoads: (int) viralLoads
            withVirluence: (float) Virulence
     withTransmissibility: (float) Transmissibility
            withBurstSize: (int) BurstSize;
-(void) run;

@end
