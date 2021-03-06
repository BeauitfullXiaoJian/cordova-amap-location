//
//  MapViewController.m
//  HelloCordova
//
//  Created by  anasit on 2019/2/9.
//

#import "MapViewController.h"

@interface MapViewController ()<AMapSearchDelegate,MAMapViewDelegate,AMapNaviDriveManagerDelegate,AMapNaviDriveViewDelegate>

@property AMapSearchAPI *search;
@property MAMapView *mapView;
@property AMapNaviDriveView *driveView;
@property NSMutableArray<MAPointAnnotation *> *annotationa;
@property (weak, nonatomic) IBOutlet UIView *mapContainer;
@property (weak, nonatomic) IBOutlet UINavigationItem *headerBar;

@end

@implementation MapViewController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [AMapServices sharedServices].enableHTTPS = YES;
    _mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    [_mapContainer addSubview:_mapView];
    [_mapView setZoomLevel:12 animated:YES];
    _mapView.showsUserLocation = YES;
    _mapView.userTrackingMode = MAUserTrackingModeFollow;
    _mapView.delegate = self;
    _annotationa = [[NSMutableArray alloc] init];
    
    // 设置地图标记
     [self setMarks];
    
    // 设置标题，返回按钮
     _headerBar.title = @"附近的门店";
     _headerBar.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(backAction)];
}

- (void)showNavigate:(MAPointAnnotation *)annotion{
    _driveView = [[AMapNaviDriveView alloc] initWithFrame:self.view.bounds];
    _driveView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [_driveView setDelegate:self];
    [self.view addSubview:_driveView];
    AMapNaviPoint * end = [AMapNaviPoint locationWithLatitude: annotion.coordinate.latitude longitude:annotion.coordinate.longitude];
    [[AMapNaviDriveManager sharedInstance] calculateDriveRouteWithEndPoints:@[end] wayPoints:nil drivingStrategy:17];
    [[AMapNaviDriveManager sharedInstance] setDelegate:self];
    [[AMapNaviDriveManager sharedInstance] addDataRepresentative:_driveView];
    NSLog(@"????????????????????????");
}

- (void)backAction{
    NSLog(@"返回");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doSearch:(NSString*)searchKey location:(CLLocation *)location{
    self.search = [[AMapSearchAPI alloc] init];
    self.search.delegate = self;
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    request.location = [AMapGeoPoint locationWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    request.keywords = searchKey;
    request.sortrule = 0;
    request.requireExtension = YES;
    [self.search AMapPOIAroundSearch:request];
    NSLog(@"开始查询");
}

- (void)setMarks{
    for(NSDictionary * mark in _marks){
        NSString *title = [mark objectForKey:@"title"];
        NSString *subtitle = [mark objectForKey:@"snippet"];
        NSString *ln = [mark objectForKey:@"ln"];
        NSString *lt = [mark objectForKey:@"lt"];
        NSLog(@"地点名称：%@",title);
        MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
        pointAnnotation.coordinate = CLLocationCoordinate2DMake(lt.doubleValue, ln.doubleValue);
        pointAnnotation.title = title;
        pointAnnotation.subtitle = subtitle;
        [_mapView addAnnotation:pointAnnotation];
    }
}


- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    NSLog(@"查询结束");
    NSLog(@"清空之前的标注");
    [_mapView removeAnnotations:_annotationa];
    [_annotationa removeAllObjects];
    for(AMapPOI* poi in response.pois){
        NSLog(@"地点名称：%@",poi.name);
        MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
        pointAnnotation.coordinate = CLLocationCoordinate2DMake(poi.location.latitude, poi.location.longitude);
        pointAnnotation.title = poi.name;
        pointAnnotation.subtitle = poi.address;
        [_mapView addAnnotation:pointAnnotation];
        [_annotationa addObject:pointAnnotation];
    }
}

- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error{
    NSLog(@"查询错误");
}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation{
    if(updatingLocation){
        CLLocation *location = userLocation.location;
        NSLog(@"用户位置变化(%f,%f,%d)",location.coordinate.latitude,location.coordinate.longitude,updatingLocation);
        if(_annotationa.count==0){
            // [self doSearch:@"煌上煌" location:location];
        }
    }
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAUserLocation class]]) {
        return nil;
    }
    
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *reuseIndetifier = @"annotationReuseIndetifier";
        CustomAnnotationView *annotationView = (CustomAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[CustomAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
        }
        annotationView.canShowCallout= NO;
        annotationView.animatesDrop = YES;
        annotationView.draggable = YES;
        annotationView.pinColor = MAPinAnnotationColorPurple;
        
        // 设置中心点偏移，使得标注底部中间点成为经纬度对应点
        // annotationView.centerOffset = CGPointMake(0, -18);
        annotationView.parentCtr = self;
        return annotationView;
    }
    return nil;
}

- (void)driveManagerOnCalculateRouteSuccess:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onCalculateRouteSuccess");
    //显示路径或开启导航
    [[AMapNaviDriveManager sharedInstance] startGPSNavi];
}

/**
 * @brief 导航界面关闭按钮点击时的回调函数
 * @param driveView 驾车导航界面
 */
- (void)driveViewCloseButtonClicked:(AMapNaviDriveView *)driveView{
    [[AMapNaviDriveManager sharedInstance] stopNavi];
    [[AMapNaviDriveManager sharedInstance] removeDataRepresentative:_driveView];
    [[AMapNaviDriveManager sharedInstance] setDelegate:nil];
    [_driveView removeFromSuperview];
}

@end
