//
//  Nematode.h
//  SCNModel
//
//  Created by Kaustubh Bhalerao on 8/3/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Virus.h"

@interface Nematode : NSObject
{
    int State;
    NSMutableArray* Viruses;
    int Age;
    float Health;
    int NumEggs;
}

-(void) incrementAge: (int) increment;
-(void) decrementHealth;
-(void) cureViruses;
-(void) reproduceSingleVirus: (Virus*) v;
-(void) reproduceViruses: (NSMutableArray*) viruses;
-(void) develop;
-(void) hatch;
-(void) burrow;
-(void) feed;

@end
