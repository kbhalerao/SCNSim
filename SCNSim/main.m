//
//  main.m
//  SCNSim
//
//  Created by Kaustubh Bhalerao on 8/4/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdio.h>
#import "helpers.h"
#import "Environment.h"
#import "Virus.h"

int main(int argc, const char * argv[])
{
    for(int i=0;i<10;i++) {
        float val = random_float();
        int state = coin_toss(val);
        float gauss = random_gauss(0, 1);
        int randint = random_integer(-100,0);
        printf("%f, %i, %f, %i\n", val, state, gauss, randint);
    }
    // insert code here...
    
    
    /*
    Environment *env = [[Environment alloc] init];
    
    
    
    int temp;
    for (int i=0; i<365; i++) {
        [env increment_age: 24];
        temp = [env temperature];
        printf("%i %i\n", [env Age]/24, temp);
    }
    
    //[env release];
    */
    
    // let's try to create an array of objects:
    
    NSMutableArray *viruslist = [[NSMutableArray alloc] init];
    
    for (int i=0; i<100; i++) {
        Virus *virus = [[Virus alloc] initWithVirulence:0.1 Transmissibility:0.2 BurstSize:4];
        [virus mutate: 0.5];
        [viruslist addObject:virus];
    }
    
    for (int i=0; i<[viruslist count]; i++) {
        Virus *virus = viruslist[i];
        printf("%i, %i, %f, %f\n", i, virus.BurstSize, virus.Transmissibility, virus.Virulence);
    }

    return 0;
}
