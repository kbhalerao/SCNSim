//
//  Nematode.m
//  SCNModel
//
//  Created by Kaustubh Bhalerao on 8/3/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import "Nematode.h"
#import "helpers.h"
#import "Soybean.h"


/* State Definitions
 #define EMBRYO 0
 #define J1 1 // inside the eggsac / cyst
 #define UNHATCHEDJ2 2
 #define J2 3 //hatched
 #define J3 4
 #define J4M 5
 #define J4F 6
 #define M 7
 #define F 8
 #define MATING 9
 #define F_PRIME 10
 #define EGGSAC 11
 #define CYST 12
 #define DEAD 13
 */

// nematode state table index is 0-10
// min_days, max_days, next_state
static int nematode_state_table[14][2]  =
            {{1,5},     //0
            {1,2},      //1
            {1,3000},   //2
            {1,4},      //3
            {3,4},      //4
            {5,6},      //5
            {3,4},      //6
            {1,21},     //7
            {2,60},     //8
            {1,21},     //9 - same as female // has no effect
            {3,5},      //10
            {1,3000},   //11
            {1,3000}};   //12

@implementation Nematode

@synthesize State;
@synthesize Viruses;
@synthesize Age;
@synthesize Health;
@synthesize NumZygotes;
@synthesize Sim;
@synthesize inContainer;
@synthesize numContained;


-(Nematode *) initWithSim: (Simulation *) sim {
    @autoreleasepool {
        if (self = [super init]) {
            Age = 0;
            State = CYST;
            Viruses = [[NSMutableArray alloc] init];
            Health = 100;
            NumZygotes = 0;
            Sim = sim;
            inContainer = nil; // not in any container
            numContained = 0;
        }
        return self;
    }
}

-(Nematode*) initAsEmbryoInSim: (Simulation*) sim {
    @autoreleasepool {
        Nematode *nem = [self initWithSim:sim];
        [nem setInContainer:self];
        [nem setState:EMBRYO];
        return nem;
    }
}

-(void) dealloc {
    //free(nematode_state_table);
    Viruses = nil;
    Sim = nil;
    inContainer = nil;
}

-(void) incrementAge: (int) increment {
    Age += increment;
}
-(void) cure_viruses { // private method
    
    [Viruses filterUsingPredicate:[NSPredicate predicateWithFormat:@"Alive == %d", TRUE]];

}
-(void) reproduceViruses {
    
    @autoreleasepool {
        float burden=0;
        // first get rid of dead viruses
        
        if ([Viruses count] > 0 && [Viruses count] <= 100 && State != UNHATCHEDJ2 &&
            State != EGGSAC && State != DEAD && State != CYST) {
            // only run if there aren't enough viruses already
            [Viruses filterUsingPredicate:[NSPredicate predicateWithFormat:@"Alive == %d", TRUE]];
            
            if ([Viruses count]) {
                
                NSMutableArray *new_viruses = [[NSMutableArray alloc] init];
                for (int i=0; i<[Viruses count]; i++) {
                    @autoreleasepool {
                        
                        if (coin_toss(Health / 100)) {
                            // reproduce only if healthy enough

                            Virus *vir = Viruses[i];
                            
                            if ([vir Alive]) {
                                for (int j=0; j<vir.BurstSize; j++) {
                                    @autoreleasepool {
                                        Virus *newvir = [[Virus alloc] initWithVirulence:vir.Virulence Transmissibility:vir.Transmissibility BurstSize:vir.BurstSize];
                                        [newvir mutate:0.4];
                                        [new_viruses addObject: newvir];
                                    }
                                }
                            }
                        }
                    }
                }
                
                [Viruses addObjectsFromArray:new_viruses];
            }
            
            //[Viruses filterUsingPredicate:[NSPredicate predicateWithFormat:@"Alive == %d", TRUE]];
            
            
            for (int i=0; i<[Viruses count]; i++) {
                burden += [Viruses[i] Virulence];
                burden = burden / 24.0; // account for burden per hour
            }
        }
        
        if (burden > Health) {
            State = DEAD;
            [[Sim deadNematodes] addObject: self];
        }
        else Health = MAX(Health-burden, 0);
    }
}

-(void) developIntoJ1 {
    // embryo develops into a J1 nematode
    if (!coin_toss((float)Health/100)) {
        State = J1;
        Age = 0;
    }
}

-(void) developIntoUnhatchedJ2 {
    // embryo develops into a J1 nematode
    if (!coin_toss((float)Health/100)) {
        State = UNHATCHEDJ2;
        Age = 0;
    }
}

//-(void) hatchTemp: (float) temperature Soy: (Soybean*) soy {
-(void) hatch {
    // unhatched J2 emerge from cyst or eggsac
    //@autoreleasepool {
        /// check containder flag
        
        int temperature = [[Sim environment] Temperature];
        float soyhost = [[Sim soybean] getHospitability];
        int gage = [[Sim soybean] GerminatedAge];
        
        if (Health >0) {
            float prob_hatch = 0;

            if (temperature >= HATCH_MIN_TEMP && temperature <= HATCH_MAX_TEMP) {
                prob_hatch = Health/100.0;
                if (gage >= SOY_HATCH_MIN && gage <= SOY_HATCH_MAX) {
                    // proxy for root exudate
                    prob_hatch *= soyhost;
                    if ([inContainer State]==EGGSAC) prob_hatch *=0.2;
                    else if ([inContainer State]==CYST) prob_hatch *= 0.002; // must be in a cyst.
                    else {
                        NSLog(@"Unhatched J2 not in any container\n");
                    }
                }
                else {
                    // soybean is not at the right point in time
                    prob_hatch = 0;
                }
            }
            if (coin_toss(prob_hatch)) {
                State = J2;
                [inContainer setNumContained:([inContainer numContained]-1)];

                if ([inContainer numContained] <=0 ) {
                    [inContainer setState:DEAD];
                    [[Sim deadNematodes] addObject: inContainer];
                    for (Nematode *nem in [Sim nematodes]) {
                        if ([nem inContainer] == self) {
                            [nem setState:DEAD];
                            [[Sim deadNematodes] addObject:nem];
                        }
                    }
                }
                
                inContainer = nil;
                Age = 0;
            }
        }
        else {
            State = DEAD;
            [[Sim deadNematodes] addObject: self];
        }
    //}
}

-(void) burrow {
    // J2 successfully burrows into soybean plant and becomes J3
    if (coin_toss([[Sim soybean] getHospitability])) {
        State = J3;
        Health = 100; // refreshed nematodes!
        Age = 0;
    }
}

-(void) feed {
    @autoreleasepool {
        float feedrate = 0;
        switch (State) {
            case J3: feedrate = J3_FEED; break;
            case J4M: feedrate = J4_FEED; break;
            case J4F: feedrate = J4_FEED; break;
            case F: feedrate = F_FEED; break;
            case F_PRIME: feedrate = F_PRIME_FEED; break;
            default: feedrate = 0; break;
        }
        
        float food = [[Sim soybean] getFoodwithFeedRate:feedrate];
        float health_gain = food / feedrate*100;
        Health = MIN(Health+health_gain, 100);
    }
}

-(void) differentiate {
    if (coin_toss((float)Health/100.0)) {
        Age = 0;
        if (coin_toss(0.5)) {
            State = J4M;
        }
        else State = J4F;
    }
}

-(void) mature {
    // J4M -> M or J4F -> F
    @autoreleasepool {
        int nextState;
        if (State == J4M) nextState = M;
        else nextState = F; //(State == J4F)
        
        int min_age = nematode_state_table[State][0];
        int max_age = nematode_state_table[State][1];
        
        if (Age >= min_age && Age <= max_age && coin_toss(Health/100.0)) {
            Age = 0;
            State = nextState;
            if (State == F) {
                [[Sim potentialMates] addObject:self];
            }
        }
    }
}

-(void) impregnateFemale: (Nematode*) fem {
    //  boy finds girls, and transmits an STD

    if (coin_toss([fem Health]/100.0)) {
        int fnumzygotes = MAX(random_integer(300,500), [fem NumZygotes]);
        [fem setNumZygotes:fnumzygotes];
    }
    @autoreleasepool {
        NSMutableArray *transmitted = [[NSMutableArray alloc] init];
        for (int i=0; i<[Viruses count]; i++) {
            @autoreleasepool {
                Virus *vir = Viruses[i];
                if (coin_toss(vir.Transmissibility)) {
                    [transmitted addObject:vir];
                    [Viruses removeObject:vir];
                }
            }
        }
        [fem addViruses:transmitted]; // this is an array..
        [fem setState: MATING];
        [[Sim potentialMates] removeObject:fem];
        if (![[Sim nematodes] containsObject:fem]) {NSLog(@"Not in nematodes\n");}
    }
}


-(void) moveSingleVirusToHost: (Nematode*) nem {
    @autoreleasepool {
        Virus *random_virus = Viruses[random_integer(0,(int)([Viruses count]-1))];
        if (coin_toss(random_virus.Transmissibility)) {
            [[nem Viruses] addObject:random_virus];
            [Viruses removeObject:random_virus];
        }
    }
}

-(void) produceEggSac {
    // F_prime goes to eggsac - produces embryos.
    @autoreleasepool {
        if (coin_toss(Health/100.0)) {
            State = EGGSAC;
            [[Sim potentialMates] removeObject:self];
            Age = 0;
            Health = 100;
            // We reset health to 100 here.
            
            // create new nematodes from numZygotes -
            // init them in embryo state,
            // transfer viruses from EGGSAC to EMBRYOs
            NSMutableArray *new_nematodes = [[NSMutableArray alloc] initWithCapacity:NumZygotes];
            while (NumZygotes) {
                @autoreleasepool {
                    
                    Nematode *baby = [[Nematode alloc] initAsEmbryoInSim:Sim];
                    [baby setInContainer:self];
                    
                    if ([Viruses count] > 0) {
                        float vir_per_egg = [Viruses count]/(float)(NumZygotes);
                        
                        while (vir_per_egg >1) {
                            [self moveSingleVirusToHost:baby];
                            vir_per_egg -= 1;
                        }
                        float vir_xmit_prob = MIN(1,vir_per_egg);
                        
                        if (coin_toss(vir_xmit_prob)) {
                            [self moveSingleVirusToHost:baby];
                        }
                    }
                    // we get a probability of
                    [new_nematodes addObject:baby];
                    NumZygotes--;
                    numContained++;
                }
            }
            
            [Sim installNewNematodes: new_nematodes];
            
        }

    }
}

-(void) growBy: (int) increment {
    [self incrementAge: increment];
    [self decrement_health];
    switch (State) {
        case EMBRYO: [self developIntoJ1];
            break;
        case J1: [self developIntoUnhatchedJ2];
            break;
        case UNHATCHEDJ2: [self hatch];
            break;
        case J2: [self burrow];
            break;
        case J3: [self feed];
            [self differentiate];
            break;
        case J4M:[self feed];
            [self mature];
            break;
        case J4F: [self feed];
            [self mature];
            break;
        case M: ; [self findMate];
            break;
        case F: [self feed];
            break;
        case MATING: [self feed];
            State = F_PRIME;
            [[Sim potentialMates] addObject:self];
            break;
        case F_PRIME: [self feed];
            [self produceEggSac];
        case EGGSAC:
            break;
        case CYST:
            break;
        default:
            break;

    }
}


-(void) decrement_health {
    @autoreleasepool {
        int min_time = nematode_state_table[State][0];
        int max_time = nematode_state_table[State][1];
        float health_per_day = 100.0/(max_time-min_time+1);
        
        if (Age >= min_time) {
            Health = MAX(Health - health_per_day, 0);
        }
        if (Health <= 0) {
            State = DEAD;
            [[Sim deadNematodes] addObject: self];
        }
        if (inContainer != nil) {
            if ([inContainer State] == DEAD) {
                State = DEAD;
                // I die if my container dies.
                [[Sim deadNematodes] addObject: self];
            }
        }
    }
}

-(void) addViruses: (NSArray*) viruses {
    @autoreleasepool {
        [Viruses addObjectsFromArray:viruses];
    }
}

-(void) findMate {
    
    if (coin_toss(Health/100)) {
        @autoreleasepool {

            if ([Sim numMales]>10) {                
                
                if ([[Sim potentialMates] count] > 10) {
                    Nematode *mate = [Sim potentialMates][random_integer(0, (int)[[Sim potentialMates] count]-1)];
                    [self impregnateFemale:mate];
                    if (!coin_toss(Health)) {
                        State = DEAD;
                        [[Sim deadNematodes] addObject:self];
                    }
                    
                }
            }
        }
    }
}

@end