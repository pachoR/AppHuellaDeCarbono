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
    [self loadNotifications];
}

- (void) loadDashboardData {
    NSArray<Actividad *> *actividades = [self.dbManager getAllActividades];
    self.ActividadesCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)actividades.count];
    
    float huellaKgCO2 = 0.0;
    for (Actividad *actividad in actividades) {
        printf("cantidad: %2.f\n", actividad.cantidad);
        huellaKgCO2 += actividad.cantidad;
    }
    
    self.HuellaCarbonoScore.text = [NSString stringWithFormat:@"%.2f", huellaKgCO2];
    
    NSInteger racha = [self.dbManager getRachaCount];
    self.RachaCount.text = [NSString stringWithFormat:@"%d", (int)racha];
}

# pragma mark - Notificaciones

- (void) loadNotifications {
    [[NSNotificationCenter defaultCenter]
         addObserver:self
            selector:@selector(handleActividadAgregada)
                name:@"ActividadAgregada"
              object:nil];
}

- (void) handleActividadAgregada {
    [self loadDashboardData];
}

@end
