//
//  Virus.h
//  SCNModel_C
//
//  Created by Kaustubh Bhalerao on 8/3/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Virus : NSObject {

}

@property int BurstSize;
@property float Transmissibility;
@property float Virulence;
@property int Alive;
@property float Durability;

-(Virus*) initWithVirulence:(float)Virulence
           Transmissibility:(float)Transmissibility
                  BurstSize:(int)BurstSize
                 Durability:(float)Durability;


-(void) mutate: (float) probability;
@end
