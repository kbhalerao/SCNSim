//
//  helpers.c
//  SCNModel_C
//
//  Created by Kaustubh Bhalerao on 8/3/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#include <stdio.h>
#include "helpers.h"
#include <stdlib.h>
#include <math.h>

#define MAX_RAND 0xfffffff


float random_float(void) {
    // provides a float between 0 and 1
    return (float)arc4random_uniform(MAX_RAND)/MAX_RAND;
}
    
int coin_toss(float probability) {
    // 0 for False, 1 for True
    // generates a uniform number between 0 and 1;
    // compares the number against probability;
    // return True if lesser, False if greater
    float val = random_float();
    if (val < probability) return 1;
    else return 0;
}

/* boxmuller.c           Implements the Polar form of the Box-Muller
 Transformation
 
 (c) Copyright 1994, Everett F. Carter Jr.
 Permission is granted by the author to use
 this software for any application provided this
 copyright notice is preserved.
 
 */


//extern float ranf();         /* ranf() is uniform in 0..1 */


float box_muller(float m, float s)	/* normal random variate generator */
{				        /* mean m, standard deviation s */
	float x1, x2, w, y1;
	static float y2;
	static int use_last = 0;
    
	if (use_last)		        /* use value from previous call */
	{
		y1 = y2;
		use_last = 0;
	}
	else
	{
		do {
			x1 = 2.0 * random_float() - 1.0;
			x2 = 2.0 * random_float() - 1.0;
			w = x1 * x1 + x2 * x2;
		} while ( w >= 1.0 );
        
		w = sqrt( (-2.0 * log( w ) ) / w );
		y1 = x1 * w;
		y2 = x2 * w;
		use_last = 1;
	}
    
	return( m + y1 * s );
}





double rand_gauss (void) {
    // helper function scaled by mean and stdev.
    // code from Knuth
    double v1,v2,s;
    
    do {
        v1 = 2.0 * (arc4random_uniform(MAX_RAND)/MAX_RAND) - 1.0;
        v2 = 2.0 * (arc4random_uniform(MAX_RAND)/MAX_RAND) - 1.0;
        
        s = v1*v1 + v2*v2;
    } while ( s >= 1.0 );
    
    if (s == 0.0)
        return 0.0;
    else
        return (v1*sqrt(-2.0 * log(s) / s));
}


float random_gauss(float mean, float stdev) {
    // Provides a random normal float with mean and stdev as specified
    //return (float)(rand_gauss()*stdev + mean);
    float val = box_muller(mean, stdev);
    while (val < 0) {
        // some times the number is less than zero, which is not appropriate for
        // our use. May choose to eliminate the random_gauss function
        // in a later version. 
        val = box_muller(mean, stdev);
    }
    return val;
}

int random_integer(int lower, int upper) {
    // provides a random integer between lower and upper bounds, inclusive
    u_int32_t range = (u_int32_t)abs(upper - lower);
    return arc4random_uniform(range) + lower;
}


float c_to_f(float temp){
    return temp*9.0/5.0+32;
}

float f_to_c(float temp) {
    return (temp-32)*5/9.0;
}