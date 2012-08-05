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

// State Definitions
//#define EMBRYO 0
//#define J1 1
//#define J2 2
//#define J3 3
//#define J4M 4
//#define J4F 5
//#define M 6
//#define F 7
//#define F_PRIME 8
//#define EGGSAC 9
//#define DEAD 10

// nematode state table index is 0-10
// min_days, max_days, next_state
int nematode_state_table[10][2]  =
    {{1,5},     //0
    {1,2},      //1
    {1,6},      //2
    {1,3},      //3
    {9,10},     //4
    {11,12},    //5
    {1,14},     //6
    {1,60},     //7
    {1,60},     //9
    {1,3000}};  //10

@implementation Nematode

-(Nematode*) initWithState: (int) state inSim: (Simulation*) sim{
    if (self = [super init]) {
        Age = 0;
        State = state;
        Viruses = [[NSMutableArray alloc] init];
        Health = 100;
        NumEggs = 0;
        Sim = sim;
    }
    return self;
}

-(int) State {
    return State;
}
-(float) Health {
    return Health;
}

-(int) NumEggs {
    return NumEggs;
}

-(void) incrementAge: (int) increment {
    Age += increment;
}
-(void) cure_viruses { // private method
    for (int i=0; i<[Viruses count]; i++) {
        Virus *vir = (Virus*) [Viruses objectAtIndex:i];
        if (vir.Virulence <= 0 || vir.Transmissibility <= 0 || vir.BurstSize <= 0) {
            [Viruses removeObject:vir];
        }
    }
}
-(void) reproduceViruses {
    [self cure_viruses];
    // first get rid of dead viruses
    float burden = 0;
    if ([Viruses count] < 30 && [Viruses count] > 0 && \
                State != EGGSAC && State != DEAD) {
        // only run if there aren't enough viruses already
        
        
        // variable to store viral burden
        
        NSMutableArray *newviruses = [[NSMutableArray alloc] init];
        // Array to store new viruses
        
        for (int i=0; i<[Viruses count]; i++) {
            if (coin_toss(Health / 100)) {
                // reproduce only if healthy enough
                
                Virus *vir = [Viruses objectAtIndex:i];
                for (int j=0; j<vir.BurstSize; j++) {
                    Virus *newvir = [[Virus alloc] initWithVirulence:vir.Virulence Transmissibility:vir.Transmissibility BurstSize:vir.BurstSize];
                    [newvir mutate:0.4];
                    [newviruses addObject: newvir];
                }
            }
        }
        
        [Viruses addObjectsFromArray:newviruses];
        for (int i=0; i<[Viruses count]; i++) {
            burden += [[Viruses objectAtIndex:i] Virulence];
        }
    }
    
    if (burden > Health) {
        State = DEAD;
    }
    else Health = MAX(Health-burden, 0);
}

-(void) develop {
    // embryo develops into a J1 nematode
    if (coin_toss(Health/100)) {
        State = J1;
    }
}

//-(void) hatchTemp: (float) temperature Soy: (Soybean*) soy {
-(void) hatch {
    
    int temperature = [[Sim environment] temperature];
    Soybean* soy = [Sim soybean];
    
    if (Health >0) {
        float prob_hatch = 0;
        // assuming embryo sufficiently developed to hatch
        if (temperature >= HATCH_MIN_TEMP && temperature <= HATCH_MAX_TEMP) {
            prob_hatch = Health/100;
            if ([soy Age] >= SOY_HATCH_MIN && [soy Age] <= SOY_HATCH_MAX) {
                prob_hatch *= MIN(soy.PlantSize/SOYMAXSIZE, 1);
            }
        }
        if (coin_toss(prob_hatch)) {
            State = J2;
        }
    }
    else State = DEAD;
}

-(void) burrow {
    // J2 successfully burrows into soybean plant and becomes J3
    if (coin_toss([[Sim soybean] getHospitability])) {
        State = J3;
    }
}

-(void) feed {
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

-(void) differentiate {
    if (coin_toss(Health/100)) {
        if (coin_toss(0.5)) {
            State = J4M;
        }
        else State = J4F;
    }
}

-(void) mature {
    // J4M -> M or J4F -> F
    int nextState;
    if (State == J4M) nextState = M;
    if (State == J4F) nextState = F;
    
    int min_age = nematode_state_table[State][0];
    int max_age = nematode_state_table[State][1];
    
    if (Age >= min_age && Age <= max_age && coin_toss(Health/100)) {
        State = nextState;
    }
}

-(void) impregnateFemale: (Nematode*) fem {
    if (coin_toss([fem Health]/100)) {
        int fnumeggs = MAX(random_integer(300,500), [fem NumEggs]);
        [fem setNumEggs:fnumeggs];
    }
    NSMutableArray *transmitted = [[NSMutableArray alloc] init];
    for (int i=0; i<[Viruses count]; i++) {
        Virus *vir = [Viruses objectAtIndex:i];
        if (coin_toss(vir.Transmissibility)) {
            [transmitted addObject:vir];
            [Viruses removeObject:vir];
        }
    }
    [fem setViruses:transmitted];
    [fem setState: MATING];
}

-(void) incubate {
    if ([[Sim environment] temperature] > INCUBATE_TEMP) {
        int num_incubate = MIN((int)random_gauss(NumEggs/4, NumEggs/10), NumEggs);
        NumEggs -= num_incubate;
        
        if(NumEggs == 0 || Health <= 0) State = DEAD;
        
    NSMutableArray *new_nematodes = [[NSMutableArray alloc] initWithCapacity:num_incubate];
        for (int i=0; i<num_incubate; i++) {
            Nematode *baby = [[Nematode alloc] initWithState:EMBRYO inSim: Sim];
            
            float vir_per_egg = [Viruses count]/(NumEggs+num_incubate);
            
            int guaranteed_viruses = (int)vir_per_egg;
            while (guaranteed_viruses >0) {
                [self moveSingleVirusToHost:baby];
                guaranteed_viruses -= 1;
            }
            float vir_xmit_prob = MIN(1,guaranteed_viruses);
            
            if (coin_toss(vir_xmit_prob)) {
                [self moveSingleVirusToHost:baby];
            }
            // we get a probability of 
            [new_nematodes addObject:baby];
        }
        [Sim installNewNematodes: new_nematodes];
    }
}

-(void) moveSingleVirusToHost: (Nematode*) nem {
    Virus *random_virus = [Viruses objectAtIndex:
                           random_integer(0,(int)([Viruses count]-1))];
    if (coin_toss(random_virus.Transmissibility)) {
        [nem setViruses:[[NSArray alloc]
                          initWithObjects:random_virus, nil]];
        [Viruses removeObject:random_virus];
    }
}

-(void) setState:(int)state {
    State = state;
}

-(void) produceEggs {
    if (!coin_toss(Health/100)) {
        State = EGGSAC;
    }
}

-(void) growBy: (int) increment {
    [self incrementAge: increment];
    [self decrement_health];
    switch (State) {
        case EMBRYO: [self develop]; 
            break;
        case J1: [self hatch];
            break;
        case J2: [self burrow];
            break;
        case J3: [self feed];
            [self differentiate];
            break;
        case J4M:[self feed];
            [self mature];
            break;
        case M: ; [self findMate];
            break;
        case F: [self feed];
            break;
        case F_PRIME: [self feed];
            [self produceEggs];
        case EGGSAC:
            [self incubate];
            break;
        case MATING: [self feed];
            State = F_PRIME;
            break;
    }
}


-(void) setNumEggs: (int) numeggs {
    NumEggs = numeggs;
}

-(void) setViruses: (NSArray*) viruses {
    [Viruses addObjectsFromArray: viruses];
}

-(void) decrement_health {
    int min_time = nematode_state_table[State][0];
    int max_time = nematode_state_table[State][1];
    float health_per_day = 100.0/(max_time-min_time+1); //TODO
    
    if (Age >= min_time) {
        Health = MAX(Health - health_per_day, 0);
        }
    if (Health <= 0) {
        State = DEAD;
    }
}

-(void) findMate {
    
    if (coin_toss(Health/100)) {
        int male_count = 0;
        for (int i=0; i<[[Sim nematodes] count]; i++) {
            if ([[[Sim nematodes] objectAtIndex:i] State] == M) male_count++;
        }
        if (male_count >10) {
            NSMutableArray *potential_mates = [[NSMutableArray alloc] init];
            for (int i=0; i<[[Sim nematodes] count]; i++) {
                Nematode *nem = [[Sim nematodes] objectAtIndex:i];
                if ([nem State] == F || [nem State] == F_PRIME) {
                    [potential_mates addObject: nem];
                }
            }
            if ([potential_mates count] > 10) {
                Nematode *mate = [potential_mates objectAtIndex:
                                  random_integer(0, (int)[potential_mates count]-1)];
                [self impregnateFemale:mate];
                if (!coin_toss(Health)) State = DEAD;
                
            }
        }
    }
}

@end