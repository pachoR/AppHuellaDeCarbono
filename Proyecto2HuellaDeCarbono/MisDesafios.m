#import "MisDesafios.h"
#import "DatabaseManager.h"

@interface MisDesafios ()
@property (strong, nonatomic) NSArray *desafiosEcologicos;
@property (strong, nonatomic) Desafio *desafioActual;
@property (weak, nonatomic) IBOutlet UIButton *BotonOtros;
@property (weak, nonatomic) IBOutlet UIButton *BotonGuardar;
@property (weak, nonatomic) IBOutlet UIButton *BotonCompletado;
@end

@implementation MisDesafios

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDesafios];
    [self cargarDesafios];
    [self setupViewStyles];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self applyShadows];
}

- (void)setupViewStyles {
    UIColor *baseColor = [self colorFromHexString:@"#079669"];
    
    // Estilo para BotonCompletado
    [self styleButton:self.BotonCompletado
           withColor:baseColor
       cornerRadius:12.0
      textColor:[UIColor whiteColor]];
    
    // Estilo para BotonGuardar
    [self styleButton:self.BotonGuardar
           withColor:baseColor
       cornerRadius:12.0
      textColor:[UIColor whiteColor]];
    
    // Estilo para BotonOtros (solo color de texto, sin fondo)
    self.BotonOtros.layer.cornerRadius = 12.0;
    self.BotonOtros.layer.borderWidth = 1.0;
    self.BotonOtros.layer.borderColor = baseColor.CGColor;
    [self.BotonOtros setTitleColor:baseColor forState:UIControlStateNormal];
    self.BotonOtros.backgroundColor = [UIColor clearColor];
    self.BotonOtros.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
}

- (void)applyShadows {
    // Sombra solo para BotonCompletado
    self.BotonCompletado.layer.shadowColor = [UIColor blackColor].CGColor;
    self.BotonCompletado.layer.shadowOffset = CGSizeMake(0, 2);
    self.BotonCompletado.layer.shadowRadius = 4.0;
    self.BotonCompletado.layer.shadowOpacity = 0.1;
    self.BotonCompletado.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.BotonCompletado.bounds
                     cornerRadius:self.BotonCompletado.layer.cornerRadius].CGPath;
}

- (void)styleButton:(UIButton *)button withColor:(UIColor *)color cornerRadius:(CGFloat)radius textColor:(UIColor *)textColor {
    if (!button) return;
    
    // Esquinas redondeadas
    button.layer.cornerRadius = radius;
    
    // Color de fondo
    button.backgroundColor = color;
    
    // Color del texto
    [button setTitleColor:textColor forState:UIControlStateNormal];
    
    // Fuente
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    
    // IMPORTANTE: NO usar masksToBounds para que la sombra funcione
    button.layer.masksToBounds = NO;
}

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

// Resto del código permanece igual...

- (void)setupDesafios {
    self.desafiosEcologicos = @[
        @"🚌 Usar transporte público por siete días",
        @"🥦 Reducir el consumo de carne por una semana",
        @"💡 Apagar luces y electrodomésticos cuando no se usen",
        @"🚿 Tomar duchas de máximo 5 minutos",
        @"🛍️ Usar bolsas reutilizables en todas las compras",
        @"🚫 Evitar productos de un solo uso",
        @"🚶 Caminar o usar bicicleta para distancias cortas",
        @"♻️ Separar y reciclar la basura correctamente",
        @"🏠 Comprar productos locales y de temporada",
        @"🧴 Reducir el consumo de plástico",
        @"🌱 Plantar un árbol o cuidar plantas",
        @"🔧 Reparar en lugar de reemplazar objetos",
        @"💧 Usar botella de agua reutilizable",
        @"🍂 Compostar residuos orgánicos",
        @"☀️ Secar la ropa al aire libre en lugar de secadora",
        @"🌡️ Configurar termostato para ahorrar energía",
        @"💡 Usar iluminación LED en toda la casa",
        @"🧹 Participar en una limpieza comunitaria",
        @"📚 Educar a otros sobre prácticas ecológicas",
        @"❄️ Reducir el uso del aire acondicionado"
    ];
}

- (void)cargarDesafios {
    DatabaseManager *dbManager = [DatabaseManager sharedManager];
    
    self.desafioActual = [dbManager getDesafioActual];
    
    if (self.desafioActual) {
        self.Desafio1Texto.text = self.desafioActual.desafioUno;
        self.Desafio2Texto.text = self.desafioActual.desafioDos;
    } else {
        [self generarDesafiosRandom];
    }
}

- (void)generarDesafiosRandom {
    if (self.desafiosEcologicos.count < 2) return;
    
    NSInteger index1 = arc4random_uniform((uint32_t)self.desafiosEcologicos.count);
    NSInteger index2;
    
    do {
        index2 = arc4random_uniform((uint32_t)self.desafiosEcologicos.count);
    } while (index2 == index1);
    
    NSString *desafio1 = self.desafiosEcologicos[index1];
    NSString *desafio2 = self.desafiosEcologicos[index2];
    
    self.Desafio1Texto.text = desafio1;
    self.Desafio2Texto.text = desafio2;
    
    self.desafioActual = [[Desafio alloc] init];
    self.desafioActual.desafioUno = desafio1;
    self.desafioActual.desafioDos = desafio2;
}

- (IBAction)BotonOtros:(id)sender {
    [self generarDesafiosRandom];
}

- (IBAction)BotonGuardar:(id)sender {
    if (!self.desafioActual) return;
    
    DatabaseManager *dbManager = [DatabaseManager sharedManager];
    BOOL success = [dbManager saveDesafiosDiarios:self.desafioActual.desafioUno
                                       desafioDos:self.desafioActual.desafioDos];
    
    if (success) {
        NSLog(@"Desafíos guardados exitosamente");
        [self mostrarAlertaConTitulo:@"Éxito" mensaje:@"Tus desafíos han sido guardados"];
    } else {
        NSLog(@"Error al guardar desafíos");
        [self mostrarAlertaConTitulo:@"Error" mensaje:@"No se pudieron guardar los desafíos"];
    }
}

- (IBAction)BotonCompletado:(id)sender {
    [self mostrarAlertaConTitulo:@"¡Felicidades!" mensaje:@"Has completado tus desafíos ecológicos"];
}

- (void)mostrarAlertaConTitulo:(NSString *)titulo mensaje:(NSString *)mensaje {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:titulo
                                                                   message:mensaje
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
    
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
