#import "OutlineView.h"
#import "KeyRemap4MacBookKeys.h"
#import "KeyRemap4MacBookNSDistributedNotificationCenter.h"

@implementation org_pqrs_KeyRemap4MacBook_OutlineView

- (void) distributedObserver_preferencesChanged:(NSNotification*)notification
{
  // [NSAutoreleasePool drain] is never called from NSDistributedNotificationCenter.
  // Therefore, we need to make own NSAutoreleasePool.
  NSAutoreleasePool* pool = [NSAutoreleasePool new];
  {
    [outlineview_ reloadData];
  }
  [pool drain];
}

- (void) distributedObserver_configXMLReloaded:(NSNotification*)notification
{
  // [NSAutoreleasePool drain] is never called from NSDistributedNotificationCenter.
  // Therefore, we need to make own NSAutoreleasePool.
  NSAutoreleasePool* pool = [NSAutoreleasePool new];
  {
    [self load:YES];
    [outlineview_ reloadData];
  }
  [pool drain];
}

- (id) init
{
  self = [super init];

  if (self) {
    [org_pqrs_KeyRemap4MacBook_NSDistributedNotificationCenter addObserver:self
                                                                  selector:@selector(distributedObserver_preferencesChanged:)
                                                                      name:kKeyRemap4MacBookPreferencesChangedNotification];

    [org_pqrs_KeyRemap4MacBook_NSDistributedNotificationCenter addObserver:self
                                                                  selector:@selector(distributedObserver_configXMLReloaded:)
                                                                      name:kKeyRemap4MacBookConfigXMLReloadedNotification];
  }

  return self;
}

- (void) dealloc
{
  [org_pqrs_KeyRemap4MacBook_NSDistributedNotificationCenter removeObserver:self];

  [datasource_ release];
  [error_message_ release];

  [super dealloc];
}

- (void) load:(BOOL)force
{
  if (force) {
    if (datasource_) {
      [datasource_ release];
      datasource_ = nil;
    }
    if (error_message_) {
      [error_message_ release];
      error_message_ = nil;
    }
  }

  if (datasource_) return;

  if (ischeckbox_) {
    datasource_ = [[client_ proxy] preferencepane_checkbox];
  } else {
    datasource_ = [[client_ proxy] preferencepane_number];
  }
  if (datasource_) {
    [datasource_ retain];
  }

  error_message_ = [[client_ proxy] preferencepane_error_message];
  if (error_message_) {
    [error_message_ retain];
  }
}

/* ---------------------------------------------------------------------- */
- (NSUInteger) outlineView:(NSOutlineView*)outlineView numberOfChildrenOfItem:(id)item
{
  [self load:NO];

  // ----------------------------------------
  if (error_message_ && ischeckbox_) {
    if (! item) {
      return 1;
    }
    return 0;
  }

  // ----------------------------------------
  NSArray* a = nil;

  // root object
  if (! item) {
    a = datasource_;

  } else {
    a = [item objectForKey:@"children"];
  }

  if (! a) return 0;
  return [a count];
}

- (id) outlineView:(NSOutlineView*)outlineView child:(NSUInteger)idx ofItem:(id)item
{
  [self load:NO];

  // ----------------------------------------
  if (error_message_ && ischeckbox_) {
    if (! item && idx == 0) {
      return error_message_;
    }
    return nil;
  }

  // ----------------------------------------
  NSArray* a = nil;

  // root object
  if (! item) {
    a = datasource_;

  } else {
    a = [item objectForKey:@"children"];
  }

  if (! a) return nil;
  if (idx >= [a count]) return nil;
  return [a objectAtIndex:idx];
}

- (BOOL) outlineView:(NSOutlineView*)outlineView isItemExpandable:(id)item
{
  if (error_message_ && ischeckbox_) {
    return NO;
  }

  // ----------------------------------------
  NSArray* a = [item objectForKey:@"children"];
  return a ? YES : NO;
}

- (id) outlineView:(NSOutlineView*)outlineView objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
  if (error_message_ && ischeckbox_) {
    NSButtonCell* cell = [tableColumn dataCell];
    [cell setTitle:error_message_];
    [cell setImagePosition:NSNoImage];
    return nil;
  }

  // ----------------------------------------
  NSString* identifier = [item objectForKey:@"identifier"];

  if (ischeckbox_) {
    NSButtonCell* cell = [tableColumn dataCell];
    if (! cell) return nil;

    [cell setTitle:[item objectForKey:@"name"]];

    if (! identifier || [identifier hasPrefix:@"notsave."]) {
      [cell setImagePosition:NSNoImage];
      return nil;

    } else {
      [cell setImagePosition:NSImageLeft];
      return [NSNumber numberWithInt:[[client_ proxy] value:identifier]];
    }

  } else {
    NSString* columnIdentifier = [tableColumn identifier];

    if ([columnIdentifier isEqualToString:@"name"]) {
      return [item objectForKey:columnIdentifier];

    } else if ([columnIdentifier isEqualToString:@"baseunit"] ||
               [columnIdentifier isEqualToString:@"default"]) {
      if (! identifier) {
        return nil;
      }
      return [item objectForKey:columnIdentifier];

    } else if ([columnIdentifier isEqualToString:@"value"]) {
      NSTextFieldCell* cell = [tableColumn dataCell];
      if (! cell) return nil;

      if (! identifier) {
        [cell setEditable:NO];
        return nil;
      } else {
        [cell setEditable:YES];
        return [NSNumber numberWithInt:[[client_ proxy] value:identifier]];
      }
    }
  }

  return nil;
}

- (CGFloat) outlineView:(NSOutlineView*)outlineView heightOfRowByItem:(id)item
{
  if (error_message_ && ischeckbox_) {
    return [outlineView rowHeight] * 20;
  }

  // ----------------------------------------
  NSNumber* number = [item objectForKey:@"cached_height"];
  if (number) return [number floatValue];

  number = [item objectForKey:@"height"];
  if (! number || [number intValue] == 0) {
    number = [NSNumber numberWithDouble:[outlineView rowHeight]];
  } else {
    number = [NSNumber numberWithDouble:([number intValue] * (CGFloat)([outlineView rowHeight]))];
  }
  return [number floatValue];
}

- (void) outlineView:(NSOutlineView*)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
  if (error_message_ && ischeckbox_) {
    return;
  }

  // ----------------------------------------
  NSString* identifier = [item objectForKey:@"identifier"];

  if (ischeckbox_) {
    if (identifier) {
      if (! [identifier hasPrefix:@"notsave."]) {
        int value = [[client_ proxy] value:identifier];
        value = ! value;
        [[client_ proxy] setValueForName:value forName:identifier];
      }
    } else {
      // expand/collapse tree
      if ([outlineView isExpandable:item]) {
        if ([outlineView isItemExpanded:item]) {
          [outlineView collapseItem:item];
        } else {
          [outlineView expandItem:item];
        }
      }
    }

  } else {
    if (identifier) {
      NSString* columnIdentifier = [tableColumn identifier];
      if ([columnIdentifier isEqualToString:@"value"]) {
        [[client_ proxy] setValueForName:[object intValue] forName:identifier];

      } else if ([columnIdentifier isEqualToString:@"stepper"]) {
        int newvalue = [[client_ proxy] value:identifier];
        NSNumber* step = [item objectForKey:@"step"];
        newvalue += ([object intValue] * [step intValue]);

        // confirm range
        if (newvalue < 0) {
          newvalue = 0;
        } else if (newvalue > 1073741824) { // 2^30
          newvalue = 1073741824;
        }

        [[client_ proxy] setValueForName:newvalue forName:identifier];

        [outlineView reloadItem:item];
      }
    }
  }
}

/* ---------------------------------------------------------------------- */
- (NSDictionary*) filterDataSource_core:(NSDictionary*)dictionary isEnabledOnly:(BOOL)isEnabledOnly strings:(NSArray*)strings
{
  // ------------------------------------------------------------
  // check children
  NSArray* children = [dictionary objectForKey:@"children"];
  if (children) {
    NSMutableArray* newchildren = [[NSMutableArray new] autorelease];
    for (NSDictionary* dict in children) {
      NSDictionary* d = [self filterDataSource_core:dict isEnabledOnly:isEnabledOnly strings:strings];
      if (d) {
        [newchildren addObject:d];
      }
    }

    if ([newchildren count] > 0) {
      NSMutableDictionary* newdictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
      [newdictionary setObject:newchildren forKey:@"children"];
      return newdictionary;
    }
  }

  // ------------------------------------------------------------
  // filter by isEnabledOnly
  if (isEnabledOnly) {
    NSString* identifier = [dictionary objectForKey:@"identifier"];
    if (! identifier) {
      return nil;
    }
    if (! [[client_ proxy] value:identifier]) {
      return nil;
    }
  }

  // check self name
  NSString* string_for_filter = [dictionary objectForKey:@"string_for_filter"];
  if (string_for_filter) {
    BOOL hit = YES;
    for (NSString* s in strings) {
      if ([string_for_filter rangeOfString:s].location == NSNotFound) hit = NO;
    }
    if (hit) {
      return dictionary;
    }
  }

  return nil;
}

- (void) filterDataSource:(BOOL)isEnabledOnly string:(NSString*)string
{
  [self load:YES];
  if (! datasource_) return;

  NSMutableArray* newdatasource = [[NSMutableArray new] autorelease];

  NSMutableArray* strings = [[NSMutableArray new] autorelease];
  if (string) {
    for (NSString* s in [string componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceCharacterSet]]) {
      if ([s length] == 0) continue;
      [strings addObject:[s lowercaseString]];
    }
  }

  for (NSDictionary* dict in datasource_) {
    NSDictionary* d = [self filterDataSource_core:dict isEnabledOnly:isEnabledOnly strings:strings];
    if (d) {
      [newdatasource addObject:d];
    }
  }

  [datasource_ release];
  datasource_ = [newdatasource retain];
  [outlineview_ reloadData];

  if ([string length] == 0 && isEnabledOnly == NO) {
    [outlineview_ collapseItem:nil collapseChildren:YES];
  } else {
    [outlineview_ expandItem:nil expandChildren:YES];
  }
}

@end
