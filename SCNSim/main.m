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
    int replicates = 10;
    
    NSString *folder = [@"~/Documents/UIUC/Papers/Journals/SCNModel/burnout2" stringByExpandingTildeInPath];

        
    int numcysts[4] = {1, 5, 10, 20};
    float infectionrate[4] = {0.2, 0.4, 0.6, 0.8};
    float virload[4] = {5, 10, 50, 100};
    float virulence[4] = {0.2, 0.4, 0.6, 0.8};
    float transmissibility[4] = {0.2, 0.4, 0.6, 0.8};
    float burstsize[4] = {4, 8, 16, 32};
        
/*
    int numcysts[1] = {20};
    float infectionrate[1] = {0.8};
    int virload[1] = {100};
    float virulence[1] = {0.8};
    float transmissibility[1] = {0.8};
    float burstsize[1] = {32};
*/
    /*
    NSString *aggfile = [NSString stringWithFormat: @"%@burnout.csv", folder];
    aggfile = [NSFileHandle fileHandleForWritingAtPath:aggfile];
    if (aggfile == nil) {
        NSLog(@"Creating logfile for the first time\n");
        [[NSFileManager defaultManager] createFileAtPath:aggfile contents:nil attributes:nil];
        aggfile = [NSFileHandle fileHandleForWritingAtPath:aggfile];
        
    }
     */
    
    //dispatch_queue_t main_queue = dispatch_get_main_queue();
    dispatch_queue_t async_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    
    __block NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    for (int cyst=0; cyst<sizeof(numcysts)/sizeof(int); cyst++) {
        [dict setObject: [NSNumber numberWithInt:numcysts[cyst]]forKey:@"cysts"];
        
        for (int inf=0; inf<sizeof(infectionrate)/sizeof(float); inf++) {
            [dict setObject: [NSNumber numberWithFloat:infectionrate[inf]]forKey:@"infrate"];
            
            for (int vload=0; vload<sizeof(virload)/sizeof(float); vload++) {
                [dict setObject: [NSNumber numberWithInt:virload[vload]]forKey:@"virload"];
                
                for (int vir=0; vir<sizeof(virulence)/sizeof(float); vir++) {
                    [dict setObject: [NSNumber numberWithFloat:virulence[vir]]forKey:@"virulence"];
                    
                    for (int trans=0; trans<sizeof(transmissibility)/sizeof(float); trans++) {
                        [dict setObject: [NSNumber numberWithFloat:transmissibility[trans]]forKey:@"transmissibility"];
                        
                        for (int bsize=0; bsize<sizeof(burstsize)/sizeof(int); bsize++) {
                            [dict setObject: [NSNumber numberWithInt:burstsize[bsize]]forKey:@"burstsize"];
                            
                            for (int i=0; i<replicates; i++) {
                                dispatch_async(async_queue, ^{
                                    @autoreleasepool {
                                        
                                        Simulation *mysim = [[Simulation alloc]
                                                             initForMaxTicks:3*24*365
                                                             withCysts:[[dict objectForKey:@"cysts"] intValue]];
                                    
                                        [mysim infectCystsAtRate:[[dict objectForKey:@"infrate"] floatValue]
                                                         atLoads:[[dict objectForKey:@"virload"] intValue]
                                                   withVirluence:[[dict objectForKey:@"virulence"] floatValue]
                                            withTransmissibility:[[dict objectForKey:@"transmissibility"] floatValue]
                                                   withBurstSize:[[dict objectForKey:@"burstsize"] intValue]];
                                        
                                        NSUUID *unique = [NSUUID UUID];
                                        NSString *filename = [NSString stringWithFormat: @"%@/%@.csv", folder, [unique UUIDString]];
                                        [mysim setLogFile:filename];
                                        NSLog(@"%@\n", filename);
                                        //dispatch_async(runner, ^{
                                            NSLog(@"%i",[mysim run]);
                                        //});
                                    }
                                });
                            }
                        }
                    }
                }
            }
        }
    }
    //dispatch_sync(async_queue, ^{
    //    NSLog(@"AllDone!");
    //    exit(0);
    //});
    
    dispatch_main();
    return 0;
}



