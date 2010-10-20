/* Copyright (c) 2010, Ben Trask
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * The names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY BEN TRASK ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL BEN TRASK BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
#import "ECVLocalizing.h"
#import <objc/runtime.h>

@interface NSObject(ECVFoundationAdditions)

+ (void *)ECV_useInstance:(BOOL)instance implementationFromClass:(Class)class forSelector:(SEL)aSel;

@end

@implementation NSObject(ECVFoundationAdditions)

+ (void *)ECV_useInstance:(BOOL)instance implementationFromClass:(Class)class forSelector:(SEL)aSel
{
	if(!instance) self = objc_getMetaClass(class_getName(self));
	Method const newMethod = instance ? class_getInstanceMethod(class, aSel) : class_getClassMethod(class, aSel);
	if(!newMethod) return NULL;
	IMP const originalImplementation = class_getMethodImplementation(self, aSel); // Make sure the IMP we return is gotten using the normal method lookup mechanism.
	(void)class_replaceMethod(self, aSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)); // If this specific class doesn't provide its own implementation of aSel--even if a superclass does--class_replaceMethod() adds the method without replacing anything and returns NULL. This behavior is good because it prevents our change from spreading to a superclass, but it means the return value is worthless.
	return originalImplementation;
}

@end

@implementation NSObject(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName {}

@end

@implementation NSArray(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	[super ECV_localizeFromTable:tableName];
	[self makeObjectsPerformSelector:@selector(ECV_localizeFromTable:) withObject:tableName];
}

@end

@implementation NSWindow(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	[super ECV_localizeFromTable:tableName];
	[self setTitle:NSLocalizedStringFromTable([self title], tableName, nil)];
	[[self contentView] ECV_localizeFromTable:tableName];
}

@end

@implementation NSView(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	[super ECV_localizeFromTable:tableName];
	[[self subviews] ECV_localizeFromTable:tableName];
}

@end

@implementation NSControl(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	[super ECV_localizeFromTable:tableName];
	[[self cell] ECV_localizeFromTable:tableName];
}

@end

@implementation NSMatrix(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	[super ECV_localizeFromTable:tableName];
	[[self cells] ECV_localizeFromTable:tableName];
}

@end

@implementation NSButtonCell(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	[super ECV_localizeFromTable:tableName];
	[self setTitle:NSLocalizedStringFromTable([self title], tableName, nil)];
	[self setAlternateTitle:NSLocalizedStringFromTable([self alternateTitle], tableName, nil)];
}

@end

@implementation NSTextFieldCell(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	[super ECV_localizeFromTable:tableName];
	[self setStringValue:NSLocalizedStringFromTable([self stringValue], tableName, nil)];
}

@end

@implementation NSPopUpButtonCell(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	// Don't call super because NSPopUpButtonCell doesn't behave like a NSButtonCell.
	[[self menu] ECV_localizeFromTable:tableName];
}

@end

@implementation NSSegmentedCell(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	[super ECV_localizeFromTable:tableName];
	NSInteger i = 0;
	for(; i < [self segmentCount]; i++) [self setLabel:NSLocalizedStringFromTable([self labelForSegment:i], tableName, nil) forSegment:i];
}

@end

@implementation NSTableView(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	[super ECV_localizeFromTable:tableName];
	[[self tableColumns] ECV_localizeFromTable:tableName];
}

@end

@implementation NSTableColumn(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	[super ECV_localizeFromTable:tableName];
	[[self headerCell] ECV_localizeFromTable:tableName];
}

@end

@implementation NSMenu(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	[super ECV_localizeFromTable:tableName];
	[self setTitle:NSLocalizedStringFromTable([self title], tableName, nil)];
	[[self itemArray] ECV_localizeFromTable:tableName];
}

@end

@implementation NSMenuItem(ECVLocalizing)

- (void)ECV_localizeFromTable:(NSString *)tableName
{
	[super ECV_localizeFromTable:tableName];
	[self setTitle:NSLocalizedStringFromTable([self title], tableName, nil)];
	[[self submenu] ECV_localizeFromTable:tableName];
}

@end

#pragma mark -

static BOOL (*ECVNSBundleLoadNibFileExternalNameTableWithZone)(id, SEL, NSString *, NSDictionary *, NSZone *);
@interface ECVBundle : NSBundle
@end

@implementation NSBundle(ECVLocalizing)

+ (void)ECV_prepareToAutoLocalize
{
	if(ECVNSBundleLoadNibFileExternalNameTableWithZone) return;
	ECVNSBundleLoadNibFileExternalNameTableWithZone = (BOOL (*)(id, SEL, NSString *, NSDictionary *, NSZone *))[self ECV_useInstance:NO implementationFromClass:[ECVBundle class] forSelector:@selector(loadNibFile:externalNameTable:withZone:)];
}

@end

@implementation ECVBundle

#pragma mark -ECVBundle(NSNibLoading)

+ (BOOL)loadNibFile:(NSString *)fileName externalNameTable:(NSDictionary *)context withZone:(NSZone *)zone
{
	if(![context objectForKey:NSNibTopLevelObjects]) {
		NSMutableDictionary *const dict = [[context mutableCopy] autorelease];
		[dict setObject:[NSMutableArray array] forKey:NSNibTopLevelObjects];
		context = dict;
	}
	if(!ECVNSBundleLoadNibFileExternalNameTableWithZone(self, _cmd, fileName, context, zone)) return NO;
	[[context objectForKey:NSNibTopLevelObjects] ECV_localizeFromTable:[[fileName lastPathComponent] stringByDeletingPathExtension]];
	return YES;
}

@end
