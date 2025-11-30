#import "MisDesafios.h"
#import "DatabaseManager.h"

@interface MisDesafios ()
@property (strong, nonatomic) NSArray *desafiosEcologicos;
@property (strong, nonatomic) Desafio *desafioActual;
@end

@implementation MisDesafios

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDesafios];
    [self cargarDesafios];
}

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
    
    // Obtener el desafío más reciente de la base de datos
    self.desafioActual = [dbManager getDesafioActual];
    
    if (self.desafioActual) {
        // Si hay desafío en la BD, usar esos valores
        self.Desafio1Texto.text = self.desafioActual.desafioUno;
        self.Desafio2Texto.text = self.desafioActual.desafioDos;
    } else {
        // Si la BD está vacía, generar desafíos random
        [self generarDesafiosRandom];
    }
}

- (void)generarDesafiosRandom {
    if (self.desafiosEcologicos.count < 2) return;
    
    // Obtener dos desafíos diferentes aleatorios
    NSInteger index1 = arc4random_uniform((uint32_t)self.desafiosEcologicos.count);
    NSInteger index2;
    
    do {
        index2 = arc4random_uniform((uint32_t)self.desafiosEcologicos.count);
    } while (index2 == index1);
    
    NSString *desafio1 = self.desafiosEcologicos[index1];
    NSString *desafio2 = self.desafiosEcologicos[index2];
    
    // Actualizar los labels
    self.Desafio1Texto.text = desafio1;
    self.Desafio2Texto.text = desafio2;
    
    // Crear objeto Desafio temporal
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
