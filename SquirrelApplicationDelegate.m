
#import "SquirrelApplicationDelegate.h"
#import "SquirrelPanel.h"
#import <rime_api.h>

@implementation SquirrelApplicationDelegate

-(NSMenu*)menu
{
  return _menu;
}

-(SquirrelPanel*)panel
{
  return _panel;
}

-(id)updater
{
  return _updater;
}

-(BOOL)useUSKeyboardLayout
{
  return _useUSKeyboardLayout;
}

-(IBAction)deploy:(id)sender
{
  NSLog(@"Start maintenace...");
  // restart
  RimeFinalize();
  [self startRimeWithFullCheck:TRUE];
  [self loadSquirrelConfig];
}

-(IBAction)openWiki:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://code.google.com/p/rimeime/w/list"]];
}

-(void)startRimeWithFullCheck:(BOOL)fullCheck
{
  RimeTraits squirrel_traits;
  squirrel_traits.shared_data_dir = [[[NSBundle mainBundle] sharedSupportPath] UTF8String];
  squirrel_traits.user_data_dir = [[@"~/Library/Rime" stringByStandardizingPath] UTF8String];
  squirrel_traits.distribution_code_name = "Squirrel";
  squirrel_traits.distribution_name = "鼠鬚管";
  squirrel_traits.distribution_version = [[[[NSBundle mainBundle] infoDictionary] 
                                           objectForKey:@"CFBundleVersion"] UTF8String];
  NSLog(@"Initializing la rime...");
  RimeInitialize(&squirrel_traits);
  if (RimeStartMaintenance((Bool)fullCheck)) {
    // TODO: notification
    NSArray* args = [NSArray arrayWithObjects:@"Preparing Rime for updates; patience.", nil];
    [NSTask launchedTaskWithLaunchPath:@"/usr/bin/say" arguments:args];
  }
}

-(void)loadSquirrelConfig
{
  RimeConfig config;
  if (!RimeConfigOpen("squirrel", &config)) {
    return;
  }
  NSLog(@"Loading squirrel specific config...");
  _useUSKeyboardLayout = FALSE;
  Bool value;
  if (RimeConfigGetBool(&config, "us_keyboard_layout", &value)) {
    _useUSKeyboardLayout = (BOOL)value;
  }
  
  SquirrelUIStyle style = { FALSE, nil, 0, 0, 0, 0, 0, 0 };
  if (RimeConfigGetBool(&config, "style/horizontal", &value)) {
    style.horizontal = (BOOL)value;
  }
  char font_face[100] = {0};
  if (RimeConfigGetString(&config, "style/font_face", font_face, sizeof(font_face))) {
    style.fontName = [[NSString alloc] initWithUTF8String:font_face];
  }
  RimeConfigGetInt(&config, "style/font_point", &style.fontSize);
  // 0xrrggbbaa
  char color[11] = {0};
  if (RimeConfigGetString(&config, "style/back_color", color, sizeof(color))) {
    style.backgroundColor = [[NSString alloc] initWithUTF8String:color];
  }
  if (RimeConfigGetString(&config, "style/candidate_text_color", color, sizeof(color))) {
    style.candidateTextColor = [[NSString alloc] initWithUTF8String:color];
  }
  if (RimeConfigGetString(&config, "style/hilited_candidate_text_color", color, sizeof(color))) {
    style.highlightedCandidateTextColor = [[NSString alloc] initWithUTF8String:color];
  }
  if (RimeConfigGetString(&config, "style/hilited_candidate_back_color", color, sizeof(color))) {
    style.highlightedCandidateBackColor = [[NSString alloc] initWithUTF8String:color];
  }
  RimeConfigGetDouble(&config, "style/corner_radius", &style.cornerRadius);
  RimeConfigClose(&config);
  
  [_panel updateUIStyle:&style];
  [style.fontName release];
  [style.backgroundColor release];
  [style.candidateTextColor release];
  [style.highlightedCandidateTextColor release];
  [style.highlightedCandidateBackColor release];
}

-(BOOL)problematicLaunchDetected
{
  BOOL detected = FALSE;
  NSString* logfile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"launch.dat"];
  //NSLog(@"[DEBUG] archive: %@", logfile);
  NSData* archive = [NSData dataWithContentsOfFile:logfile options:NSDataReadingUncached error:nil];
  if (archive) {
    NSDate* previousLaunch = [NSKeyedUnarchiver unarchiveObjectWithData:archive];
    if (previousLaunch && [previousLaunch timeIntervalSinceNow] >= -2) {
      detected = TRUE;
    }
  }
  NSDate* now = [NSDate date];
  NSData* record = [NSKeyedArchiver archivedDataWithRootObject:now];
  [record writeToFile:logfile atomically:NO];
  return detected;
}

//add an awakeFromNib item so that we can set the action method.  Note that 
//any menuItems without an action will be disabled when displayed in the Text 
//Input Menu.
-(void)awakeFromNib
{
  //NSLog(@"SquirrelApplicationDelegate awakeFromNib");
}

-(void)dealloc 
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];
}

@end  //SquirrelApplicationDelegate
