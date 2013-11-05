/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Mintech (http://mintech.kr)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "MTSystemInfo.h"
#include <net/if_dl.h>
#include <netinet/in.h>
#include <ifaddrs.h>
#include <stdio.h>

#include <CoreFoundation/CoreFoundation.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

@implementation MTSystemInfo

+ (float)systemVersion
{
    NSString *systemVersionFilePath = @"/System/Library/CoreServices/SystemVersion.plist";
    NSDictionary *systemVersionDictionary = [NSDictionary dictionaryWithContentsOfFile:systemVersionFilePath];

    NSString *systemVersion = [systemVersionDictionary objectForKey:@"ProductVersion"];
    
    return systemVersion.floatValue;
}

+ (NSString *)ipAddressForSockAddr:(struct sockaddr *)pSockAddr
{
    char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
    struct sockaddr_in  *pSockAddrV4 = (struct sockaddr_in *) pSockAddr;
    struct sockaddr_in6 *pSockAddrV6 = (struct sockaddr_in6 *)pSockAddr;
    
    const void *pAddr = (pSockAddr->sa_family == AF_INET) ?
    (void *)(&(pSockAddrV4->sin_addr)) :
    (void *)(&(pSockAddrV6->sin6_addr));
    
    const char *pStr = inet_ntop (pSockAddr->sa_family, pAddr, addrBuf, (socklen_t)sizeof(addrBuf));
    if (pStr == NULL) [NSException raise: NSInternalInconsistencyException
                                  format: @"Cannot convert address to string."];
    
    return [NSString stringWithCString:pStr encoding:NSASCIIStringEncoding];
}

+ (NSString *)interfaceNameWithIpAddresss:(NSString *)ipAddress
{
    int	result;
	struct ifaddrs	*ifbase, *ifiterator;
    
	result = getifaddrs(&ifbase);
	ifiterator = ifbase;
    
    while (!result && (ifiterator != NULL))
	{
        if (ifiterator->ifa_addr->sa_family == AF_INET || ifiterator->ifa_addr->sa_family == AF_INET6)
        {
            NSString *ipAddressForInterface = [self ipAddressForSockAddr:ifiterator->ifa_addr];
            if ([ipAddress isEqualToString:ipAddressForInterface]) {
                return [NSString stringWithFormat:@"%s", ifiterator->ifa_name];
            }
        }
        ifiterator = ifiterator->ifa_next;
    }
    return nil;
}

+ (NSString *)macAddressWithInterfaceName:(NSString *)interfaceName withDelimiter:(NSString *)delimiter
{
    int	result;
	struct ifaddrs	*ifbase, *ifiterator;
    
	result = getifaddrs(&ifbase);
	ifiterator = ifbase;
    NSString *macAddress;
    
    while (!result && (ifiterator != NULL))
	{
        NSString* interfaceNameForInterface = [NSString stringWithFormat:@"%s", ifiterator->ifa_name];
        
        if ([interfaceNameForInterface isEqualToString:interfaceName] && ifiterator->ifa_addr->sa_family == AF_LINK)
        {
            struct sockaddr_dl* dlAddr;
			dlAddr = (struct sockaddr_dl *)(ifiterator->ifa_addr);
            unsigned char mac_address[6];
            memcpy(mac_address, &dlAddr->sdl_data[dlAddr->sdl_nlen], 6);
            
            macAddress =
            [NSString stringWithFormat:@"%02X%@%02X%@%02X%@%02X%@%02X%@%02X"
             , mac_address[0], delimiter, mac_address[1], delimiter, mac_address[2], delimiter
             , mac_address[3], delimiter, mac_address[4], delimiter, mac_address[5]];
            
            break;
            
        }
        
        ifiterator = ifiterator->ifa_next;
    }
    
    return macAddress;
}

+ (NSString *)macAddressWithIpAddress:(NSString *)ipAddress delimeter:(NSString *)delimeter
{
    return [self macAddressWithInterfaceName:[self interfaceNameWithIpAddresss:ipAddress] withDelimiter:delimeter];
}

+ (NSString *)ipAddressForCFSocket:(CFSocketRef)cfSocket
{
    CFDataRef addressData = CFSocketCopyAddress(cfSocket);
    
    NSString *ipAddress = [self ipAddressForSockAddr:(struct sockaddr *) CFDataGetBytePtr
                           (addressData)];
    CFRelease(addressData);
    return ipAddress;
}


@end
