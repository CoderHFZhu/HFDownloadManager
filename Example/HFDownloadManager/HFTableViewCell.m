//
//  HFTableViewCell.m
//  HFDownloadManager
//
//  Created by zack on 2017/3/29.
//  Copyright © 2017年 zack. All rights reserved.
//

#import "HFTableViewCell.h"
#import "HFDownloadManager.h"
#import "HFModel.h"

@interface HFTableViewCell()
@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLab;
@property (weak, nonatomic) IBOutlet UILabel *sizeLab;
@property (weak, nonatomic) IBOutlet UILabel *speedLab;
@end
@implementation HFTableViewCell

-(void)setModel:(HFModel *)model{
    _model = model;
    
    self.nameLab.text = model.name;
    //检查之前是否已经下载，若已经下载，获取下载进度。
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:model.destinationPath];
    if(exist)
    {
        //获取原来的下载进度
        self.progressView.progress = [[HFDownloadManager shredManager] lastProgress:model.url];
        //获取原来的文件已下载部分大小及文件总大小
        self.sizeLab.text = [[HFDownloadManager shredManager] filesSize:model.url];
        //原来的进度
        self.progressLab.text = [NSString stringWithFormat:@"%.2f%%",self.progressView.progress*100];
    }
    if(self.progressView.progress == 1.0)
    {
        [self.downloadBtn setTitle:@"完成" forState:UIControlStateNormal];
        self.downloadBtn.enabled=NO;
    }
    else if(self.progressView.progress>0.0)
        [self.downloadBtn setTitle:@"恢复" forState:UIControlStateNormal];
    else
        [self.downloadBtn setTitle:@"开始" forState:UIControlStateNormal];
    
}



- (IBAction)touchDownloadBtn:(UIButton *)sender {
    
    
    
    if([sender.currentTitle isEqualToString:@"开始"]||[sender.currentTitle isEqualToString:@"恢复"])
    {
        [sender setTitle:@"暂停" forState:UIControlStateNormal];
        
        //添加下载任务
        [[HFDownloadManager shredManager] downloadWithUrlString:self.model.url toPath:self.model.destinationPath process:^(float progress, NSString *sizeString, NSString *speedString) {
       
          
            dispatch_sync(dispatch_get_main_queue(), ^{
                //更新进度条的进度值
                self.progressView.progress=progress;
                //更新进度值文字
                self.progressLab.text=[NSString stringWithFormat:@"%.2f%%",progress*100];
                //更新文件已下载的大小
                self.sizeLab.text=sizeString;
                //显示网速
                self.speedLab.text=speedString;
                
                
            });
        } completion:^{
            dispatch_sync(dispatch_get_main_queue(), ^{

                [sender setTitle:@"完成" forState:UIControlStateNormal];
                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"提示" message:[NSString stringWithFormat:@"%@下载完成✅",self.model.name] delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
                [alert show];
            });
            
        } failure:^(NSError *error) {
            dispatch_sync(dispatch_get_main_queue(), ^{

                [[HFDownloadManager shredManager] cancelDownloadTaskWithURLString:self.model.url];
                [sender setTitle:@"恢复" forState:UIControlStateNormal];
                UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alert show];
            });
            
        }];
    }
    else if([sender.currentTitle isEqualToString:@"暂停"])
    {
        [sender setTitle:@"恢复" forState:UIControlStateNormal];
        [[HFDownloadManager shredManager] cancelDownloadTaskWithURLString:self.model.url];
      
    }

    
    
    
    
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
