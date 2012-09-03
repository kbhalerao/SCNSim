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
            numMales = 0;
            potentialMates = [[NSMutableArray alloc] init];
            deadNematodes = [[NSMutableArray alloc] init];
            deathByVirus = 0;
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
@synthesize numMales;
@synthesize potentialMates;
@synthesize deadNematodes;
@synthesize deathByVirus;

-(void) dealloc {
    environment = nil;
    soybean = nil;
    nematodes = nil;
    report_dict = nil;
    potentialMates = nil;
}

-(void) populateCysts: (int) cysts {
    @autoreleasepool {
        for(int i=0; i<cysts; i++) {
            Nematode *cyst = [[Nematode alloc] initWithSim: self];
            [cyst setHealth:random_float()*100];
            [nematodes addObject:cyst];
            
            int numUnhatchedJ2 = random_integer(300,500);
            [cyst setNumContained:numUnhatchedJ2];
            for (int i=0; i<numUnhatchedJ2; i++) {
                Nematode *j2u = [[Nematode alloc] initWithSim:self];
                [j2u setInContainer: cyst];
                [j2u setState:UNHATCHEDJ2];
                [nematodes addObject:j2u];
            }
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

-(void) infectCystsAtRate:(float)infectionRate          atBurden:(float)burden
            withVirluence:(float)Virulence  withTransmissibility:(float)Transmissibility
           withDurability:(float)Durability {
    @autoreleasepool {
        for (int i=0; i<[nematodes count]; i++) {
            if (coin_toss(infectionRate) && [nematodes[i] State] == UNHATCHEDJ2) {
                NSMutableDictionary *viruses = [[NSMutableDictionary alloc] initWithCapacity:4];
                viruses[@"Burden"] = @(burden);
                viruses[@"Transmissibility"] = @(Transmissibility);
                viruses[@"Durability"] = @(Durability);
                viruses[@"Virulence"] = @(Virulence);
                
                [nematodes[i] addInfection:viruses];
            }
        }
        NSLog(@"Infected eggs with viruses\n");
    }
}

-(void) removeDeadNematodes {
    @autoreleasepool {
        [nematodes removeObjectsInArray:deadNematodes];
        [deadNematodes removeAllObjects];
    }
}

-(void) convertEggSacsToCysts {
    
    if([environment Temperature] < 68) {
        @autoreleasepool {
            
            for (Nematode *nem in nematodes) {
                if ([nem State] == EGGSAC) {
                    [nem setState:CYST];
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
        @autoreleasepool {
            // run every day
            
            for (int i=0; i<[nematodes count]; i++) {
                @autoreleasepool {
                    [nematodes[i] reproduceViruses];
                }
            }
            [environment increment_age:1];
            [self removeDeadNematodes];
            [soybean growIncrement:1 temp:[environment Temperature]];
            for (int i=0; i<[nematodes count]; i++) [nematodes[i] growBy: 1];
            [self convertEggSacsToCysts];
            
            
            @autoreleasepool {
                if (simTicks % reportInterval==0) [self report];
            }
        }
        simTicks ++;
        //NSLog(@"%d", simTicks);
    }
    [logfile closeFile];
    return simTicks;
}

-(void) report {
    @autoreleasepool {
        
        report_dict[@"Tick"] = @(simTicks);
        report_dict[@"Temperature"] = @([environment Temperature]);
        report_dict[@"Soybean"] = @([soybean PlantSize]);
        report_dict[@"Nematodes"] = @([nematodes count]);
        report_dict[@"Death by virus"] = @(deathByVirus);
        
        @autoreleasepool {
            NSArray *stats_health = [self meanAndStandardDeviationOf:[nematodes valueForKey:@"Health"]];
            report_dict[@"Health mean"] = stats_health[0];
            report_dict[@"Health stdev"] = stats_health[1];
            if ([stats_health[0] floatValue] > 100) NSLog(@"Ping!\n"); // Yikes!
        }
        
        @autoreleasepool {
            int nem_infected = 0;

            NSArray *infection_array = [nematodes valueForKey:@"Infection"];

            NSMutableArray *burden = [[NSMutableArray alloc] init];
            NSMutableArray *wt_trans = [[NSMutableArray alloc] init];
            NSMutableArray *wt_vir = [[NSMutableArray alloc] init];
            NSMutableArray *wt_dur = [[NSMutableArray alloc] init];
            
            float sum_burden = 0;
            for (int i=0; i<[infection_array count]; i++) {
                NSDictionary *inf = infection_array[i];
                burden[i] = inf[@"Burden"];
                sum_burden += [burden[i] floatValue];
                if ([burden[i] floatValue] > 0) {
                    nem_infected++;
                    [wt_trans addObject:@([burden[i] floatValue]*[inf[@"Transmissibility"] floatValue])];
                    [wt_dur addObject:@([burden[i] floatValue]*[inf[@"Transmissibility"] floatValue])];
                    [wt_vir addObject:@([burden[i] floatValue]*[inf[@"Virulence"] floatValue])];
                }                
            }
            
            report_dict[@"Virus Load"] = @(sum_burden/nem_infected);
            report_dict[@"Fraction Infected"] = @((float)nem_infected/[nematodes count]);
            
            
            NSArray *trans_stats = [self meanAndStandardDeviationOf:wt_trans];
            report_dict[@"Transmissibility mean"] = trans_stats[0];
            report_dict[@"Transmissibility stdev"] = trans_stats[1];
            
            NSArray *vir_stats = [self meanAndStandardDeviationOf:wt_vir];
            report_dict[@"Virulence mean"] = vir_stats[0];
            report_dict[@"Virulence stdev"] = vir_stats[1];
            
            NSArray *dur_stats = [self meanAndStandardDeviationOf:wt_dur];
            report_dict[@"Durability mean"] = dur_stats[0];
            report_dict[@"Durability stdev"] = dur_stats[1];
            
            if (!nem_infected && breakIfNoViruses) {
                NSLog(@"All viruses dead");
                Done = TRUE;
            }

        }
        
        
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
        
        // here's an update of the potential males 
        numMales = [stateCounts[M] intValue]; // for use in hatching function
        
        int numEggSacs = [stateCounts[EGGSAC] intValue];
        int numCysts = [stateCounts[CYST] intValue];
        
        int unhatcheds = [stateCounts[EMBRYO] intValue] + [stateCounts[J1] intValue] + [stateCounts[UNHATCHEDJ2] intValue];
        report_dict[@"Eggs per container mean"] = @(unhatcheds/((float) (numEggSacs + numCysts)));
        
        
        
        if (simTicks==0) {
            // run only for the first time
            // create the keys structure from the dictionary to use everytime
            columns = [report_dict allKeys];
            NSString *header = [NSString stringWithFormat: @"%@\n", [columns componentsJoinedByString:@","]];
            [logfile writeData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        NSArray *report_values = [report_dict objectsForKeys:columns notFoundMarker:@"None"];
        
        NSString *report_line = [NSString stringWithFormat:@"%@\n", [report_values componentsJoinedByString:@","]];
        //NSLog(@"%@",report_line);
        [logfile writeData:[report_line dataUsingEncoding:NSUTF8StringEncoding]];
        

        
        if (![nematodes count]) {
            NSLog(@"All nematodes dead");
            Done = TRUE;
        }
    }
}



//// Statistical functions


// code adapted from StackOverflow

-(NSNumber*) meanOf:(NSArray *)array {
    @autoreleasepool {
        
        float runningTotal = 0.0;
            
            for(NSNumber *number in array)
            {
                @try {runningTotal += [number floatValue];}
                @catch (NSException *e) {
                    NSLog(@"Exception: %@", [e reason]);
                }
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
