//
//  main.m
//  UTF8String
//
//  Created by Nico Schmidt on 02.09.12.
//  Copyright (c) 2012 Nico Schmidt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UTF8String.h"

uint64_t dispatch_benchmark(size_t count, void (^block)(void));

uint8_t str1[] = "\xF0\x90\x91\x8F abcdefghijklmnopqrstuvw \xc3\xa4\xc3\x9f \xe0\xa5\xa7 \xe3\x96\x84";

#define CLASS NSString

int main(int argc, const char * argv[])
{
    NSUInteger size = 1000;
    NSUInteger stringSize = sizeof(str1)-1;
    void *m = malloc(size);
    uint8_t *end = m;
    end += size;
    uint8_t *p;
    for (p = m; p < end; p += stringSize) {
        memcpy(p, str1, stringSize);
    }
    stringSize = (uint8_t *)p - (uint8_t *)m;

    NSString *s = [[CLASS alloc] initWithBytesNoCopy:m length:stringSize encoding:NSUTF8StringEncoding freeWhenDone:NO];

    @autoreleasepool {
        uint64_t nanoseconds = dispatch_benchmark(1, ^{
            @autoreleasepool {
                [s length];
            }
        });
        
        NSLog(@"string length took %f ms", nanoseconds/1e6);
        
        nanoseconds = dispatch_benchmark(1, ^{
            @autoreleasepool {
                [s componentsSeparatedByString:@" "];
            }
        });
        
        NSLog(@"componentsSeparatedByString took %f ms", nanoseconds/1e6);

    }
    return 0;
}

