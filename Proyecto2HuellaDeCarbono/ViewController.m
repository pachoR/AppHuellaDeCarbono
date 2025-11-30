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
    NSInteger rachaActual = [self.dbManager getRachaActual];
    
    NSArray<HabitoSostenible *> *habitosHoy = [self.dbManager getHabitosByFecha:[NSDate date]];
    float co2Hoy = 0.0;
    for (HabitoSostenible *habito in habitosHoy) {
        co2Hoy += habito.cantidadCO2Ahorrado;
    }
    
    NSDate *inicioMes = [self getStartOfCurrentMonth];
    NSDate *finMes = [NSDate date];
    NSInteger totalActividades = [self getActividadesEntreFechas:inicioMes y:finMes];
    
    [self updateDashboardUI:co2Hoy racha:rachaActual actividades:totalActividades];
    [self animateLabels];
}


#pragma mark - Helper Methods
- (NSDate *)getStartOfCurrentMonth {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:[NSDate date]];
    return [calendar dateFromComponents:components];
}

- (NSInteger)getActividadesEntreFechas:(NSDate *)inicio y:(NSDate *)fin {
    NSArray<HabitoSostenible *> *todosHabitos = [self.dbManager getAllHabitos];
    NSInteger count = 0;
    
    for (HabitoSostenible *habito in todosHabitos) {
        if ([habito.fecha compare:inicio] != NSOrderedAscending &&
            [habito.fecha compare:fin] != NSOrderedDescending) {
            count++;
        }
    }
    
    return count;
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

#pragma mark - Animaciones
- (void)animateLabels {
    // Animación de entrada con bounce
    [UIView animateWithDuration:0.6
                          delay:0.0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.8
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.HuellaCarbonoScore.transform = CGAffineTransformMakeScale(1.1, 1.1);
        self.RachaCount.transform = CGAffineTransformMakeScale(1.1, 1.1);
        self.ActividadesCount.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            self.HuellaCarbonoScore.transform = CGAffineTransformIdentity;
            self.RachaCount.transform = CGAffineTransformIdentity;
            self.ActividadesCount.transform = CGAffineTransformIdentity;
        }];
    }];
}
@end
