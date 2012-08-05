//
//  Simulation.m
//  SCNSim
//
//  Created by Kaustubh Bhalerao on 8/4/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import "Simulation.h"
#import "Soybean.h"
#import "Environment.h"
#import "Nematode.h"
#import "helpers.h"

@implementation Simulation

-(Simulation*) initForMaxTicks: (int) ticks withCysts: (int) cysts {
    if (self =[super init]) {
        maxTicks = ticks;
        simTicks = 0;
        environment = [[Environment alloc] init];
        soybean = [[Soybean alloc] init];
        nematodes = [[NSMutableArray alloc] init];
        
        [self populateCysts: cysts];
    }
    return self;
}

-(void) populateCysts: (int) cysts {
    NSMutableArray *cystList = [[NSMutableArray alloc] init];
    for(int i=0; i<cysts; i++) {
        Nematode *cyst = [[Nematode alloc] initWithState:EGGSAC inSim:self];
        [cystList addObject:cyst];
    }
}

-(void) installNewNematodes: (NSArray*) new_nematodes {
    [nematodes addObjectsFromArray:nematodes];
}
-(Soybean*) soybean {
    return soybean;
}
-(Environment*) environment {
    return environment;
}
-(NSMutableArray*) nematodes {
    return nematodes;
}

-(void) setLogFile: (NSString*) logfilename {
    logfile = [NSFileHandle fileHandleForWritingAtPath:logfilename];
    if (logfile == nil) {
        NSLog(@"Failed to open file\n");
    }
    else {
        const char *header = "Tick,Temperature,Soybean Size,Nematode count,Avg Health, \
        Virus load avg,Virus load std dev,Avg virulence,Virulence st dev, \
        Avg transmissibility,Transmissibility st dev,Avg burst size,Burst size st dev,\
        Avg eggs per sac\n";
        
        NSData *line = [[NSData alloc] initWithBytes:header length:strlen(header)];
        [logfile writeData: line];
    }
}

-(void) infectCystsAtRate: (float) infectionRate          atLoads: (int) viralLoads
            withVirluence: (float) Virulence withTransmissibility: (float) Transmissibility
            withBurstSize: (int) BurstSize {
    for (int i=0; i<[nematodes count]; i++) {
        if (coin_toss(infectionRate)) {
            NSMutableArray *viruslist = [[NSMutableArray alloc] init];
            for (int j=0; j<BurstSize; j++) {
                Virus *virus = [[Virus alloc] initWithVirulence:Virulence
                                               Transmissibility:Transmissibility
                                                      BurstSize:BurstSize];
                [virus mutate:1];
                [viruslist addObject:virus];
            }
        }
    }
    NSLog(@"Infected eggs with viruses\n");
}
-(void) run {
    ;
}

-(void) report {
    ;
}
@end
