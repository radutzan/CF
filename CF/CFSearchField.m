//
//  CFSearchField.m
//  CF
//
//  Created by Radu Dutzan on 6/11/14.
//  Copyright (c) 2014 Onda. All rights reserved.
//

#import "CFSearchField.h"

@interface CFSearchField () <UITextFieldDelegate>

@property (nonatomic, strong) UIImageView *glyphView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, copy, readwrite) NSString *text;

@end

@implementation CFSearchField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _glyphView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16.0, frame.size.height - 3.0)];
        _glyphView.contentMode = UIViewContentModeCenter;
        _glyphView.image = [[UIImage imageNamed:@"searchfield-glyph"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _glyphView.userInteractionEnabled = YES;
        [self addSubview:_glyphView];
        
        UITapGestureRecognizer *glyphTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(glyphTapped)];
        [_glyphView addGestureRecognizer:glyphTap];
        
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(_glyphView.bounds.size.width + 2.0, -1.0, frame.size.width - 1.0 - _glyphView.bounds.size.width, frame.size.height)];
        _textField.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        _textField.returnKeyType = UIReturnKeySearch;
        _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.delegate = self;
        _textField.font = [UIFont fontWithName:DEFAULT_FONT_NAME_MEDIUM size:17.0];
        [self addSubview:_textField];
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.frame = CGRectOffset(_activityIndicator.frame, frame.size.width + 3.0, 12.0);
        [self addSubview:_activityIndicator];
        
        _text = @"";
    }
    return self;
}

- (void)glyphTapped
{
    [self.textField becomeFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.glyphView.tintColor = nil;
    [self.delegate searchFieldDidBeginEditing:self];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
//    self.glyphView.tintColor = [UIColor colorWithWhite:0 alpha:.2];
    [self.activityIndicator stopAnimating];
    [self.delegate searchFieldDidEndEditing:self];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *searchString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    self.text = searchString;
    [self.delegate searchField:self textDidChange:searchString];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    [self.delegate searchField:self textDidChange:@""];
    [self.activityIndicator stopAnimating];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.delegate searchFieldSearchButtonClicked:self];
    return YES;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = placeholder;
    self.textField.placeholder = placeholder;
}

- (BOOL)isEditing
{
    return self.textField.editing;
}

- (void)clear
{
    self.textField.text = @"";
    [self.delegate searchField:self textDidChange:@""];
}

@end
