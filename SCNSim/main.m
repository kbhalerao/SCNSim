//
//  main.m
//  SCNSim
//
//  Created by Kaustubh Bhalerao on 8/4/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Simulation.h"
#import "helpers.h"
#import <dispatch/dispatch.h>


int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        
        // read the plist 
        NSString *errorDesc = nil;
        NSPropertyListFormat format;
        NSString *plistPath;
        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                  NSUserDomainMask, YES) objectAtIndex:0];
        plistPath = [rootPath stringByAppendingPathComponent:@"SimulationProperties.plist"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
            plistPath = [[NSBundle mainBundle] pathForResource:@"SimulationProperties" ofType:@"plist"];
        }
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        NSDictionary *simDict = (NSDictionary *)[NSPropertyListSerialization
                                              propertyListFromData:plistXML
                                              mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                              format:&format
                                              errorDescription:&errorDesc];
        if (!simDict) {
            NSLog(@"Error reading plist: %@, format: %ld", errorDesc, format);
            exit(-1);
        }
        
        // extract values from the plist
        

        NSString *fileid = [simDict[@"Experiment identifier"] stringValue];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:fileid
                                  withIntermediateDirectories:YES attributes:nil error:nil];
        
        [[NSFileManager defaultManager] createFileAtPath:[NSString stringWithFormat: @"%@.csv", fileid]
                                                contents:nil attributes:nil];
        
        __block NSFileHandle *agglog = [NSFileHandle fileHandleForWritingAtPath:
                                        [NSString stringWithFormat: @"%@.csv", fileid]];
        
        if (agglog == nil) {
            NSLog(@"Failed to open aggregate log file\n");
            exit(-1);
        }
        
        NSString *header = @"Cysts, InfectionRate, ViralLoad, Virulence, Transmissibility, BurstSize, MaxTicks, Filename\n";
        
        [agglog writeData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        NSArray *numcysts = simDict[@"Number of cysts"];
        NSArray *infectionrate = simDict[@"Infection rate"];
        NSArray *virload = simDict[@"Viral loads"];
        NSArray *virulence = simDict[@"Virulence"];
        NSArray *transmissibility = simDict[@"Transmissibility"];
        NSArray *burstsize = simDict[@"Burst size"];
        int replicates = [[simDict objectForKey:@"Replicates"] intValue];
        
        dispatch_queue_t io_queue = dispatch_queue_create("edu.illinois.bhalerao.io", NULL);
        dispatch_queue_t async_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_group_t group = dispatch_group_create();
        uint64_t cpuCount = [[NSProcessInfo processInfo] processorCount];
        dispatch_semaphore_t jobSemaphore = dispatch_semaphore_create(cpuCount * 2);
        
        NSMutableDictionary *basedict = [[NSMutableDictionary alloc] init];
        
        for (NSNumber *item_nc in numcysts) {
            basedict[@"cysts"] = item_nc;
            
            for (NSNumber *item_ir in infectionrate) {
                basedict[@"infrate"] = item_ir;
                
                for (NSNumber *item_vl in virload) {
                    basedict[@"virload"] = item_vl;
                    
                    for (NSNumber *item_v in virulence) {
                        basedict[@"virulence"] = item_v;
                        
                        for (NSNumber *item_t in transmissibility) {
                            basedict[@"transmissibility"] = item_t;
                            
                            for (NSNumber *item_bs in burstsize) {
                                basedict[@"burstsize"] = item_bs;
                                
                                @autoreleasepool {
                                    for (int i=0; i<replicates; i++) {
                                        NSDictionary *dict = [NSDictionary dictionaryWithDictionary:basedict];
                                        
                                        dispatch_semaphore_wait(jobSemaphore, DISPATCH_TIME_FOREVER);
                                        
                                        dispatch_group_async(group, io_queue, ^{
                                            @autoreleasepool {
                                                dispatch_group_async(group, async_queue, ^{
                                                    //[basedict self];
                                                    Simulation *mysim = [[Simulation alloc]
                                                                         initForMaxTicks:[simDict[@"Max ticks"] intValue]
                                                                         withCysts:[dict[@"cysts"] intValue]];
                                                    
                                                    [mysim setBreakIfNoViruses:[simDict[@"Break if no viruses"] boolValue]];
                                                    
                                                    [mysim infectCystsAtRate:[dict[@"infrate"] floatValue]
                                                                     atLoads:[dict[@"virload"] intValue]
                                                               withVirluence:[dict[@"virulence"] floatValue]
                                                        withTransmissibility:[dict[@"transmissibility"] floatValue]
                                                               withBurstSize:[dict[@"burstsize"] intValue]];
                                                    
                                                    [mysim setReportInterval:[simDict[@"Report interval"] intValue]];
                                                    
                                                    NSUUID *unique = [NSUUID UUID];
                                                    NSString *ufilename = [NSString stringWithFormat: @"%@/%@.csv",
                                                                          fileid, [unique UUIDString]];
                                                    
                                                    [mysim setLogFile:ufilename];
                                                    //NSLog(@"%@\n", filename);
                                                    //dispatch_sync(async_queue, ^{
                                                    int runs = [mysim run];
                                                    //@"Cysts, InfectionRate, ViralLoad, Virulence, Transmisibility, BurstSize, MaxTicks, Filename\n"
                                                    if (runs) {
                                                        NSString *iteration = [NSString stringWithFormat:@"%d,%.2f,%d,%.2f,%.2f,%d,%d,%@\n",
                                                                               [dict[@"cysts"] intValue],
                                                                               [dict[@"infrate"] floatValue],
                                                                               [dict[@"virload"] intValue],
                                                                               [dict[@"virulence"] floatValue],
                                                                               [dict[@"transmissibility"] floatValue],
                                                                               [dict[@"burstsize"] intValue],
                                                                               runs,
                                                                               [unique UUIDString]];
                                                        
                                                        dispatch_group_async(group, io_queue, ^{
                                                            
                                                            @autoreleasepool {
                                                                [agglog writeData:[iteration dataUsingEncoding:NSUTF8StringEncoding]];
                                                                NSLog(@"%@", iteration);
                                                                dispatch_semaphore_signal(jobSemaphore);
                                                            }
                                                        });}
                                                    else {dispatch_semaphore_signal(jobSemaphore);}
                                                });
                                            }
                                        });
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    }
}



