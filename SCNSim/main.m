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
        int replicates = 100;
        
        [[NSFileManager defaultManager] createFileAtPath:[@"~/Documents/UIUC/Papers/Journals/SCNModel/test.csv" stringByExpandingTildeInPath] contents:nil attributes:nil];
        __block NSFileHandle *agglog = [NSFileHandle fileHandleForWritingAtPath:[@"~/Documents/UIUC/Papers/Journals/SCNModel/test.csv" stringByExpandingTildeInPath]];
        if (agglog == nil) {
            NSLog(@"Failed to open file\n");
        }
        
        NSString *header = @"Cysts, InfectionRate, ViralLoad, Virulence, Transmissibility, BurstSize, MaxTicks, Filename\n";
        
        [agglog writeData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        /*
         int numcysts[4] = {1, 5, 10, 20};
         float infectionrate[4] = {0.2, 0.4, 0.6, 0.8};
         float virload[4] = {5, 10, 50, 100};
         float virulence[4] = {0.2, 0.4, 0.6, 0.8};
         float transmissibility[4] = {0.2, 0.4, 0.6, 0.8};
         float burstsize[4] = {4, 8, 16, 32};
         */
        
        int numcysts[] = {16,18,20,21,22,23,24,25,26,27,28,29,30,32,34};
        float infectionrate[] = {0};
        int virload[] = {100};
        float virulence[] = {0.1};
        float transmissibility[] = {0.8};
        int burstsize[] = {50};
        
        /*
         NSString *aggfile = [NSString stringWithFormat: @"%@burnout.csv", folder];
         aggfile = [NSFileHandle fileHandleForWritingAtPath:aggfile];
         if (aggfile == nil) {
         NSLog(@"Creating logfile for the first time\n");
         [[NSFileManager defaultManager] createFileAtPath:aggfile contents:nil attributes:nil];
         aggfile = [NSFileHandle fileHandleForWritingAtPath:aggfile];
         
         }
         */
        
        dispatch_queue_t io_queue = dispatch_queue_create("edu.illinois.bhalerao.io", NULL);
        dispatch_queue_t async_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_group_t group = dispatch_group_create();
        uint64_t cpuCount = [[NSProcessInfo processInfo] processorCount];
        dispatch_semaphore_t jobSemaphore = dispatch_semaphore_create(cpuCount * 2);
        
        NSMutableDictionary *basedict = [[NSMutableDictionary alloc] init];
        
        for (int cyst=0; cyst<sizeof(numcysts)/sizeof(int); cyst++) {
            basedict[@"cysts"] = @(numcysts[cyst]);
            
            for (int inf=0; inf<sizeof(infectionrate)/sizeof(float); inf++) {
                basedict[@"infrate"] = @(infectionrate[inf]);
                
                for (int vload=0; vload<sizeof(virload)/sizeof(float); vload++) {
                    basedict[@"virload"] = @(virload[vload]);
                    
                    for (int vir=0; vir<sizeof(virulence)/sizeof(float); vir++) {
                        basedict[@"virulence"] = @(virulence[vir]);
                        
                        for (int trans=0; trans<sizeof(transmissibility)/sizeof(float); trans++) {
                            basedict[@"transmissibility"] = @(transmissibility[trans]);
                            
                            for (int bsize=0; bsize<sizeof(burstsize)/sizeof(int); bsize++) {
                                basedict[@"burstsize"] = @(burstsize[bsize]);
                                
                                for (int i=0; i<replicates; i++) {
                                    NSDictionary *dict = [NSDictionary dictionaryWithDictionary:basedict];
                                    
                                    dispatch_semaphore_wait(jobSemaphore, DISPATCH_TIME_FOREVER);

                                    dispatch_group_async(group, io_queue, ^{
                                        @autoreleasepool {
                                        dispatch_group_async(group, async_queue, ^{
                                            //[basedict self];
                                            Simulation *mysim = [[Simulation alloc]
                                                                 initForMaxTicks:10*24*365
                                                                 withCysts:[dict[@"cysts"] intValue]];
                                            
                                            [mysim infectCystsAtRate:[dict[@"infrate"] floatValue]
                                                             atLoads:[dict[@"virload"] intValue]
                                                       withVirluence:[dict[@"virulence"] floatValue]
                                                withTransmissibility:[dict[@"transmissibility"] floatValue]
                                                       withBurstSize:[dict[@"burstsize"] intValue]];
                                            
                                            NSUUID *unique = [NSUUID UUID];
                                            NSString *filename = [NSString stringWithFormat: @"%@/%@.csv",
                                                                  [@"~/Documents/UIUC/Papers/Journals/SCNModel/test" stringByExpandingTildeInPath],
                                                                  [unique UUIDString]];
                                            [mysim setLogFile:filename];
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
                                                    [agglog writeData:[iteration dataUsingEncoding:NSUTF8StringEncoding]];
                                                    NSLog(@"%@", iteration);
                                                    dispatch_semaphore_signal(jobSemaphore);
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
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    }
}



