//
//  main.m
//  SCNSim
//
//  Created by Kaustubh Bhalerao on 8/4/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Simulation.h"


int main(int argc, const char * argv[])
{
    Simulation *mysim = [[Simulation alloc] initForMaxTicks:24*365 withCysts:5];
    [mysim infectCystsAtRate:1 atLoads:10 withVirluence:0.1 withTransmissibility:0.8 withBurstSize:8];
    [mysim setLogFile:@"/Users/kbhalerao/Documents/UIUC/Papers/Journals/SCNModel/log.txt"];
    [mysim run];
    
    return 0;

}
