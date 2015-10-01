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
@synthesize Age;
@synthesize Health;
@synthesize NumZygotes;
@synthesize Sim;
@synthesize inContainer;
@synthesize numContained;
@synthesize Infection;
@synthesize generation;


-(Nematode *) initWithSim: (Simulation *) sim {
    @autoreleasepool {
        if (self = [super init]) {
            Age = 0;
            State = CYST;
            Health = 100;
            NumZygotes = 0;
            Sim = sim;
            inContainer = nil; // not in any container
            numContained = 0;
            
            Infection = [[NSMutableDictionary alloc] initWithCapacity:4];
            Infection[@"Burden"] = @(0);
            Infection[@"Virulence"] = @(0);
            Infection[@"Transmissibility"] = @(0);
            Infection[@"Durability"] = @(0);
            
            generation = 0;
            
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
    Infection = nil;
    Sim = nil;
    inContainer = nil;
}

-(void) incrementAge: (int) increment {
    Age += increment;
}
-(void) cure_viruses { // private method
    // Multiply the burden by the complement of durability
    Infection[@"Burden"] = @([Infection[@"Burden"] floatValue] * [Infection[@"Durability"] floatValue]);
}


-(void) setNematodeToDead {
    
    if (inContainer != nil) {
        [inContainer setNumContained:[inContainer numContained]-1];
    }
    
    else {
        // not in container
        if ([[Sim potentialMates] containsObject:self]) {
            [[Sim potentialMates] removeObject:self];
        }
        
        if (numContained > 0) {
            numContained = 0;

            @autoreleasepool {
                for (Nematode *baby in [Sim nematodes]) {
                    if ([baby inContainer] == self) {
                        [baby setState:DEAD];
                        [[Sim deadNematodes] addObject:baby];
                    }
                }
            }
        }
    }

    State = DEAD;
    [[Sim deadNematodes] addObject:self];
}

-(NSNumber *) mutateParameter:(NSString *) key {
    float param = [Infection[key] floatValue];
    param += random_gauss(0, param*0.15); // vary within 15%
    param = MAX(param, 0);
    if ([key isEqual: @"Transmissibility"] || [key isEqual: @"Durability"]) {
        param = MIN(1, param);
    }
    return (@(param));
}
-(void) reproduceViruses {
    
    @autoreleasepool {
        
        if ([Infection[@"Burden"] floatValue] > 0.0001 && State != UNHATCHEDJ2 &&
            State != EGGSAC && State != DEAD && State != CYST) {
            // increased burden value to be very small... prevent rounding errors.
            [self cure_viruses];
            // only run if there aren't enough viruses already
            // first we mutate the virus burden
            
            if (coin_toss([Sim mutationRate])) {
                Infection[@"Virulence"] = [self mutateParameter:@"Virulence"];
                Infection[@"Transmissibility"] = [self mutateParameter:@"Transmissibility"];
                Infection[@"Durability"] = [self mutateParameter:@"Durability"];
                
                if ([Infection[@"Virulence"] floatValue] == 0 ||
                    [Infection[@"Durability"] floatValue] == 0 ||
                    [Infection[@"Transmissibility"] floatValue] == 0) {
                    Infection[@"Burden"] = 0;
                }
            }
            
            Infection[@"Burden"] = @([Infection[@"Burden"] floatValue] * [Infection[@"Virulence"] floatValue]);
            if([Infection[@"Burden"] floatValue] <= 0.0001) {
                Infection[@"Burden"] = @(0);
            }
            Health = Health-[Infection[@"Burden"] floatValue];
            
            if (Health <= 0) {
                [Sim setDeathByVirus:[Sim deathByVirus]+1];
                [self setNematodeToDead];
            }
        }
    }
}

-(void) developIntoJ1 {
    // embryo develops into a J1 nematode
    if (coin_toss((float)Health/100)) {
        State = J1;
        Age = 0;
        if ([self inContainer] == nil) {
            NSLog(@"J1 not in container!");
        }
    }
}

-(void) developIntoUnhatchedJ2 {
    // embryo develops into a J1 nematode
    if (coin_toss((float)Health/100)) {
        State = UNHATCHEDJ2;
        Age = 0;
        Health = 100;
        if ([self inContainer] == nil) {
            NSLog(@"UJ2 not in container!");
        }
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
                        NSLog(@"Gen %d Unhatched J2 not in any container\n", generation);
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
                    [inContainer setNematodeToDead];
                }
                
                inContainer = nil;
                Age = 0;
            }
        }
        else {
            [self setNematodeToDead];
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
            case MATING: feedrate = MATING_FEED; break;
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
        
        float burdenTransmitted = [Infection[@"Burden"] floatValue] * [Infection[@"Transmissibility"] floatValue];
        
        Infection[@"Burden"] = @([Infection[@"Burden"] floatValue] - burdenTransmitted);
        
        NSMutableDictionary *TransmittedViruses = [NSMutableDictionary dictionaryWithDictionary:Infection];
        TransmittedViruses[@"Burden"] = @(burdenTransmitted);
        
        [fem addInfection:TransmittedViruses];
        
        if (![[Sim nematodes] containsObject:fem]) {
            NSLog(@"Not in nematodes\n");
        }
        [fem setState: MATING];
        [[Sim potentialMates] removeObject:fem];
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
            float BurdenPerBaby = [Infection[@"Burden"] floatValue] / NumZygotes;
            while (NumZygotes) {
                @autoreleasepool {
                    
                    Nematode *baby = [[Nematode alloc] initAsEmbryoInSim:Sim];
                    [baby setInContainer:self];
                    [baby setGeneration:([self generation]+1)];
                    NSMutableDictionary *TransmittedInfection = [NSMutableDictionary dictionaryWithDictionary:Infection];
                    TransmittedInfection[@"Burden"] = @(BurdenPerBaby);
                    
                    [baby addInfection:TransmittedInfection];
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
            [self setNematodeToDead];
        }
    }
}

-(void) addInfection:(NSDictionary *) newInfection {
    @autoreleasepool {
        float burden = [Infection[@"Burden"] floatValue];
        float transmittedburden = [newInfection[@"Burden"] floatValue];
        
        if (burden + transmittedburden > 0) {

            float newburden = burden + transmittedburden;
            float newvirulence = (burden * [Infection[@"Virulence"] floatValue] +
                                  transmittedburden * [newInfection[@"Virulence"] floatValue])/(burden + transmittedburden);
            
            float newtransmissibility = (burden * [Infection[@"Transmissibility"] floatValue] +
                                  transmittedburden * [newInfection[@"Transmissibility"] floatValue])/(burden + transmittedburden);
            
            float newdurability = (burden * [Infection[@"Durability"] floatValue] +
                                  transmittedburden * [newInfection[@"Durability"] floatValue])/(burden + transmittedburden);
            
            Infection[@"Burden"] = @(newburden);
            Infection[@"Virulence"] = @(newvirulence);
            Infection[@"Transmissibility"] = @(newtransmissibility);
            Infection[@"Durability"] = @(newdurability);
        }
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
                        [self setNematodeToDead];
                    }
                    
                }
            }
        }
    }
}

@end