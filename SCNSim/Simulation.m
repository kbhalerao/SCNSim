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
    @autoreleasepool {
        if (self =[super init]) {
            maxTicks = ticks;
            simTicks = 0;
            environment = [[Environment alloc] init];
            soybean = [[Soybean alloc] init];
            nematodes = [[NSMutableArray alloc] init];
            report_dict = [[NSMutableDictionary alloc] initWithCapacity:30]; //hopefully enough...
            reportInterval = 24;
            Done = FALSE;
            [self populateCysts: cysts];
            breakIfNoViruses = FALSE;
        }
        return self;
    }
}

@synthesize soybean;
@synthesize environment;
@synthesize nematodes;
@synthesize simTicks;
@synthesize reportInterval;
@synthesize breakIfNoViruses;


-(void) populateCysts: (int) cysts {
    @autoreleasepool {
        for(int i=0; i<cysts; i++) {
            Nematode *cyst = [[Nematode alloc] initCystWithNumUnhatchedJ2s:random_integer(300,500)
                                                                     inSim:self];
            [nematodes addObject:cyst];
        }
    }
}

-(void) installNewNematodes: (NSMutableArray*) new_nematodes {
    [nematodes addObjectsFromArray:new_nematodes];
}

-(void) setLogFile: (NSString*) logfilename {
    @autoreleasepool {
        [[NSFileManager defaultManager] createFileAtPath:logfilename contents:nil attributes:nil];
        logfile = [NSFileHandle fileHandleForWritingAtPath:logfilename];
        if (logfile == nil) {
            NSLog(@"Failed to open file\n");
        }
    }
}

-(void) infectCystsAtRate: (float) infectionRate          atLoads: (int) viralLoads
            withVirluence: (float) Virulence withTransmissibility: (float) Transmissibility
            withBurstSize: (int) BurstSize {
    @autoreleasepool {
        for (int i=0; i<[nematodes count]; i++) {
            if (coin_toss(infectionRate)) {
                NSMutableArray *viruslist = [[NSMutableArray alloc] init];
                for (int j=0; j<BurstSize; j++) {
                    @autoreleasepool {
                        Virus *virus = [[Virus alloc] initWithVirulence:Virulence
                                                       Transmissibility:Transmissibility
                                                              BurstSize:BurstSize];
                        [virus mutate:1];
                        [viruslist addObject:virus];
                    }
                }
                [nematodes[i] setViruses:viruslist];
            }
        }
        NSLog(@"Infected eggs with viruses\n");
    }
}

-(void) removeDeadNematodes {
    
    @autoreleasepool {
        NSArray *deadNematodes = [nematodes filteredArrayUsingPredicate:
                                  [NSPredicate predicateWithFormat:@"State == %i", DEAD]];
        for (Nematode *nem in deadNematodes) {
            [nem setSim: nil];
            [nem setViruses:nil];
            [nem setInContainer:nil];
        }
    }
    [nematodes filterUsingPredicate:[NSPredicate predicateWithFormat:@"State != %i", DEAD]];

}

-(void) convertEggSacsToCysts {
    
    if([environment temperature] <68) {
        @autoreleasepool {
            NSArray *eggsacs = [nematodes filteredArrayUsingPredicate:
                                [NSPredicate predicateWithFormat:@"State == %i", EGGSAC]];
            if ([eggsacs count]>0) {
                // convert all eggsacs to cysts and change
                // nematode memberships to incontainer cysts.

                for (Nematode *sac in eggsacs) {
                    [sac setState:CYST];
                }
            }
        }
    }
}

-(void) logMessage: (NSString*) logstring {
    @autoreleasepool {
        NSLog(@"%d: %@\n", simTicks, logstring);
    }
}

-(int) run {
    while (simTicks < maxTicks && !Done) {
        for (int i=0; i<[nematodes count]; i++) [nematodes[i] reproduceViruses];
        if (simTicks % reportInterval==0) [self report];
        if (simTicks % 24==0) {
            [environment increment_age:24];
            [soybean growIncrement:1 temp:[environment temperature]];
            [self removeDeadNematodes];
            for (int i=0; i<[nematodes count]; i++) [nematodes[i] growBy: 1];
        }
        simTicks ++;
        //NSLog(@"%d", simTicks);
    }
    [self cleanup];
    return simTicks;
}

-(void) cleanup {
    [logfile closeFile];
    Done = TRUE;
}

-(void) report {
    @autoreleasepool {
        
        report_dict[@"Tick"] = @(simTicks);
        report_dict[@"Temperature"] = @([environment temperature]);
        report_dict[@"Soybean"] = @([soybean PlantSize]);
        report_dict[@"Nematodes"] = @([nematodes count]);
        
        NSArray *stats_health = [self meanAndStandardDeviationOf:[nematodes valueForKey:@"Health"]];
        report_dict[@"Health mean"] = stats_health[0];
        report_dict[@"Health stdev"] = stats_health[1];
        if ([stats_health[0] floatValue] > 100) NSLog(@"Ping!\n"); // Yikes!
        
        NSMutableArray *vir_acc = [[NSMutableArray alloc] init];
        NSArray *vir_arrays = [nematodes valueForKey:@"Viruses"];
        for (int i=0; i<[vir_arrays count]; i++) [vir_acc addObjectsFromArray:vir_arrays[i]];
        
        report_dict[@"Virus Load"] = @([vir_acc count]/(float)[nematodes count]);
        
        NSArray *trans_stats = [self meanAndStandardDeviationOf:[vir_acc valueForKey:@"Transmissibility"]];
        report_dict[@"Transmissibility mean"] = trans_stats[0];
        report_dict[@"Transmissibility stdev"] = trans_stats[1];
        
        NSArray *vir_stats = [self meanAndStandardDeviationOf:[vir_acc valueForKey:@"Virulence"]];
        report_dict[@"Virulence mean"] = vir_stats[0];
        report_dict[@"Virulence stdev"] = vir_stats[1];
        
        NSArray *burst_stats = [self meanAndStandardDeviationOf:[vir_acc valueForKey:@"BurstSize"]];
        report_dict[@"BurstSize mean"] = burst_stats[0];
        report_dict[@"BurstSize stdev"] = burst_stats[1];
        
        NSArray *stateNames = @[@"Embryo", @"J1", @"UnhatchedJ2", @"J2", @"J3", \
                               @"J4M", @"J4F", @"M", @"F", @"Mating", @"F_Prime", @"EggSac", @"Cyst", @"Dead"];
        
        NSMutableArray *stateCounts = [[NSMutableArray alloc] initWithCapacity:[stateNames count]];
        for (int i=0; i<[stateNames count]; i++) [stateCounts setObject:@0 atIndexedSubscript:i];
        
        @autoreleasepool {
            for (Nematode *nem in nematodes) {
                int st = [nem State];
                int current_count = [stateCounts[st] intValue];
                current_count++;
                [stateCounts setObject: @(current_count) atIndexedSubscript:st];
            }
        }
        
        for (int i=0; i<[stateNames count]; i++) {
            report_dict[stateNames[i] ] = stateCounts[i];
        }
        
        NSArray *eggsacs = [nematodes filteredArrayUsingPredicate:
                         [NSPredicate predicateWithFormat:@"State == %i", EGGSAC]];
        NSArray *cysts = [nematodes filteredArrayUsingPredicate:
                          [NSPredicate predicateWithFormat:@"State == %i", CYST]];
        
        NSArray *allUnhatchedJ2s = [nematodes filteredArrayUsingPredicate:
                                    [NSPredicate predicateWithFormat:@"inContainer != nil"]];
    
        report_dict[@"Eggs per container mean"] = @(((float)[eggsacs count] + (float)[cysts count]) \
                                                                /[allUnhatchedJ2s count]);
        
        
        if (simTicks==0) {
            // run only for the first time
            // create the keys structure from the dictionary to use everytime
            columns = [report_dict allKeys];
            NSString *header = [NSString stringWithFormat: @"%@\n", [columns componentsJoinedByString:@","]];
            [logfile writeData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        NSArray *report_values = [report_dict objectsForKeys:columns notFoundMarker:@"None"];
        
        NSString *report_line = [NSString stringWithFormat:@"%@\n", [report_values componentsJoinedByString:@","]];
        [logfile writeData:[report_line dataUsingEncoding:NSUTF8StringEncoding]];
        
        if (![vir_acc count] && breakIfNoViruses) [self cleanup];
        if (![nematodes count]) [self cleanup];
        // eject if the viruses or nematodes are all dead
    }
}



//// Statistical functions


// code adapted from StackOverflow

-(NSNumber*) meanOf:(NSArray *)array {
    @autoreleasepool {
        
        float runningTotal = 0.0;
            
            for(NSNumber *number in array)
            {
                runningTotal += [number floatValue];
            }
        
        return @(runningTotal / [array count]);
    }    
}

-(NSArray*) meanAndStandardDeviationOf:(NSArray*) array {
    @autoreleasepool {
    
        if(![array count]) return @[@0,@0];
        else {
            NSNumber *average = [self meanOf: array];
            float mean = [average floatValue];
            float sumOfSquaredDifferences = 0.0;
            
            for(NSNumber *number in array)
            {
                float valueOfNumber = [number floatValue];
                float difference = valueOfNumber - mean;
                sumOfSquaredDifferences += difference * difference;
            }
            
            NSNumber* sd= @(sqrt(sumOfSquaredDifferences / [array count]));
            
            return @[average, sd];
        }
    }
}

@end
