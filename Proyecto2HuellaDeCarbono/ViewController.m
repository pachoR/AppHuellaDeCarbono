//
//  ViewController.m
//  Proyecto2HuellaDeCarbono
//
//  Created by Alejandro Francisco Ruiz Guerrero on 29/11/25.
//

#import "ViewController.h"
#import "DatabaseManager.h"

@interface ViewController ()
@property (nonatomic, strong) DatabaseManager *dbManager;
@property (nonatomic, strong) NSTimer *updateTimer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dbManager = [DatabaseManager sharedManager];
    [self.dbManager initializeDatabase];
    // Do any additional setup after loading the view.
    [self loadDashboardData];
}

- (void) loadDashboardData {
    NSLog(@"loadDashboardData");
    printf("loadDashbaordData\n");
}


#pragma mark - Helper Methods
- (NSDate *)getStartOfCurrentMonth {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:[NSDate date]];
    return [calendar dateFromComponents:components];
}

- (void)updateDashboardUI:(float)co2 racha:(NSInteger)racha actividades:(NSInteger)actividades {
    // Actualizar Huella de Carbono (CO2 ahorrado hoy)
    self.HuellaCarbonoScore.text = [NSString stringWithFormat:@"%.1f kg", co2];
    
    // Actualizar Racha
    self.RachaCount.text = [NSString stringWithFormat:@"%ld", (long)racha];
    
    // Actualizar Actividades
    self.ActividadesCount.text = [NSString stringWithFormat:@"%ld", (long)actividades];
    
    // Log para debug
    NSLog(@"Dashboard actualizado - CO2: %.1f kg, Racha: %ld días, Actividades: %ld",
          co2, (long)racha, (long)actividades);
}

@end
