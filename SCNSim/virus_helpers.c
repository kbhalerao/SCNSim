//
//  virus_helpers.c
//  SCNSim
//
//  Created by Kaustubh Bhalerao on 8/4/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#include <stdio.h>
#import "Virus.h"


void mutate(Virus* virus, float probability) {
    if(coin_toss(probability)) {
        virus.Transmissibility += random_gauss(0, 0.05);
        virus.Virulence += random_gauss(0, 0.05);
        virus.BurstSize += random_integer(-3, 3);
    }
    
}
