//
//  ViewController3.m
//  IBCoder1
//
//  Created by Bowen on 2019/4/29.
//  Copyright © 2019 BowenCoder. All rights reserved.
//

#import "ViewController3.h"

@interface ViewController3 ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *tableArray;

@end

@implementation ViewController3

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialize];
    [self setupUI];
    NSLog(@"%s", __func__);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"%s", __func__);

}

- (void)initialize {
    self.tableArray = @[@"编译速度-远程编译（XCRemoteCache）", @"热修复", @"App瘦身", @"性能监控", @"libpag动画和TGFX图形渲染库", @"filament实时物理渲染引擎", @"React-Native和VL", @"数据驱动（IGListKit）", @"开发效率工具"];
}

- (void)setupUI {
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = ({
        UITableView *tb = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        tb.backgroundColor = [UIColor clearColor];
        tb.dataSource = self;
        tb.delegate = self;
        [self.view addSubview:tb];
        tb;
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor whiteColor];
    }
    cell.textLabel.text = self.tableArray[indexPath.row];
    cell.textLabel.layer.masksToBounds = YES;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"IBGroup3Controller%ld",indexPath.row+1];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *controller = [NSString stringWithFormat:@"IBGroup3Controller%ld",indexPath.row+1];
    Class class = NSClassFromString(controller);
    
    UIViewController *vc = [[class alloc] init];
    vc.title = self.tableArray[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];

}



@end
