//
//  helpers.h
//  SCNModel_C
//
//  Created by Kaustubh Bhalerao on 8/3/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#ifndef SCNModel_C_helpers_h
#define SCNModel_C_helpers_h

float random_float(void);
// provides a float between 0 and 1

int coin_toss(float probability); // 0 for False, 1 for True
// generates a uniform number between 0 and 1;
// compares the number against probability;
// return True if lesser, False if greater

float random_gauss(float mean, float stdev);
// Provides a random normal float with mean and stdev as specified

int random_integer(int lower, int upper);
// provides a random integer between lower and upper bounds, inclusive

float f_to_c(float temp);
// Fahrenheit to centigrade conversion

float c_to_f(float temp);
// Centigrade to Fahrenheit

#endif
