/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/socket.h> // Per msqr
#include <net/if.h>
#include <net/if_dl.h>

#import <Cordova/CDV.h>
#import "CDVDevice.h"

@implementation UIDevice (ModelVersion)

- (NSString*)modelVersion
{
    size_t size;

    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char* machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString* platform = [NSString stringWithUTF8String:machine];
    free(machine);

    return platform;
}

@end

@interface CDVDevice () {}
@end

@implementation CDVDevice

- (void)getDeviceInfo:(CDVInvokedUrlCommand*)command
{
    NSDictionary* deviceProperties = [self deviceProperties];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:deviceProperties];

    /* Settings.plist
     * Read the optional Settings.plist file and push these user-defined settings down into the web application.
     * This can be useful for supplying build-time configuration variables down to the app to change its behavior,
     * such as specifying Full / Lite version, or localization (English vs German, for instance).
     */
    // TODO: turn this into an iOS only plugin
    NSDictionary* temp = [CDVViewController getBundlePlist:@"Settings"];

    if ([temp respondsToSelector:@selector(JSONString)]) {
        NSLog(@"Deprecation warning: window.Setting will be removed Aug 2013. Refer to https://issues.apache.org/jira/browse/CB-2433");
        NSString* js = [NSString stringWithFormat:@"window.Settings = %@;", [temp JSONString]];
        [self.commandDelegate evalJs:js];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSDictionary*)deviceProperties
{
    UIDevice* device = [UIDevice currentDevice];
    NSMutableDictionary* devProps = [NSMutableDictionary dictionaryWithCapacity:4];

    [devProps setObject:[device modelVersion] forKey:@"model"];
    [devProps setObject:@"iOS" forKey:@"platform"];
    [devProps setObject:[device systemVersion] forKey:@"version"];
    [devProps setObject:[device uniqueAppInstanceIdentifier] forKey:@"uuid"];
    [devProps setObject:[[self class] cordovaVersion] forKey:@"cordova"];
    [devProps setObject:[[self class] macaddress] forKey:@"macaddress"];
    
    NSDictionary* devReturn = [NSDictionary dictionaryWithDictionary:devProps];
    return devReturn;
}

+ (NSString *) macaddress
{
	int                 mib[6];
	size_t              len;
	char                *buf;
	unsigned char       *ptr;
	struct if_msghdr    *ifm;
	struct sockaddr_dl  *sdl;
    
	mib[0] = CTL_NET;
	mib[1] = AF_ROUTE;
	mib[2] = 0;
	mib[3] = AF_LINK;
	mib[4] = NET_RT_IFLIST;
    
	if ((mib[5] = if_nametoindex("en0")) == 0) {
		printf("Error: if_nametoindex error/n");
		return NULL;
	}
    
	if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
		printf("Error: sysctl, take 1/n");
		return NULL;
	}
    
	if ((buf = malloc(len)) == NULL) {
		printf("Could not allocate memory. error!/n");
		return NULL;
	}
    
	if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
		printf("Error: sysctl, take 2");
		return NULL;
	}
    
	ifm = (struct if_msghdr *)buf;
	sdl = (struct sockaddr_dl *)(ifm + 1);
	ptr = (unsigned char *)LLADDR(sdl);
	// NSString *outstring = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
	NSString *outstring = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x", *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
	free(buf);
	return [outstring uppercaseString];
    
}

+ (NSString*)cordovaVersion
{
    return CDV_VERSION;
}

@end
