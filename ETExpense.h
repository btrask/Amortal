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
// Other Sources
#import "ETPropertyListSerializing.h"

extern NSString *const ETExpenseDidChangeNotification;

@interface ETExpense : NSObject <ETPropertyListSerializing, NSPasteboardReading, NSPasteboardWriting>
{
	@private
	NSDate *_date;
	NSDecimalNumber *_quantity;
	NSDecimalNumber *_amount;
	NSString *_purpose;
	NSString *_notes;

	NSUndoManager *_undoManager;
}

- (id)init;
- (id)initWithPropertyList:(id const)plist;

@property(copy) NSDate *date;
@property(copy) NSDecimalNumber *quantity;
@property(copy) NSDecimalNumber *amount;
@property(copy) NSString *purpose;
@property(copy) NSString *notes;

@property(readonly) BOOL isStopped;

- (ETExpense *)next:(BOOL)flag expenseInArray:(NSArray *)expenses;

- (BOOL)getDuration:(out NSTimeInterval *)outDuration withNext:(BOOL)flag expense:(ETExpense *)expense;
- (BOOL)getDuration:(out NSTimeInterval *)outDuration withNext:(BOOL)flag expenseInArray:(NSArray *)expenses;

- (NSComparisonResult)compare:(ETExpense *)obj;

@property(assign) NSUndoManager *undoManager;

@end
