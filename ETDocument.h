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
// Models
@class ETExpense;

// Views
#import "ETTableView.h"

@interface ETDocument : NSDocument <ETTableViewDataSource, NSTableViewDataSource, NSTableViewDelegate>
{
	@private
	IBOutlet ETTableView *expenseTableView;
	IBOutlet NSTableColumn *dateColumn;
	IBOutlet NSTableColumn *durationColumn;
	IBOutlet NSTableColumn *quantityColumn;
	IBOutlet NSTableColumn *amountColumn;
	IBOutlet NSTableColumn *purposeColumn;
	IBOutlet NSTableColumn *notesColumn;
	IBOutlet NSTextField *statusTextField;
	NSMutableArray *_expenses;
	NSRect _windowRect;
	BOOL _incompatibleVersion;
}

- (IBAction)selectRelated:(id)sender;
- (IBAction)selectPrevious:(id)sender;
- (IBAction)selectNext:(id)sender;

- (IBAction)copy:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)delete:(id)sender;

@property(readonly) NSArray *expenses;
- (void)addExpense:(ETExpense *)expense;
- (void)removeExpense:(ETExpense *)expense;

- (void)addExpenses:(NSArray *const)expenses;
- (void)removeExpensesAtIndexes:(NSIndexSet *const)indexes;

- (NSArray *)selectedExpenses;
- (ETExpense *)selectedExpense;
- (BOOL)selectExpense:(ETExpense *)expense;

- (void)expenseDidChange:(NSNotification *)aNotif;

@end
