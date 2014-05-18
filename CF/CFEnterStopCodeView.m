//
//  CFEnterStopCodeView.m
//  CF
//
//  Created by Radu Dutzan on 11/16/13.
//  Copyright (c) 2013 Onda. All rights reserved.
//

#import "CFEnterStopCodeView.h"
#import "CFElPeA.h"

@interface CFEnterStopCodeView () <UITextFieldDelegate>

@end

@implementation CFEnterStopCodeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width - 240.0) / 2, (frame.size.height - 240.0) / 2, 240.0, 240.0)];
        [self addSubview:containerView];
        
        UILabel *enterStopCodeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, containerView.bounds.size.width, 165.0)];
        enterStopCodeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:46.0];
        enterStopCodeLabel.text = NSLocalizedString(@"ENTER_STOP_CODE", nil);
        enterStopCodeLabel.numberOfLines = 2;
        enterStopCodeLabel.textColor = [UIColor colorWithWhite:0 alpha:0.65];
        [containerView addSubview:enterStopCodeLabel];
        
        self.elPeA = [[CFElPeA alloc] initWithFrame:CGRectMake(0, enterStopCodeLabel.bounds.size.height, 200.0, 62.0)];
        self.elPeA.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:46.0];
        self.elPeA.placeholder = @"PA420";
        self.elPeA.autocorrectionType = UITextAutocorrectionTypeNo;
        self.elPeA.returnKeyType = UIReturnKeyGo;
        self.elPeA.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        self.elPeA.delegate = self;
        self.elPeA.layer.cornerRadius = 5.0;
        self.elPeA.layer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.07].CGColor;
        self.elPeA.layer.sublayerTransform = CATransform3DMakeTranslation(10.0, 0, 0);
        [containerView addSubview:self.elPeA];
        
        UIButton *letsGo = [UIButton buttonWithType:UIButtonTypeSystem];
        letsGo.frame = CGRectMake(self.elPeA.bounds.size.width + 4.0, self.elPeA.frame.origin.y, 44.0, 62.0);
        [letsGo setImage:[UIImage imageNamed:@"button-go"] forState:UIControlStateNormal];
        [letsGo addTarget:self action:@selector(submitRequest) forControlEvents:UIControlEventTouchUpInside];
        [containerView addSubview:letsGo];
    }
    return self;
}

- (void)submitRequest
{
    [self.delegate enterStopCodeViewDidEnterStopCode:[self.elPeA.text uppercaseString]];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    string = [string uppercaseString];
    
    self.elPeA.text = [self.elPeA.text stringByReplacingCharactersInRange:range withString:string];
    
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self submitRequest];
    [textField resignFirstResponder];
    
    return YES;
}

@end
