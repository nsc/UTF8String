//
//  UTF8String.m
//  UTF8String
//
//  Created by Nico Schmidt on 02.09.12.
//  Copyright (c) 2012 Nico Schmidt. All rights reserved.
//

#import "UTF8String.h"

@implementation UTF8String
{
    const uint8_t*  _utf8string;
    NSUInteger      _utf8length;
    NSUInteger      _length;
    BOOL            _freeWhenDone;
    NSUInteger      _cachedCharacterIndex;
    NSUInteger      _cachedByteIndex;
}

- (id)initWithBytesNoCopy:(void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding freeWhenDone:(BOOL)flag
{
    if (encoding == NSUTF8StringEncoding) {
        self = [super init];
        
        if (self) {
            _utf8string = (const uint8_t*)bytes;
            _utf8length = length;
            _freeWhenDone = flag;
            _length = NSNotFound;
        }
        
        return self;
    }
    
    return (id)[[NSString alloc] initWithBytesNoCopy:bytes length:length encoding:encoding freeWhenDone:flag];
}

- (void)dealloc
{
    if (_freeWhenDone) {
        free((void *)_utf8string);
    }
}

- (NSUInteger)length
{
    if (_length == NSNotFound) {
        _length = [self __parseStringUntilCharacterIndex:NSNotFound character:NULL];
    }
    
    return _length;
}

- (NSUInteger)__parseStringUntilCharacterIndex:(NSUInteger)index character:(unichar *)character
{
    uint32_t unicodeCharacter;
    const uint8_t* p = _utf8string;
    NSUInteger byteIndex = 0;
    unichar result;
    
    NSUInteger i=0;
    if (_cachedCharacterIndex <= index) {
        p += _cachedByteIndex;
        i = _cachedCharacterIndex;
    }
    BOOL is4ByteEncoding = NO;
    for (; i <= index && byteIndex < _utf8length; ++i, byteIndex = (uint8_t*)p - (uint8_t*)_utf8string) {
        if (is4ByteEncoding) {
            // utf16 low surrogate for four byte encoding
            result = (unicodeCharacter & 0x3FF) | 0xDC00;
            is4ByteEncoding = NO;
            continue;
        }
        
        uint8_t c = *p++;
        if ((c & 0x80) == 0) {
            // one byte
            unicodeCharacter = c;
            result = unicodeCharacter;
            continue;
        } else if ((0xE0 & c) == 0xC0) {
            // two bytes
            unicodeCharacter = ((c & 0x1F) << 6);
            c = *p++;
            unicodeCharacter |= 0x3F & c;
            result = unicodeCharacter;
            continue;
        } else if ((0xF0 & c) == 0xE0) {
            // three bytes
            unicodeCharacter = ((c & 0x0F) << 12);
            c = *p++;
            unicodeCharacter |= (0x3F & c) << 6;
            c = *p++;
            unicodeCharacter |= (0x3F & c);
            result = unicodeCharacter;
            continue;
        } else if ((0xF8 & c) == 0xF0) {
            is4ByteEncoding = YES;
            
            unicodeCharacter = ((c & 0x07) << 18);
            c = *p++;
            unicodeCharacter |= (0x3F & c) << 12;
            c = *p++;
            unicodeCharacter |= (0x3F & c) << 6;
            c = *p++;
            unicodeCharacter |= (0x3F & c);
            
            // utf16 high surrogate for four byte encoding
            result = ((unicodeCharacter & 0x1EFC00) >> 10) | 0xD800;
            continue;
        }
    }
    
    if (character) {
        *character = result;
    }
    
    if (!is4ByteEncoding) {
        _cachedByteIndex = byteIndex;
        _cachedCharacterIndex = i;
    }
    
    return i;
}

- (unichar)characterAtIndex:(NSUInteger)index
{
    unichar character;
    [self __parseStringUntilCharacterIndex:index character:&character];
    
    return character;
}

@end
