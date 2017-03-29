//
//  HFViewController.m
//  HFDownloadManager
//
//  Created by zack on 03/29/2017.
//  Copyright (c) 2017 zack. All rights reserved.
//

#import "HFViewController.h"
#import "HFModel.h"
#import "HFTableViewCell.h"
#import <HFDownloadManager/HFDownloadManager.h>
@interface HFViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
/** <#属性解释#>*/
@property (nonatomic ,strong) NSMutableArray *dataArr;
@end
static inline NSString *kCachePath() {
    return ([NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject])
;
}
@implementation HFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    self.dataArr = [NSMutableArray array];
    HFModel *model = [HFModel new];
    model.name = @"Weibo.4.5.3.37575common_wbupdate.1423811415";
    model.url = @"http://dlsw.baidu.com/sw-search-sp/soft/3f/12289/Weibo.4.5.3.37575common_wbupdate.1423811415.exe";
    model.destinationPath = [kCachePath() stringByAppendingPathComponent:model.name];
    [self.dataArr addObject:model];
    
    HFModel *anotherModel = [HFModel new];
    anotherModel.name = @"20071212235955316_2.jpg";
    anotherModel.url = @"http://pica.nipic.com/2007-12-12/20071212235955316_2.jpg";
    anotherModel.destinationPath = [kCachePath() stringByAppendingPathComponent:anotherModel.name];
    [self.dataArr addObject:anotherModel];
    
    HFModel *third = [HFModel new];
    third.name = @"xcode";
    third.url = @"http://dota2.dl.wanmei.com/dota2/client/DOTA2Setup20160329.zip";
    third.destinationPath = [kCachePath() stringByAppendingPathComponent:third.name];
    [self.dataArr addObject:third];

    
}

#pragma mark - UITableView
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArr.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   
    HFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HFTableViewCell"];
    cell.model = self.dataArr[indexPath.row];
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    HFModel *model=[self.dataArr objectAtIndex:indexPath.row];
    [[HFDownloadManager shredManager] removeForUrl:model.url file:model.destinationPath];
    [self.dataArr removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    __weak typeof(self) wkself=self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [wkself.tableView reloadData];
        });
    });

    
}
-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return @"delete";
}

@end
