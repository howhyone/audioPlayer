//
//  ViewController.h
//  audioPlayer
//
//  Created by mac on 2018/4/16.
//  Copyright © 2018年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property(nonatomic, strong)void(^isSelctRecordBlock)(BOOL selected);

@end

