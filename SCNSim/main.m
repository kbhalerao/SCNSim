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


int main(int argc, const char * argv[])
{
    Simulation *mysim = [[Simulation alloc] initForMaxTicks:3*24*365 withCysts:10];
    [mysim infectCystsAtRate:0.4 atLoads:10 withVirluence:0.1 withTransmissibility:0.8 withBurstSize:4];
    [mysim setLogFile:@"/Users/kbhalerao/Documents/UIUC/Papers/Journals/SCNModel/log.txt"];
    [mysim run];
    
    //for (int i=0; i<100; i++) {
    //    printf("%f\n", random_gauss(0,1));
    //}
    
    return 0;

}
