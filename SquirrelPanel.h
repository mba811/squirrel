//
//  SquirrelPanel.h
//  Squirrel
//
//  Created by 弓辰 on 2012/2/13.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct {
  bool horizontal;
  NSString* fontName;
  int fontSize;
  NSString *backgroundColor;
  NSString *candidateTextColor;
  NSString *highlightedCandidateTextColor;
  NSString *highlightedCandidateBackColor;
  double cornerRadius;
} SquirrelUIStyle;

@interface SquirrelPanel : NSObject {
  NSRect _position;
  NSWindow* _window;
  NSView* _view;
  NSMutableDictionary* _attrs;
  NSMutableDictionary* _highlightedAttrs;
  NSMutableDictionary* _commentAttrs;
  bool _horizontal;
}

-(void)show;
-(void)hide;
-(void)updatePosition:(NSRect)caretPos;
-(void)updateCandidates:(NSArray*)candidates
            andComments:(NSArray*)comments
             withLabels:(NSString*)labels
            highlighted:(NSUInteger)index;
-(void)updateUIStyle:(SquirrelUIStyle*)style;

@end
