//
//  Virus.m
//  SCNModel_C
//
//  Created by Kaustubh Bhalerao on 8/3/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import "Virus.h"
#import "helpers.h"

@implementation Virus

@synthesize Virulence;
@synthesize Transmissibility;
@synthesize BurstSize;
@synthesize Alive;

-(Virus*) initWithVirulence:(float)virulence
           Transmissibility:(float)transmissibility
                  BurstSize:(int)burstSize {
    
    if (self = [super init]) {
        BurstSize = burstSize;
        Transmissibility = transmissibility;
        Virulence = virulence;
        Alive = TRUE;
    }
    return self;
}

-(void) mutate:(float)probability {
    // modifies the genome of the virus based on a given probability
    // sets upper limit to virulence and transmissibility as 1
    // since these numbers are used as a probability
    
    if(coin_toss(probability)) {
        Transmissibility += random_gauss(0, 0.05);
        Virulence += random_gauss(0, 0.05);
        BurstSize += random_integer(-3, 3);
    }
    if (Transmissibility > 1) Transmissibility = 1;
    if (Virulence > 1) Virulence = 1;
    if (Transmissibility <= 0) Alive=FALSE;
    if (Virulence <= 0) Alive=FALSE;
    if (BurstSize <= 0) Alive=FALSE;
}

@end
