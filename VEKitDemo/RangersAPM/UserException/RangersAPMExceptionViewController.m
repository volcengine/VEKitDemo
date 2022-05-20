//
//  RangersAPMExceptionViewController.m
//  RangersAPM_iOS
//
//  Created by xuminghao.eric on 2020/11/12.
//

#import "RangersAPMExceptionViewController.h"
#import "RangersAPMCellItem.h"
#import <RangersAPM/RangersAPM+UserException.h>

static NSString *const kExceptionTypePlaceholder = @"ExceptionType, Default:ExceptionTypeTest";
static NSString *const kCustomKeyPlaceholder = @"CustomKey, Default:customKeyDemoTest";
static NSString *const kCustomValuePlaceholder = @"CustomValue, Default:customValueDemoTest";
static NSString *const kFilterKeyPlaceholder = @"FilterKey, Default:filterKeyDemoTest";
static NSString *const kFilterValuePlaceholder = @"FilterValue, Default:filterValueDemoTest";
static NSString *const kDefaultAppIDPlaceholder = @"AppID, Default:";
static NSString *const kDefaultAppID = @"194767";

static NSInteger kExceptionCounts = 0;

typedef void (^manualUserExceptionAlertHandler)(NSString *exceptionType, NSString *customKey, NSString *customValue, NSString *filterKey, NSString *filterValue, NSString *appID);

@interface RangersAPMExceptionViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, copy) NSMutableArray *items;

@end

@implementation RangersAPMExceptionViewController

#pragma mark - Test cases

- (void)recordUserException:(NSString *)exceptionType customs:(NSDictionary *)customs filters:(NSDictionary *)filters appID:(NSString *)appID callback:(void (^)(NSError * _Nullable))callback {
    [RangersAPM trackAllThreadsLogExceptionType:exceptionType skippedDepth:0 customParams:customs filters:filters callback:^(NSError * _Nullable error) {
        callback(error);
    }];
}

- (void)userExceptionTrigger {
    BOOL __block success = YES;
    NSInteger exceptionCountsAfterRecord = kExceptionCounts + 5; //由于短时间内无法记录相同的错误，维护一个全局变量，以错误次数作为后缀
    for (NSInteger i = kExceptionCounts; i < exceptionCountsAfterRecord; i++) {
        [self recordUserException:[NSString stringWithFormat:@"ExceptionTypeDemoTest%ld", i] customs:@{@"customKeyDemoTest":@"customValueDemoTest"} filters:@{@"filterKeyDemoTest":@"filterValueDemooTest"} appID:kDefaultAppID callback:^(NSError * _Nullable error) {
            if (error) {
                success = NO;
            }
        }];
    }
    kExceptionCounts = exceptionCountsAfterRecord;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误记录上报成功" message:@"请到RangersAPM平台查看上报的自定义错误日志" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:action];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误记录上报失败" message:@"请重新尝试或手动触发" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:action];
            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}

- (void)manualUserExceptionTrigger {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [self userExceptionAlertWithOKHandler:^(NSString *exceptionType, NSString *customKey, NSString *customValue, NSString *filterKey, NSString *filterValue, NSString *appID) {
            [self recordUserException:exceptionType customs:@{customKey:customValue} filters:@{filterKey:filterValue} appID:appID callback:^(NSError * _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error) {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"自定义错误记录失败" message:[NSString stringWithFormat:@"%@", error] preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                            [alert addAction:action];
                            [self presentViewController:alert animated:YES completion:nil];
                        } else {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"自定义错误记录成功" message:nil preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                            [alert addAction:action];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    });
            }];
        }];
        [self presentViewController:alert animated:YES completion:nil];
    });
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"RangersAPMExceptionCell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    
    self.title = @"自定义错误";
    // Do any additional setup after loading the view.
}

#pragma mark UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RangersAPMExceptionCell"];
    RangersAPMCellItem *item = [self.items objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@",item.title];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RangersAPMCellItem *item = [self.items objectAtIndex:indexPath.row];
    if (item.selectBlock) {
        item.selectBlock();
    }
}

#pragma mark - Lazy-load
- (NSMutableArray *)items
{
    if (!_items) {
        _items = [[NSMutableArray alloc] init];
        
        __weak typeof(self) weakSelf = self;
        void(^userExceptionBlock)(void) = ^{
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf userExceptionTrigger];
            }
        };
        RangersAPMCellItem *userExceptionItem = [RangersAPMCellItem itemWithTitle:@"记录五次自定义错误并上报" block:userExceptionBlock];
        
        void(^manualUserExceptionBlock)(void) = ^{
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf manualUserExceptionTrigger];
            }
        };
        RangersAPMCellItem *manualUserExceptionItem = [RangersAPMCellItem itemWithTitle:@"手动记录自定义错误(五次记录触发一次上报)" block:manualUserExceptionBlock];
        
        [_items addObject:userExceptionItem];
        [_items addObject:manualUserExceptionItem];
    }
    return _items;
}

- (UIAlertController *)userExceptionAlertWithOKHandler:(manualUserExceptionAlertHandler)okHandler{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"定制自定义错误" message:@"请输入自定义信息，不输入则使用默认值" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *exceptionType;
        NSString *customKey;
        NSString *customValue;
        NSString *filterKey;
        NSString *filterValue;
        NSString *aid;
        for (UITextField *text in alert.textFields) {
            if ([text.placeholder isEqualToString:kExceptionTypePlaceholder]) {
                exceptionType = [NSString stringWithString:(text.text.length ? text.text : @"ExceptionTypeTest")];
                continue;;
            }
            if ([text.placeholder isEqualToString:kCustomKeyPlaceholder]) {
                customKey = [NSString stringWithString:(text.text.length ? text.text : @"customKeyTest")];
                continue;;
            }
            if ([text.placeholder isEqualToString:kCustomValuePlaceholder]) {
                customValue = [NSString stringWithString:(text.text.length ? text.text : @"customValueTest")];
                continue;;
            }
            if ([text.placeholder isEqualToString:kFilterKeyPlaceholder]) {
                filterKey = [NSString stringWithString:(text.text.length ? text.text : @"filterKeyTest")];
                continue;;
            }
            if ([text.placeholder isEqualToString:kFilterValuePlaceholder]) {
                filterValue = [NSString stringWithString:(text.text.length ? text.text : @"filterValueTest")];
                continue;;
            }
            if ([text.placeholder isEqualToString:[NSString stringWithFormat:@"%@%@",kDefaultAppIDPlaceholder, kDefaultAppID]]) {
                aid = [NSString stringWithString:(text.text.length ? text.text : kDefaultAppID)];
                continue;;
            }
        }
        
        okHandler(exceptionType, customKey, customValue, filterKey, filterValue, aid);
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = kExceptionTypePlaceholder;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = kCustomKeyPlaceholder;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = kCustomValuePlaceholder;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = kFilterKeyPlaceholder;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = kFilterValuePlaceholder;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = [NSString stringWithFormat:@"%@%@",kDefaultAppIDPlaceholder, kDefaultAppID];
    }];
    [alert addAction:ok];
    [alert addAction:cancel];
    return alert;
}

@end
