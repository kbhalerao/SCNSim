//
//  Environment.h
//  SCNModel_C
//
//  Created by Kaustubh Bhalerao on 8/3/12.
//  Copyright (c) 2012 Kaustubh Bhalerao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Environment : NSObject
{
    int Age;
}
-(Environment*) init;
-(float) temperature;
-(int) Age;
-(void) increment_age: (int) increment;
@end
