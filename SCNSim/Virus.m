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

    -(Virus*) initWithVirulence:(float)virulence Transmissibility:(float)transmissibility BurstSize:(int)burstSize {
        if (self = [super init]) {
            [self setBurstSize: burstSize];
            [self setTransmissibility: transmissibility];
            [self setVirulence: virulence];
        }
        return self;
    }
    -(int) BurstSize {
        return BurstSize;
    }
    -(float) Transmissibility {
        return Transmissibility;
    }
    -(float) Virulence {
        return Virulence;
    }
    
    -(void) setBurstSize: (int) newburst {
        BurstSize = newburst;
    }
    -(void) setTransmissibility: (float) newtransmissibility {
        Transmissibility = newtransmissibility;
    }
    -(void) setVirulence: (float) newvirulence {
        Virulence = newvirulence;
    }
@end
