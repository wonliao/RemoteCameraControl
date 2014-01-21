//
//  CHDraggableView+Avatar.m
//  ChatHeads
//
//  Created by Matthias Hochgatterer on 4/19/13.
//  Copyright (c) 2013 Matthias Hochgatterer. All rights reserved.
//

#import "CHDraggableView+Avatar.h"

#import "CHAvatarView.h"

@implementation CHDraggableView (Avatar)

static CHAvatarView *lightView;

+ (id)draggableViewWithImage:(UIImage *)image
{
    CHDraggableView *view = [[CHDraggableView alloc] initWithFrame:CGRectMake(0, 0, 66, 66)];

    lightView = [[CHAvatarView alloc] initWithFrame:CGRectInset(view.bounds, 2, 2)];
    lightView.backgroundColor = [UIColor clearColor];
    [lightView setImage:[UIImage imageNamed:@"light.png"]];
    lightView.center = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
    [view addSubview:lightView];
    [lightView setHidden:YES];

    CHAvatarView *avatarView = [[CHAvatarView alloc] initWithFrame:CGRectInset(view.bounds, 8, 8)];
    avatarView.backgroundColor = [UIColor clearColor];
    [avatarView setImage:image];
    avatarView.center = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
    [view addSubview:avatarView];

    return view;
}

- (void)lightViewSetHidden:(BOOL)flag
{
    [lightView setHidden:flag];
}

@end
