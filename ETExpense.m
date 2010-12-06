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
#import "ETExpense.h"

// Other Sources
#import "ETFoundationAdditions.h"

NSString *const ETExpenseDidChangeNotification = @"ETExpenseDidChange";

static NSString *const ETDateKey = @"ETDate";
static NSString *const ETQuantityKey = @"ETQuantity";
static NSString *const ETAmountKey = @"ETAmount";
static NSString *const ETPurposeKey = @"ETPurpose";
static NSString *const ETNotesKey = @"ETNotes";

@implementation ETExpense

#pragma mark +<ETPropertyListSerializing>

+ (id)ET_objectWithPropertyList:(id)plist
{
	ETExpense *const expense = [[[self alloc] init] autorelease];
	[expense setDate:[NSDate ET_objectWithPropertyList:[plist objectForKey:ETDateKey]]];
	[expense setQuantity:[NSDecimalNumber ET_objectWithPropertyList:[plist objectForKey:ETQuantityKey]]];
	[expense setAmount:[NSDecimalNumber ET_objectWithPropertyList:[plist objectForKey:ETAmountKey]]];
	[expense setPurpose:[NSString ET_objectWithPropertyList:[plist objectForKey:ETPurposeKey]]];
	[expense setNotes:[NSString ET_objectWithPropertyList:[plist objectForKey:ETNotesKey]]];
	return expense;
}

#pragma mark -ETExpense

- (NSDate *)date
{
	return [[_date retain] autorelease];
}
- (void)setDate:(NSDate *)val
{
	if(ETEqualObjects(_date, val)) return;
	[[self ET_undo] setDate:_date];
	[_date release];
	_date = [val copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ETExpenseDidChangeNotification object:self];
}
- (NSDecimalNumber *)quantity
{
	return [[_quantity retain] autorelease];
}
- (void)setQuantity:(NSDecimalNumber *)val
{
	if(ETEqualObjects(_quantity, val)) return;
	if([val ET_isZero]) [self setAmount:[NSDecimalNumber zero]];
	[[self ET_undo] setQuantity:_quantity];
	[_quantity release];
	_quantity = [val copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ETExpenseDidChangeNotification object:self];
}
- (NSDecimalNumber *)amount
{
	return [[_amount retain] autorelease];
}
- (void)setAmount:(NSDecimalNumber *)val
{
	if([[self quantity] ET_isZero]) return;
	if(ETEqualObjects(_amount, val)) return;
	[[self ET_undo] setAmount:_amount];
	[_amount release];
	_amount = [val copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ETExpenseDidChangeNotification object:self];
}
- (NSString *)purpose
{
	return [[_purpose retain] autorelease];
}
- (void)setPurpose:(NSString *)str
{
	if(ETEqualObjects(_purpose, str)) return;
	[[self ET_undo] setPurpose:_purpose];
	[_purpose release];
	_purpose = [str copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ETExpenseDidChangeNotification object:self];
}
- (NSString *)notes
{
	return [[_notes retain] autorelease];
}
- (void)setNotes:(NSString *)str
{
	if(ETEqualObjects(_notes, str)) return;
	[[self ET_undo] setNotes:_notes];
	[_notes release];
	_notes = [str copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ETExpenseDidChangeNotification object:self];
}

#pragma mark -

- (ETExpense *)next:(BOOL)flag expenseInArray:(NSArray *)expenses
{
	NSUInteger i = [expenses indexOfObjectIdenticalTo:self];
	NSAssert(NSNotFound != i, @"Expense must be in expense array");
	NSInteger const increment = flag ? 1 : -1;
	NSRange const range = flag ? NSMakeRange(i + 1, [expenses count] - (i + 1)) : NSMakeRange(0, i);
	for(i += increment; NSLocationInRange(i, range); i += increment) {
		ETExpense *const e = [expenses objectAtIndex:i];
		if([self isEqual:e]) return e;
	}
	return nil;
}

#pragma mark -

- (BOOL)getDuration:(out NSTimeInterval *)outDuration withNext:(BOOL)flag expense:(ETExpense *)expense
{
	NSDate *const d = [expense date];
	if(d && self != expense) {
		if(outDuration) *outDuration = flag ? [d timeIntervalSinceDate:[self date]] : [[self date] timeIntervalSinceDate:d];
		return YES;
	} else {
		if(outDuration) *outDuration = 0.0;
		return NO;
	}
}
- (BOOL)getDuration:(out NSTimeInterval *)outDuration withNext:(BOOL)flag expenseInArray:(NSArray *)expenses
{
	return [self getDuration:outDuration withNext:flag expense:[self next:flag expenseInArray:expenses]];
}

#pragma mark -

- (NSComparisonResult)compare:(ETExpense *)expense
{
	return [[self date] compare:[expense date]];
}
- (id)key
{
	return [[self purpose] lowercaseString];
}

#pragma mark -

@synthesize undoManager = _undoManager;

#pragma mark -<ETPropertyListSerializing>

- (id)ET_propertyList
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[[self date] ET_propertyList], ETDateKey,
		[[self quantity] ET_propertyList], ETQuantityKey,
		[[self amount] ET_propertyList], ETAmountKey,
		[[self purpose] ET_propertyList], ETPurposeKey,
		[[self notes] ET_propertyList], ETNotesKey,
		nil];
}

#pragma mark -NSObject

- (id)init
{
	if((self = [super init])) {
		[self setDate:[NSDate date]];
		[self setQuantity:[NSDecimalNumber one]];
		[self setAmount:[NSDecimalNumber zero]];
		[self setPurpose:@""];
		[self setNotes:@""];
	}
	return self;
}
- (void)dealloc
{
	[_date release];
	[_quantity release];
	[_amount release];
	[_purpose release];
	[_notes release];
	[super dealloc];
}

#pragma mark -<NSObject>

- (NSUInteger)hash
{
	return [ETExpense hash] ^ [[self key] hash];
}
- (BOOL)isEqual:(id)obj
{
	return [obj isKindOfClass:[ETExpense class]] && ETEqualObjects([obj key], [self key]);
}

@end
