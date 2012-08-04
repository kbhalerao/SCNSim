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
    
    Environment *env = [[Environment alloc] init];
    
    
    
    int temp;
    for (int i=0; i<365; i++) {
        [env increment_age: 24];
        temp = [env temperature];
        printf("%i %i\n", [env Age]/24, temp);
    }
    
    //[env release];
    
    return 0;
}
