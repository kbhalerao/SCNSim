//
//  Virus.h
//  SCNModel_C
//
//  Created by Kaustubh Bhalerao on 8/3/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Virus : NSObject {
    int BurstSize;
    float Transmissibility;
    float Virulence;
}
-(Virus*) initWithVirulence:(float)Virulence Transmissibility:(float)Transmissibility BurstSize:(int)BurstSize;
-(int) BurstSize;
-(float) Transmissibility;
-(float) Virulence;

-(void) setBurstSize: (int) newburst;
-(void) setTransmissibility: (float) newtransmissibility;
-(void) setVirulence: (float) newvirulence;
@end
