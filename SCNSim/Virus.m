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

    -(Virus*) initWithVirulence:(float)virulence Transmissibility:(float)transmissibility BurstSize:(int)burstSize {
        if (self = [super init]) {
            [self setBurstSize: burstSize];
            [self setTransmissibility: transmissibility];
            [self setVirulence: virulence];
        }
        return self;
    }

    -(void) mutate:(float)probability {
        if(coin_toss(probability)) {
            Transmissibility += random_gauss(0, 0.1);
            Virulence += random_gauss(0, 0.1);
            BurstSize += random_integer(-4, 4);
        }
        if (Transmissibility > 1) Transmissibility = 1;
        if (Virulence > 1) Virulence = 1;
    }

@end
