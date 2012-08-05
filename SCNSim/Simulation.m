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
        report_dict = [[NSMutableDictionary alloc] initWithCapacity:30]; //hopefully enough...
        reportInterval = 24;
        
        [self populateCysts: cysts];
    }
    return self;
}

-(void) populateCysts: (int) cysts {
    for(int i=0; i<cysts; i++) {
        Nematode *cyst = [[Nematode alloc] initWithState:EGGSAC inSim:self];
        [nematodes addObject:cyst];
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
    [[NSFileManager defaultManager] createFileAtPath:logfilename contents:nil attributes:nil];
    logfile = [NSFileHandle fileHandleForWritingAtPath:logfilename];
    if (logfile == nil) {
        NSLog(@"Failed to open file\n");
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

-(void) removeDeadNematodes {
    NSLog(@"Total Nematode Count %lu\n", [nematodes count]);
    NSPredicate *notdead = [NSPredicate predicateWithFormat:@"State != %i", @DEAD];
    NSPredicate *dead = [NSPredicate predicateWithFormat:@"State == %i", @DEAD];
    NSMutableArray *livenematodes = (NSMutableArray*)[nematodes filteredArrayUsingPredicate:notdead];
    NSMutableArray *deadnematodes = (NSMutableArray*)[nematodes filteredArrayUsingPredicate:dead];
    NSLog(@"Live :%lu  ", [livenematodes count]);
    NSLog(@"Dead: %lu\n", [deadnematodes count]);
    
}

-(void) logMessage: (NSString*) logstring {
    NSLog(@"%d: %@\n", simTicks, logstring);
}

-(void) run {
    while (simTicks < maxTicks) {
        for (int i=0; i<[nematodes count]; i++) [[nematodes objectAtIndex:i] reproduceViruses];
        if (simTicks % reportInterval==0) [self report];
        if (simTicks % 24==0) {
            [environment increment_age:24];
            [soybean growIncrement:1 temp:[environment temperature]];
            for (int i=0; i<[nematodes count]; i++) [[nematodes objectAtIndex:i] growBy: 1];
        }
        simTicks ++;
        //NSLog(@"%d", simTicks);
    }
    [logfile closeFile];
}

-(NSArray*) getArrayWithProperty: (NSString*) property ForArray: (NSMutableArray*) array {
    NSMutableArray *prop_array = [[NSMutableArray alloc] init];
    for (int i=0; i<[array count]; i++) {
        id value = [[array objectAtIndex:i] valueForKey: property];
        [prop_array addObject:value];
    }
    return prop_array;
}

-(NSArray*) getStatsForProperty: (NSString*) property ForArray: (NSMutableArray*) array {
    return [self meanAndStandardDeviationOf:[self getArrayWithProperty:property ForArray:array]];
}

-(NSArray*) partitionArrayforState: (int) state {
    NSPredicate *fraction = [NSPredicate predicateWithFormat:@"State != %i", state];
    return [nematodes filteredArrayUsingPredicate:fraction];
}

-(void) report {
    
    [report_dict setObject:[NSNumber numberWithInt:simTicks] forKey:@"Ticks"];
    [report_dict setObject: [NSNumber numberWithInt:[environment temperature]] forKey: @"Temperature"];
    [report_dict setObject: [NSNumber numberWithFloat:[soybean PlantSize]] forKey: @"Soybean"];
    [report_dict setObject: [NSNumber numberWithUnsignedLong:[nematodes count]] forKey: @"Nematodes"];
    
    NSArray *stats_health = [self getStatsForProperty:@"Health" ForArray:nematodes];
    [report_dict setObject: stats_health[0] forKey: @"Health mean"];
    [report_dict setObject: stats_health[1] forKey: @"Health stdev"];
    
    NSMutableArray *vir_acc = [[NSMutableArray alloc] init];
    NSArray *vir_arrays = [self getArrayWithProperty:@"Viruses" ForArray:nematodes];
    for (int i=0; i<[vir_arrays count]; i++) {
        [vir_acc addObjectsFromArray:[vir_arrays objectAtIndex: i]];
    }
    
    [report_dict setObject: [NSNumber numberWithFloat:[vir_acc count]/[nematodes count]] forKey: @"Virus Load"];
    
    NSArray *trans_stats = [self getStatsForProperty:@"Transmissibility" ForArray:vir_acc];
    [report_dict setObject: trans_stats[0] forKey: @"Transmissibility mean"];
    [report_dict setObject: trans_stats[1] forKey: @"Transmissibility stdev"];
    
    NSArray *vir_stats = [self getStatsForProperty:@"Virulence" ForArray:vir_acc];
    [report_dict setObject: vir_stats[0] forKey: @"Virulence mean"];
    [report_dict setObject: vir_stats[1] forKey: @"Virulence stdev"];
    
    NSArray *burst_stats = [self getStatsForProperty:@"BurstSize" ForArray:vir_acc];
    [report_dict setObject: burst_stats[0] forKey: @"BurstSize mean"];
    [report_dict setObject: burst_stats[1] forKey: @"BurstSize stdev"];
    
    NSArray *stateNames = [[NSArray alloc] initWithObjects: @"Embryo", @"J1", @"J2", @"J3", \
                           @"J4M", @"J4F", @"M", @"F", @"F_Prime", @"EggSac", @"Dead", @"Mating", nil];
    
    for (int i=0; i<[stateNames count]; i++) {
        NSNumber *statecount = [NSNumber numberWithUnsignedLong:[[self partitionArrayforState:i] count]];
        [report_dict setObject:statecount forKey:[stateNames objectAtIndex:i]];
    }
    
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
    
    
}

//// Statistical functions


// code adapted from StackOverflow

-(NSNumber*) meanOf:(NSArray *)array {
    float runningTotal = 0.0;
    
    for(NSNumber *number in array)
    {
        runningTotal += [number floatValue];
    }
    
    return [NSNumber numberWithFloat:(runningTotal / [array count])];
}

-(NSArray*) meanAndStandardDeviationOf:(NSArray*) array {
    
    if(![array count]) return [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:0],\
                               [NSNumber numberWithInt:0], nil];
    
    NSNumber *average = [self meanOf: array];
    float mean = [average floatValue];
    float sumOfSquaredDifferences = 0.0;
    
    for(NSNumber *number in array)
    {
        float valueOfNumber = [number floatValue];
        float difference = valueOfNumber - mean;
        sumOfSquaredDifferences += difference * difference;
    }
    
    NSNumber* sd= [NSNumber numberWithFloat:sqrt(sumOfSquaredDifferences / [array count])];
    
    return [[NSArray alloc] initWithObjects:average, sd, nil];
}

@end
