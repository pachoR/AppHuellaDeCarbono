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
    [self setupViewStyles];
}

- (void) loadStyles {
    
}

- (void) loadDashboardData {
    NSArray<Actividad *> *actividades = [self.dbManager getActividadesHoy];
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


# pragma mark - Styles

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Re-aplicar estilos que dependen del tamaño de las vistas
    [self applyShadows];
}

- (void)setupViewStyles {
    UIColor *baseColor = [self colorFromHexString:@"#079669"];
//    UIColor *baseWhite = [self colorFromHexString:@"#FFFFFF"];
    [self styleNavBar];
    
    [self styleView:self.RachaView withColor:baseColor cornerRadius:12.0];
    [self styleView:self.ActividadesView withColor:baseColor cornerRadius:12.0];
    
    
    [self styleButton:self.EstadisticasButton withColor:baseColor cornerRadius:12.0];
    [self styleButton:self.ObjetivosButton withColor:baseColor cornerRadius:12.0];
    [self styleButton:self.AgregarActividadButton withColor:baseColor
         cornerRadius:12.0];
    
    
    [self styleLabel:self.GenericLabels withColor:baseColor];
    [self styleLabel:self.HuellaCarbonoScore withColor:baseColor];
    [self styleLabel:self.TitleBanner withColor:baseColor];
    
    
    [self applyShadows];
}

- (void)styleNavBar {
    // Esquinas redondeadas
    self.NavBar.layer.cornerRadius = 12.0;
    self.NavBar.layer.masksToBounds = NO;
    self.NavBar.backgroundColor = [UIColor whiteColor];
    
}

- (void)applyShadows {
    // Sombra para NavBar
    self.NavBar.layer.shadowColor = [UIColor blackColor].CGColor;
    self.NavBar.layer.shadowOffset = CGSizeMake(0, 2);
    self.NavBar.layer.shadowRadius = 4.0;
    self.NavBar.layer.shadowOpacity = 0.1;
    self.NavBar.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.NavBar.bounds
                                                            cornerRadius:self.NavBar.layer.cornerRadius].CGPath;
    
    // Sombra para RachaView
    self.RachaView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.RachaView.layer.shadowOffset = CGSizeMake(0, 1);
    self.RachaView.layer.shadowRadius = 3.0;
    self.RachaView.layer.shadowOpacity = 0.08;
    
    // IMPORTANTE: Solo crear shadowPath si la vista tiene tamaño
    if (!CGRectIsEmpty(self.RachaView.bounds)) {
        self.RachaView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.RachaView.bounds
                                                                   cornerRadius:self.RachaView.layer.cornerRadius].CGPath;
    }
    
    // Sombra para ActividadesView
    self.ActividadesView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.ActividadesView.layer.shadowOffset = CGSizeMake(0, 1);
    self.ActividadesView.layer.shadowRadius = 3.0;
    self.ActividadesView.layer.shadowOpacity = 0.08;
    
    if (!CGRectIsEmpty(self.ActividadesView.bounds)) {
        self.ActividadesView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.ActividadesView.bounds
                                                                         cornerRadius:self.ActividadesView.layer.cornerRadius].CGPath;
    }
    
    // Asegurar que las vistas pueden mostrar sombras
    self.RachaView.layer.masksToBounds = NO;
    self.ActividadesView.layer.masksToBounds = NO;
}

- (void)styleView:(UIView *)view withColor:(UIColor *)color cornerRadius:(CGFloat)radius {
    if (!view) return;
    
    // Esquinas redondeadas
    view.layer.cornerRadius = radius;
    view.layer.masksToBounds = NO;
    
    // Color de fondo
    view.backgroundColor = color;
    
    // Opcional: agregar una pequeña sombra interna
    view.layer.borderWidth = 0;
}

- (void)styleButton:(UIButton *)button withColor:(UIColor *)color cornerRadius:(CGFloat)radius {
    if (!button) {
        NSLog(@"No button");
        return;
    };
    
    // Esquinas redondeadas
    button.layer.cornerRadius = radius;
    button.layer.masksToBounds = YES;
    
    // Color de fondo
    button.backgroundColor = color;
    
    // Color del texto (blanco para mejor contraste)
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    // Fuente más prominente
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
}

-(void)styleLabel: (UILabel *)label withColor:(UIColor *)color {
    if (!label) return;
    
    label.textColor = color;
}

// Método auxiliar para crear UIColor desde hex string
- (UIColor *)colorFromHexString:(NSString *)hexString {
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    
    if([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    float alpha = ((baseValue >> 0) & 0xFF)/255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end
