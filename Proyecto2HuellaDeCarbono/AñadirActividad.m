#import "AñadirActividad.h"

@interface An_adirActividad ()
@property (nonatomic, assign) float currentValue;
@property (nonatomic, strong) NSString *currentUnit;
@end

@implementation An_adirActividad

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupInitialState];
}

- (void)setupInitialState {
    // Configurar stepper
    self.stepperControl.minimumValue = 0;
    self.stepperControl.maximumValue = 1000;
    self.stepperControl.stepValue = 0.5;
    self.stepperControl.value = 0;
    
    // Estado inicial
    self.currentValue = 0;
    [self updateLabelsForSegment:0];
    [self updateIncreaseScore];
}

- (void)updateLabelsForSegment:(NSInteger)segmentIndex {
    switch (segmentIndex) {
        case 0: // Transporte
            self.LabelTipoConsumo.text = @"Kilómetros recorridos (km):";
            self.currentUnit = @"km";
            break;
        case 1: // Energía
            self.LabelTipoConsumo.text = @"Energía consumida (kWh):";
            self.currentUnit = @"kWh";
            break;
        case 2: // Alimentación
            self.LabelTipoConsumo.text = @"Alimento consumido (kg):";
            self.currentUnit = @"kg";
            break;
        default:
            break;
    }
}

- (void)updateIncreaseScore {
    self.IncreaseScore.text = [NSString stringWithFormat:@"%.1f", self.currentValue];
}

- (float)calculateCO2ForCurrentSelection {
    NSInteger segmentIndex = self.SegmentTipoActividad.selectedSegmentIndex;
    float co2 = 0.0;
    
    switch (segmentIndex) {
        case 0: // Transporte - 0.18 por KM
            co2 = self.currentValue * 0.18;
            break;
        case 1: // Energía - 0.25 por kWh
            co2 = self.currentValue * 0.25;
            break;
        case 2: // Alimentación - 1.0 por KG
            co2 = self.currentValue * 1.0;
            break;
        default:
            break;
    }
    
    return co2;
}

- (NSString *)getTipoActividadString {
    NSInteger segmentIndex = self.SegmentTipoActividad.selectedSegmentIndex;
    
    switch (segmentIndex) {
        case 0: return @"transporte";
        case 1: return @"energia";
        case 2: return @"alimentacion";
        default: return @"otro";
    }
}

#pragma mark - IBActions

- (IBAction)SegmentTipoActividadChanged:(id)sender {
    [self updateLabelsForSegment:self.SegmentTipoActividad.selectedSegmentIndex];
    // Resetear valor cuando cambia el segmento
    self.currentValue = 0;
    self.stepperControl.value = 0;
    [self updateIncreaseScore];
}

- (IBAction)IncreaseStepper:(id)sender {
    self.currentValue = self.stepperControl.value;
    [self updateIncreaseScore];
}

- (IBAction)Añadir:(id)sender {
    if (self.currentValue <= 0) {
        [self showAlertWithTitle:@"Error" message:@"El valor debe ser mayor a 0"];
        return;
    }
    
    // Calcular CO2
    float co2Ahorrado = [self calculateCO2ForCurrentSelection];
    NSString *tipoActividad = [self getTipoActividadString];
    
    // Crear y guardar actividad
    Actividad *actividad = [[Actividad alloc] init];
    actividad.tipoAct = tipoActividad;
    actividad.cantidad = co2Ahorrado;
    actividad.fecha = [NSDate date];
    
    DatabaseManager *dbManager = [DatabaseManager sharedManager];
    BOOL success = [dbManager insertActividad:actividad];
    
    if (success) {
        [self showAlertWithTitle:@"Éxito"
                         message:[NSString stringWithFormat:@"Actividad agregada correctamente\n%.1f %@ = %.2f kg CO2",
                                  self.currentValue, self.currentUnit, co2Ahorrado]]; // 2 segundos
        
        // Resetear valores
        self.currentValue = 0;
        self.stepperControl.value = 0;
        [self updateIncreaseScore];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ActividadAgregada" object:nil];
        
        // Cerrar la pantalla después de que se cierre el alert
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    } else {
        [self showAlertWithTitle:@"Error" message:@"No se pudo guardar la actividad"];
    }
}

// Método actualizado con opción de auto-dismiss
- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
//    if (!autoDismiss) {
//        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
//                                                           style:UIAlertActionStyleDefault
//                                                         handler:nil];
//        [alert addAction:okAction];
//    }
    
    [self presentViewController:alert animated:YES completion:nil];
//    
//    if (autoDismiss) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [alert dismissViewControllerAnimated:YES completion:nil];
//        });
//    }
}
@end
