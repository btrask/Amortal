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
#import "ETDocument.h"

// Models
#import "ETExpense.h"

// Other Sources
#import "ETFoundationAdditions.h"

static NSUInteger const ETCurrentVersion = 0;
static NSUInteger const ETSecondsPerDay = (60 * 60 * 24);

static NSString *const ETVersionKey = @"ETVersion";
static NSString *const ETExpensesKey = @"ETExpenses";
static NSString *const ETWindowRectKey = @"ETWindowRect";

@interface ETDocument(Private)

- (void)_setExpenses:(NSMutableArray *)expenses;

@end

@implementation ETDocument

#pragma mark -ETDocument

- (IBAction)selectRelated:(id)sender
{
	NSArray *const selectedExpenses = [self selectedExpenses];
	NSMutableIndexSet *const selection = [NSMutableIndexSet indexSet];
	NSUInteger i;
	for(i = 0; i < [_expenses count]; ++i) {
		ETExpense *const expense = [_expenses objectAtIndex:i];
		if([selectedExpenses containsObject:expense] && [expense getDuration:NULL withNext:YES expenseInArray:_expenses]) [selection addIndex:i];
	}
	[expenseTableView selectRowIndexes:selection byExtendingSelection:NO];
}
- (IBAction)selectPrevious:(id)sender
{
	[self selectExpense:[[self selectedExpense] next:NO expenseInArray:_expenses]];
}
- (IBAction)selectNext:(id)sender
{
	[self selectExpense:[[self selectedExpense] next:YES expenseInArray:_expenses]];
}

#pragma mark -

- (NSArray *)expenses
{
	return [[_expenses copy] autorelease];
}
- (void)addExpense:(ETExpense *)expense
{
	[[self ET_undo] removeExpense:expense];
	[_expenses addObject:expense];
	[_expenses sortUsingSelector:@selector(compare:)];
	NSUInteger const i = [_expenses indexOfObjectIdenticalTo:expense];
	[expenseTableView reloadData];
	[expenseTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
	[expenseTableView scrollRowToVisible:i];
	[expense ET_addObserver:self selector:@selector(expenseDidChange:) name:ETExpenseDidChangeNotification];
}
- (void)removeExpense:(ETExpense *)expense
{
	[[self ET_undo] addExpense:expense];
	[_expenses removeObjectIdenticalTo:expense];
	[self expenseDidChange:nil];
	[expense ET_removeObserver:self name:ETExpenseDidChangeNotification];
}

#pragma mark -

- (NSArray *)selectedExpenses
{
	return [_expenses objectsAtIndexes:[expenseTableView selectedRowIndexes]];
}
- (ETExpense *)selectedExpense
{
	NSArray *const e = [self selectedExpenses];
	return [e count] == 1 ? [e objectAtIndex:0] : nil;
}
- (BOOL)selectExpense:(ETExpense *)expense
{
	NSUInteger const i = [_expenses indexOfObjectIdenticalTo:expense];
	if(NSNotFound == i) return NO;
	[expenseTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
	[expenseTableView scrollRowToVisible:i];
	return YES;
}

#pragma mark -

- (void)expenseDidChange:(NSNotification *)aNotif
{
	[expenseTableView reloadData];
	[self tableViewSelectionDidChange:nil];
}

#pragma mark -ETDocument(Private)

- (void)_setExpenses:(NSMutableArray *)expenses
{
	if(ETEqualObjects(_expenses, expenses)) return;
	[[self ET_undo] _setExpenses:_expenses];
	for(ETExpense *const expense in _expenses) [expense ET_removeObserver:self name:ETExpenseDidChangeNotification];
	[_expenses release];
	_expenses = [expenses retain];
	for(ETExpense *const expense in _expenses) [expense ET_addObserver:self selector:@selector(expenseDidChange:) name:ETExpenseDidChangeNotification];
	[self expenseDidChange:nil];
}

#pragma mark -<ETTableViewDataSource>

- (void)tableViewShouldCreateRow:(ETTableView *)sender
{
	ETExpense *const expense = [[[ETExpense alloc] init] autorelease];
	[expense setUndoManager:[self undoManager]];
	[self addExpense:expense];
	NSUInteger const i = [_expenses indexOfObjectIdenticalTo:expense];
	[expenseTableView editColumn:[[expenseTableView tableColumns] indexOfObjectIdenticalTo:purposeColumn] row:i withEvent:[[expenseTableView window] currentEvent] select:YES];
}
- (void)tableViewShouldDeleteSelection:(ETTableView *)sender
{
	[[self ET_undo] _setExpenses:[[_expenses mutableCopy] autorelease]];
	[_expenses removeObjectsAtIndexes:[expenseTableView selectedRowIndexes]];
	[expenseTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[self expenseDidChange:nil];
}

#pragma mark -<NSTableViewDataSource>

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [_expenses count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	ETExpense *const expense = [_expenses objectAtIndex:row];
	if(tableColumn == dateColumn) {
		return [expense date];
	} else if(tableColumn == durationColumn) {
		NSTimeInterval duration = 0;
		if(![expense getDuration:&duration withNext:YES expenseInArray:_expenses]) return [[expense quantity] ET_isZero] ? NSLocalizedString(@"(stopped)", nil) : NSLocalizedString(@"(ongoing)", nil);
		unsigned long const days = (unsigned long)round(duration / ETSecondsPerDay);
		if(1 == days) return NSLocalizedString(@"1 day", nil);
		return [NSString localizedStringWithFormat:NSLocalizedString(@"%lu days", nil), days];
	} else if(tableColumn == quantityColumn) {
		return [expense quantity];
	} else if(tableColumn == amountColumn) {
		if([[expense quantity] ET_isZero]) return [NSDecimalNumber notANumber];
		return [expense amount];
	} else if(tableColumn == purposeColumn) {
		return [expense purpose];
	} else if(tableColumn == notesColumn) {
		return [expense notes];
	}
	return nil;
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	ETExpense *const expense = [_expenses objectAtIndex:row];
	if(tableColumn == dateColumn) {
		[expense setDate:object];
		[_expenses sortUsingSelector:@selector(compare:)];
		[expenseTableView reloadData];
		[self selectExpense:expense];
	} else if(tableColumn == durationColumn) {
		ETAssertNotReached(@"Duration column is not editable.");
	} else if(tableColumn == quantityColumn) {
		[expense setQuantity:object];
	} else if(tableColumn == amountColumn) {
		NSAssert(![[expense quantity] ET_isZero], @"Cannot set the amount when the quantity is zero.");
		[expense setAmount:object];
	} else if(tableColumn == purposeColumn) {
		[expense setPurpose:object];
	} else if(tableColumn == notesColumn) {
		[expense setNotes:object];
	}
}

#pragma mark -<NSTableViewDelegate>

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	ETExpense *const expense = [_expenses objectAtIndex:row];
	BOOL const editing = ([tableView editedRow] == row && [tableView editedColumn] == (NSInteger)[[tableView tableColumns] indexOfObjectIdenticalTo:tableColumn]);
	if(editing) {
		[cell setTextColor:[NSColor controlTextColor]];
	} else if([[expense quantity] ET_isZero]) {
		[cell setTextColor:[NSColor disabledControlTextColor]];
	} else {
		BOOL const negative = [[expense amount] ET_isNegative];
		BOOL const ongoing = ![expense getDuration:NULL withNext:(YES) expenseInArray:_expenses];
		if(tableColumn == amountColumn && negative) {
			BOOL const selected = [[tableView selectedRowIndexes] containsIndex:row] && [[tableView window] isKeyWindow];
			[cell setTextColor:selected ? [NSColor colorWithDeviceRed:1.0 green:0.75 blue:0.75 alpha:1.0] : [NSColor redColor]];
		} else if(tableColumn == durationColumn && ongoing) {
			[cell setTextColor:[NSColor disabledControlTextColor]];
		} else {
			[cell setTextColor:[NSColor controlTextColor]];
		}
	}
}
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	ETExpense *const expense = [_expenses objectAtIndex:row];
	if(tableColumn == amountColumn) {
		if([[expense quantity] ET_isZero]) return NO;
	}
	return YES;
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotif
{
	NSMutableIndexSet *const remainingExpenses = [[[expenseTableView selectedRowIndexes] mutableCopy] autorelease];
	if(![remainingExpenses count]) return [statusTextField setStringValue:@""];

	NSDecimalNumber *total = [NSDecimalNumber zero];
	NSMutableDictionary *dollarsPerKey = [NSMutableDictionary dictionary];
	NSMutableDictionary *secondsPerKey = [NSMutableDictionary dictionary];

	NSUInteger i;
	for(i = [remainingExpenses firstIndex]; NSNotFound != i; i = [remainingExpenses indexGreaterThanIndex:i]) {
		ETExpense *const expense = [_expenses objectAtIndex:i];
		id const key = [expense key];

		BOOL const none = [[expense quantity] ET_isZero];
		NSDecimalNumber *const amount = [expense amount];
		total = [total decimalNumberByAdding:amount];

		NSTimeInterval duration = 0.0;
		if(![expense getDuration:&duration withNext:YES expenseInArray:_expenses] && !none) {
			dollarsPerKey = nil;
			secondsPerKey = nil;
		}
		if(dollarsPerKey && duration >= 0) {
			NSDecimalNumber *const dollars = [dollarsPerKey objectForKey:key];
			NSNumber *const seconds = [secondsPerKey objectForKey:key];
			[dollarsPerKey setObject:[dollars ? dollars : [NSDecimalNumber zero] decimalNumberByAdding:amount] forKey:key];
			[secondsPerKey setObject:[NSNumber numberWithDouble:(seconds ? [seconds doubleValue] : 0.0) + duration] forKey:key];
		}
	}

	double daily = 0.0;
	for(id const key in dollarsPerKey) {
		daily += [[dollarsPerKey objectForKey:key] doubleValue] / ([[secondsPerKey objectForKey:key] doubleValue] / ETSecondsPerDay);
	}

	NSString *const totalString = [NSNumberFormatter localizedStringFromNumber:total numberStyle:NSNumberFormatterCurrencyStyle];
	NSString *const dailyString = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:daily] numberStyle:NSNumberFormatterCurrencyStyle];

	NSShadow *const s = [[[NSShadow alloc] init] autorelease];
	[s setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.25]];
	[s setShadowOffset:NSMakeSize(0.0, -1.0)];
	NSString *const statusString = [NSString localizedStringWithFormat:NSLocalizedString(@"%@ total, %@", nil), totalString, dollarsPerKey ? [NSString localizedStringWithFormat:NSLocalizedString(@"%@ per day", nil), dailyString] : NSLocalizedString(@"ongoing", nil)];
	NSMutableParagraphStyle *const style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[style setAlignment:NSCenterTextAlignment];
	[style setLineBreakMode:NSLineBreakByTruncatingTail];
	NSDictionary *const attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		s, NSShadowAttributeName,
		[NSFont labelFontOfSize:11.0], NSFontAttributeName,
		style, NSParagraphStyleAttributeName,
		nil];
	[statusTextField setAttributedStringValue:[[[NSAttributedString alloc] initWithString:statusString attributes:attributes] autorelease]];
}

#pragma mark -NSDocument

- (NSString *)windowNibName
{
	return @"ETDocument";
}
- (void)windowControllerDidLoadNib:(NSWindowController *)controller
{
	[super windowControllerDidLoadNib:controller];
	NSNumberFormatter *const quantityFormatter = [[quantityColumn dataCell] formatter];
	NSNumberFormatter *const amountFormatter = [[amountColumn dataCell] formatter];
	[quantityFormatter setGeneratesDecimalNumbers:YES];
	[amountFormatter setGeneratesDecimalNumbers:YES];
	[amountFormatter setNotANumberSymbol:NSLocalizedString(@"N/A", nil)];
	[statusTextField setStringValue:@""];
	if(!NSIsEmptyRect(_windowRect)) {
		[controller setShouldCascadeWindows:NO];
		[[controller window] setFrame:_windowRect display:YES];
	}
}
- (void)showWindows
{
	[super showWindows];
	if(!_incompatibleVersion) return;
	[[NSAlert alertWithMessageText:NSLocalizedString(@"This document was saved with a newer version of Amortal.", nil) defaultButton:NSLocalizedString(@"OK", nil) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Some attributes or formatting may be lost.", nil)] beginSheetModalForWindow:[expenseTableView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

#pragma mark -

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	NSDictionary *const plist = [NSDictionary dictionaryWithObjectsAndKeys:
		[[NSNumber numberWithUnsignedInteger:ETCurrentVersion] ET_propertyList], ETVersionKey,
		[_expenses ET_propertyList], ETExpensesKey,
		[NSStringFromRect([[expenseTableView window] frame]) ET_propertyList], ETWindowRectKey,
		nil];
	return [NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListXMLFormat_v1_0 options:kNilOptions error:outError];
}
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	NSDictionary *const plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:outError];
	if(!plist) return NO;
	[[self undoManager] disableUndoRegistration];
	NSArray *const expenses = [plist objectForKey:ETExpensesKey];
	for(id const obj in expenses) {
		ETExpense *const expense = [ETExpense ET_objectWithPropertyList:obj];
		[expense setUndoManager:[self undoManager]];
		[self addExpense:expense];
	}
	_windowRect = NSRectFromString([NSString ET_objectWithPropertyList:[plist objectForKey:ETWindowRectKey]]);
	if([[NSNumber ET_objectWithPropertyList:[plist objectForKey:ETVersionKey]] unsignedIntegerValue] > ETCurrentVersion) _incompatibleVersion = YES;
	[self expenseDidChange:nil];
	[[self undoManager] enableUndoRegistration];
	return YES;
}

#pragma mark -NSObject

- (id)init
{
	if((self = [super init])) {
		_expenses = [[NSMutableArray alloc] init];
	}
	return self;
}
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[expenseTableView setDataSource:nil];
	[_expenses release];
	[super dealloc];
}

#pragma mark -NSObject(NSMenuValidation)

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL const action = [anItem action];
	if(@selector(selectRelated:) == action) {
		if(![[expenseTableView selectedRowIndexes] count]) return NO;
	}
	if(![self selectedExpense]) {
		if(@selector(selectPrevious:) == action) return NO;
		if(@selector(selectNext:) == action) return NO;
	}
	return [super validateMenuItem:anItem];
}

@end
