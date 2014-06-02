//
//  CFStopSuggestionView.m
//  CF
//
//  Created by Radu Dutzan on 5/31/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFStopSuggestionView.h"
#import "CFStopSignView.h"
#import "CFStopServicesButtonArrayView.h"

@interface CFStopSuggestionView () <CFStopServicesButtonArrayViewDelegate>

@property (nonatomic, strong) CFStopSignView *stopSignView;
@property (nonatomic, strong) CFStopServicesButtonArrayView *stopServicesView;

@end

@implementation CFStopSuggestionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        _stopSignView = [[CFStopSignView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 52.0)];
        [self addSubview:_stopSignView];
        
        _stopServicesView = [[CFStopServicesButtonArrayView alloc] initWithFrame:CGRectMake(0, _stopSignView.bounds.size.height, frame.size.width, 0)];
        _stopServicesView.delegate = self;
        [self addSubview:_stopServicesView];
    }
    return self;
}

- (void)setStop:(CFStop *)stop
{
    self.stopSignView.stop = stop;
    self.stopServicesView.services = stop.services;
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.bounds.size.width, self.stopSignView.bounds.size.height + self.stopServicesView.bounds.size.height);
}

- (void)servicesButtonArrayViewDidSelectService:(NSString *)serviceName
{
    [self.delegate stopSuggestionViewDidSelectService:serviceName directionString:@"lol"];
}

@end
