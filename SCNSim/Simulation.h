//
//  Simulation.h
//  SCNSim
//
//  Created by Kaustubh Bhalerao on 8/4/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Simulation : NSObject {
    NSMutableArray *Nematodes;
}
-(void) installNewNematodes: (NSArray*) nematodes;

@end
