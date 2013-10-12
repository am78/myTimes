//
//  CalItemView.m
//  Calendar
//
//  Created by Michael Anteboth on 20.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CalItemView.h"
#import "CalEventDescriptor.h"
#import "WorkUnitDetailsTableViewController.h"
#import "TimeWorkUnit.h"
#import "CalendarTableView.h"
#import "CalendarTableViewController.h"
#import "TaskTrackerAppDelegate.h"

@implementation CalItemView

@synthesize calItemDescriptors;
@synthesize calItemImage;

#define MAIN_FONT_SIZE 12
#define MIN_MAIN_FONT_SIZE 10
#define SECONDARY_FONT_SIZE 10
#define MIN_SECONDARY_FONT_SIZE 6
#define DEFAULT_ALPHA 0.85;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		[self setUserInteractionEnabled:TRUE];
        // Initialization code
		self.backgroundColor = [UIColor clearColor];
		self.alpha = DEFAULT_ALPHA;
		[UIView setAnimationDelay:0];
		
		UIImage* btn = [UIImage imageNamed:@"roundedrect3.png"];
		self.calItemImage = [btn stretchableImageWithLeftCapWidth:10.0 topCapHeight:15.0];
    }
    return self;
}

#pragma mark mouse touches


-(CalEventDescriptor*) getSelectedItemFor:(CGPoint)point {
	CalEventDescriptor* sel = nil;
	for (CalEventDescriptor* desc in calItemDescriptors) {
		if (CGRectContainsPoint(desc.rect, point)) {
			//point is in rect of item so set it as selected item
			if (sel != nil && desc.indentLevel > selectedItem.indentLevel) {
				sel = desc;
			} else {
				sel = desc;
			}
		}
	}
	return sel;
}

-(void) selectCalItem:(CGPoint)point {
	selectedItem = [self getSelectedItemFor:point];
	if (selectedItem != nil) {
		//repaint is nessecary if selection is not nil
		[self setNeedsDisplayInRect:selectedItem.rect];
	}
}

//displays a workunit in the workunit edit view
-(void) displayItem:(CalEventDescriptor*)item {
	TimeWorkUnit* wu = (TimeWorkUnit*) item.referenceObject;
	Project* project;
	ProjectTask* task;
	//find project and Task for the workunit
	TaskTrackerAppDelegate *appDelegate = (TaskTrackerAppDelegate *)[[UIApplication sharedApplication] delegate];
	for (Project* p in appDelegate.data) {
		for (ProjectTask* pt in p.tasks) {
			for (TimeWorkUnit* w in pt.workUnits) {
				if (w == wu) {
					project = p;
					task = pt;
					break;
				}
			}
		}
	}
	
	
	CalendarTableView* tv = (CalendarTableView*) self.superview;
	CalendarTableViewController* tvctl = (CalendarTableViewController*) tv.delegate;
	
	//create WorkUnitEditView
	WorkUnitDetailsTableViewController* ctl = [[WorkUnitDetailsTableViewController alloc] initWithNibName:@"WorkUnitDetailsView" bundle:nil];
	//tell the controller that we only edit an existing work unit
	ctl.workUnitAddMode = FALSE;
	//set task in controller
	ctl.parentTask = task;
	ctl.parentProject = project;
	//set workUnit in controller
	ctl.workUnit = wu;
	//set parent table to reload table view after WorkUnit creation
	ctl.parentTable = tv;
	//popup the view controller
	[tvctl.navigationController pushViewController:ctl animated:YES];	
	[ctl release];
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	UITouch *touch = [touches anyObject];
	touchPoint1 = [touch locationInView:self];
	[self selectCalItem:touchPoint1];
	
	CalEventDescriptor* sel = [self getSelectedItemFor:touchPoint1];
	if (sel != nil) {
		[self displayItem:sel];
	}
	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	//deselect if there is any selection
	selectedItem = nil;
	[self setNeedsDisplay];
}

// Handles the end of a touch event.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	touchPoint2 = [touch locationInView:self];
	
/*	if (touchPoint1.x == touchPoint2.x && touchPoint1.y == touchPoint2.y) {
		//display selected item
		CalEventDescriptor* sel = [self getSelectedItemFor:touchPoint2];
		if (sel != nil) {
			[self displayItem:sel];
		}
	}
 */
	//deselect if there is any selection
	//if (selectedItem != nil) {		
		selectedItem = nil;
		[self setNeedsDisplay];
	//}
}	


#pragma mark drawing code

- (void)drawRoundRect:(CGRect)rect 
				 text:(NSString*)text 
		  description:(NSString*)description
			rectColor:(UIColor*)rectColor
		  strokeColor:(UIColor*)strokeColor 
		  strokeWidth:(int)strokeWidth 
		 cornerRadius:(float)cornerRadius
		   isSelected:(BOOL)selected
{	

	 CGContextRef context = UIGraphicsGetCurrentContext();
		
	/** draw round rect */
    CGContextSetLineWidth(context, strokeWidth);
    CGContextSetStrokeColorWithColor(context, strokeColor.CGColor);
	
	//use selection color if item is selected
	UIColor* selClr = rectColor;
	if (selected) {
		selClr = [UIColor yellowColor];
	} 
	CGContextSetFillColorWithColor(context, selClr.CGColor);
    
    CGFloat radius = cornerRadius;
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    
    // Make sure corner radius isn't larger than half the shorter side
    if (radius > width/2.0)
        radius = width/2.0;
    if (radius > height/2.0)
        radius = height/2.0;    
	
	CGRect smallRect = CGRectMake(rect.origin.x+1, rect.origin.y+1, rect.size.width-2, rect.size.height-2);
	
    CGFloat minx = CGRectGetMinX(smallRect);
    CGFloat midx = CGRectGetMidX(smallRect);
    CGFloat maxx = CGRectGetMaxX(smallRect);
    CGFloat miny = CGRectGetMinY(smallRect);
    CGFloat midy = CGRectGetMidY(smallRect);
    CGFloat maxy = CGRectGetMaxY(smallRect);
    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);

	
	/** draw a button image for more depth */
	[self.calItemImage drawInRect:rect blendMode:kCGBlendModeNormal alpha:1];
	
		
	/** draw text **/	
	// Color and font for the main text items (time zone name, time)	
	UIColor *mainTextColor = [UIColor blackColor];
	UIFont *mainFont = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
	UIFont *secFont = [UIFont systemFontOfSize:SECONDARY_FONT_SIZE];
	// Set the color for the main text items
	[mainTextColor set];
	
	CGFloat boundsX = rect.origin.x;
	CGFloat boundsY = rect.origin.y;
	CGPoint point;
	
	int maxWidth = rect.size.width - 13;
	
	//draw text
	point = CGPointMake(boundsX + 10, boundsY + 2);
	[text drawAtPoint:point forWidth:maxWidth withFont:mainFont minFontSize:MIN_MAIN_FONT_SIZE actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
	
	//draw description text 
	point = CGPointMake(boundsX + 10, boundsY + 15);
	[description drawAtPoint:point forWidth:maxWidth withFont:secFont minFontSize:SECONDARY_FONT_SIZE actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignBaselines];	
}

- (void)drawRect:(CGRect)rect {
//	[super drawRect:rect];
	
	for (CalEventDescriptor* desc in self.calItemDescriptors) {
		BOOL selected = desc == selectedItem;
		[self drawRoundRect:desc.rect 
					   text:desc.text 
				description:desc.description 
				  rectColor:desc.color 
				strokeColor:desc.color 
				strokeWidth:0 
			   cornerRadius:5
				 isSelected:selected];
	}
}


- (void)dealloc {
	[calItemImage release];
	[calItemDescriptors release];
    [super dealloc];
}


@end
