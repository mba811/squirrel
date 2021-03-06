//
//  SquirrelPanel.m
//  Squirrel
//
//  Created by 弓辰 on 2012/2/13.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "SquirrelPanel.h"

static const int kBorderHeight = 10;
static const int kBorderWidth = 10;
static const int kOffsetHeight = 5;
static const int kFontSize = 24;

@interface SquirrelView : NSView
{
  NSAttributedString* _content;
}

@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic, assign) double cornerRadius;

-(NSSize)contentSize;
-(void)setContent:(NSAttributedString*)content;

@end


@implementation SquirrelView

@synthesize backgroundColor = _backgroundColor;
@synthesize cornerRadius = _cornerRadius;

-(NSSize)contentSize
{
  if (!_content) return NSMakeSize(0, 0);
  return [_content size];
}

-(void)setContent:(NSAttributedString*)content
{
  [content retain];
  [_content release];
  _content = content;
  [self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)rect
{
  if (!_content) {
    return;
  }

  if (_backgroundColor != nil) {
    [_backgroundColor set]; 
  } else {
    [[NSColor windowBackgroundColor] set];
  }

  NSBezierPath * path;
  path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:_cornerRadius yRadius:_cornerRadius];
  [path fill];

  NSPoint point = rect.origin;
  point.x += kBorderWidth;
  point.y += kBorderHeight;
  [_content drawAtPoint:point];
}

@end


@implementation SquirrelPanel

-(id)init
{
  //NSLog(@"SqurrelPanel init");
  _position = NSMakeRect(0, 0, 0, 0);
  _window = [[NSWindow alloc] initWithContentRect:_position
                                        styleMask:NSBorderlessWindowMask
                                          backing:NSBackingStoreBuffered
                                            defer:NO];
  [_window setLevel:NSScreenSaverWindowLevel + 1];
  [_window setHasShadow:YES];    
  [_window setOpaque:NO];
  [_window setBackgroundColor:[NSColor clearColor]];
  _view = [[SquirrelView alloc] initWithFrame:[[_window contentView] frame]];
  [_window setContentView:_view];
  
  _attrs = [[NSMutableDictionary alloc] init];
  [_attrs setObject:[NSColor controlTextColor] forKey:NSForegroundColorAttributeName];
  [_attrs setObject:[NSFont userFontOfSize:kFontSize] forKey:NSFontAttributeName];
  
  _highlightedAttrs = [[NSMutableDictionary alloc] init];
  [_highlightedAttrs setObject:[NSColor selectedControlTextColor] forKey:NSForegroundColorAttributeName];
  [_highlightedAttrs setObject:[NSColor selectedTextBackgroundColor] forKey:NSBackgroundColorAttributeName];
  [_highlightedAttrs setObject:[NSFont userFontOfSize:kFontSize] forKey:NSFontAttributeName];
  
  _commentAttrs = [[NSMutableDictionary alloc] init];
  [_commentAttrs setObject:[NSColor disabledControlTextColor] forKey:NSForegroundColorAttributeName];
  [_commentAttrs setObject:[NSFont userFontOfSize:kFontSize] forKey:NSFontAttributeName];
  
  _horizontal = FALSE;
  return self;
}

-(void)show
{
  NSRect window_rect = [_window frame];
  // resize frame
  NSSize content_size = [(SquirrelView*)_view contentSize];
  window_rect.size.height = content_size.height + kBorderHeight * 2;
  window_rect.size.width = content_size.width + kBorderWidth * 2;
  // reposition window
  window_rect.origin.x = NSMinX(_position);
  window_rect.origin.y = NSMinY(_position) - kOffsetHeight - NSHeight(window_rect);
  // fit in current screen
  NSRect screen_rect = [[NSScreen mainScreen] frame];
  NSArray* screens = [NSScreen screens];
  NSUInteger i;
  for (i = 0; i < [screens count]; ++i) {
    NSRect rect = [[screens objectAtIndex:i] frame];
    if (NSPointInRect(_position.origin, rect)) {
      screen_rect = rect;
      break;
    }
  }
  if (NSMaxX(window_rect) > NSMaxX(screen_rect)) {
    window_rect.origin.x = NSMaxX(screen_rect) - NSWidth(window_rect);
  }
  if (NSMinX(window_rect) < NSMinX(screen_rect)) {
    window_rect.origin.x = NSMinX(screen_rect);
  }
  if (NSMinY(window_rect) < NSMinY(screen_rect)) {
    window_rect.origin.y = NSMaxY(_position) + kOffsetHeight;
  }
  if (NSMaxY(window_rect) > NSMaxY(screen_rect)) {
    window_rect.origin.y = NSMaxY(screen_rect) - NSHeight(window_rect);
  }
  if (NSMinY(window_rect) < NSMinY(screen_rect)) {
    window_rect.origin.y = NSMinY(screen_rect);
  }
  // voila !
  [_window setFrame:window_rect display:YES];
  [_window orderFront:nil];
}

-(void)hide
{
  [_window orderOut:nil];
}

-(void)updatePosition:(NSRect)caretPos
{
  _position = caretPos;
}

-(void)updateCandidates:(NSArray*)candidates
            andComments:(NSArray*)comments
             withLabels:(NSString*)labels
            highlighted:(NSUInteger)index
{
  if ([candidates count] == 0) {
    [self hide];
    return;
  }
  NSMutableAttributedString* text = [[NSMutableAttributedString alloc] init];
  NSUInteger i;
  for (i = 0; i < [candidates count]; ++i) {
    NSString* str;
    if (i < [labels length]) {
      str = [NSString stringWithFormat:@"%c. %@ ", [labels characterAtIndex:i], [candidates objectAtIndex:i]];
    }
    else {
      str = [NSString stringWithFormat:@"%d. %@ ", i + 1, [candidates objectAtIndex:i]];
    }
    NSMutableAttributedString* line = [[[NSMutableAttributedString alloc] initWithString:str attributes:_attrs] autorelease];
    if (i == index) {
      NSRange whole_line = NSMakeRange(0, [line length]);
      [line setAttributes:_highlightedAttrs range:whole_line];
    }
    if (i < [comments count] && [[comments objectAtIndex:i] length] != 0) {
      [line appendAttributedString:[[NSAttributedString alloc] initWithString: [comments objectAtIndex:i] attributes:_commentAttrs]];
    }
    if (i > 0) {
      [text appendAttributedString:[[NSAttributedString alloc] initWithString: _horizontal ? @" " : @"\n" attributes:_attrs]];
    }
    [text appendAttributedString:line];
  }
  [(SquirrelView*)_view setContent:text];
  [text release];
  [self show];
}

-(NSColor *)colorFromString:(NSString *)string
{
    if (string == nil) {
        return nil;
    }
    
    int r, g, b, a;
    sscanf([string cStringUsingEncoding:NSUTF8StringEncoding], "0x%02x%02x%02x%02x", &r, &g, &b, &a);
    
    return [NSColor colorWithDeviceRed:(float) r / 255.f green:(float) g / 255.f blue:(float) b / 255.f alpha:(float) a / 255.f];
}

-(void)updateUIStyle:(SquirrelUIStyle *)style
{
  _horizontal = style->horizontal;
  if (style->fontSize == 0) {  // default size
    style->fontSize = kFontSize;
  }
  if (style->fontName != nil) {
    [_attrs setObject:[NSFont fontWithName:style->fontName size:style->fontSize] forKey:NSFontAttributeName];
    [_highlightedAttrs setObject:[NSFont fontWithName:style->fontName size:style->fontSize] forKey:NSFontAttributeName];
    [_commentAttrs setObject:[NSFont fontWithName:style->fontName size:style->fontSize] forKey:NSFontAttributeName];
  }
  else {  // default font
    [_attrs setObject:[NSFont userFontOfSize:style->fontSize] forKey:NSFontAttributeName];
    [_highlightedAttrs setObject:[NSFont userFontOfSize:style->fontSize] forKey:NSFontAttributeName];
    [_commentAttrs setObject:[NSFont userFontOfSize:style->fontSize] forKey:NSFontAttributeName];
  }
  if (style->backgroundColor != nil) {
    NSColor *color = [self colorFromString:style->backgroundColor];
    [(SquirrelView *) _view setBackgroundColor:(color)];
  }
  if (style->candidateTextColor != nil) {
    NSColor *color = [self colorFromString:style->candidateTextColor];
    [_attrs setObject:color forKey:NSForegroundColorAttributeName];
  }
  if (style->highlightedCandidateTextColor != nil) {
    NSColor *color = [self colorFromString:style->highlightedCandidateTextColor];
    [_highlightedAttrs setObject:color forKey:NSForegroundColorAttributeName];
  }
  if (style->highlightedCandidateBackColor != nil) {
    NSColor *color = [self colorFromString:style->highlightedCandidateBackColor];
  [_highlightedAttrs setObject:color forKey:NSBackgroundColorAttributeName];
  }
  [(SquirrelView *) _view setCornerRadius:style->cornerRadius];
}

@end
